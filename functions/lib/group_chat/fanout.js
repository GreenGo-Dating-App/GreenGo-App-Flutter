"use strict";
/**
 * Group Chat fan-out (NEW, isolated module).
 *
 * Triggered when a message is appended to a group in the dedicated `groups`
 * collection. The client writes the message exactly once; this function does
 * all the O(N) work server-side so the client write path stays O(1):
 *
 *   1. Denormalize lastMessage / lastMessageAt onto the group doc.
 *   2. Fan out a tiny summary to each member's private inbox index
 *      `user_group_inbox/{uid}/threads/{groupId}` and bump unread for everyone
 *      except the sender (batched, 450 writes/commit).
 *   3. Push an FCM notification to active, non-muted recipients (chunked
 *      multicast).
 *
 * Does NOT touch the legacy 1:1 `conversations` collection or its functions.
 *
 * Scale note: groups are capped (256 members) so per-message multicast is
 * bounded. For unbounded public "Culture Rooms" later, switch step 3 to FCM
 * topic publish (O(1)) by subscribing members to a `group_{id}` topic on join.
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
exports.onGroupMessageCreated = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const db = admin.firestore();
const INBOX_COL = 'user_group_inbox';
const THREADS_SUB = 'threads';
const BATCH_LIMIT = 450;
const FCM_CHUNK = 500;
function previewFor(type, content) {
    switch (type) {
        case 'image':
            return '📷 Photo';
        case 'video':
            return '🎥 Video';
        case 'gif':
            return 'GIF';
        case 'sticker':
            return '✨ Sticker';
        case 'voice_note':
            return '🎤 Voice message';
        case 'system':
            return content;
        default:
            return content.length > 120 ? `${content.substring(0, 117)}...` : content;
    }
}
async function senderDisplayName(senderId) {
    try {
        const doc = await db.collection('profiles').doc(senderId).get();
        const d = doc.data();
        return (d === null || d === void 0 ? void 0 : d.nickname) || (d === null || d === void 0 ? void 0 : d.name) || 'Someone';
    }
    catch (_a) {
        return 'Someone';
    }
}
exports.onGroupMessageCreated = (0, firestore_1.onDocumentCreated)('groups/{groupId}/messages/{messageId}', async (event) => {
    var _a, _b, _c, _d;
    const snap = event.data;
    if (!snap)
        return;
    const msg = snap.data();
    const groupId = event.params.groupId;
    const senderId = msg.senderId || '';
    const type = msg.type || 'text';
    const content = msg.content || '';
    const sentAt = msg.sentAt ||
        admin.firestore.FieldValue.serverTimestamp();
    const isSystem = type === 'system';
    const groupRef = db.collection('groups').doc(groupId);
    const groupSnap = await groupRef.get();
    if (!groupSnap.exists)
        return;
    const group = groupSnap.data();
    const participants = group.participants || [];
    if (participants.length === 0)
        return;
    const groupName = ((_a = group.groupInfo) === null || _a === void 0 ? void 0 : _a.name) || 'Group';
    const groupPhoto = (_c = (_b = group.groupInfo) === null || _b === void 0 ? void 0 : _b.photoUrl) !== null && _c !== void 0 ? _c : null;
    const preview = previewFor(type, content);
    // 1) Denormalize last message onto the group doc.
    await groupRef.set({
        lastMessage: {
            messageId: snap.id,
            senderId,
            content: preview,
            type,
            sentAt,
        },
        lastMessageAt: sentAt,
    }, { merge: true });
    // 2) Fan out inbox summaries (batched).
    let batch = db.batch();
    let ops = 0;
    const commits = [];
    for (const uid of participants) {
        const threadRef = db
            .collection(INBOX_COL)
            .doc(uid)
            .collection(THREADS_SUB)
            .doc(groupId);
        const update = {
            groupId,
            name: groupName,
            photoUrl: groupPhoto,
            isGroup: true,
            lastMessagePreview: preview,
            lastSenderId: senderId,
            lastMessageAt: sentAt,
            updatedAt: sentAt,
            memberCount: participants.length,
        };
        if (uid !== senderId) {
            update.unreadCount = admin.firestore.FieldValue.increment(1);
        }
        batch.set(threadRef, update, { merge: true });
        ops++;
        if (ops >= BATCH_LIMIT) {
            commits.push(batch.commit());
            batch = db.batch();
            ops = 0;
        }
    }
    if (ops > 0)
        commits.push(batch.commit());
    await Promise.all(commits);
    // 3) Push notifications (skip system messages, sender, muted/left members).
    if (isSystem)
        return;
    const recipientIds = participants.filter((u) => u !== senderId);
    if (recipientIds.length === 0)
        return;
    const [senderName, memberDocs] = await Promise.all([
        senderDisplayName(senderId),
        Promise.all(recipientIds.map((u) => groupRef.collection('members').doc(u).get())),
    ]);
    const activeRecipients = recipientIds.filter((_, i) => {
        const m = memberDocs[i].data();
        if (!m)
            return true;
        if (m.leftAt)
            return false;
        if (m.notificationsEnabled === false)
            return false;
        return true;
    });
    if (activeRecipients.length === 0)
        return;
    const tokenDocs = await Promise.all(activeRecipients.map((u) => db.collection('users').doc(u).get()));
    const tokens = [];
    for (const td of tokenDocs) {
        const t = (_d = td.data()) === null || _d === void 0 ? void 0 : _d.fcmToken;
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
                notification: { title: groupName, body: `${senderName}: ${preview}` },
                data: {
                    type: 'group_message',
                    groupId,
                    // conversationId mirrors groupId so the client foreground handler
                    // and tap-routing treat groups like 1:1 exchanges.
                    conversationId: groupId,
                    senderId,
                },
                // Match the 1:1 "exchange" notification sound + channel exactly.
                android: {
                    priority: 'high',
                    collapseKey: `group_${groupId}`,
                    notification: {
                        sound: 'default',
                        channelId: 'greengo_notifications',
                        priority: 'high',
                        tag: `group_${groupId}`,
                    },
                },
                apns: {
                    headers: { 'apns-collapse-id': `group_${groupId}` },
                    payload: {
                        aps: {
                            sound: 'default',
                            badge: 1,
                        },
                    },
                },
            });
        }
        catch (e) {
            // Best-effort: never fail the trigger on notification errors.
            console.error('Group FCM multicast failed', e);
        }
    }
});
//# sourceMappingURL=fanout.js.map