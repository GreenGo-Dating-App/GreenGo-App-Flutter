/**
 * Admin-only callables for managing coupons from the admin panel.
 * All gated by users/{uid}.isAdmin === true (via verifyAdminAuth).
 */

import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { db, verifyAdminAuth, handleError, logInfo } from '../shared/utils';
import { TierName } from '../shared/grants';

const VALID_DURATIONS_DAYS = [7, 14, 30, 60, 90, 180, 365];
const VALID_TIERS: TierName[] = ['BASIC', 'SILVER', 'GOLD', 'PLATINUM'];

interface UpsertCouponRequest {
  couponId?: string | null;
  code: string;
  type: 'membership' | 'base_membership' | 'coins';
  tier?: TierName | null;
  coinAmount?: number | null;
  durationDays: number;
  maxRedemptions?: number | null;
  expiresAt?: string | null; // ISO date string
  allowedEmail?: string | null;
  autoGrantOnSignup?: boolean;
  disabled?: boolean;
  notes?: string;
}

interface ListCouponsRequest {
  limit?: number;
  startAfter?: string | null; // last couponId for pagination
  filter?: { disabled?: boolean; type?: string };
}

interface GetCouponRedemptionsRequest {
  couponId: string;
  limit?: number;
}

interface SetCouponDisabledRequest {
  couponId: string;
  disabled: boolean;
}

export const upsertCoupon = onCall<UpsertCouponRequest>(
  { memory: '256MiB', timeoutSeconds: 30 },
  async (request: CallableRequest<UpsertCouponRequest>) => {
    try {
      const adminUid = await verifyAdminAuth(request.auth);
      const data = request.data;
      if (!data) throw new HttpsError('invalid-argument', 'Missing payload');

      const code = String(data.code || '').trim().toUpperCase();
      if (code.length < 3 || code.length > 64) {
        throw new HttpsError('invalid-argument', 'Code must be 3–64 characters');
      }

      if (!['membership', 'base_membership', 'coins'].includes(data.type)) {
        throw new HttpsError('invalid-argument', `Invalid type: ${data.type}`);
      }

      if (!VALID_DURATIONS_DAYS.includes(data.durationDays)) {
        throw new HttpsError(
          'invalid-argument',
          `durationDays must be one of ${VALID_DURATIONS_DAYS.join(', ')}`,
        );
      }

      if (data.type === 'membership') {
        if (!data.tier || !VALID_TIERS.includes(data.tier)) {
          throw new HttpsError('invalid-argument', 'Membership coupon requires a valid tier');
        }
      }
      if (data.type === 'coins') {
        if (!data.coinAmount || data.coinAmount <= 0) {
          throw new HttpsError('invalid-argument', 'Coin coupon requires a positive coinAmount');
        }
      }

      // autoGrantOnSignup only makes sense for a per-email coupon — otherwise
      // every new user with any email would trip the trigger.
      if (data.autoGrantOnSignup && !data.allowedEmail) {
        throw new HttpsError(
          'invalid-argument',
          'autoGrantOnSignup requires allowedEmail to be set',
        );
      }

      // ── Code uniqueness (case-insensitive) ──
      const existing = await db
        .collection('coupons')
        .where('code', '==', code)
        .limit(1)
        .get();
      if (!existing.empty && existing.docs[0].id !== data.couponId) {
        throw new HttpsError('already-exists', `Code "${code}" is already in use`);
      }

      const now = admin.firestore.Timestamp.now();
      const payload: Record<string, any> = {
        code,
        type: data.type,
        tier: data.type === 'membership' ? data.tier : null,
        coinAmount: data.type === 'coins' ? data.coinAmount : null,
        durationDays: data.durationDays,
        maxRedemptions:
          data.maxRedemptions === undefined || data.maxRedemptions === null
            ? null
            : Number(data.maxRedemptions),
        expiresAt: data.expiresAt ? admin.firestore.Timestamp.fromDate(new Date(data.expiresAt)) : null,
        allowedEmail: data.allowedEmail ? String(data.allowedEmail).toLowerCase().trim() : null,
        autoGrantOnSignup: !!data.autoGrantOnSignup,
        disabled: !!data.disabled,
        notes: data.notes ? String(data.notes).slice(0, 500) : '',
        updatedAt: now,
        updatedBy: adminUid,
      };

      if (data.couponId) {
        await db.collection('coupons').doc(data.couponId).set(payload, { merge: true });
        logInfo(`upsertCoupon (update) id=${data.couponId} code=${code} by=${adminUid}`);
        return { ok: true, couponId: data.couponId };
      }

      const docRef = await db.collection('coupons').add({
        ...payload,
        redemptionsCount: 0,
        createdAt: now,
        createdBy: adminUid,
      });
      logInfo(`upsertCoupon (create) id=${docRef.id} code=${code} by=${adminUid}`);
      return { ok: true, couponId: docRef.id };
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      throw handleError(err);
    }
  },
);

