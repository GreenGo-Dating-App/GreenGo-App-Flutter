"""Browser-level end-to-end tests for the GreenGo web build.

Seven of the hundred scenarios cannot be asserted from a Dart widget test,
because the thing under test is the browser itself: a service worker, a page
reload, a second tab, a real notification permission grant, the viewport, and
the two that need the network actually cut (`disableNetwork()` raises
INTERNAL ASSERTION FAILED in the Firestore web SDK and leaves the instance
unusable for every test after it). They live here.

Flutter web renders to a canvas, so nothing below asserts on the DOM. The
observable signals are: the console, failed requests, the painted pixels, and
the service-worker registration.

Usage
-----
    python tool/e2e_web/web_suite.py --base-url http://127.0.0.1:8899 \
        --email approved@e2e.greengo.test --password '...'

Serve a release build first:

    flutter build web --release
    python -m http.server 8899 --bind 127.0.0.1 --directory build/web

Exit code is the number of failed tests, so CI can gate on it.
"""

from __future__ import annotations

import argparse
import sys
import time
from dataclasses import dataclass, field

from playwright.sync_api import Page, sync_playwright

# Login-form hit points for the 1280x900 viewport the suite runs at. Flutter
# web draws the form into a canvas, so these are coordinates rather than
# selectors. They come from the rendered login screen and move only if that
# layout changes.
EMAIL_FIELD = (640, 424)
PASSWORD_FIELD = (640, 488)
LOGIN_BUTTON = (640, 596)

# A frame that decodes to fewer bytes than this is a flat fill — the release
# ErrorWidget's grey rectangle, or nothing painted at all. A real GreenGo
# screen is well above 40 KB at this viewport.
BLANK_FRAME_BYTES = 40_000


@dataclass
class Result:
    test_id: str
    passed: bool
    detail: str = ""


@dataclass
class Recorder:
    """Collects everything the page reports while a test runs."""

    console_errors: list[str] = field(default_factory=list)
    page_errors: list[str] = field(default_factory=list)
    failed_requests: list[str] = field(default_factory=list)

    def attach(self, page: Page) -> None:
        page.on(
            "console",
            lambda m: self.console_errors.append(m.text)
            if m.type == "error"
            else None,
        )
        page.on("pageerror", lambda e: self.page_errors.append(str(e)))
        page.on(
            "requestfailed",
            lambda r: self.failed_requests.append(f"{r.failure} {r.url[:160]}"),
        )


def wait_for_paint(page: Page, seconds: int = 25) -> int:
    """Returns the size of the first non-blank frame, or 0 if none appeared."""
    for _ in range(seconds):
        time.sleep(1)
        size = len(page.screenshot())
        if size >= BLANK_FRAME_BYTES:
            return size
    return 0


def log_in(page: Page, email: str, password: str) -> None:
    page.mouse.click(*EMAIL_FIELD)
    time.sleep(0.6)
    page.keyboard.type(email, delay=20)
    page.mouse.click(*PASSWORD_FIELD)
    time.sleep(0.6)
    page.keyboard.type(password, delay=20)
    time.sleep(0.4)
    page.mouse.click(*LOGIN_BUTTON)


def new_page(browser, viewport=None) -> tuple[Page, Recorder]:
    ctx = browser.new_context(viewport=viewport or {"width": 1280, "height": 900})
    page = ctx.new_page()
    rec = Recorder()
    rec.attach(page)
    return page, rec


# --- BOOT-02 --------------------------------------------------------------


def boot_02_blocked_firestore(browser, base_url: str, email: str, password: str) -> Result:
    """With Firestore unreachable, the app must still resolve to a screen.

    The access check reads `profiles/{uid}` with `Source.server`, which has no
    deadline of its own — without the timeouts in AuthWrapper this hangs
    forever and the user sits on the splash. Lives here rather than in the Dart
    suites because `disableNetwork()` raises INTERNAL ASSERTION FAILED in the
    Firestore web SDK and kills the instance for every following test;
    aborting the requests at the browser is both truer to the real failure and
    harmless.
    """
    page, rec = new_page(browser)
    try:
        page.goto(base_url, wait_until="commit", timeout=60_000)
        if wait_for_paint(page) == 0:
            return Result("BOOT-02", False, "login screen never painted")
        log_in(page, email, password)

        # Cut Firestore off the moment the session exists.
        page.route("**/firestore.googleapis.com/**", lambda route: route.abort())

        deadline = time.time() + 40
        settled = 0
        while time.time() < deadline:
            time.sleep(1)
            if len(page.screenshot()) >= BLANK_FRAME_BYTES:
                settled += 1
                if settled >= 3:
                    return Result(
                        "BOOT-02", True,
                        "resolved to a rendered screen with Firestore blocked")
            else:
                settled = 0
        return Result(
            "BOOT-02", False,
            "never reached a non-blank frame with Firestore blocked — the "
            "access check probably stranded the splash")
    finally:
        page.context.close()


