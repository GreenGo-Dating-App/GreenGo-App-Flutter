/**
 * Monthly coin allowance — the coins every membership tier promises in the app
 * (TierEntitlements.monthlyCoins): Base (FREE tier) 20, SILVER 300, GOLD 400,
 * PLATINUM 500 (TEST = Platinum). The FREE-tier amount is the Base membership
 * allowance, so it is paid only while the Base membership is active.
 *
 * Replaces the old `grantMonthlyAllowances`, which never paid anyone: it
 * filtered users.subscriptionTier by lower-case values the server never
 * writes, wrote to the wrong collection (`coin_balances`, the app reads
 * `coinBalances`), had no FREE/PLATINUM amounts and no double-pay guard.
 *
 *  - Tier = the EFFECTIVE tier on profiles/{uid} (shared/effectiveTier.ts):
 *    an expired paid tier gets the FREE (Base) amount — and only with an
 *    active Base membership; no Base membership = no coins.
 *  - Exactly once per user per month: a ledger doc
 *    `coinAllowanceGrants/{uid}_{YYYYMM}` is CREATED before crediting; a
 *    second run for the same month finds it and skips.
 *  - Credit via shared grantCoins → `coinBalances` + `coinTransactions`
 *    (source 'allowance'), plus an in-app notification (no mass push).
 *  - Skips banned / suspended / deleted accounts.
 *  - Scales: pages profiles by document id (300 per page, 20 in parallel)
 *    under a time budget, persisting the cursor in
 *    `coin_allowance_runs/{YYYYMM}`. The schedule fires hourly on days 1-3 of
 *    each month; every run resumes where the last stopped and does nothing
 *    once the month is complete.
 *
 * HTTP twin `runMonthlyCoinAllowancesNow?token=` (COIN_ALLOWANCE_TOKEN in the
 * gitignored functions/.env) is a DRY RUN by default: it counts what the
 * current month would grant without writing. `&dryRun=0` runs it for real.
 */
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { adminTokenOk } from '../shared/adminToken';
import '../shared/firebaseAdmin';
import { grantCoins } from '../shared/grants';
import { effectiveTier, EffectiveTier, isBaseMembershipActive } from '../shared/effectiveTier';
import { logInfo, logError } from '../shared/utils';

const db = admin.firestore();

/** Must match TierEntitlements.monthlyCoins in the app. */
export const MONTHLY_COINS: Record<EffectiveTier, number> = {
  FREE: 20, // Base membership (requires an active Base plan)
  SILVER: 300,
  GOLD: 400,
  PLATINUM: 500,
  TEST: 500,
};

const PAGE_SIZE = 300;
const PARALLEL = 20;
const TIME_BUDGET_MS = 480_000;

