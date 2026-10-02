"use strict";
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
exports.createUserExperience = exports.EXPERIENCE_COUNTS = exports.EXPERIENCES = void 0;
exports.safetyError = safetyError;
exports.countPublishedPaid = countPublishedPaid;
/**
 * createUserExperience — the ONLY way to create a `user_experiences` doc.
 *
 * Why a callable (and `allow create: if false` in the rules) instead of a
 * rules-only check against a trigger-maintained counter:
 *  - atomic: the per-host counter `user_experience_counts/{uid}` is read and
 *    incremented in the SAME transaction that writes the experience, so two
 *    parallel creates cannot both slip under the limit (a trigger-maintained
 *    counter lags the write, and a burst of creates would all pass the rule);
 *  - one tier rule: the limit uses shared/effectiveTier.ts (expired Silver =
 *    FREE), which handles every stored `membershipEndDate` shape (Timestamp,
 *    millis, ISO string) — Firestore rules cannot parse the string forms;
 *  - full server validation + moderation of the payload at write time, and
 *    every server-owned field (ratings, status 'hidden', moderation, hostId)
 *    is set here, never taken from the client.
 * Cost: one cold-start-prone round trip per create, and creation needs the
 * function deployed (edits/deletes stay direct Firestore writes).
 *
 * A host downgraded below their current count keeps every existing
 * experience (nothing is auto-hidden) — they just cannot create new ones.
 */
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const effectiveTier_1 = require("../shared/effectiveTier");
const moderation_1 = require("./moderation");
const validation_1 = require("./validation");
const safety_1 = require("./safety");
const db = admin.firestore();
exports.EXPERIENCES = 'user_experiences';
exports.EXPERIENCE_COUNTS = 'user_experience_counts';
exports.createUserExperience = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 60 }, async (request) => {
    var _a, _b;
    const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const v = (0, validation_1.validateExperiencePayload)(request.data);
    if (!v.ok) {
        throw new https_1.HttpsError('invalid-argument', 'invalid_experience', {
            code: 'invalid_experience',
            fields: v.errors,
        });
    }
    const mod = (0, moderation_1.moderateExperienceText)(v.data);
    if (!mod.ok) {
        // contact_info: phones / e-mails / handles / PIX keys outside the
        // payment link (anti-scam); prohibited_text: language.
        const code = mod.reason === 'contact_info' ? 'contact_info' : 'prohibited_text';
        throw new https_1.HttpsError('invalid-argument', code, { code, kinds: (_b = mod.terms) !== null && _b !== void 0 ? _b : [] });
    }
    const profileRef = db.collection('profiles').doc(uid);
    const counterRef = db.collection(exports.EXPERIENCE_COUNTS).doc(uid);
    const expRef = db.collection(exports.EXPERIENCES).doc();
    const result = await db.runTransaction(async (tx) => {
        var _a, _b, _c;
        const [profileSnap, counterSnap] = await Promise.all([
            tx.get(profileRef),
            tx.get(counterRef),
        ]);
        const profile = (_a = profileSnap.data()) !== null && _a !== void 0 ? _a : null;
        // Phase 1 safety: ID document uploaded to create; agreement + approved
        // document (+ new-host paid limit) to publish a listing taking money.
        const blocked = (0, safety_1.createBlockReason)(profile);
        if (blocked)
            throw safetyError(blocked);
        // A new listing has no dates yet, and availability must be defined by
        // dates: it is always stored as a draft, published via
        // publishUserExperience once it has an upcoming date.
        const tier = (0, effectiveTier_1.effectiveTier)(profile);
        const max = (0, validation_1.maxExperiencesFor)(tier, (0, effectiveTier_1.isProfileAdmin)(profile));
        let count = Number((_c = (_b = counterSnap.data()) === null || _b === void 0 ? void 0 : _b.count) !== null && _c !== void 0 ? _c : 0) || 0;
        if (max !== null && count >= max) {
            // Self-heal a drifted counter (e.g. a failed delete trigger) before
            // refusing: the authoritative number is the host's actual docs.
            const agg = await tx.get(db.collection(exports.EXPERIENCES).where('hostId', '==', uid).count());
            count = agg.data().count;
            if (count >= max) {
                throw new https_1.HttpsError('resource-exhausted', 'experience_limit', {
                    code: 'experience_limit',
                    limit: max,
                    count,
                    tier,
                });
            }
        }
        const now = admin.firestore.FieldValue.serverTimestamp();
        tx.set(expRef, Object.assign(Object.assign({}, v.data), { status: 'draft', hostId: uid, createdAt: now, updatedAt: now, ratingSum: 0, ratingCount: 0, ratingAvg: 0, reviewCount: 0, ratingDist: { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 }, viewCount: 0, 
            // Explore promotion is server-owned (setExperienceFeatured, admin).
            isFeatured: false, 
            // Its (empty) aggregate is part of the host's profile totals from the
            // start, so review triggers keep profiles/{uid}.hostRating* in step.
            // Without a profile there is nothing to count into (backfill later).
            hostRatingCounted: profileSnap.exists }));
        tx.set(counterRef, { count: count + 1, updatedAt: now }, { merge: true });
        return { id: expRef.id, count: count + 1, limit: max, status: 'draft' };
    });
    return result;
});
/** Structured refusal the client maps to a guided prompt (see safety.ts). */
function safetyError(code) {
    return new https_1.HttpsError('failed-precondition', code, { code });
}
/** The host's published PAID listings (aggregate count: 1 read / 1000 docs). */
async function countPublishedPaid(tx, hostId, excludeId) {
    const agg = await tx.get(db.collection(exports.EXPERIENCES)
        .where('hostId', '==', hostId)
        .where('status', '==', 'published')
        .where('isFree', '==', false)
        .count());
    let n = agg.data().count;
    if (excludeId) {
        const self = await tx.get(db.collection(exports.EXPERIENCES).doc(excludeId));
        const d = self.data();
        if (d && d.hostId === hostId && d.status === 'published' && d.isFree === false)
            n -= 1;
    }
    return Math.max(0, n);
}
//# sourceMappingURL=createUserExperience.js.map