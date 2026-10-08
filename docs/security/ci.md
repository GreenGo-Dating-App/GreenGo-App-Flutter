# Security CI gates

Workflow: [`.github/workflows/security.yml`](../../.github/workflows/security.yml) (name `security`).
It runs on every pull request, on every push to `main`, and on manual runs (`workflow_dispatch`).
No secret is used. The emulators run against fake project ids, the gitignored Firebase config
files are replaced with placeholders, and no job can reach production.

## What must pass before merging

Make **`security / gate`** a required status check on `main`
(Settings → Branches → branch protection rule for `main` → *Require status checks to pass* → add `gate`).
`gate` fails if any of the jobs below failed, was cancelled or was skipped. All of them are blocking.

| Job | Blocks on | Report-only |
|---|---|---|
| `functions` (a) | `npm ci` fails; `tsc --noEmit` error; a **critical** npm advisory in production deps that is not in the allowlist, or whose allowlist entry has expired | **high** npm advisories (printed as warnings) |
| `emulator-suites` (b) | any failing test in the Jest security suites; any failing ATTACK/LEGIT case in the three rules client scripts | none |
| `secrets` (c) | gitleaks finds a secret in the commits of the PR/push, or anywhere in the tracked files at HEAD | full-history scan (manual runs only) |
| `policy` (d, e) | the app exports a Cloud Function the web repo owns; a file in `assets/legal/` differs from the manifest | none |
| `flutter` (f) | `flutter analyze` reports any **error** (warnings and infos are allowed for now); any failing `flutter test` | analyzer warnings and infos |

`pr-guard.yml` (the G0 hygiene gate: analyzer errors + new unbounded Firestore queries) keeps running next to this workflow.

## (a) Cloud Functions: `functions`

```bash
cd functions
npm ci
npx tsc -p . --noEmit
python ../tools/security/npm_audit_gate.py          # runs `npm audit --omit=dev --json` and applies the policy
```

`tools/security/npm_audit_gate.py` is a thin wrapper around `npm audit --omit=dev --audit-level=critical`.

**Why high is not blocking yet.** On 2026-10-08 the production tree has 8 high advisories (axios, sharp/libvips,
joi + node-forge via passkit-generator, @grpc/grpc-js, fast-xml-parser, @fastify/busboy). Several need a
semver-major upgrade (sharp 0.35, passkit-generator) that changes deployed function behaviour and must be
tested on its own. A blocking `high` gate would turn every unrelated PR red until then, and people learn to
ignore a gate that is always red. Tighten to `high` once `npm audit --omit=dev --audit-level=high` is clean:
change `elif a["severity"] == "high"` in the script into a blocking branch.

**Critical exceptions** live in `tools/security/npm_audit_allowlist.json`. Each entry has a GHSA id, a reason
and an `expires` date of at most about a month. When an entry expires, the advisory blocks again.
Today there are two entries, both expiring 2026-10-31, and both are fixed by a lockfile-only, semver-compatible update:

```bash
cd functions && npm update proxy-addr websocket-driver   # then: npx tsc --noEmit, run the emulator suites, commit package-lock.json
```

After that, delete both entries from the allowlist.

## (b) Emulator security suites: `emulator-suites`

The Jest suites (`functions/__tests__/security/*.emulator.test.ts`) and the three "real client" rules scripts
(`phase0` and `privacy` for Firestore rules, `media` for Storage rules), which sign in through the Auth
emulator and use the Firebase **web** SDK the apps use.

```bash
cd functions
# Jest: setup.ts pins GCLOUD_PROJECT=test-project, so the emulator must use the same id
firebase emulators:exec --only firestore,auth,storage --project test-project "npx jest --config jest.security.config.js"

# Rules clients: need the firebase web SDK on NODE_PATH (any node_modules that has firebase@12, e.g. the admin panel's)
export NODE_PATH="/path/to/greengo-admin-panel/node_modules"      # Windows: use ; between multiple paths
firebase emulators:exec --only firestore,auth         --project demo-ci "node __tests__/security/phase0.rules.emulator.js"
firebase emulators:exec --only firestore,auth,storage --project demo-ci "node __tests__/security/media.rules.emulator.js"
firebase emulators:exec --only firestore,auth         --project demo-ci "node __tests__/security/privacy.rules.emulator.js"
```

On a PC where other emulators are running, use a private config with your own ports
(`--config ../firebase.emulators.<you>.json`) and a private `TEMP` (see `C:\dev\AGENT_RULES.md`).

**The Firebase web SDK in CI.** `firebase` (the web SDK) is not a dependency of `functions/`, and adding it
would change `functions/package.json` and `package-lock.json`, which are deployed. CI installs
`firebase@12.6.0` (the version in `greengo-admin-panel/package-lock.json`) into `$RUNNER_TEMP/websdk`,
outside the repo, and points `NODE_PATH` there. `firebase-admin` still resolves from `functions/node_modules`.
`npm ci` therefore keeps checking that the committed lockfile is consistent.

The rules scripts each sign up fixed users (`alice@example.com`, ...), so each one runs in its own fresh emulator.

## (c) Secret scanning: `secrets`

