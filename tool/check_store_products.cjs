#!/usr/bin/env node
/**
 * Pre-submission gate: verify the App Store Connect catalogue from Windows.
 *
 * GreenGo was rejected under Guideline 2.1(b) because its In-App Purchases had
 * never been submitted for review. StoreKit then returned no products and the
 * app showed a configuration message to the reviewer. The check that would have
 * caught it needs no device, no Mac and no Xcode — just the App Store Connect
 * API — so it runs here, in CI, before anything is submitted.
 *
 * FAILS (exit 1) when any product in tool/store_products.json is:
 *   - absent from App Store Connect, or
 *   - in a state that is not reviewable (MISSING_METADATA is the usual one,
 *     and it almost always means a missing Review Screenshot).
 *
 * Usage:
 *   node tool/check_store_products.cjs
 *   node tool/check_store_products.cjs --json      # machine-readable summary
 *   node tool/check_store_products.cjs --require-credentials   # CI: no silent skip
 *
 * Credentials — an App Store Connect API key with at least App Manager access
 * (App Store Connect -> Users and Access -> Integrations):
 *   ASC_KEY_ID=...            the 10-character Key ID
 *   ASC_ISSUER_ID=...         the issuer UUID
 *   ASC_PRIVATE_KEY_PATH=...  path to the downloaded AuthKey_XXXX.p8
 *   ASC_APP_ID=...            the app's numeric Apple ID (App Information page)
 *
 * The .p8 downloads exactly once and must never be committed.
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const JSON_OUT = process.argv.includes('--json');
const REQUIRE_CREDENTIALS = process.argv.includes('--require-credentials');
const ROOT = path.resolve(__dirname, '..');
const CATALOGUE = path.join(ROOT, 'tool', 'store_products.json');

const REVIEWABLE_STATES = new Set([
  'READY_TO_SUBMIT',
  'WAITING_FOR_REVIEW',
  'IN_REVIEW',
  'APPROVED',
  'DEVELOPER_ACTION_NEEDED',
  'PENDING_BINARY_APPROVAL',
]);

function fail(msg) {
  console.error(`ERROR: ${msg}`);
  process.exit(1);
}

function base64url(input) {
  return Buffer.from(input)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

/** ES256 JWT, per Apple's "Generating Tokens for API Requests". */
function makeToken({ keyId, issuerId, privateKey }) {
  const header = { alg: 'ES256', kid: keyId, typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: issuerId,
    iat: now,
    exp: now + 19 * 60, // Apple rejects anything over 20 minutes
    aud: 'appstoreconnect-v1',
  };
  const unsigned = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(payload))}`;
  const signature = crypto.sign('sha256', Buffer.from(unsigned), {
    key: privateKey,
    dsaEncoding: 'ieee-p1363',
  });
  return `${unsigned}.${base64url(signature)}`;
}

async function ascGet(token, url) {
  const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
  if (!res.ok) {
    const body = await res.text();
    fail(`App Store Connect ${res.status} for ${url}\n${body.slice(0, 600)}`);
  }
  return res.json();
}

/** Follows pagination and returns every entry. */
async function ascGetAll(token, url) {
  const out = [];
  let next = url;
  while (next) {
    const page = await ascGet(token, next);
    out.push(...(page.data || []));
    next = page.links && page.links.next ? page.links.next : null;
  }
  return out;
}

async function main() {
  const catalogue = JSON.parse(fs.readFileSync(CATALOGUE, 'utf8'));
  const expected = [
    ...catalogue.subscriptions.ios.map((id) => ({ id, kind: 'subscription' })),
    ...catalogue.consumables.ios.map((id) => ({ id, kind: 'consumable' })),
  ];

  if (expected.length !== catalogue.expectedTotal) {
    fail(
      `catalogue says expectedTotal=${catalogue.expectedTotal} but lists ${expected.length} products`
    );
  }

  const keyId = process.env.ASC_KEY_ID;
  const issuerId = process.env.ASC_ISSUER_ID;
  const keyPath = process.env.ASC_PRIVATE_KEY_PATH;
  const appId = process.env.ASC_APP_ID;

  if (!keyId || !issuerId || !keyPath || !appId) {
    console.error(
      'App Store Connect credentials not set.\n' +
        '  Needed: ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY_PATH, ASC_APP_ID\n' +
        '  This check is what proves Guideline 2.1(b) is fixed — do not submit without running it.'
    );
    // A check that silently skips is a check that cannot fail, which is how the
    // original rejection slipped through. Release pipelines pass
    // --require-credentials so a missing key is a hard failure; a developer
    // machine without keys is merely warned.
    process.exit(REQUIRE_CREDENTIALS ? 1 : 0);
  }

  if (!fs.existsSync(keyPath)) fail(`private key not found at ${keyPath}`);
  const token = makeToken({
    keyId,
    issuerId,
    privateKey: fs.readFileSync(keyPath, 'utf8'),
  });

  const base = 'https://api.appstoreconnect.apple.com/v1';

  // Consumables / non-consumables live on the app; subscriptions live inside
  // subscription groups, so they need a second walk.
  const iaps = await ascGetAll(
    token,
    `${base}/apps/${appId}/inAppPurchasesV2?limit=200&fields[inAppPurchases]=productId,state,name`
  );

  const groups = await ascGetAll(
    token,
    `${base}/apps/${appId}/subscriptionGroups?limit=200&fields[subscriptionGroups]=referenceName`
  );

  const subs = [];
  for (const g of groups) {
    const inGroup = await ascGetAll(
      token,
      `${base}/subscriptionGroups/${g.id}/subscriptions?limit=200&fields[subscriptions]=productId,state,name`
    );
    for (const s of inGroup) {
      subs.push({ ...s, groupReferenceName: g.attributes.referenceName });
    }
  }

  const found = new Map();
  for (const p of [...iaps, ...subs]) {
    found.set(p.attributes.productId, {
      state: p.attributes.state,
      name: p.attributes.name,
      group: p.groupReferenceName || null,
    });
  }

  const problems = [];
  const rows = [];

  for (const { id, kind } of expected) {
    const hit = found.get(id);
    if (!hit) {
      problems.push(`MISSING      ${id} — not present in App Store Connect`);
      rows.push({ id, kind, state: 'ABSENT', ok: false });
      continue;
    }
    const ok = REVIEWABLE_STATES.has(hit.state);
    if (!ok) {
      const hint =
        hit.state === 'MISSING_METADATA'
          ? ' (almost always a missing Review Screenshot)'
          : '';
      problems.push(`NOT READY    ${id} — state ${hit.state}${hint}`);
    }
    rows.push({ id, kind, state: hit.state, group: hit.group, ok });
  }

  // All 7 subscriptions must sit in ONE group, or upgrades behave as
  // crossgrades and users get billed oddly.
  const groupNames = new Set(
    rows.filter((r) => r.kind === 'subscription' && r.group).map((r) => r.group)
  );
  if (groupNames.size > 1) {
    problems.push(
      `SPLIT GROUP  subscriptions span ${groupNames.size} groups: ${[...groupNames].join(', ')}`
    );
  }

  if (JSON_OUT) {
    console.log(JSON.stringify({ rows, problems }, null, 2));
  } else {
    console.log('App Store Connect catalogue check');
    console.log('─'.repeat(72));
    for (const r of rows) {
      console.log(`  ${r.ok ? 'OK  ' : 'FAIL'}  ${r.state.padEnd(24)} ${r.id}`);
    }
    console.log('─'.repeat(72));
  }

  if (problems.length > 0) {
    console.error(`\n${problems.length} problem(s):`);
    for (const p of problems) console.error(`  ${p}`);
    console.error(
      '\nDo NOT submit. Every product must be Ready to Submit and attached to the version.'
    );
    process.exit(1);
  }

  console.log(`\nAll ${expected.length} products present and reviewable.`);
  process.exit(0);
}

main().catch((e) => {
  console.error('FAILED:', e);
  process.exit(1);
});
