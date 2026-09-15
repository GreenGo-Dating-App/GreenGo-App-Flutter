/**
 * v4.0.0 migration — make every existing coin non-expiring.
 *
 * App Store Review Guideline 3.1.1: "Purchased credits or currencies ... may
 * never expire." GreenGo shipped a 365-day expiry on every coin batch, plus two
 * scheduled functions (`processExpiredCoins`, `sendExpirationWarnings`) that
 * deducted coins and nagged users about them. The code is gone as of v4.0.0;
 * this script cleans the data that code left behind.
 *
 * It does two independent things:
 *
 *   PHASE 1 — STRIP
 *     Remove `expirationDate` / `expiresAt` from every entry of every coin
 *     batch array, in both the camelCase `coinBalances` collection (the one the
 *     Flutter client actually reads) and the legacy snake_case `coin_balances`.
 *     Purely subtractive and safe to re-run.
 *
 *   PHASE 2 — REFUND
 *     Find coins the old sweeper already destroyed and give them back. A
 *     refund is recorded with its own ledger document keyed by the original
 *     transaction id, so re-running can never credit the same user twice.
 *
 * Usage:
 *   node functions/scripts/removeCoinExpiry.cjs              # dry run (default)
 *   node functions/scripts/removeCoinExpiry.cjs --commit     # actually write
 *   node functions/scripts/removeCoinExpiry.cjs --commit --skip-refund
 *
 * Credentials (only needed with --commit) — either:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 *   or an existing `gcloud auth application-default login` session.
 *
 * Written as plain CommonJS on purpose: `ts-node` is not installed in
 * functions/ and the npm registry is unreachable from this machine, so this
 * runs with the `firebase-admin` already in node_modules.
 */

const admin = require('firebase-admin');

const args = process.argv.slice(2);
const COMMIT = args.includes('--commit');
const SKIP_REFUND = args.includes('--skip-refund');

const BALANCE_COLLECTIONS = [
  { name: 'coinBalances', batchFields: ['coinBatches'] },
  { name: 'coin_balances', batchFields: ['coinBatches', 'batches'] },
];
const EXPIRY_KEYS = ['expirationDate', 'expiresAt'];

// How the old sweeper labelled what it took.
const EXPIRY_TX_MARKERS = ['Coins expired', 'coins expired', 'expired'];
const TX_COLLECTIONS = ['coinTransactions', 'coin_transactions'];
const REFUND_LEDGER = 'coinExpiryRefunds';

function log(...a) {
  console.log(...a);
}

function stripExpiry(batches) {
  let touched = 0;
  const cleaned = batches.map((b) => {
    if (!b || typeof b !== 'object') return b;
    const copy = { ...b };
    let hit = false;
    for (const k of EXPIRY_KEYS) {
      if (k in copy) {
        delete copy[k];
        hit = true;
      }
    }
    if (hit) touched += 1;
    return copy;
  });
  return { cleaned, touched };
}

async function phaseStrip(db) {
  log('\n── PHASE 1: strip expiry from coin batches ──');
  const totals = { docs: 0, docsChanged: 0, batchesChanged: 0 };

  for (const { name, batchFields } of BALANCE_COLLECTIONS) {
    let snap;
    try {
      snap = await db.collection(name).get();
    } catch (e) {
      log(`  ${name}: unreadable (${e.message}) — skipped`);
      continue;
    }
    if (snap.empty) {
      log(`  ${name}: empty`);
      continue;
    }

    let changed = 0;
    let batchHits = 0;
    let writer = COMMIT ? db.batch() : null;
    let queued = 0;

    for (const doc of snap.docs) {
      totals.docs += 1;
      const data = doc.data();
      const update = {};

      for (const field of batchFields) {
        const arr = data[field];
        if (!Array.isArray(arr) || arr.length === 0) continue;
        const { cleaned, touched } = stripExpiry(arr);
        if (touched > 0) {
          update[field] = cleaned;
          batchHits += touched;
        }
      }

      if (Object.keys(update).length === 0) continue;
      changed += 1;

      if (COMMIT) {
        writer.update(doc.ref, update);
        queued += 1;
        if (queued >= 400) {
          await writer.commit();
          writer = db.batch();
          queued = 0;
        }
      }
    }

    if (COMMIT && queued > 0) await writer.commit();
    log(`  ${name}: ${snap.size} docs, ${changed} with expiry, ${batchHits} batches cleaned`);
    totals.docsChanged += changed;
    totals.batchesChanged += batchHits;
  }

  log(
    `  TOTAL: ${totals.docsChanged}/${totals.docs} balance docs would be updated ` +
      `(${totals.batchesChanged} batches)`
  );
  return totals;
}

function looksLikeExpiryDebit(tx) {
  const type = String(tx.type || '').toLowerCase();
  if (type !== 'debit') return false;
  const reason = String(tx.reason || '');
  const description = String(tx.description || '');
  const haystack = `${reason} ${description}`;
  return (
    reason === 'expired' ||
    EXPIRY_TX_MARKERS.some((m) => haystack.includes(m))
  );
}

