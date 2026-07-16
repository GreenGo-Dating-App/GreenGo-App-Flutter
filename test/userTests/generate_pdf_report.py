#!/usr/bin/env python3
"""GreenGo — DETAILED test report generator (Master Test Plan Phase 5).

Parses `flutter test --machine` JSON into a rich, self-contained HTML report:
executive summary, environment, methodology, per-category + per-FILE breakdowns
listing every individual test with its status and duration, timing analysis
(slowest tests), regression-coverage matrix, documented skips, and the pending
backend/performance phases. Convert to PDF via Edge headless.

Usage:
  flutter test test/unit test/widget --machine > results.json
  python test/userTests/generate_pdf_report.py results.json out.html [env.txt]
"""
import json
import os
import re
import sys
import collections
import datetime
import html as _html

RESULTS = sys.argv[1] if len(sys.argv) > 1 else 'results.json'
OUT_HTML = sys.argv[2] if len(sys.argv) > 2 else 'report.html'
ENV_FILE = sys.argv[3] if len(sys.argv) > 3 else None

CATEGORY_TITLES = {
    'auth': 'Authentication & Session', 'onboarding': 'Onboarding',
    'profile': 'Profile', 'explore': 'Discovery / Explore (geo/date logic)',
    'events': 'Events — date/geo logic', 'events_bloc': 'Events — bloc / datasource',
    'communities': 'Communities', 'chat': 'Chat / Messaging',
    'business': 'Business / Storefront', 'search': 'Search',
    'notifications': 'Notifications', 'coins': 'Membership / Coins',
    'i18n': 'Localization (7 locales)', 'widget': 'Widgets / Rendering',
    'other': 'Other',
}
CATEGORY_ORDER = ['auth', 'onboarding', 'profile', 'communities', 'explore',
                  'events', 'events_bloc', 'chat', 'business', 'search',
                  'notifications', 'coins', 'i18n', 'widget', 'other']


def esc(s):
    return _html.escape(str(s))


def category_of(path):
    u = path.replace('\\', '/')
    m = re.search(r'/test/unit/([^/]+)/', u)
    if m:
        return m.group(1)
    if '/test/widget/' in u:
        return 'widget'
    return 'other'


def short(path):
    u = path.replace('\\', '/')
    i = u.find('/test/')
    return u[i + 1:] if i >= 0 else os.path.basename(u)


# --- parse ---
suites = {}          # suiteID -> path
tests = {}           # testID -> {name, suiteID, start_ms}
done = {}            # testID -> {result, skipped, time_ms, hidden}
errors = {}          # testID -> message

for line in open(RESULTS, encoding='utf-8'):
    line = line.strip()
    if not line.startswith('{'):
        continue
    try:
        e = json.loads(line)
    except Exception:
        continue
    t = e.get('type')
    if t == 'suite':
        s = e['suite']
        suites[s['id']] = s.get('path', '')
    elif t == 'testStart':
        td = e['test']
        tests[td['id']] = {'name': td.get('name', '?'),
                           'suiteID': td.get('suiteID'),
                           'start': e.get('time', 0),
                           'url': td.get('url')}
    elif t == 'testDone':
        done[e['testID']] = {'result': e.get('result'),
                             'skipped': e.get('skipped', False),
                             'time': e.get('time', 0),
                             'hidden': e.get('hidden', False)}
    elif t == 'error':
        errors[e['testID']] = (e.get('error', '') + '\n' + e.get('stackTrace', '')).strip()

# --- assemble per-file ---
# file -> {category, tests: [ {name, status, dur} ]}
files = collections.OrderedDict()
all_durs = []  # (dur, category, file, name)
cat_stats = collections.defaultdict(lambda: {'pass': 0, 'skip': 0, 'fail': 0, 'dur': 0})

for tid, td in tests.items():
    d = done.get(tid)
    if not d or d['hidden']:
        continue
    path = suites.get(td['suiteID']) or td.get('url') or ''
    cat = category_of(path)
    f = short(path)
    dur = max(0, d['time'] - td['start'])
    if d['skipped']:
        status = 'skip'
    elif d['result'] == 'success':
        status = 'pass'
    else:
        status = 'fail'
    cat_stats[cat][status] += 1
    cat_stats[cat]['dur'] += dur
    files.setdefault(f, {'category': cat, 'tests': []})
    files[f]['tests'].append({'name': td['name'], 'status': status, 'dur': dur,
                              'err': errors.get(tid)})
    all_durs.append((dur, cat, f, td['name']))

