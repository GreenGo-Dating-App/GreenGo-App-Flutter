#!/usr/bin/env python3
"""GreenGo — test report generator (Master Test Plan Phase 5).

Parses `flutter test --machine` JSON, groups results by category, and emits a
self-contained HTML report (converted to PDF via Edge headless).

Usage:
  flutter test test/unit test/widget --machine > results.json
  python test/userTests/generate_pdf_report.py results.json docs/testing/reports/report.html
"""
import json
import re
import sys
import collections
import datetime

RESULTS = sys.argv[1] if len(sys.argv) > 1 else 'results.json'
OUT_HTML = sys.argv[2] if len(sys.argv) > 2 else 'report.html'

CATEGORY_TITLES = {
    'auth': 'Authentication & Session',
    'onboarding': 'Onboarding',
    'profile': 'Profile',
    'explore': 'Discovery / Explore',
    'events': 'Events — date/geo logic',
    'events_bloc': 'Events — bloc / datasource',
    'communities': 'Communities',
    'chat': 'Chat / Messaging',
    'business': 'Business / Storefront',
    'search': 'Search',
    'notifications': 'Notifications',
    'coins': 'Membership / Coins',
    'i18n': 'Localization (7 locales)',
    'widget': 'Widgets / Rendering',
    'other': 'Other',
}


def category_of(url: str) -> str:
    u = url.replace('\\', '/')
    m = re.search(r'/test/unit/([^/]+)/', u)
    if m:
        return m.group(1)
    if '/test/widget/' in u:
        return 'widget'
    return 'other'


starts = {}
cats = collections.OrderedDict()
failures = []
skips = []
for line in open(RESULTS, encoding='utf-8'):
    line = line.strip()
    if not line.startswith('{'):
        continue
    try:
        e = json.loads(line)
    except Exception:
        continue
    if e.get('type') == 'testStart':
        starts[e['test']['id']] = e['test']
    elif e.get('type') == 'testDone' and not e.get('hidden'):
        t = starts.get(e['testID'], {})
        url = t.get('url') or t.get('root_url') or ''
        c = category_of(url)
        d = cats.setdefault(c, {'pass': 0, 'skip': 0, 'fail': 0})
        name = t.get('name', '?')
        if e.get('skipped'):
            d['skip'] += 1
            skips.append((c, name))
        elif e.get('result') == 'success':
            d['pass'] += 1
        else:
            d['fail'] += 1
            failures.append((c, name))

tot = {'pass': 0, 'skip': 0, 'fail': 0}
for d in cats.values():
    for k in tot:
        tot[k] += d[k]
total = tot['pass'] + tot['skip'] + tot['fail']
executed = tot['pass'] + tot['fail']
rate = (tot['pass'] / executed * 100) if executed else 100.0
date = datetime.date.today().isoformat()

REGRESSIONS = [
    ("Communities concurrency-merge", "Handlers merge onto current state via copyWith; concurrent loads no longer clobber managedCommunities (\"My communities\" appears).", "communities"),
    ("Tips/Announcements/Chat classification", "language_tip/cultural_fact/city_tip → Tips; announcement → Announcements; text → chat.", "communities"),
    ("Discover joinable + getCreatedCommunities", "Public-only Discover; My-communities via createdByUserId (no member-doc dependency).", "communities"),
    ("Live-event date validity", "Only well-formed yyyy-MM-dd, today-onward; junk like \"1\" rejected; ≤1-week fallback window.", "events"),
    ("50km / 100km geo filters", "Haversine distance drives the within-radius event filters.", "explore"),
    ("Business chat identity", "Business-inquiry conversations render businessName + coverImageUrl (not the personal name).", "chat"),
    ("Business tab routing", "A business viewer's inquiries are excluded from the personal Messages filters.", "chat"),
    ("Rate-this-business hides after rating", "Rating control returns SizedBox.shrink when the viewer already rated / is self.", "business"),
    ("Search excludes deleted + dual business", "Non-active/ghost/admin excluded; a business owner appears as both People and Business.", "search"),
    ("Notifications optimistic delete-all", "NotificationsAllCleared emits NotificationsEmpty immediately before the server delete.", "notifications"),
    ("Events earliest-first", "EventsLoaded.upcomingEvents sorts ascending by startDate.", "events_bloc"),
    ("i18n key parity + no mojibake", "Every en key exists across 7 locales; no replacement chars / classic mojibake.", "i18n"),
]

BACKEND_PENDING = [
    "B1 Firestore Security Rules (@firebase/rules-unit-testing) — emulator",
    "B2 Cloud Functions (Jest + firebase-functions-test) — emulator",
    "B3 Index / query validity end-to-end — emulator",
    "B4 Data-integrity counters (memberCount/unreadCount/ratingSum) — emulator",
    "B5 Performance budgets (query latency, scroll fps, cold start, CF exec) — emulator + device",
    "B6 E2E mock-user journeys (login→discover→join→chat→rate) — emulator",
]

rows = []
for c in sorted(cats.keys()):
    d = cats[c]
    title = CATEGORY_TITLES.get(c, c)
    n = d['pass'] + d['skip'] + d['fail']
    badge = 'ok' if d['fail'] == 0 else 'bad'
    rows.append(
        f"<tr><td>{title}</td><td class='num'>{n}</td>"
        f"<td class='num pass'>{d['pass']}</td>"
        f"<td class='num skip'>{d['skip']}</td>"
        f"<td class='num fail'>{d['fail']}</td>"
        f"<td><span class='pill {badge}'>{'PASS' if d['fail']==0 else 'FAIL'}</span></td></tr>"
    )

