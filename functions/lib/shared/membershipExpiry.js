"use strict";
/**
 * Membership expiry primitives shared by the hourly expiry jobs, the store
 * notification handlers, the Stripe webhook and the one-off migration.
 *
 * Paid tier (SILVER/GOLD/PLATINUM) and Base membership are INDEPENDENT:
 *   - a paid tier ending sets `membershipTier: 'FREE'` and never touches
 *     `hasBaseMembership` / `baseMembershipEndDate`;
 *   - a Base membership ending sets `hasBaseMembership: false` and never
 *     touches the tier.
 *
 * `membershipEndDate` is kept for history; `membershipExpiredAt` and
 * `previousMembershipTier` record the downgrade. Every write is idempotent:
 * re-running on an already-downgraded profile is a no-op (the planner skips
 * it), and the expiry notification has a deterministic id.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.WriteQueue = exports.MAX_BATCH_OPS = void 0;
exports.planTierExpiry = planTierExpiry;
exports.planBaseExpiry = planBaseExpiry;
exports.downgradeTierNow = downgradeTierNow;
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("./utils");
const effectiveTier_1 = require("./effectiveTier");
/** Max operations per WriteBatch (Firestore hard limit is 500). */
exports.MAX_BATCH_OPS = 400;
/** Subscription statuses that still claim an entitlement (both casings in prod). */
const LIVE_SUBSCRIPTION_STATUSES = [
    'active', 'ACTIVE', 'in_grace_period', 'GRACE', 'on_hold',
];
/**
 * Buffers writes and commits them in batches of at most [MAX_BATCH_OPS].
 * Call [flush] at the end.
 */
class WriteQueue {
    constructor(firestore = utils_1.db) {
        this.firestore = firestore;
        this.ops = 0;
        this.committedOps = 0;
        this.batch = firestore.batch();
    }
    async set(ref, data, merge = true) {
        if (merge)
            this.batch.set(ref, data, { merge: true });
        else
            this.batch.set(ref, data);
        await this.bump();
    }
    async update(ref, data) {
        this.batch.update(ref, data);
        await this.bump();
    }
    async bump() {
        this.ops++;
        if (this.ops >= exports.MAX_BATCH_OPS)
            await this.flush();
    }
    async flush() {
        if (this.ops === 0)
            return;
        const b = this.batch;
        const n = this.ops;
        this.batch = this.firestore.batch();
        this.ops = 0;
        await b.commit();
        this.committedOps += n;
    }
}
exports.WriteQueue = WriteQueue;
/**
 * Plans (enqueues) the downgrade of one profile's PAID tier to FREE:
 *   profiles/{uid}: membershipTier 'FREE', membershipExpiredAt, previousMembershipTier
 *   users/{uid}:    subscriptionTier 'free', membershipEndDate (mirror; only if the doc exists)
 *   memberships where userId==uid && isActive → isActive false
 *   subscriptions (non-Base) still 'active'/'ACTIVE'/grace whose endDate passed → 'expired'
 *   notifications/membership_expired_{uid}_{endMillis} (deterministic → idempotent)
 *
 * Returns the tier that was removed, or null when nothing had to change
 * (already FREE, TEST, admin, or still active).
 */