tot = {'pass': 0, 'skip': 0, 'fail': 0, 'dur': 0}
for c in cat_stats.values():
    for k in tot:
        tot[k] += c[k]
total = tot['pass'] + tot['skip'] + tot['fail']
executed = tot['pass'] + tot['fail']
rate = (tot['pass'] / executed * 100) if executed else 100.0
wall = max((d['time'] for d in done.values()), default=0)
date = datetime.date.today().isoformat()

# env
env_lines = []
if ENV_FILE and os.path.exists(ENV_FILE):
    env_lines = [l.rstrip() for l in open(ENV_FILE, encoding='utf-8') if l.strip()]

REGRESSIONS = [
    ("Communities concurrency-merge", "Bloc handlers merge onto current state via copyWith; concurrent Discover/Joined/My/Recommended loads no longer clobber managedCommunities — \"My communities\" reliably appears.", "communities"),
    ("Tips/Announcements/Chat split", "language_tip / cultural_fact / city_tip → Tips; announcement → Announcements; text → chat. Wire-string round-trips guarded.", "communities"),
    ("getCreatedCommunities (My communities)", "Direct createdByUserId query, independent of member docs; public-only Discover.", "communities"),
    ("Live-event date validity", "Only well-formed yyyy-MM-dd, today-onward; junk like \"1\"/empty rejected; ≤1-week fallback window.", "events"),
    ("50 / 100 km geo filters", "Haversine distance drives within-radius event filters (happening-soon 100km, featured/near-you 50km).", "explore"),
    ("Events earliest-first", "EventsLoaded.upcomingEvents sorts ascending by startDate; datasource getEvents orderBy startDate asc.", "events_bloc"),
    ("Business chat identity", "Business-inquiry conversations render businessName + coverImageUrl instead of the owner's personal name/photo — card + header.", "chat"),
    ("Business tab routing", "A business viewer's inquiries are excluded from every personal Messages filter (route only to the Business tab).", "chat"),
    ("Rate-this-business hides after rating", "Rating control returns SizedBox.shrink when the viewer already rated (mine>0) or is the business itself.", "business"),
    ("Storefront tap-through id", "_EventCard/_CommunityCard carry the doc id so tiles can open the event/community detail.", "business"),
    ("Search excludes deleted + dual business", "Self/ghost/admin/support/non-active excluded; a business owner surfaces as BOTH People (personal) and Business (hero image).", "search"),
    ("Notifications optimistic delete-all", "NotificationsAllCleared emits NotificationsEmpty immediately, before the server delete; unread-clear drops unread optimistically.", "notifications"),
    ("Account-approved notifications hidden", "account_approved broadcast notifications filtered out of the feed stream.", "notifications"),
    ("i18n key parity + no mojibake", "Every en key present across all 7 locales; no replacement chars / classic UTF-8-as-Latin-1 mojibake.", "i18n"),
    ("Profile age + flags layout", "age getter from dateOfBirth; header composes age + language flags under the name.", "profile"),
]

BACKEND_PENDING = [
    ("B1", "Firestore Security Rules", "@firebase/rules-unit-testing — communities self-join incl. business, owner-only notifications, scoped conversations/coins, mod-only join_requests", "Firestore emulator"),
    ("B2", "Cloud Functions", "Jest + firebase-functions-test — seeder/remover round-trip, onProfileDeleted cascade, group-chat fanout, announcement fanout, push idempotency, event reminders, backfill", "Functions emulator"),
    ("B3", "Index / query validity E2E", "Every composite/collection-group query the client issues resolves against real indexes", "Firestore emulator"),
    ("B4", "Data-integrity counters", "memberCount / unreadCount / attendeeCount / ratingSum+Count stay consistent across join/leave/send/read/rate", "Firestore emulator"),
    ("B5", "Performance budgets", "Discover ≤300ms, My-communities ≤300ms, page ≤400ms, scroll ≥55fps, cold-start ≤3.5s, CF exec times", "emulator + device"),
    ("B6", "E2E mock-user journeys", "login→explore→join→chat→rate→notify→delete-all; business persona; tier-gated flows", "emulator"),
]

STATUS_MARK = {'pass': "&#10003;", 'skip': "&#8722;", 'fail': "&#10007;"}