export const listCoupons = onCall<ListCouponsRequest>(
  { memory: '256MiB', timeoutSeconds: 30 },
  async (request: CallableRequest<ListCouponsRequest>) => {
    try {
      await verifyAdminAuth(request.auth);
      const limit = Math.min(Math.max(request.data?.limit || 50, 1), 200);
      const filter = request.data?.filter || {};

      let q: FirebaseFirestore.Query = db.collection('coupons').orderBy('createdAt', 'desc');
      if (filter.disabled !== undefined) q = q.where('disabled', '==', filter.disabled);
      if (filter.type) q = q.where('type', '==', filter.type);

      if (request.data?.startAfter) {
        const cursorSnap = await db.collection('coupons').doc(request.data.startAfter).get();
        if (cursorSnap.exists) q = q.startAfter(cursorSnap);
      }

      q = q.limit(limit);
      const snap = await q.get();
      const items = snap.docs.map((d) => {
        const data = d.data();
        return {
          id: d.id,
          ...data,
          createdAt: data.createdAt?.toDate?.().toISOString?.() || null,
          updatedAt: data.updatedAt?.toDate?.().toISOString?.() || null,
          expiresAt: data.expiresAt?.toDate?.().toISOString?.() || null,
          lastRedeemedAt: data.lastRedeemedAt?.toDate?.().toISOString?.() || null,
          remainingUses:
            data.maxRedemptions == null
              ? null
              : Math.max(0, (data.maxRedemptions as number) - (data.redemptionsCount || 0)),
        };
      });
      return {
        ok: true,
        items,
        nextCursor: items.length === limit ? items[items.length - 1].id : null,
      };
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      throw handleError(err);
    }
  },
);

export const getCouponRedemptions = onCall<GetCouponRedemptionsRequest>(
  { memory: '256MiB', timeoutSeconds: 30 },
  async (request: CallableRequest<GetCouponRedemptionsRequest>) => {
    try {
      await verifyAdminAuth(request.auth);
      const couponId = String(request.data?.couponId || '').trim();
      if (!couponId) throw new HttpsError('invalid-argument', 'couponId is required');
      const limit = Math.min(Math.max(request.data?.limit || 100, 1), 500);

      const snap = await db
        .collection('coupons')
        .doc(couponId)
        .collection('redemptions')
        .orderBy('redeemedAt', 'desc')
        .limit(limit)
        .get();

      const items = snap.docs.map((d) => {
        const data = d.data();
        return {
          userId: d.id,
          ...data,
          redeemedAt: data.redeemedAt?.toDate?.().toISOString?.() || null,
        };
      });
      return { ok: true, items };
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      throw handleError(err);
    }
  },
);

export const setCouponDisabled = onCall<SetCouponDisabledRequest>(
  { memory: '128MiB', timeoutSeconds: 15 },
  async (request: CallableRequest<SetCouponDisabledRequest>) => {
    try {
      const adminUid = await verifyAdminAuth(request.auth);
      const couponId = String(request.data?.couponId || '').trim();
      if (!couponId) throw new HttpsError('invalid-argument', 'couponId is required');

      await db.collection('coupons').doc(couponId).update({
        disabled: !!request.data?.disabled,
        updatedAt: admin.firestore.Timestamp.now(),
        updatedBy: adminUid,
      });
      logInfo(`setCouponDisabled id=${couponId} disabled=${request.data?.disabled} by=${adminUid}`);
      return { ok: true };
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      throw handleError(err);
    }
  },
);
