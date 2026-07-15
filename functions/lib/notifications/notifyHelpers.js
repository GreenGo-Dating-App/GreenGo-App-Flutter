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
exports.resolveActor = resolveActor;
exports.emitNotification = emitNotification;
/**
 * Shared notification helpers (NEW). Resolve an actor's avatar + name and emit
 * an actor-attributed in-app notification (+ FCM push). Titles are stored
 * WITHOUT the actor name; the Flutter tile renders `actorName` bold + tappable.
 */
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const db = admin.firestore();
/** Resolve an actor's display name + avatar from their profile. */
async function resolveActor(actorId) {
    try {
        const snap = await db.collection('profiles').doc(actorId).get();
        const p = snap.data() || {};
        const name = p.displayName ||
            p.nickname ||
            p.name ||
            'Someone';
        const photo = p.profilePhotoUrl ||
            (Array.isArray(p.photos) ? p.photos[0] : undefined) ||
            (Array.isArray(p.photoUrls) ? p.photoUrls[0] : undefined);
        return { id: actorId, name, photo };
    }
    catch (_a) {
        return { id: actorId, name: 'Someone' };
    }
}
/** Resolve a recipient's FCM token (users/{id}.fcmToken). */
async function tokenFor(userId) {
    var _a;
    try {
        const snap = await db.collection('users').doc(userId).get();
        return (_a = snap.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
    }
    catch (_b) {
        return undefined;
    }
}
/**
 * Emit ONE notification to [recipientId]: an in-app `notifications` doc carrying
 * the actor identity (avatar + name), plus a best-effort FCM push. No-op when
 * the recipient is the actor (unless [allowSelf]).
 */
async function emitNotification(params) {
    const { recipientId, type, title, body, data, actor, allowSelf } = params;
    if (!recipientId)
        return;
    if (actor && recipientId === actor.id && !allowSelf)
        return;
    // pushSent: true — emitNotification sends its own FCM push below, so the
    // onNotificationCreatedPush parity trigger must skip this doc (no double-push).
    // Covers all callers of this helper (engagementNotifications, group_chat/membership).
    await db.collection('notifications').add(Object.assign(Object.assign({ userId: recipientId, type,
        title, message: body, body,
        data, isRead: false, createdAt: admin.firestore.FieldValue.serverTimestamp(), pushSent: true }, (actor ? { actorId: actor.id, actorName: actor.name } : {})), ((actor === null || actor === void 0 ? void 0 : actor.photo) ? { imageUrl: actor.photo } : {})));
    try {
        const token = await tokenFor(recipientId);
        if (token) {
            await admin.messaging().send({
                token,
                notification: Object.assign({ title: actor ? `${actor.name} ${title}` : title, body }, ((actor === null || actor === void 0 ? void 0 : actor.photo) ? { imageUrl: actor.photo } : {})),
                data,
                android: {
                    priority: 'high',
                    notification: { sound: 'default', channelId: 'greengo_notifications' },
                },
                apns: { payload: { aps: { sound: 'default', badge: 1 } } },
            });
        }
    }
    catch (_a) {
        // Never fail the trigger on a push error.
    }
}
//# sourceMappingURL=notifyHelpers.js.map