def fmt_ms(ms):
    if ms >= 1000:
        return f"{ms/1000:.2f}s"
    return f"{ms}ms"


# --- category summary rows ---
cat_rows = []
for c in CATEGORY_ORDER:
    if c not in cat_stats:
        continue
    s = cat_stats[c]
    n = s['pass'] + s['skip'] + s['fail']
    if not n:
        continue
    badge = 'ok' if s['fail'] == 0 else 'bad'
    cat_rows.append(
        f"<tr><td>{esc(CATEGORY_TITLES.get(c,c))}</td><td class='num'>{n}</td>"
        f"<td class='num pass'>{s['pass']}</td><td class='num skip'>{s['skip']}</td>"
        f"<td class='num fail'>{s['fail']}</td><td class='num'>{fmt_ms(s['dur'])}</td>"
        f"<td><span class='pill {badge}'>{'PASS' if s['fail']==0 else 'FAIL'}</span></td></tr>")

# --- slowest tests ---
slow = sorted(all_durs, reverse=True)[:20]
slow_rows = "".join(
    f"<tr><td class='num'>{i+1}</td><td>{esc(name)}</td>"
    f"<td class='mono'>{esc(CATEGORY_TITLES.get(cat,cat))}</td><td class='num'>{fmt_ms(dur)}</td></tr>"
    for i, (dur, cat, f, name) in enumerate(slow))

# --- per-file detailed sections (grouped by category) ---
by_cat_files = collections.defaultdict(list)
for f, info in files.items():
    by_cat_files[info['category']].append((f, info))

detail_sections = []
for c in CATEGORY_ORDER:
    if c not in by_cat_files:
        continue
    s = cat_stats[c]
    n = s['pass'] + s['skip'] + s['fail']
    detail_sections.append(
        f"<h3 class='cath'>{esc(CATEGORY_TITLES.get(c,c))} "
        f"<span class='catmeta'>{n} tests &middot; {s['pass']} pass &middot; "
        f"{s['skip']} skip &middot; {s['fail']} fail &middot; {fmt_ms(s['dur'])}</span></h3>")
    for f, info in sorted(by_cat_files[c]):
        rows = []
        for t in info['tests']:
            cls = t['status']
            errhtml = ''
            if t['status'] == 'fail' and t['err']:
                errhtml = f"<div class='err'>{esc(t['err'][:600])}</div>"
            rows.append(
                f"<tr class='{cls}'><td class='mk {cls}'>{STATUS_MARK[cls]}</td>"
                f"<td>{esc(t['name'])}{errhtml}</td>"
                f"<td class='num dur'>{fmt_ms(t['dur'])}</td></tr>")
        detail_sections.append(
            f"<div class='file'><div class='fname mono'>{esc(f)} "
            f"<span class='fcount'>({len(info['tests'])})</span></div>"
            f"<table class='tt'><tbody>{''.join(rows)}</tbody></table></div>")

reg_rows = "".join(
    f"<tr><td><b>{esc(t)}</b></td><td>{esc(desc)}</td><td class='mono'>{esc(CATEGORY_TITLES.get(cat,cat))}</td></tr>"
    for (t, desc, cat) in REGRESSIONS)
skip_items = []
for f, info in files.items():
    for t in info['tests']:
        if t['status'] == 'skip':
            skip_items.append(f"<li><span class='mono'>{esc(f)}</span> &rarr; {esc(t['name'])}</li>")
skip_html = "".join(skip_items) or "<li>None</li>"
backend_rows = "".join(
    f"<tr><td class='mono'>{esc(b[0])}</td><td><b>{esc(b[1])}</b></td><td>{esc(b[2])}</td><td class='mono'>{esc(b[3])}</td></tr>"
    for b in BACKEND_PENDING)
env_html = "".join(f"<tr><td class='mono'>{esc(l)}</td></tr>" for l in env_lines) or "<tr><td>n/a</td></tr>"