export function periodOf(d: Date): string {
  return `${d.getUTCFullYear()}${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
}

/** Accounts that must not receive coins. */
export function isExcluded(p: Record<string, any>): boolean {
  const status = String(p.accountStatus || 'active').toLowerCase();
  return p.isBanned === true || ['banned', 'suspended', 'deleted'].includes(status);
}

interface RunResult {
  period: string;
  dryRun: boolean;
  scanned: number;
  granted: number;
  alreadyGranted: number;
  excluded: number;
  coins: number;
  byTier: Record<string, number>;
  errors: number;
  complete: boolean;
}

async function grantOne(
  uid: string,
  data: Record<string, any>,
  period: string,
  now: Date,
  dryRun: boolean,
  out: RunResult,
): Promise<void> {
  if (isExcluded(data)) {
    out.excluded++;
    return;
  }
  const tier = effectiveTier(data, now);
  // The FREE-tier amount is the Base membership's allowance.
  if (tier === 'FREE' && !isBaseMembershipActive(data, now)) return;
  const amount = MONTHLY_COINS[tier] ?? 0;
  if (amount <= 0) return;
  const ledger = db.collection('coinAllowanceGrants').doc(`${uid}_${period}`);

  if (dryRun) {
    if ((await ledger.get()).exists) {
      out.alreadyGranted++;
    } else {
      out.granted++;
      out.coins += amount;
      out.byTier[tier] = (out.byTier[tier] || 0) + 1;
    }
    return;
  }

  try {
    // create() fails if it exists → the month was already paid.
    await ledger.create({
      userId: uid,
      period,
      tier,
      amount,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e: any) {
    if (e?.code === 6 || /already exists/i.test(String(e?.message))) {
      out.alreadyGranted++;
      return;
    }
    throw e;
  }

  try {
    await grantCoins(uid, amount, 'allowance', 'monthlyAllowance', { tier, period });
  } catch (e) {
    // Let a later run retry this user.
    await ledger.delete().catch(() => undefined);
    throw e;
  }
  await ledger.update({ status: 'granted' });
  await db.collection('notifications').add({
    userId: uid,
    type: 'coins_allowance',
    title: 'Monthly coins added',
    message: `You received ${amount} coins with your ${tier === 'FREE' ? 'free' : tier.toLowerCase()} membership this month.`,
    data: { type: 'coins_allowance', amount: String(amount), period },
    isRead: false,
    // In-app only: a push to every member each month is not wanted.
    pushSent: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  out.granted++;
  out.coins += amount;
  out.byTier[tier] = (out.byTier[tier] || 0) + 1;
}

export async function runAllowances(opts: {
  dryRun: boolean;
  now?: Date;
}): Promise<RunResult> {
  const now = opts.now ?? new Date();
  const period = periodOf(now);
  const started = Date.now();
  const stateRef = db.collection('coin_allowance_runs').doc(period);
  const out: RunResult = {
    period,
    dryRun: opts.dryRun,
    scanned: 0,
    granted: 0,
    alreadyGranted: 0,
    excluded: 0,
    coins: 0,
    byTier: {},
    errors: 0,
    complete: false,
  };

  const state = opts.dryRun ? undefined : (await stateRef.get()).data();
  if (state?.complete) {
    out.complete = true;
    return out;
  }
  let cursor: string | undefined = opts.dryRun ? undefined : state?.cursor;

  while (Date.now() - started < TIME_BUDGET_MS) {
    let q = db
      .collection('profiles')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(PAGE_SIZE);
    if (cursor) q = q.startAfter(cursor);
    const page = await q.get();
    if (page.empty) {
      out.complete = true;
      break;
    }
    for (let i = 0; i < page.docs.length; i += PARALLEL) {
      await Promise.all(
        page.docs.slice(i, i + PARALLEL).map((d) =>
          grantOne(d.id, d.data(), period, now, opts.dryRun, out).catch((e) => {
            out.errors++;
            logError(`allowance failed uid=${d.id}`, e);
          }),
        ),
      );
    }
    out.scanned += page.size;
    cursor = page.docs[page.docs.length - 1].id;
    if (page.size < PAGE_SIZE) {
      out.complete = true;
      break;
    }
  }

  if (!opts.dryRun) {
    await stateRef.set(
      {
        period,
        cursor: out.complete ? null : cursor ?? null,
        complete: out.complete,
        granted: admin.firestore.FieldValue.increment(out.granted),
        coins: admin.firestore.FieldValue.increment(out.coins),
        errors: admin.firestore.FieldValue.increment(out.errors),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  logInfo(`monthly allowance ${JSON.stringify(out)}`);
  return out;
}

export const grantMonthlyCoinAllowances = onSchedule(
  {
    // Hourly on days 1-3: each run resumes the month's cursor, and once the
    // month is complete every later run is a no-op.
    schedule: '5 * 1-3 * *',
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
  },
  async () => {
    try {
      await runAllowances({ dryRun: false });
    } catch (e) {
      logError('grantMonthlyCoinAllowances failed', e);
    }
  },
);

export const runMonthlyCoinAllowancesNow = onRequest(
  { memory: '512MiB', timeoutSeconds: 540 },
  async (req, res) => {
    if (!process.env.COIN_ALLOWANCE_TOKEN) {
      res.status(503).json({ error: 'not configured' });
      return;
    }
    if (!adminTokenOk(req, [process.env.COIN_ALLOWANCE_TOKEN], 'runMonthlyCoinAllowancesNow')) { // L-05
      res.status(403).json({ error: 'forbidden' });
      return;
    }
    const dryRun = req.query.dryRun !== '0';
    try {
      res.json(await runAllowances({ dryRun }));
    } catch (e: any) {
      res.status(500).json({ error: String(e?.message || e) });
    }
  },
);
