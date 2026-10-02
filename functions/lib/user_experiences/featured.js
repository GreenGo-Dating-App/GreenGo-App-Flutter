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
exports.setExperienceFeatured = exports.featuredPatch = exports.FEATURE_MAX_DAYS = void 0;
/**
 * setExperienceFeatured — admin-only promotion of a member-hosted experience
 * into Explore "Top experiences" (tier 1: featured first).
 *
 *   { experienceId: string, days: 0..30 }
 *     days 1..30 → isFeatured: true,  featuredUntil: now + days
 *     days 0     → isFeatured: false, featuredUntil: null (unfeature)
 *
 * `isFeatured` / `featuredUntil` are SERVER-OWNED: firestore.rules lists them in
 * serverOwnedExperienceFields() (no client update), creates go through the
 * createUserExperience callable (always `isFeatured: false`). The client treats
 * a listing as featured only while `isFeatured && featuredUntil > now`, so an
 * expired promotion needs no cleanup job.
 *
 * No payment / boost purchase flow yet — admins only.
 */
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const createUserExperience_1 = require("./createUserExperience");
const featuredPatch_1 = require("./featuredPatch");
Object.defineProperty(exports, "FEATURE_MAX_DAYS", { enumerable: true, get: function () { return featuredPatch_1.FEATURE_MAX_DAYS; } });
Object.defineProperty(exports, "featuredPatch", { enumerable: true, get: function () { return featuredPatch_1.featuredPatch; } });
const db = admin.firestore();
exports.setExperienceFeatured = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 30 }, async (request) => {
    var _a, _b, _c, _d, _e;
    const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const me = await db.collection('users').doc(uid).get();
    if (!((_b = me.data()) === null || _b === void 0 ? void 0 : _b.isAdmin))
        throw new https_1.HttpsError('permission-denied', 'Admin only.');
    const experienceId = (_c = request.data) === null || _c === void 0 ? void 0 : _c.experienceId;
    if (typeof experienceId !== 'string' || !experienceId || experienceId.includes('/')) {
        throw new https_1.HttpsError('invalid-argument', 'experienceId required.');
    }
    const patch = (0, featuredPatch_1.featuredPatch)((_d = request.data) === null || _d === void 0 ? void 0 : _d.days, Date.now());
    if ('error' in patch) {
        throw new https_1.HttpsError('invalid-argument', `days must be an integer 0..${featuredPatch_1.FEATURE_MAX_DAYS}.`);
    }
    const ref = db.collection(createUserExperience_1.EXPERIENCES).doc(experienceId);
    const snap = await ref.get();
    if (!snap.exists)
        throw new https_1.HttpsError('not-found', 'Experience not found.');
    if (patch.isFeatured && snap.get('status') !== 'published') {
        throw new https_1.HttpsError('failed-precondition', 'Only published experiences can be featured.');
    }
    const featuredUntil = patch.featuredUntilMs === null
        ? null
        : admin.firestore.Timestamp.fromMillis(patch.featuredUntilMs);
    await ref.update({ isFeatured: patch.isFeatured, featuredUntil });
    console.log(`setExperienceFeatured(${experienceId}, days=${(_e = request.data) === null || _e === void 0 ? void 0 : _e.days}) by ${uid}`);
    return {
        experienceId,
        isFeatured: patch.isFeatured,
        featuredUntil: patch.featuredUntilMs,
    };
});
//# sourceMappingURL=featured.js.map