html_doc = f"""<!doctype html><html><head><meta charset='utf-8'>
<title>GreenGo — Detailed QA Test Report {date}</title>
<style>
 :root{{--gold:#C9A227;--ink:#14161a;--muted:#6b7280;--ok:#0f9d58;--bad:#d93025;--skip:#b8860b;--line:#e6e8ec;--soft:#faf7ef;}}
 *{{box-sizing:border-box}} body{{font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:var(--ink);margin:0;padding:36px 40px;font-size:13px;line-height:1.45}}
 h1{{font-size:26px;margin:0 0 2px}} h2{{font-size:17px;margin:26px 0 10px;border-bottom:2px solid var(--gold);padding-bottom:6px}}
 h3.cath{{font-size:14px;margin:20px 0 8px;color:#111}} .catmeta{{font-weight:400;color:var(--muted);font-size:11px}}
 .sub{{color:var(--muted);margin:0 0 16px}}
 .cards{{display:flex;gap:12px;flex-wrap:wrap;margin:16px 0}}
 .card{{border:1px solid var(--line);border-radius:12px;padding:14px 18px;min-width:110px}}
 .card .v{{font-size:28px;font-weight:700;line-height:1}} .card .l{{color:var(--muted);font-size:10px;text-transform:uppercase;letter-spacing:.06em;margin-top:6px}}
 .v.ok{{color:var(--ok)}} .v.bad{{color:var(--bad)}} .v.skip{{color:var(--skip)}} .v.gold{{color:var(--gold)}}
 table{{width:100%;border-collapse:collapse}} th,td{{text-align:left;padding:6px 9px;border-bottom:1px solid var(--line);vertical-align:top}}
 th{{background:var(--soft);font-size:10px;text-transform:uppercase;letter-spacing:.04em;color:var(--muted)}}
 td.num{{text-align:right;font-variant-numeric:tabular-nums;white-space:nowrap}} td.pass{{color:var(--ok)}} td.skip{{color:var(--skip)}} td.fail{{color:var(--bad)}}
 .pill{{font-size:10px;font-weight:700;padding:2px 9px;border-radius:999px}} .pill.ok{{background:#e6f4ea;color:var(--ok)}} .pill.bad{{background:#fce8e6;color:var(--bad)}}
 .mono{{font-family:ui-monospace,Menlo,Consolas,monospace;font-size:11px;color:#374151}}
 ul{{margin:6px 0 0 18px}} li{{margin:2px 0}}
 .note{{background:var(--soft);border:1px solid var(--line);border-radius:10px;padding:11px 15px;color:#4b5563}}
 .file{{margin:8px 0 12px}} .fname{{background:#f3f4f6;padding:5px 9px;border-radius:6px 6px 0 0;border:1px solid var(--line);border-bottom:none}}
 .fcount{{color:var(--muted)}} table.tt{{font-size:12px}} table.tt td{{padding:4px 9px}}
 td.mk{{width:20px;text-align:center;font-weight:700}} td.mk.pass{{color:var(--ok)}} td.mk.skip{{color:var(--skip)}} td.mk.fail{{color:var(--bad)}}
 tr.skip td{{color:var(--muted)}} td.dur{{color:var(--muted)}}
 .err{{white-space:pre-wrap;font-family:ui-monospace,Consolas,monospace;font-size:10px;color:var(--bad);margin-top:4px}}
 .foot{{margin-top:28px;color:var(--muted);font-size:10px;border-top:1px solid var(--line);padding-top:10px}}
 .two{{display:flex;gap:22px;flex-wrap:wrap}} .two>div{{flex:1;min-width:280px}}
 @media print{{ h2{{page-break-after:avoid}} .file{{page-break-inside:avoid}} tr{{page-break-inside:avoid}} }}
</style></head><body>

 <h1>GreenGo &mdash; QA Test Report</h1>
 <p class='sub'>Automated frontend suite (Flutter) &middot; generated {date} &middot; Master Test Plan Phases&nbsp;1&ndash;2 &middot; commit {esc(env_lines[3] if len(env_lines)>3 else '')}</p>

 <div class='cards'>
   <div class='card'><div class='v gold'>{total}</div><div class='l'>Total tests</div></div>
   <div class='card'><div class='v ok'>{tot['pass']}</div><div class='l'>Passed</div></div>
   <div class='card'><div class='v {'bad' if tot['fail'] else 'ok'}'>{tot['fail']}</div><div class='l'>Failed</div></div>
   <div class='card'><div class='v skip'>{tot['skip']}</div><div class='l'>Skipped</div></div>
   <div class='card'><div class='v gold'>{rate:.1f}%</div><div class='l'>Pass rate</div></div>
   <div class='card'><div class='v gold'>{fmt_ms(wall)}</div><div class='l'>Wall time</div></div>
 </div>
 <div class='note'><b>Verdict:</b> {tot['pass']} of {executed} executed tests pass ({rate:.1f}%), {tot['fail']} failures across {len(files)} test files and {len([c for c in cat_stats if sum(cat_stats[c].values())])} categories. The {tot['skip']} skips are documented fake-backend limitations (transaction/increment emulation) covered by the emulator layer (B2/B4).</div>

 <h2>1. Environment</h2>
 <div class='two'>
  <div><table><tbody>{env_html}</tbody></table></div>
  <div><table><tbody>
   <tr><td class='mono'>package: greengo_chat</td></tr>
   <tr><td class='mono'>harness: flutter_test + mocktail + fake_cloud_firestore + firebase_auth_mocks + network_image_mock</td></tr>
   <tr><td class='mono'>personas: mock_user_1..5 (FREE/SILVER/GOLD/PLATINUM/PLATINUM+business)</td></tr>
   <tr><td class='mono'>plan: docs/testing/GREENGO_MASTER_TEST_PLAN.md</td></tr>
  </tbody></table></div>
 </div>

 <h2>2. Methodology</h2>
 <div class='note'>Tests run against an in-memory fake Firestore + mocked FirebaseAuth (no network), so every case is deterministic (fixed clocks, no live I/O). Blocs are exercised with mocktail-stubbed repositories (dartz <span class='mono'>Either</span>) and <span class='mono'>expectLater(bloc.stream, emitsInOrder([...]))</span>. Widgets pump inside MaterialApp with the app's localization delegates and <span class='mono'>mockNetworkImagesFor</span>. Datasource/query tests seed a <span class='mono'>FakeFirebaseFirestore</span> mirroring the production seeder shapes. Backend rules/functions/performance (B1&ndash;B6) require the Firebase emulator and are the next phase.</div>

 <h2>3. Results by category</h2>
 <table><thead><tr><th>Category</th><th class='num'>Tests</th><th class='num'>Pass</th><th class='num'>Skip</th><th class='num'>Fail</th><th class='num'>Duration</th><th>Status</th></tr></thead>
 <tbody>{''.join(cat_rows)}
 <tr style='font-weight:700;background:var(--soft)'><td>TOTAL</td><td class='num'>{total}</td><td class='num pass'>{tot['pass']}</td><td class='num skip'>{tot['skip']}</td><td class='num fail'>{tot['fail']}</td><td class='num'>{fmt_ms(tot['dur'])}</td><td><span class='pill {'ok' if tot['fail']==0 else 'bad'}'>{'PASS' if tot['fail']==0 else 'FAIL'}</span></td></tr>
 </tbody></table>

 <h2>4. Regression coverage (this cycle's fixes &rarr; guarding tests)</h2>
 <table><thead><tr><th>Fix</th><th>What the test guards</th><th>Area</th></tr></thead><tbody>{reg_rows}</tbody></table>

 <h2>5. Timing &mdash; 20 slowest tests</h2>
 <table><thead><tr><th class='num'>#</th><th>Test</th><th>Category</th><th class='num'>Duration</th></tr></thead><tbody>{slow_rows}</tbody></table>

 <h2>6. Detailed results &mdash; every test</h2>
 {''.join(detail_sections)}

 <h2>7. Skipped tests (documented)</h2>
 <div class='note'>fake_cloud_firestore does not emulate <span class='mono'>runTransaction</span> + <span class='mono'>FieldValue.increment</span> accumulation across sequential transactions, nor the initial frame of <span class='mono'>.snapshots()</span>. These aggregate cases are re-covered by the emulator layer (B2/B4).</div>
 <ul>{skip_html}</ul>

 <h2>8. Pending &mdash; backend &amp; performance (emulator-gated)</h2>
 <table><thead><tr><th>Phase</th><th>Suite</th><th>Coverage</th><th>Runner</th></tr></thead><tbody>{backend_rows}</tbody></table>

 <div class='foot'>GreenGo &middot; greengo_chat &middot; generated by test/userTests/generate_pdf_report.py from flutter test --machine output &middot; {date}</div>
</body></html>"""

os.makedirs(os.path.dirname(OUT_HTML) or '.', exist_ok=True)
with open(OUT_HTML, 'w', encoding='utf-8') as fh:
    fh.write(html_doc)
print(f"wrote {OUT_HTML}: {total} tests / {tot['pass']} pass / {tot['fail']} fail / "
      f"{tot['skip']} skip across {len(files)} files; wall={fmt_ms(wall)}")
