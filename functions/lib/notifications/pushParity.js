"use strict";
/**
 * Push notification parity (NEW, isolated module).
 *
 * GOAL: every in-app notification doc created in the `notifications` collection
 * ALSO delivers an FCM push to that user's phone — WITHOUT double-pushing the
 * many notification types that already send their own push.
 *
 * How the double-push is avoided: every existing Cloud Function that both writes
 * a `notifications` doc AND sends its own FCM push now stamps `pushSent: true`
 * on the doc it writes. This trigger reads the created doc and:
 *   - RETURNS immediately if `pushSent === true` (someone already pushed it), else
 *   - resolves the recipient's fcmToken and sends a best-effort push using the
 *     doc's own `title`, `message`/`body` and `data` map, then marks the doc
 *     `pushSent: true` so a retry can't re-push.
 *
 * Notification writers that DON'T push (coin gifts, gamification, subscriptions,
 * call/video, admin-index, etc.) are intentionally left unmarked — this trigger
 * is what finally delivers their push. That is the parity win.
 *
 * Fires on: notifications/{notifId} onCreate. Never throws.
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
exports.onNotificationCreatedPush = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
require("../shared/firebaseAdmin");
const db = admin.firestore();
/** Coerce an arbitrary notification `data` map into FCM's string→string shape. */
function stringifyData(raw, type) {
    const out = {};
    if (raw && typeof raw === 'object') {
        for (const [k, v] of Object.entries(raw)) {
            if (v === null || v === undefined)
                continue;
            out[k] = typeof v === 'string' ? v : JSON.stringify(v);
        }
    }
    // Ensure the app always has a `type` to route on.
    if (!out.type && type)
        out.type = type;
    return out;
}
exports.onNotificationCreatedPush = (0, firestore_1.onDocumentCreated)('notifications/{notifId}', (0, monitoring_1.monitored)('onNotificationCreatedPush', async (event) => {
    var _a;
    const snap = event.data;
    if (!snap)
        return;
    const doc = snap.data();
    if (!doc)
        return;
    // Another function already pushed this one — do nothing.
    if (doc.pushSent === true)
        return;
    const userId = doc.userId ||
        doc.recipientId ||
        doc.uid ||
        '';
    if (!userId)
        return;
    const title = doc.title || 'GreenGo';
    const body = doc.message ||
        doc.body ||
        '';
    const type = doc.type || 'notification';
    const data = stringifyData(doc.data, type);
    const imageUrl = doc.imageUrl || undefined;
    // Best-effort push — never throw out of the trigger.
    try {
        const userSnap = await db.collection('users').doc(userId).get();
        const token = (_a = userSnap.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
        if (token) {
            await admin.messaging().send({
                token,
                notification: Object.assign({ title,
                    body }, (imageUrl ? { imageUrl } : {})),
                data,
                android: {
                    priority: 'high',
                    notification: Object.assign({ sound: 'default', channelId: 'greengo_notifications' }, (imageUrl ? { imageUrl } : {})),
                },
                apns: { payload: { aps: { sound: 'default', badge: 1 } } },
            });
        }
    }
    catch (e) {
        console.error('onNotificationCreatedPush send failed', event.params.notifId, e);
    }
    // Mark handled (idempotent). onDocumentCreated does NOT re-fire on update,
    // so this cannot loop.
    try {
        await snap.ref.update({ pushSent: true });
    }
    catch (_b) {
        // ignore
    }
}));
//# sourceMappingURL=pushParity.js.map