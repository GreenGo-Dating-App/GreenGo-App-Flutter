#!/usr/bin/env python3
"""End-user smoke test against the LIVE site: does login reach the app?

Written after a rules deploy produced a grey screen after login. Every check in
that deploy passed - emulator rules tests, a production REST probe - because
they all tested what I believed the app did. None of them opened the app.

This does. It drives a real Chrome against https://greengo-chat.web.app, signs
in with a real account, and then asks the only question that actually mattered:

  after login, is there anything on the screen, and did Firestore deny anything?

Flutter web renders to a canvas, so there is no DOM to assert on. Instead it
watches:
  * console errors, especially `permission-denied` - the outage signature
  * failed network requests to firestore.googleapis.com
  * whether the canvas is still blank after the app should have drawn

Usage:
  python3 tool/e2e_login_smoke.py --email <addr> --password <pw>
  python3 tool/e2e_login_smoke.py            # anonymous checks only
"""

import argparse
import sys
import time

from playwright.sync_api import sync_playwright

URL = "https://greengo-chat.web.app"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--email")
    ap.add_argument("--password")
    ap.add_argument("--url", default=URL)
    ap.add_argument("--headed", action="store_true")
    args = ap.parse_args()

    navigated = None
    console_errors = []
    denied = []
    failed_requests = []

    with sync_playwright() as p:
        # The installed Chrome, not a downloaded chromium: closest to what a
        # real user runs, and avoids `playwright install` on a locked network.
        browser = p.chromium.launch(channel="chrome", headless=not args.headed)
        page = browser.new_page(viewport={"width": 1280, "height": 900})

        def on_console(msg):
            if msg.type in ("error", "warning"):
                text = msg.text
                if "permission-denied" in text or "PERMISSION_DENIED" in text:
                    denied.append(text)
                if msg.type == "error":
                    console_errors.append(text)

        def on_response(res):
            if "firestore.googleapis.com" in res.url and res.status >= 400:
                # The URL is always .../documents:commit - useless on its own.
                # The document paths are in the request body, and they are what
                # says WHICH rule refused.
                detail = ""
                try:
                    body = res.request.post_data or ""
                    import re as _re
                    paths = _re.findall(r'"documents/([^"]{1,80})"', body)
                    if paths:
                        detail = " paths=" + ",".join(sorted(set(paths))[:6])
                except Exception:
                    pass
                failed_requests.append(f"{res.status}{detail}")

        # Firestore's REST transport empties post_data by the time the
        # response event fires, so bodies are captured on the way out and
        # matched up afterwards.
        commits = []

        def on_request(r):
            if "firestore.googleapis.com" in r.url and r.method == "POST":
                try:
                    commits.append(r.post_data or "")
                except Exception:
                    commits.append("")

        page.on("request", on_request)
        page.on("console", on_console)
        page.on("response", on_response)
        page.on("pageerror", lambda e: console_errors.append(f"pageerror: {e}"))

        print(f"opening {args.url}")
        page.goto(args.url, wait_until="load", timeout=90_000)
        # Flutter boots the engine then paints; give it room on a cold CDN.
        page.wait_for_timeout(12_000)

        shot = "tool/e2e_before_login.png"
        page.screenshot(path=shot)
        print(f"  screenshot: {shot}")

        if args.email and args.password:
            print("attempting login")
            # Flutter web draws into a canvas, so there are no input elements to
            # fill. Typing goes to whatever the app has focused; clicking is by
            # coordinate. This is deliberately crude - it is a smoke test, not a
            # UI test, and the assertion is about errors, not about widgets.
            before = page.screenshot()
            page.mouse.click(640, 424)      # email field
            page.keyboard.type(args.email, delay=30)
            page.mouse.click(640, 488)      # password field
            page.keyboard.type(args.password, delay=30)
            # Enter does not submit this form - the button must be clicked.
            # Discovering that took a run that reported PASS while sitting on
            # the login screen, so the navigation check below is not optional.
            page.mouse.click(640, 596)      # Login button
            page.wait_for_timeout(20_000)

            shot = "tool/e2e_after_login.png"
            page.screenshot(path=shot)
            print(f"  screenshot: {shot}")

            after = page.screenshot()
            if before == after:
                print("  LOGIN DID NOT NAVIGATE - the screen is unchanged.")
                print("  Treating this as a failure: a result from a session")
                print("  that never logged in says nothing about login.")
                navigated = False
            else:
                navigated = True
                print("  screen changed after login")

        # Is anything actually drawn? A grey screen is a canvas of one colour.
        variance = page.evaluate(
            """() => {
              const c = document.querySelector('canvas');
              if (!c) return -1;
              try {
                const g = c.getContext('webgl2') || c.getContext('webgl');
                if (g) return -2;              // cannot sample a WebGL canvas
                const ctx = c.getContext('2d');
                const d = ctx.getImageData(0, 0, c.width, c.height).data;
                const seen = new Set();
                for (let i = 0; i < d.length; i += 4000) {
                  seen.add(`${d[i]},${d[i+1]},${d[i+2]}`);
                }
                return seen.size;              // 1 == a single flat colour
              } catch (e) { return -3; }
            }"""
        )

        browser.close()

    print("\n--- result ---")
    print(f"  console errors        : {len(console_errors)}")
    print(f"  permission-denied     : {len(denied)}")
    print(f"  failed Firestore calls: {len(failed_requests)}")
    if variance >= 0:
        print(f"  distinct canvas colours: {variance}"
              f"{'  <- FLAT, likely a blank screen' if variance == 1 else ''}")

    for d in denied[:10]:
        print(f"    DENIED: {d[:160]}")
    for f in failed_requests[:10]:
        print(f"    HTTP  : {f}")
    if failed_requests:
        import re as _re
        paths = set()
        for body in commits:
            for m in _re.finditer(r"documents/([A-Za-z_][A-Za-z0-9_]*)/", body):
                paths.add(m.group(1))
        print(f"    collections written during this session: {sorted(paths)}")
    for e in console_errors[:8]:
        print(f"    ERROR : {e[:160]}")

    bad = bool(denied or failed_requests) or variance == 1
    if navigated is False:
        bad = True
        print("  login never navigated - result is inconclusive, failing")
    print("\n" + ("FAIL - see above" if bad else "PASS - no denials, no failed reads"))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
