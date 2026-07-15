"use strict";
/**
 * Report-count maintenance (NEW, isolated module) — #22.
 *
 * The client can create a `user_reports/{id}` doc but CANNOT increment
 * `users/{reportedUserId}.reportCount` (security rules deny writing another
 * user's doc), so that best-effort client write was silently denied and the
 * moderation triage counter never moved.
 *
 * This Admin-SDK trigger bumps the counter authoritatively when a report doc is
 * created. Idempotent per report via a marker on the report doc.
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
exports.onUserReportCreated = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
require("../shared/firebaseAdmin");
const db = admin.firestore();
exports.onUserReportCreated = (0, firestore_1.onDocumentCreated)('user_reports/{reportId}', (0, monitoring_1.monitored)('onUserReportCreated', async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const r = snap.data();
    const reportedUserId = (r === null || r === void 0 ? void 0 : r.reportedUserId) || '';
    if (!reportedUserId)
        return;
    if ((r === null || r === void 0 ? void 0 : r.countApplied) === true)
        return; // already counted
    // Mark the report as counted first (idempotency guard against retries).
    await snap.ref.update({ countApplied: true });
    await db.collection('users').doc(reportedUserId).set({
        reportCount: admin.firestore.FieldValue.increment(1),
        lastReportedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
}));
//# sourceMappingURL=reportCountTrigger.js.map