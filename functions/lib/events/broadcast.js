"use strict";
/**
 * Event admin broadcast fan-out (NEW, isolated module).
 *
 * When an organizer posts a broadcast (isBroadcast === true) in an event's
 * messages subcollection, push an FCM notification to every attendee (excluding
 * the sender, muted attendees, and those who left). Mirrors the group-chat
 * fan-out pattern. Events have no attendee cap, so tokens are sent in chunks.
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
exports.onEventBroadcastCreated = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const db = admin.firestore();
const FCM_CHUNK = 500;
exports.onEventBroadcastCreated = (0, firestore_1.onDocumentCreated)('events/{eventId}/messages/{messageId}', async (event) => {
    var _a, _b;
    const snap = event.data;
    if (!snap)
        return;
    const msg = snap.data();
    if (msg.isBroadcast !== true)
        return;
    const eventId = event.params.eventId;
    const senderId = msg.senderId || '';
    const text = msg.text || '';
    const eventDoc = await db.collection('events').doc(eventId).get();
    const title = ((_a = eventDoc.data()) === null || _a === void 0 ? void 0 : _a.title) || 'Event';
    const attendeesSnap = await db
        .collection('events')
        .doc(eventId)
        .collection('attendees')
        .get();
    const recipientIds = attendeesSnap.docs
        .filter((d) => {
        const a = d.data();
        if (d.id === senderId)
            return false;
        if (a.muteNotifications === true)
            return false;
        if (a.leftAt)
            return false;
        return true;
    })
        .map((d) => d.id);
    if (recipientIds.length === 0)
        return;
    const tokenDocs = await Promise.all(recipientIds.map((u) => db.collection('users').doc(u).get()));
    const tokens = [];
    for (const td of tokenDocs) {
        const t = (_b = td.data()) === null || _b === void 0 ? void 0 : _b.fcmToken;
        if (t)
            tokens.push(t);
    }
    if (tokens.length === 0)
        return;
    for (let i = 0; i < tokens.length; i += FCM_CHUNK) {
        const chunk = tokens.slice(i, i + FCM_CHUNK);
        try {
            await admin.messaging().sendEachForMulticast({
                tokens: chunk,
                notification: { title: `📣 ${title}`, body: text },
                data: { type: 'event_broadcast', eventId },
                android: { priority: 'high' },
            });
        }
        catch (e) {
            console.error('Event broadcast FCM failed', e);
        }
    }
});
//# sourceMappingURL=broadcast.js.map