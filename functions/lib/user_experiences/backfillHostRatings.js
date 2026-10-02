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
exports.backfillHostRatings = void 0;
/**
 * backfillHostRatings — admin-only, resumable, one-off.
 *
 * Folds every experience that predates the host-rating totals (no
 * `hostRatingCounted: true`) into `profiles/{hostId}.hostRatingSum /
 * hostRatingCount / hostRatingAvg`. The experience's own aggregate is the sum
 * of its VISIBLE reviews (maintained exactly-once by onExperienceReviewWritten),
 * so the host totals become Σ visible reviews over all their experiences.
 *
 * Per experience, ONE transaction reads the experience + the host profile,
 * adds the aggregate and sets `hostRatingCounted: true`. Review triggers read
 * the same experience in their transactions, so a review landing concurrently
 * is counted exactly once (before the flag: inside the aggregate we add; after
 * it: by the trigger). Re-running is safe: flagged experiences are skipped.
 *
 * Pages `user_experiences` by document id; call repeatedly with the returned
 * `cursor` until `done`.
 */
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const aggregates_1 = require("./aggregates");
const createUserExperience_1 = require("./createUserExperience");
const db = admin.firestore();
exports.backfillHostRatings = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 540 }, async (request) => {
    var _a, _b, _c, _d;
    const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const me = await db.collection('users').doc(uid).get();
    if (!((_b = me.data()) === null || _b === void 0 ? void 0 : _b.isAdmin))
        throw new https_1.HttpsError('permission-denied', 'Admin only.');
    const pageSize = Math.min(Math.max(Number((_c = request.data) === null || _c === void 0 ? void 0 : _c.pageSize) || 200, 1), 500);
    let q = db
        .collection(createUserExperience_1.EXPERIENCES)
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(pageSize);
    if (typeof ((_d = request.data) === null || _d === void 0 ? void 0 : _d.cursor) === 'string' && request.data.cursor) {
        q = q.startAfter(request.data.cursor);
    }
    const page = await q.get();
    let counted = 0;
    let failed = 0;
    for (const doc of page.docs) {
        if (doc.get('hostRatingCounted') === true)
            continue;
        const hostId = doc.get('hostId');
        if (typeof hostId !== 'string' || !hostId)
            continue;
        try {
            const done = await db.runTransaction(async (tx) => {
                const [exp, profile] = await Promise.all([
                    tx.get(doc.ref),
                    tx.get(db.collection('profiles').doc(hostId)),
                ]);
                if (!exp.exists || exp.get('hostRatingCounted') === true)
                    return false;
                if (!profile.exists)
                    return false; // deleted host: nothing to fold into
                tx.update(profile.ref, Object.assign({}, (0, aggregates_1.applyHostRatingDelta)(profile.data(), (0, aggregates_1.experienceHostContribution)(exp.data()))));
                tx.update(exp.ref, { hostRatingCounted: true });
                return true;
            });
            if (done)
                counted++;
        }
        catch (e) {
            failed++;
            console.error(`backfillHostRatings ${doc.id} failed:`, e);
        }
    }
    const last = page.docs[page.docs.length - 1];
    return {
        scanned: page.size,
        counted,
        failed,
        cursor: last ? last.id : null,
        done: page.size < pageSize,
    };
});
//# sourceMappingURL=backfillHostRatings.js.map