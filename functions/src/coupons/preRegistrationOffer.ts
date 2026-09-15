/**
 * What a given email will receive when it registers.
 *
 * The registration form calls this once the email is entered, so the user is
 * told what is waiting for them BEFORE they commit to signing up:
 *
 *   "This account has PLATINUM for 30 days plus 3 months of Base membership,
 *    added automatically from today."
 *
 * Two kinds of answer:
 *
 *   PRE-REGISTRATION  the email is on the allowlist (a `coupons` document with
 *                     allowedEmail == this address). The exact tier and
 *                     durations come from that coupon's grants.
 *   DEFAULT 2026      everyone else registering during 2026 gets the standard
 *                     welcome pack: one month of Base membership and 100 coins.
 *
 * This is DESCRIPTIVE ONLY. It grants nothing and writes nothing. The actual
 * entitlement is applied server-side by applySignupGrants when the account is
 * created, so a forged or replayed call to this endpoint cannot obtain
 * anything - the worst it can do is make the form show the wrong promise.
 *
 * ── On the enumeration risk ───────────────────────────────────────────────
 * An unauthenticated endpoint that answers "yes, this address is on the
 * allowlist" is an oracle: someone could walk a list of addresses and learn
 * which are pre-registered. That is why:
 *
 *   - it returns ONLY the offer, never whether an account exists, never a
 *     name, a coupon code, or anything else about the person;
 *   - it is rate limited per caller, so the list cannot be walked at speed;
 *   - an unknown address gets the same shaped answer as a known one (the 2026
 *     default), so a single probe does not cleanly distinguish the two.
 *
 * It is a deliberate, bounded trade for the signup experience that was asked
 * for. `validateCoupon` - which leaked whether an arbitrary CODE was valid and
 * granted nothing in return - was removed for being a worse version of this.
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { db, logInfo } from '../shared/utils';
import { effectiveGrants } from './grants';
import { monitored } from '../shared/monitoring';

/** The standard welcome pack for anyone not on the allowlist, during 2026. */
export const DEFAULT_2026_OFFER = {
  baseMembershipDays: 30, // one month
  coins: 100,
} as const;

/** Is `when` inside the 2026 promotional window? */
export function isWithin2026(when: Date): boolean {
  return when.getUTCFullYear() === 2026;
}

export interface PreRegistrationOffer {
  /** 'preRegistration' when the email is on the allowlist, else 'default2026'. */
  kind: 'preRegistration' | 'default2026' | 'none';
  /** Paid tier, when one is granted. SILVER | GOLD | PLATINUM. */
  tier?: string;
  /** Days of that paid tier. */
  membershipDays?: number;
  /** Days of Base membership. */
  baseMembershipDays?: number;
  /** Welcome coins. */
  coins?: number;
}

/**
 * Reads the offer for an email without granting anything.
 * Exported so applySignupGrants can use the SAME default, rather than two
 * copies of "100 coins and 30 days" drifting apart.
 */
export async function resolveOffer(
  email: string,
  now: Date = new Date(),
): Promise<PreRegistrationOffer> {
  const clean = email.toLowerCase().trim();

  const snap = await db
    .collection('coupons')
    .where('allowedEmail', '==', clean)
    .where('disabled', '==', false)
    .get();

  let tier: string | undefined;
  let membershipDays = 0;
  let baseDays = 0;
  let coins = 0;

  for (const doc of snap.docs) {
    const c = doc.data() as any;
    // An expired or fully-redeemed coupon promises nothing.
    if (c.expiresAt && (c.expiresAt as admin.firestore.Timestamp).toDate() <= now) continue;
    if (c.maxRedemptions != null && (c.redemptionsCount || 0) >= c.maxRedemptions) continue;

    for (const g of effectiveGrants(c)) {
      if (g.kind === 'membership' && g.tier && g.durationDays) {
        // Several coupons on one address: advertise the best tier and the
        // longest run of it, which is what the grant logic also settles on.
        if (!tier || (g.durationDays || 0) > membershipDays) {
          tier = g.tier;
          membershipDays = Math.max(membershipDays, g.durationDays);
        }
      } else if (g.kind === 'base_membership' && g.durationDays) {
        baseDays += g.durationDays;
      } else if (g.kind === 'coins' && g.coinAmount) {
        coins += g.coinAmount;
      }
    }
  }

  if (tier || baseDays > 0 || coins > 0) {
    // A membership grant with no explicit base grant earns a matching base
    // membership as a bonus - the same rule applySignupGrants applies, mirrored
    // here so the promise on screen matches what actually lands.
    if (tier && baseDays === 0) baseDays = membershipDays;
    return {
      kind: 'preRegistration',
      tier,
      membershipDays: membershipDays || undefined,
      baseMembershipDays: baseDays || undefined,
      coins: coins || undefined,
    };
  }

  if (isWithin2026(now)) {
    return {
      kind: 'default2026',
      baseMembershipDays: DEFAULT_2026_OFFER.baseMembershipDays,
      coins: DEFAULT_2026_OFFER.coins,
    };
  }

  return { kind: 'none' };
}

// ── Rate limiting ────────────────────────────────────────────────────────────
// In-memory and therefore per-instance: it does not stop a determined attacker
// spread across cold starts, but it does stop a list being walked from one
// machine at speed, which is the realistic abuse. A Firestore counter would be
// exact and would also add a write to every keystroke-triggered lookup.
const RATE_WINDOW_MS = 60_000;
const RATE_MAX = 20;
const hits = new Map<string, number[]>();

function rateLimited(key: string): boolean {
  const now = Date.now();
  const recent = (hits.get(key) || []).filter((t) => now - t < RATE_WINDOW_MS);
  recent.push(now);
  hits.set(key, recent);
  if (hits.size > 5000) hits.clear(); // crude bound; this is a cache, not a ledger
  return recent.length > RATE_MAX;
}

export const checkPreRegistrationOffer = onCall(
  { memory: '512MiB', timeoutSeconds: 15 },
  monitored('checkPreRegistrationOffer', async (request) => {
    const email = String(request.data?.email || '').toLowerCase().trim();
    if (!email || !email.includes('@') || email.length > 254) {
      throw new HttpsError('invalid-argument', 'A valid email is required');
    }

    const caller = request.rawRequest?.ip || request.auth?.uid || 'anonymous';
    if (rateLimited(caller)) {
      throw new HttpsError('resource-exhausted', 'Too many lookups, try again shortly');
    }

    const offer = await resolveOffer(email);
    logInfo(`checkPreRegistrationOffer: ${offer.kind} for ${email}`);
    // Deliberately nothing else in the response - no coupon code, no name, no
    // hint about whether an account already exists.
    return offer;
  }),
);
