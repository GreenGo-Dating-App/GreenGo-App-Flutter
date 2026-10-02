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
exports.onExperienceReportCreated = exports.acceptHostAgreement = exports.publishUserExperience = void 0;
/**
 * User experiences — Phase 1 safety callables + report trigger.
 *
 *  publishUserExperience  {experienceId, asFree?}
 *    The ONLY way to publish a listing that takes money (firestore.rules deny
 *    a direct client transition into "published + paid / with link", because
 *    the new-host limit needs a count rules cannot do). Also used for free
 *    publishes so the client has one path. In one transaction: host owns it,
 *    not hidden, ID document + host agreement + approved document for paid,
 *    new-host paid limit; `asFree` turns it into a free listing first.
 *
 *  acceptHostAgreement    {version}
 *    Records profiles/{uid}.hostAgreementAcceptedAt / hostAgreementVersion
 *    (server-owned: clients cannot write them).
 *
 *  onExperienceReportCreated  reports/{reportId}
 *    Counts DISTINCT reporters per experience (marker per reporter under
 *    user_experiences/{id}/reporters, no client access). At 3 the listing is
 *    hidden (status 'hidden', moderation.reason 'reports') pending admin
 *    review, and the host is notified. Host self-reports never count.
 */
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const notifyHelpers_1 = require("../notifications/notifyHelpers");
const createUserExperience_1 = require("./createUserExperience");
const safety_1 = require("./safety");
const db = admin.firestore();
const OPTS = { memory: '512MiB', timeoutSeconds: 60 };
exports.publishUserExperience = (0, https_1.onCall)(OPTS, async (request) => {
    var _a, _b, _c;
    const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const id = typeof ((_b = request.data) === null || _b === void 0 ? void 0 : _b.experienceId) === 'string' ? request.data.experienceId : '';
    if (!id)
        throw new https_1.HttpsError('invalid-argument', 'experienceId is required.');
    const asFree = ((_c = request.data) === null || _c === void 0 ? void 0 : _c.asFree) === true;
    const expRef = db.collection(createUserExperience_1.EXPERIENCES).doc(id);
    const profileRef = db.collection('profiles').doc(uid);
    return db.runTransaction(async (tx) => {
        var _a, _b;
        const [exp, profileSnap] = await Promise.all([tx.get(expRef), tx.get(profileRef)]);
        if (!exp.exists)
            throw new https_1.HttpsError('not-found', 'not_found', { code: 'not_found' });
        const data = (_a = exp.data()) !== null && _a !== void 0 ? _a : {};
        if (data.hostId !== uid)
            throw new https_1.HttpsError('permission-denied', 'Not your experience.');
        if (data.status === 'hidden') {
            throw new https_1.HttpsError('failed-precondition', 'hidden', { code: 'hidden' });
        }
        const profile = (_b = profileSnap.data()) !== null && _b !== void 0 ? _b : null;
        const next = Object.assign(Object.assign({}, data), (asFree ? safety_1.AS_FREE_PATCH : {}));
        let otherPublishedPaid = 0;
        if (next.isFree !== true && (profile === null || profile === void 0 ? void 0 : profile.isAdmin) !== true && (0, safety_1.isNewHost)(profile)) {
            otherPublishedPaid = await (0, createUserExperience_1.countPublishedPaid)(tx, uid, id);
        }
        const why = (0, safety_1.publishBlockReason)({ profile, experience: next, otherPublishedPaid });
        if (why)
            throw (0, createUserExperience_1.safetyError)(why);
        tx.update(expRef, Object.assign(Object.assign({}, (asFree ? safety_1.AS_FREE_PATCH : {})), { status: 'published', updatedAt: admin.firestore.FieldValue.serverTimestamp() }));
        return { status: 'published', asFree };
    });
});
exports.acceptHostAgreement = (0, https_1.onCall)(OPTS, async (request) => {
    var _a, _b;
    const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const version = Number((_b = request.data) === null || _b === void 0 ? void 0 : _b.version);
    if (version !== safety_1.HOST_AGREEMENT_VERSION) {
        // An old client accepting an outdated text must not count as consent.
        throw new https_1.HttpsError('failed-precondition', 'agreement_outdated', {
            code: 'agreement_outdated',
            current: safety_1.HOST_AGREEMENT_VERSION,
        });
    }
    const ref = db.collection('profiles').doc(uid);
    const snap = await ref.get();
    if (!snap.exists)
        throw new https_1.HttpsError('failed-precondition', 'Complete your profile first.');
    await ref.update({
        hostAgreementAcceptedAt: admin.firestore.FieldValue.serverTimestamp(),
        hostAgreementVersion: safety_1.HOST_AGREEMENT_VERSION,
    });
    return { version: safety_1.HOST_AGREEMENT_VERSION };
});
exports.onExperienceReportCreated = (0, firestore_1.onDocumentCreated)(Object.assign({ document: 'reports/{reportId}' }, OPTS), async (event) => {
    var _a;
    const r = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!r || !safety_1.EXPERIENCE_REPORT_TYPES.includes(String(r.type)))
        return;
    const experienceId = typeof r.experienceId === 'string' ? r.experienceId : '';
    const reporterId = typeof r.reporterId === 'string' ? r.reporterId : '';
    if (!experienceId || !reporterId)
        return;
    const expRef = db.collection(createUserExperience_1.EXPERIENCES).doc(experienceId);
    const markerRef = expRef.collection('reporters').doc(reporterId);
    let hidden = null;
    try {
        await db.runTransaction(async (tx) => {
            var _a, _b, _c;
            const [exp, marker] = await Promise.all([tx.get(expRef), tx.get(markerRef)]);
            if (!exp.exists || marker.exists)
                return; // gone, or this reporter already counted
            const data = (_a = exp.data()) !== null && _a !== void 0 ? _a : {};
            if (data.hostId === reporterId)
                return;
            const distinct = (Number(data.reportCount) || 0) + 1;
            tx.set(markerRef, {
                reportId: event.params.reportId,
                reason: typeof r.reason === 'string' ? r.reason.slice(0, 40) : null,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            const patch = { reportCount: distinct };
            if ((0, safety_1.shouldHideForReports)(distinct, data.status)) {
                patch.status = 'hidden';
                // `auto` absent: the text-moderation trigger never auto-restores it;
                // only an admin decision does.
                patch.moderation = {
                    reason: 'reports',
                    reportCount: distinct,
                    previousStatus: data.status === 'published' ? 'published' : 'draft',
                    hiddenAt: admin.firestore.FieldValue.serverTimestamp(),
                };
                hidden = { hostId: String((_b = data.hostId) !== null && _b !== void 0 ? _b : ''), title: String((_c = data.title) !== null && _c !== void 0 ? _c : '') };
            }
            tx.update(expRef, patch);
        });
    }
    catch (e) {
        console.error(`experience report count failed (${experienceId}):`, e);
        return;
    }
    const h = hidden;
    if (h && h.hostId) {
        try {
            await (0, notifyHelpers_1.emitNotification)({
                recipientId: h.hostId,
                type: 'experience_hidden',
                title: 'Your experience was hidden after several reports',
                body: h.title.slice(0, 120) || 'Pending review by GreenGo',
                data: { action: 'experience', experienceId },
            });
        }
        catch (e) {
            console.error(`experience hidden notify failed (${experienceId}):`, e);
        }
    }
});
//# sourceMappingURL=safetyCallables.js.map