async function planTierExpiry(profileSnap, queue, opts) {
    var _a, _b, _c, _d, _e, _f;
    const data = profileSnap.data();
    if (!data)
        return null;
    const uid = profileSnap.id;
    const now = (_a = opts.now) !== null && _a !== void 0 ? _a : admin.firestore.Timestamp.now();
    const nowDate = now.toDate();
    const stored = (0, effectiveTier_1.normalizeStoredTier)(data.membershipTier);
    // TEST testers and admins keep their stored tier (same as the client).
    if (stored === 'TEST' || (0, effectiveTier_1.isProfileAdmin)(data))
        return null;
    // Already FREE (only the raw value 'FREE' counts; 'free'/'BASIC' get normalised).
    if (data.membershipTier === 'FREE')
        return null;
    const requirePast = opts.requirePastEndDate !== false;
    if (requirePast && (0, effectiveTier_1.effectiveTier)(data, nowDate) !== 'FREE')
        return null;
    const endDate = (0, effectiveTier_1.tierDateFromValue)(data.membershipEndDate);
    await queue.set(profileSnap.ref, {
        membershipTier: 'FREE',
        previousMembershipTier: String((_b = data.membershipTier) !== null && _b !== void 0 ? _b : ''),
        membershipExpiredAt: now,
        membershipExpiryReason: opts.reason,
        updatedAt: now,
    });
    // Mirrors: never used for decisions, but keep them from contradicting the profile.
    const userRef = utils_1.db.collection('users').doc(uid);
    const [userSnap, activeMemberships, liveSubs] = await Promise.all([
        userRef.get(),
        utils_1.db.collection('memberships')
            .where('userId', '==', uid)
            .where('isActive', '==', true)
            .get(),
        utils_1.db.collection('subscriptions')
            .where('userId', '==', uid)
            .where('status', 'in', LIVE_SUBSCRIPTION_STATUSES)
            .get(),
    ]);
    if (userSnap.exists) {
        await queue.set(userRef, {
            subscriptionTier: effectiveTier_1.USERS_FREE_TIER,
            membershipEndDate: endDate ? admin.firestore.Timestamp.fromDate(endDate) : null,
            updatedAt: now,
        });
    }
    for (const m of activeMemberships.docs) {
        await queue.set(m.ref, { isActive: false, expiredAt: now, updatedAt: now });
    }
    for (const s of liveSubs.docs) {
        const sd = s.data();
        if ((0, effectiveTier_1.isBaseProductId)(sd.productId) || String(sd.tier || '').toUpperCase() === 'BASE')
            continue;
        const subEnd = (0, effectiveTier_1.tierDateFromValue)((_d = (_c = sd.endDate) !== null && _c !== void 0 ? _c : sd.storeExpiryDate) !== null && _d !== void 0 ? _d : sd.expirationDate);
        // A still-running store/Stripe period on this record means the profile
        // was ended early (refund/revoke) — the caller decides that; for the
        // plain expiry path only records whose own period is over are closed.
        if (requirePast && subEnd && subEnd.getTime() > nowDate.getTime())
            continue;
        await queue.set(s.ref, { status: 'expired', updatedAt: now });
    }
    // Legacy 'BASIC' was never a paid tier the user bought: normalise silently.
    if (opts.notify !== false && stored !== 'BASIC') {
        const key = `${uid}_${endDate ? endDate.getTime() : 'noend'}`;
        await queue.set(utils_1.db.collection('notifications').doc(`membership_expired_${key}`), {
            userId: uid,
            type: 'membership_expired',
            title: 'Membership Expired',
            body: 'Your membership has expired. Purchase a new membership to restore premium features.',
            data: { previousTier: String((_e = data.membershipTier) !== null && _e !== void 0 ? _e : '') },
            read: false,
            sent: false,
            createdAt: now,
        }, false);
    }
    return String((_f = data.membershipTier) !== null && _f !== void 0 ? _f : '');
}
/**
 * Plans the expiry of a profile's Base membership: hasBaseMembership false +
 * baseMembershipExpiredAt. Never touches the tier. Returns true when a write
 * was enqueued.
 */
async function planBaseExpiry(profileSnap, queue, now = admin.firestore.Timestamp.now()) {
    const data = profileSnap.data();
    if (!data || data.hasBaseMembership !== true)
        return false;
    const end = (0, effectiveTier_1.tierDateFromValue)(data.baseMembershipEndDate);
    if (end && end.getTime() > now.toMillis())
        return false; // still active
    await queue.set(profileSnap.ref, {
        hasBaseMembership: false,
        baseMembershipExpiredAt: now,
        updatedAt: now,
    });
    return true;
}
/**
 * Immediately downgrades one user's paid tier (store refund/revoke, Stripe
 * subscription deleted). Returns the removed tier or null.
 */
async function downgradeTierNow(uid, reason, notify = true) {
    const snap = await utils_1.db.collection('profiles').doc(uid).get();
    if (!snap.exists)
        return null;
    const queue = new WriteQueue();
    try {
        const removed = await planTierExpiry(snap, queue, {
            reason,
            notify,
            requirePastEndDate: false,
        });
        await queue.flush();
        return removed;
    }
    catch (e) {
        (0, utils_1.logError)(`downgradeTierNow failed for ${uid}`, e);
        throw e;
    }
}
//# sourceMappingURL=membershipExpiry.js.map