gitleaks 8.30.1 CLI. The release tarball is downloaded and checked against its published sha256.
`gitleaks/gitleaks-action` is not used because it needs a paid licence for organisation-owned repos.
It runs two scans, and both block:

1. The commits of the PR (`base..head`), or of the push (`before..after`).
2. Every tracked file at HEAD (`git archive HEAD`, then `gitleaks dir`). This also catches a secret that
   entered the tree before this gate existed.

Config: [`.gitleaks.toml`](../../.gitleaks.toml). It extends all default rules and adds narrow allowlists:
the public Firebase **web** apiKey (exact value), the public firebase-tools OAuth client secret (exact value),
placeholders like `sk_live_xxxx`, test fixtures, and cache-key names like `recommendations_v1`.
One entry is a **known finding** rather than a false positive: the fallback unsubscribe HMAC secret in
`functions/src/shared/marketingConsent.ts`. Remove that entry when the fallback is removed.

```bash
gitleaks git . --config .gitleaks.toml --redact --log-opts="origin/main..HEAD"   # your branch's commits
gitleaks dir . --config .gitleaks.toml --redact                                  # working tree (also scans gitignored local files such as functions/.env, so expect hits there)
```

**How the config was validated (2026-10-08, gitleaks 8.30.1, locally).** The tracked tree at HEAD has 0 findings,
and so does the (shallow) local history. In a scratch repo, one commit per case, scanned with `gitleaks git --log-opts=base..HEAD`:

| Planted | Result |
|---|---|
| `sk_live_` + 24 random chars in a new file | FAIL (exit 1) |
| real-format `sk_live_` key appended to `docs/misc/QUICK_START.md` (a file that contains an allowlisted placeholder) | FAIL |
| PEM RSA private key (`openssl genrsa`) | FAIL |
| Google service-account JSON with a `private_key` | FAIL |
| AWS access key id | FAIL |
| a second `AIzaSy…` key added to `web/firebase-messaging-sw.js` (next to the allowlisted one) | FAIL |
| a different secret value in `marketingConsent.ts` | FAIL |
| placeholder `sk_live_xxxxxxxxxxxxxxxx` | PASS (exit 0) |

Manual runs (`workflow_dispatch` with *full_history_secret_scan*) also scan the whole history.
That scan is informational and does not block.

## (d) Function-name ownership: `policy`

Both repos deploy Cloud Functions to the same project and codebase, so a name exported by both is
overwritten by whichever repo deploys last (P1-9). The web repo owns the Stripe family. It is not available in CI,
so its names are listed in `tools/security/web_owned_functions.txt`. **Keep that list in sync** with the
uncommented exports of the web repo's `functions/src/index.ts`.

```bash
python tools/security/check_function_ownership.py      # exit 0 ok, 1 collision, 2 parse problem
```

The parser strips comments, reads every `export { … }`, `export const|function|class`, and `export * as`.
It refuses a bare `export * from` (the names would be invisible), and it fails if fewer than 50 exports are parsed,
so a broken parser can't turn into a green check. Validated: 335 exports parsed today, exit 0; with
`stripeWebhook` un-commented in a copy of `index.ts`, exit 1.

## (e) Legal documents hash check: `policy`

`assets/legal/*` (the privacy policy and terms the app shows in-app) must match
`tools/security/legal_manifest.json` (sha256 of each file, with CRLF normalised to LF so Windows checkouts match).
Changing, adding or removing a legal file without updating the manifest fails. That turns every legal-text
change into a deliberate step, visible in the PR.

```bash
python tools/security/check_legal_manifest.py            # verify
python tools/security/check_legal_manifest.py --update   # ONLY after the legal change was reviewed and approved
```

Validated: the manifest hashes equal the hashes of the committed git blobs. Appending a line to
`terms-and-conditions-en.txt` gives exit 1, and so does adding a new file.

## (f) Flutter: `flutter`

`lib/firebase_options.dart` and `android/app/google-services.json` are gitignored, and
`lib/main.dart` plus `integration_test/` import the first one. CI writes placeholders with fake values
(`tools/security/ci_stub_firebase_config.sh`, which never overwrites an existing file), then runs:

```bash
flutter pub get
flutter analyze        # job fails only on `error` lines
flutter test
```

The Flutter version is pinned to 3.44.4, like `codemagic.yaml`. Validated locally on 2026-10-08 (Flutter 3.44.2),
with the real config files moved away and the placeholders in place: `flutter analyze` 161 issues, 0 errors;
`flutter test` 1559 passed, 4 skipped, 0 failed (the same numbers as with the real config).

## Things that can only be verified on GitHub

- The first real run: runner images, the pinned action SHAs, the gitleaks download and checksum, and Java 21 + firebase-tools 15.8.0 on Linux.
- That `npm ci` succeeds on Linux with the committed `functions/package-lock.json` (e.g. sharp's native binary).
- How long the jobs take. The Flutter job is the slowest; `cache: true` helps on later runs.
- `actionlint` 1.7.7 passes locally, but expression and context edge cases (e.g. `github.event.before` on the first push of a branch) are only exercised for real on GitHub.