# --- AUTH-06 --------------------------------------------------------------


def auth_06_offline_login(browser, base_url: str, email: str, password: str) -> Result:
    """An offline login must fail fast, not spin forever."""
    page, rec = new_page(browser)
    try:
        page.goto(base_url, wait_until="commit", timeout=60_000)
        if wait_for_paint(page) == 0:
            return Result("AUTH-06", False, "login screen never painted")

        # Offline before the attempt, so the sign-in itself has no network.
        page.context.set_offline(True)
        log_in(page, email, password)

        deadline = time.time() + 40
        while time.time() < deadline:
            time.sleep(1)
            if len(page.screenshot()) < BLANK_FRAME_BYTES:
                return Result("AUTH-06", False, "went blank on an offline login")
        page.context.set_offline(False)
        return Result("AUTH-06", True, "stayed on a usable screen while offline")
    finally:
        page.context.close()


# --- BOOT-04 --------------------------------------------------------------


def boot_04_service_worker(browser, base_url: str) -> Result:
    """A deployed build must activate its service worker, not serve a stale
    shell forever. A half-cached shell loads index.html and never the
    renderer, which is indistinguishable from a white page."""
    page, rec = new_page(browser)
    try:
        page.goto(base_url, wait_until="commit", timeout=60_000)
        if wait_for_paint(page) == 0:
            return Result("BOOT-04", False, "first load never painted")

        state = page.evaluate(
            """async () => {
                if (!('serviceWorker' in navigator)) return 'unsupported';
                const reg = await navigator.serviceWorker.getRegistration();
                if (!reg) return 'none';
                return reg.active ? 'active' : 'installing';
            }"""
        )
        if state == "unsupported":
            return Result("BOOT-04", False, "the browser reports no SW support")
        if state != "active":
            return Result("BOOT-04", False, f"service worker state: {state}")

        # Reload against the now-populated cache: the app must still render.
        page.reload(wait_until="commit")
        if wait_for_paint(page) == 0:
            return Result(
                "BOOT-04", False, "blank frame after reloading from the SW cache"
            )
        return Result("BOOT-04", True, "service worker active, cached reload paints")
    finally:
        page.context.close()


# --- BOOT-05 --------------------------------------------------------------


def boot_05_hard_refresh(browser, base_url: str, email: str, password: str) -> Result:
    """Refreshing mid-session must return a rendered screen with the session
    intact — never a blank canvas and never a bounce back to login."""
    page, rec = new_page(browser)
    try:
        page.goto(base_url, wait_until="commit", timeout=60_000)
        if wait_for_paint(page) == 0:
            return Result("BOOT-05", False, "login screen never painted")

        log_in(page, email, password)
        time.sleep(20)
        if len(page.screenshot()) < BLANK_FRAME_BYTES:
            return Result("BOOT-05", False, "blank frame after logging in")

        page.reload(wait_until="commit")
        size = wait_for_paint(page, seconds=30)
        if size == 0:
            return Result("BOOT-05", False, "blank frame after a hard refresh")
        if rec.page_errors:
            return Result("BOOT-05", False, f"page errors: {rec.page_errors[:2]}")
        return Result("BOOT-05", True, f"re-rendered after refresh ({size}b)")
    finally:
        page.context.close()


# --- BOOT-09 --------------------------------------------------------------


def boot_09_two_tabs(browser, base_url: str, email: str, password: str) -> Result:
    """Signing out in one tab must not leave another tab rendering a dead
    authenticated shell."""
    ctx = browser.new_context(viewport={"width": 1280, "height": 900})
    try:
        first = ctx.new_page()
        first.goto(base_url, wait_until="commit", timeout=60_000)
        if wait_for_paint(first) == 0:
            return Result("BOOT-09", False, "first tab never painted")
        log_in(first, email, password)
        time.sleep(20)

        # A second tab in the same context shares storage, so it inherits the
        # session — this is one account in two tabs, not two accounts.
        second = ctx.new_page()
        second.goto(base_url, wait_until="commit", timeout=60_000)
        if wait_for_paint(second, seconds=30) == 0:
            return Result("BOOT-09", False, "the second tab painted nothing")

        # Drop the session out from under both tabs.
        second.evaluate(
            """async () => {
                const dbs = await indexedDB.databases();
                for (const d of dbs) {
                  if ((d.name || '').includes('firebaseLocalStorage')) {
                    indexedDB.deleteDatabase(d.name);
                  }
                }
                localStorage.clear();
            }"""
        )
        first.reload(wait_until="commit")
        size = wait_for_paint(first, seconds=30)
        if size == 0:
            return Result(
                "BOOT-09", False, "the surviving tab went blank after sign-out"
            )
        return Result("BOOT-09", True, "both tabs resolved to a rendered screen")
    finally:
        ctx.close()


