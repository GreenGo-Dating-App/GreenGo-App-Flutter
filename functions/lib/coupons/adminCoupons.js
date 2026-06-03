"use strict";
/**
 * Admin-only callables for managing coupons from the admin panel.
 * All gated by users/{uid}.isAdmin === true (via verifyAdminAuth).
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
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.setCouponDisabled = exports.getCouponRedemptions = exports.listCoupons = exports.upsertCoupon = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("../shared/utils");
const grants_1 = require("./grants");
const VALID_DURATIONS_DAYS = [7, 14, 30, 60, 90, 180, 365];
const VALID_TIERS = ['BASIC', 'SILVER', 'GOLD', 'PLATINUM'];
exports.upsertCoupon = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 30 }, async (request) => {
    try {
        const adminUid = await (0, utils_1.verifyAdminAuth)(request.auth);
        const data = request.data;
        if (!data)
            throw new https_1.HttpsError('invalid-argument', 'Missing payload');
        const code = String(data.code || '').trim().toUpperCase();
        if (code.length < 3 || code.length > 64) {
            throw new https_1.HttpsError('invalid-argument', 'Code must be 3–64 characters');
        }
        const isBundle = Array.isArray(data.grants) && data.grants.length > 0;
        if (isBundle) {
            // Validate every grant; reject the whole upsert if any is malformed.
            try {
                data.grants.forEach((g, i) => (0, grants_1.validateGrant)(g, i));
            }
            catch (e) {
                throw new https_1.HttpsError('invalid-argument', String((e === null || e === void 0 ? void 0 : e.message) || e));
            }
        }
        else {
            // Legacy single-grant validation
            if (!data.type || !['membership', 'base_membership', 'coins'].includes(data.type)) {
                throw new https_1.HttpsError('invalid-argument', `Invalid type: ${data.type}`);
            }
            if (typeof data.durationDays !== 'number' ||
                !VALID_DURATIONS_DAYS.includes(data.durationDays)) {
                throw new https_1.HttpsError('invalid-argument', `durationDays must be one of ${VALID_DURATIONS_DAYS.join(', ')}`);
            }
            if (data.type === 'membership') {
                if (!data.tier || !VALID_TIERS.includes(data.tier)) {
                    throw new https_1.HttpsError('invalid-argument', 'Membership coupon requires a valid tier');
                }
            }
            if (data.type === 'coins') {
                if (!data.coinAmount || data.coinAmount <= 0) {
                    throw new https_1.HttpsError('invalid-argument', 'Coin coupon requires a positive coinAmount');
                }
            }
        }
        // autoGrantOnSignup only makes sense for a per-email coupon — otherwise
        // every new user with any email would trip the trigger.
        if (data.autoGrantOnSignup && !data.allowedEmail) {
            throw new https_1.HttpsError('invalid-argument', 'autoGrantOnSignup requires allowedEmail to be set');
        }
        // ── Code uniqueness (case-insensitive) ──
        const existing = await utils_1.db
            .collection('coupons')
            .where('code', '==', code)
            .limit(1)
            .get();
        if (!existing.empty && existing.docs[0].id !== data.couponId) {
            throw new https_1.HttpsError('already-exists', `Code "${code}" is already in use`);
        }
        const now = admin.firestore.Timestamp.now();
        const payload = {
            code,
            // Persist legacy single-grant fields only when the admin didn't
            // supply a bundle. Bundle coupons store only `grants`.
            type: isBundle ? null : data.type,
            tier: !isBundle && data.type === 'membership' ? data.tier : null,
            coinAmount: !isBundle && data.type === 'coins' ? data.coinAmount : null,
            durationDays: isBundle ? null : data.durationDays,
            grants: isBundle ? data.grants : null,
            maxRedemptions: data.maxRedemptions === undefined || data.maxRedemptions === null
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
            await utils_1.db.collection('coupons').doc(data.couponId).set(payload, { merge: true });
            (0, utils_1.logInfo)(`upsertCoupon (update) id=${data.couponId} code=${code} by=${adminUid}`);
            return { ok: true, couponId: data.couponId };
        }
        const docRef = await utils_1.db.collection('coupons').add(Object.assign(Object.assign({}, payload), { redemptionsCount: 0, createdAt: now, createdBy: adminUid }));
        (0, utils_1.logInfo)(`upsertCoupon (create) id=${docRef.id} code=${code} by=${adminUid}`);
        return { ok: true, couponId: docRef.id };
    }
    catch (err) {
        if (err instanceof https_1.HttpsError)
            throw err;
        throw (0, utils_1.handleError)(err);
    }
});
exports.listCoupons = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 30 }, async (request) => {
    var _a, _b, _c;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const limit = Math.min(Math.max(((_a = request.data) === null || _a === void 0 ? void 0 : _a.limit) || 50, 1), 200);
        const filter = ((_b = request.data) === null || _b === void 0 ? void 0 : _b.filter) || {};
        let q = utils_1.db.collection('coupons').orderBy('createdAt', 'desc');
        if (filter.disabled !== undefined)
            q = q.where('disabled', '==', filter.disabled);
        if (filter.type)
            q = q.where('type', '==', filter.type);
        if ((_c = request.data) === null || _c === void 0 ? void 0 : _c.startAfter) {
            const cursorSnap = await utils_1.db.collection('coupons').doc(request.data.startAfter).get();
            if (cursorSnap.exists)
                q = q.startAfter(cursorSnap);
        }
        q = q.limit(limit);
        const snap = await q.get();
        const items = snap.docs.map((d) => {
            var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q, _r;
            const data = d.data();
            return Object.assign(Object.assign({ id: d.id }, data), { createdAt: ((_d = (_b = (_a = data.createdAt) === null || _a === void 0 ? void 0 : _a.toDate) === null || _b === void 0 ? void 0 : (_c = _b.call(_a)).toISOString) === null || _d === void 0 ? void 0 : _d.call(_c)) || null, updatedAt: ((_h = (_f = (_e = data.updatedAt) === null || _e === void 0 ? void 0 : _e.toDate) === null || _f === void 0 ? void 0 : (_g = _f.call(_e)).toISOString) === null || _h === void 0 ? void 0 : _h.call(_g)) || null, expiresAt: ((_m = (_k = (_j = data.expiresAt) === null || _j === void 0 ? void 0 : _j.toDate) === null || _k === void 0 ? void 0 : (_l = _k.call(_j)).toISOString) === null || _m === void 0 ? void 0 : _m.call(_l)) || null, lastRedeemedAt: ((_r = (_p = (_o = data.lastRedeemedAt) === null || _o === void 0 ? void 0 : _o.toDate) === null || _p === void 0 ? void 0 : (_q = _p.call(_o)).toISOString) === null || _r === void 0 ? void 0 : _r.call(_q)) || null, remainingUses: data.maxRedemptions == null
                    ? null
                    : Math.max(0, data.maxRedemptions - (data.redemptionsCount || 0)) });
        });
        return {
            ok: true,
            items,
            nextCursor: items.length === limit ? items[items.length - 1].id : null,
        };
    }
    catch (err) {
        if (err instanceof https_1.HttpsError)
            throw err;
        throw (0, utils_1.handleError)(err);
    }
});
exports.getCouponRedemptions = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 30 }, async (request) => {
    var _a, _b;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const couponId = String(((_a = request.data) === null || _a === void 0 ? void 0 : _a.couponId) || '').trim();
        if (!couponId)
            throw new https_1.HttpsError('invalid-argument', 'couponId is required');
        const limit = Math.min(Math.max(((_b = request.data) === null || _b === void 0 ? void 0 : _b.limit) || 100, 1), 500);
        const snap = await utils_1.db
            .collection('coupons')
            .doc(couponId)
            .collection('redemptions')
            .orderBy('redeemedAt', 'desc')
            .limit(limit)
            .get();
        const items = snap.docs.map((d) => {
            var _a, _b, _c, _d;
            const data = d.data();
            return Object.assign(Object.assign({ userId: d.id }, data), { redeemedAt: ((_d = (_b = (_a = data.redeemedAt) === null || _a === void 0 ? void 0 : _a.toDate) === null || _b === void 0 ? void 0 : (_c = _b.call(_a)).toISOString) === null || _d === void 0 ? void 0 : _d.call(_c)) || null });
        });
        return { ok: true, items };
    }
    catch (err) {
        if (err instanceof https_1.HttpsError)
            throw err;
        throw (0, utils_1.handleError)(err);
    }
});
exports.setCouponDisabled = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 15 }, async (request) => {
    var _a, _b, _c;
    try {
        const adminUid = await (0, utils_1.verifyAdminAuth)(request.auth);
        const couponId = String(((_a = request.data) === null || _a === void 0 ? void 0 : _a.couponId) || '').trim();
        if (!couponId)
            throw new https_1.HttpsError('invalid-argument', 'couponId is required');
        await utils_1.db.collection('coupons').doc(couponId).update({
            disabled: !!((_b = request.data) === null || _b === void 0 ? void 0 : _b.disabled),
            updatedAt: admin.firestore.Timestamp.now(),
            updatedBy: adminUid,
        });
        (0, utils_1.logInfo)(`setCouponDisabled id=${couponId} disabled=${(_c = request.data) === null || _c === void 0 ? void 0 : _c.disabled} by=${adminUid}`);
        return { ok: true };
    }
    catch (err) {
        if (err instanceof https_1.HttpsError)
            throw err;
        throw (0, utils_1.handleError)(err);
    }
});
//# sourceMappingURL=adminCoupons.js.map