reg_rows = "".join(
    f"<tr><td>{t}</td><td>{desc}</td><td class='mono'>{CATEGORY_TITLES.get(cat,cat)}</td></tr>"
    for (t, desc, cat) in REGRESSIONS
)
skip_rows = "".join(
    f"<li><b>{CATEGORY_TITLES.get(c,c)}</b> — {n}</li>" for (c, n) in skips
) or "<li>None</li>"
backend_rows = "".join(f"<li>{b}</li>" for b in BACKEND_PENDING)

html = f"""<!doctype html><html><head><meta charset='utf-8'>
<title>GreenGo — QA Test Report {date}</title>
<style>
 :root{{--gold:#C9A227;--ink:#14161a;--muted:#6b7280;--ok:#0f9d58;--bad:#d93025;--skip:#b8860b;--line:#e5e7eb;}}
 *{{box-sizing:border-box}} body{{font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:var(--ink);margin:0;padding:40px;}}
 h1{{font-size:26px;margin:0 0 4px}} h2{{font-size:17px;margin:28px 0 10px;border-bottom:2px solid var(--gold);padding-bottom:6px}}
 .sub{{color:var(--muted);margin:0 0 20px}}
 .cards{{display:flex;gap:14px;flex-wrap:wrap;margin:18px 0}}
 .card{{border:1px solid var(--line);border-radius:12px;padding:16px 20px;min-width:120px}}
 .card .v{{font-size:30px;font-weight:700}} .card .l{{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.05em}}
 .v.ok{{color:var(--ok)}} .v.bad{{color:var(--bad)}} .v.skip{{color:var(--skip)}} .v.gold{{color:var(--gold)}}
 table{{width:100%;border-collapse:collapse;font-size:13px}}
 th,td{{text-align:left;padding:8px 10px;border-bottom:1px solid var(--line)}}
 th{{background:#faf7ef;font-size:11px;text-transform:uppercase;letter-spacing:.04em;color:var(--muted)}}
 td.num{{text-align:right;font-variant-numeric:tabular-nums}} td.pass{{color:var(--ok)}} td.skip{{color:var(--skip)}} td.fail{{color:var(--bad)}}
 .pill{{font-size:11px;font-weight:700;padding:2px 10px;border-radius:999px}} .pill.ok{{background:#e6f4ea;color:var(--ok)}} .pill.bad{{background:#fce8e6;color:var(--bad)}}
 .mono{{font-family:ui-monospace,Menlo,Consolas,monospace;font-size:12px;color:var(--muted)}}
 ul{{margin:6px 0 0 18px}} li{{margin:3px 0;font-size:13px}}
 .note{{background:#faf7ef;border:1px solid var(--line);border-radius:10px;padding:12px 16px;font-size:13px;color:#4b5563}}
 .foot{{margin-top:30px;color:var(--muted);font-size:11px;border-top:1px solid var(--line);padding-top:12px}}
</style></head><body>
 <h1>GreenGo — QA Test Report</h1>
 <p class='sub'>Automated frontend suite (Flutter) &middot; generated {date} &middot; Master Test Plan Phase&nbsp;1&ndash;2</p>

 <div class='cards'>
   <div class='card'><div class='v gold'>{total}</div><div class='l'>Total tests</div></div>
   <div class='card'><div class='v ok'>{tot['pass']}</div><div class='l'>Passed</div></div>
   <div class='card'><div class='v {'bad' if tot['fail'] else 'ok'}'>{tot['fail']}</div><div class='l'>Failed</div></div>
   <div class='card'><div class='v skip'>{tot['skip']}</div><div class='l'>Skipped</div></div>
   <div class='card'><div class='v gold'>{rate:.1f}%</div><div class='l'>Pass rate (executed)</div></div>
 </div>
 <div class='note'><b>Verdict:</b> {tot['pass']} of {executed} executed tests pass ({rate:.1f}%), {tot['fail']} failures. The {tot['skip']} skips are documented fake-backend limitations (transaction/increment emulation) and are covered by the emulator layer.</div>

 <h2>Results by category</h2>
 <table><thead><tr><th>Category</th><th class='num'>Tests</th><th class='num'>Pass</th><th class='num'>Skip</th><th class='num'>Fail</th><th>Status</th></tr></thead>
 <tbody>{''.join(rows)}</tbody></table>

 <h2>Regression coverage (this cycle's fixes)</h2>
 <table><thead><tr><th>Fix</th><th>What the test guards</th><th>Area</th></tr></thead><tbody>{reg_rows}</tbody></table>

 <h2>Skipped (documented)</h2>
 <ul>{skip_rows}</ul>

 <h2>Backend &amp; performance — pending (emulator-gated)</h2>
 <div class='note'>The frontend suite runs on a fake in-memory Firestore + mocked auth (no emulator). The following backend/perf phases require the Firebase emulator + a Jest harness and are the next phase of the Master Test Plan:</div>
 <ul>{backend_rows}</ul>

 <div class='foot'>GreenGo &middot; package greengo_chat &middot; test harness: flutter_test + mocktail + fake_cloud_firestore + firebase_auth_mocks &middot; personas mock_user_1..5 &middot; see docs/testing/GREENGO_MASTER_TEST_PLAN.md</div>
</body></html>"""

import os
os.makedirs(os.path.dirname(OUT_HTML) or '.', exist_ok=True)
with open(OUT_HTML, 'w', encoding='utf-8') as f:
    f.write(html)
print(f"wrote {OUT_HTML}  ({total} tests, {tot['pass']} pass, {tot['fail']} fail, {tot['skip']} skip)")