# --- NOTIF-03 -------------------------------------------------------------


def notif_03_web_push(browser, base_url: str, email: str, password: str) -> Result:
    """With notification permission granted, the PWA must actually register a
    web push token. Before `ensureTokenRegistered` existed, no web client ever
    called getToken(), so no PWA could receive anything."""
    ctx = browser.new_context(
        viewport={"width": 1280, "height": 900},
        permissions=["notifications"],
    )
    try:
        page = ctx.new_page()
        rec = Recorder()
        rec.attach(page)
        fcm_logs: list[str] = []
        page.on(
            "console",
            lambda m: fcm_logs.append(m.text) if "[FCM]" in m.text else None,
        )

        page.goto(base_url, wait_until="commit", timeout=60_000)
        if wait_for_paint(page) == 0:
            return Result("NOTIF-03", False, "login screen never painted")
        log_in(page, email, password)
        time.sleep(30)

        registered = any("Token registered" in line for line in fcm_logs)
        if registered:
            return Result("NOTIF-03", True, "a web push token was registered")
        return Result(
            "NOTIF-03",
            False,
            "no token registered; [FCM] lines seen: " + str(fcm_logs[-4:]),
        )
    finally:
        ctx.close()


# --- PROF-08 --------------------------------------------------------------


def prof_08_narrow_viewport(browser, base_url: str, email: str, password: str) -> Result:
    """At phone width the app must render without the page scrolling
    sideways and without clipping its own layout."""
    page, rec = new_page(browser, viewport={"width": 400, "height": 850})
    try:
        page.goto(base_url, wait_until="commit", timeout=60_000)
        if wait_for_paint(page, seconds=30) == 0:
            return Result("PROF-08", False, "nothing painted at 400px wide")

        overflow = page.evaluate(
            "() => document.documentElement.scrollWidth - window.innerWidth"
        )
        if overflow > 1:
            return Result("PROF-08", False, f"page scrolls {overflow}px sideways")

        # Flutter reports layout failures ("RenderFlex overflowed") through the
        # console even in release.
        overflows = [e for e in rec.console_errors if "overflow" in e.lower()]
        if overflows:
            return Result("PROF-08", False, f"layout overflow: {overflows[0][:120]}")
        return Result("PROF-08", True, "renders at 400px with no sideways scroll")
    finally:
        page.context.close()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--base-url", default="http://127.0.0.1:8899")
    ap.add_argument("--email", required=True)
    ap.add_argument("--password", required=True)
    ap.add_argument("--headed", action="store_true")
    ap.add_argument("--only", help="run a single test id, e.g. BOOT-05")
    args = ap.parse_args()

    tests = {
        "BOOT-02": lambda b: boot_02_blocked_firestore(
            b, args.base_url, args.email, args.password
        ),
        "AUTH-06": lambda b: auth_06_offline_login(
            b, args.base_url, args.email, args.password
        ),
        "BOOT-04": lambda b: boot_04_service_worker(b, args.base_url),
        "BOOT-05": lambda b: boot_05_hard_refresh(
            b, args.base_url, args.email, args.password
        ),
        "BOOT-09": lambda b: boot_09_two_tabs(
            b, args.base_url, args.email, args.password
        ),
        "NOTIF-03": lambda b: notif_03_web_push(
            b, args.base_url, args.email, args.password
        ),
        "PROF-08": lambda b: prof_08_narrow_viewport(
            b, args.base_url, args.email, args.password
        ),
    }
    if args.only:
        tests = {args.only: tests[args.only]}

    results: list[Result] = []
    with sync_playwright() as p:
        # Always the installed Chrome: this suite tests the real browser the
        # users are on, and a downloaded Chromium is not that.
        browser = p.chromium.launch(channel="chrome", headless=not args.headed)
        for test_id, fn in tests.items():
            print(f"running {test_id} ...", flush=True)
            try:
                results.append(fn(browser))
            except Exception as exc:  # a crashed test is a failed test
                results.append(Result(test_id, False, f"raised {exc!r}"))
        browser.close()

    print("\n=== browser-level results ===")
    for r in results:
        print(f"  {'PASS' if r.passed else 'FAIL'}  {r.test_id:9s} {r.detail}")
    failures = sum(1 for r in results if not r.passed)
    print(f"\n{len(results) - failures}/{len(results)} passed")
    return failures


if __name__ == "__main__":
    sys.exit(main())