async function phaseRefund(db) {
  log('\n── PHASE 2: refund coins the old sweeper destroyed ──');

  const owed = new Map(); // uid -> { coins, txIds: [] }
  let scanned = 0;

  for (const name of TX_COLLECTIONS) {
    let snap;
    try {
      snap = await db.collection(name).get();
    } catch (e) {
      log(`  ${name}: unreadable (${e.message}) — skipped`);
      continue;
    }
    for (const doc of snap.docs) {
      scanned += 1;
      const tx = doc.data();
      if (!looksLikeExpiryDebit(tx)) continue;
      const uid = tx.userId;
      const amount = Number(tx.amount) || 0;
      if (!uid || amount <= 0) continue;
      const entry = owed.get(uid) || { coins: 0, txIds: [] };
      entry.coins += amount;
      entry.txIds.push(`${name}/${doc.id}`);
      owed.set(uid, entry);
    }
  }

  log(`  scanned ${scanned} transactions across ${TX_COLLECTIONS.join(', ')}`);

  if (owed.size === 0) {
    log('  no expiry debits found — nothing was ever destroyed. Nothing to refund.');
    return { users: 0, coins: 0 };
  }

  let refundedUsers = 0;
  let refundedCoins = 0;

  for (const [uid, entry] of owed) {
    // Idempotency: one ledger doc per original transaction.
    const fresh = [];
    for (const txId of entry.txIds) {
      const ledgerId = txId.replace(/\//g, '__');
      const ledgerRef = db.collection(REFUND_LEDGER).doc(ledgerId);
      const exists = (await ledgerRef.get()).exists;
      if (!exists) fresh.push({ txId, ledgerRef });
    }
    if (fresh.length === 0) continue;

    // Credit only the debits that have not already been reversed, re-reading
    // each one for its exact amount rather than trusting the running total.
    let toCredit = 0;
    for (const f of fresh) {
      const [coll, docId] = f.txId.split('/');
      const txDoc = await db.collection(coll).doc(docId).get();
      toCredit += Number(txDoc.data()?.amount) || 0;
    }
    if (toCredit <= 0) continue;

    refundedUsers += 1;
    refundedCoins += toCredit;
    log(`  ${uid}: +${toCredit} coins (${fresh.length} expiry debits)`);

    if (!COMMIT) continue;

    const balanceRef = db.collection('coinBalances').doc(uid);
    await db.runTransaction(async (t) => {
      const snap = await t.get(balanceRef);
      const data = snap.exists ? snap.data() : {};
      const now = admin.firestore.Timestamp.now();
      const batches = Array.isArray(data.coinBatches) ? [...data.coinBatches] : [];
      batches.push({
        batchId: `expiry_refund_${now.toMillis()}`,
        initialCoins: toCredit,
        remainingCoins: toCredit,
        source: 'refund',
        acquiredDate: now,
      });
      t.set(
        balanceRef,
        {
          userId: uid,
          totalCoins: (Number(data.totalCoins) || 0) + toCredit,
          earnedCoins: Number(data.earnedCoins) || 0,
          purchasedCoins: Number(data.purchasedCoins) || 0,
          giftedCoins: Number(data.giftedCoins) || 0,
          spentCoins: Number(data.spentCoins) || 0,
          lastUpdated: now,
          coinBatches: batches,
        },
        { merge: true }
      );
      t.set(db.collection('coinTransactions').doc(), {
        userId: uid,
        type: 'credit',
        amount: toCredit,
        balanceAfter: (Number(data.totalCoins) || 0) + toCredit,
        reason: 'expiryReversal',
        description: 'Coins restored — coins no longer expire (v4.0.0)',
        createdAt: now,
      });
      for (const f of fresh) {
        t.set(f.ledgerRef, {
          userId: uid,
          originalTransaction: f.txId,
          refundedAt: now,
        });
      }
    });
  }

  log(`  TOTAL: ${refundedUsers} users, ${refundedCoins} coins`);
  return { users: refundedUsers, coins: refundedCoins };
}

async function main() {
  log('GreenGo v4.0.0 — coin expiry removal');
  log(COMMIT ? 'MODE: COMMIT (writes to Firestore)' : 'MODE: DRY RUN (no writes)');

  admin.initializeApp();
  const db = admin.firestore();

  const strip = await phaseStrip(db);
  const refund = SKIP_REFUND ? { users: 0, coins: 0 } : await phaseRefund(db);

  log('\n── SUMMARY ──');
  log(`  balance docs to update : ${strip.docsChanged}`);
  log(`  batches to clean       : ${strip.batchesChanged}`);
  log(`  users to refund        : ${refund.users}`);
  log(`  coins to restore       : ${refund.coins}`);
  if (!COMMIT) log('\n  Dry run only. Re-run with --commit to apply.');
  process.exit(0);
}

main().catch((e) => {
  console.error('FAILED:', e);
  process.exit(1);
});
