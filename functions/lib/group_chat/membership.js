"use strict";
/**
 * Group Chat membership maintenance (NEW, isolated module).
 *
 * All cross-user writes for groups happen here with the Admin SDK (which
 * bypasses security rules), so clients only ever write the group document and
 * their own data. Two triggers on the dedicated `groups` collection:
 *
 *   onGroupCreated           — seed every member's `members/{uid}` doc and
 *                              private `user_group_inbox` thread; post the
 *                              "created" system message.
 *   onGroupParticipantsChanged — diff the participants array on update; seed
 *                              added members, mark removed members (leftAt +
 *                              delete their inbox thread), post system messages,
 *                              and keep each member doc's role in sync with the
 *                              authoritative `roles` map.
 *
 * Never touches the legacy 1:1 `conversations` collection or its functions.
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
exports.onGroupInfoChanged = exports.onGroupParticipantsChanged = exports.onGroupCreated = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
const notifyHelpers_1 = require("../notifications/notifyHelpers");
require("../shared/firebaseAdmin");
const db = admin.firestore();
const INBOX_COL = 'user_group_inbox';
const THREADS_SUB = 'threads';
const BATCH_LIMIT = 450;
function inboxThreadRef(uid, groupId) {
    return db.collection(INBOX_COL).doc(uid).collection(THREADS_SUB).doc(groupId);
}
function memberRef(groupId, uid) {
    return db.collection('groups').doc(groupId).collection('members').doc(uid);
}
function systemMessageRef(groupId) {
    return db.collection('groups').doc(groupId).collection('messages').doc();
}
async function commitInChunks(writes) {
    let batch = db.batch();
    let ops = 0;
    const commits = [];
    for (const apply of writes) {
        apply(batch);
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
}
function seedWrites(groupId, uid, role, name, photoUrl, memberCount, preview, unread) {
    const now = admin.firestore.FieldValue.serverTimestamp();
    return [
        (b) => b.set(memberRef(groupId, uid), {
            userId: uid,
            role,
            joinedAt: now,
            lastReadAt: now,
            notificationsEnabled: true,
            leftAt: null,
        }, { merge: true }),
        (b) => b.set(inboxThreadRef(uid, groupId), {
            groupId,
            name,
            photoUrl,
            isGroup: true,
            lastMessagePreview: preview,
            lastMessageAt: now,
            unreadCount: unread,
            pinned: false,
            muted: false,
            memberCount,
            updatedAt: now,
        }, { merge: true }),
    ];
}
exports.onGroupCreated = (0, firestore_1.onDocumentCreated)('groups/{groupId}', (0, monitoring_1.monitored)("onGroupCreated", async (event) => {
    var _a, _b, _c;
    const snap = event.data;
    if (!snap)
        return;
    const groupId = event.params.groupId;
    const group = snap.data();
    const participants = group.participants || [];
    const roles = group.roles || {};
    const name = ((_a = group.groupInfo) === null || _a === void 0 ? void 0 : _a.name) || 'Group';
    const photoUrl = (_c = (_b = group.groupInfo) === null || _b === void 0 ? void 0 : _b.photoUrl) !== null && _c !== void 0 ? _c : null;
    const createdBy = group.createdBy;
    const writes = [];
    for (const uid of participants) {
        writes.push(...seedWrites(groupId, uid, roles[uid] || 'member', name, photoUrl, participants.length, 'Group created', 0));
    }
    // "created" system message.
    writes.push((b) => b.set(systemMessageRef(groupId), {
        senderId: createdBy,
        receiverId: '',
        matchId: groupId,
        content: `created the group "${name}"`,
        type: 'system',
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
    }));
    await commitInChunks(writes);
}));
exports.onGroupParticipantsChanged = (0, firestore_1.onDocumentUpdated)('groups/{groupId}', (0, monitoring_1.monitored)("onGroupParticipantsChanged", async (event) => {
    var _a, _b, _c, _d, _e, _f;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    const groupId = event.params.groupId;
    const prev = before.participants || [];
    const next = after.participants || [];
    const roles = after.roles || {};
    const name = ((_c = after.groupInfo) === null || _c === void 0 ? void 0 : _c.name) || 'Group';
    const photoUrl = (_e = (_d = after.groupInfo) === null || _d === void 0 ? void 0 : _d.photoUrl) !== null && _e !== void 0 ? _e : null;
    const added = next.filter((u) => !prev.includes(u));
    const removed = prev.filter((u) => !next.includes(u));
    if (added.length === 0 && removed.length === 0)
        return;
    const now = admin.firestore.FieldValue.serverTimestamp();
    const writes = [];
    for (const uid of added) {
        writes.push(...seedWrites(groupId, uid, roles[uid] || 'member', name, photoUrl, next.length, 'You were added to the group', 1));
    }
    for (const uid of removed) {
        writes.push((b) => b.set(memberRef(groupId, uid), { leftAt: now }, { merge: true }));
        writes.push((b) => b.delete(inboxThreadRef(uid, groupId)));
    }
    if (added.length > 0) {
        writes.push((b) => b.set(systemMessageRef(groupId), {
            senderId: '',
            receiverId: '',
            matchId: groupId,
            content: added.length === 1
                ? 'A new member joined'
                : `${added.length} new members joined`,
            type: 'system',
            status: 'sent',
            sentAt: now,
        }));
    }
    if (removed.length > 0) {
        writes.push((b) => b.set(systemMessageRef(groupId), {
            senderId: '',
            receiverId: '',
            matchId: groupId,
            content: removed.length === 1
                ? 'A member left the group'
                : `${removed.length} members left the group`,
            type: 'system',
            status: 'sent',
            sentAt: now,
        }));
    }
    await commitInChunks(writes);
    // Notifications: tell each ADDED user they were added (b), and tell the
    // group owner that someone joined their group (d). The actor for "added
    // you" is the group owner (the usual adder); for "joined your group" it's
    // the added user.
    if (added.length > 0) {
        const ownerId = after.createdBy ||
            ((_f = after.groupInfo) === null || _f === void 0 ? void 0 : _f.createdBy) || '';
        const ownerActor = ownerId ? await (0, notifyHelpers_1.resolveActor)(ownerId) : undefined;
        for (const uid of added) {
            if (uid === ownerId)
                continue;
            // → the added user
            await (0, notifyHelpers_1.emitNotification)({
                recipientId: uid,
                type: 'group_add',
                title: `added you to ${name}`,
                body: name,
                data: { type: 'group_add', groupId, action: 'open_group', actorId: ownerId },
                actor: ownerActor,
            });
            // → the group owner
            if (ownerId) {
                const joiner = await (0, notifyHelpers_1.resolveActor)(uid);
                await (0, notifyHelpers_1.emitNotification)({
                    recipientId: ownerId,
                    type: 'group_join',
                    title: `joined your group ${name}`,
                    body: name,
                    data: { type: 'group_join', groupId, action: 'open_group', actorId: uid },
                    actor: joiner,
                });
            }
        }
    }
}));
/**
 * onGroupInfoChanged — when the group name or photo changes, fan the new value
 * out to every member's inbox index so the group list / icon updates instantly
 * for everyone (not just the open chat). Cheap: one merge-set per member.
 */
exports.onGroupInfoChanged = (0, firestore_1.onDocumentUpdated)('groups/{groupId}', (0, monitoring_1.monitored)("onGroupInfoChanged", async (event) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    const groupId = event.params.groupId;
    const beforeName = (_d = (_c = before.groupInfo) === null || _c === void 0 ? void 0 : _c.name) !== null && _d !== void 0 ? _d : null;
    const afterName = (_f = (_e = after.groupInfo) === null || _e === void 0 ? void 0 : _e.name) !== null && _f !== void 0 ? _f : null;
    const beforePhoto = (_h = (_g = before.groupInfo) === null || _g === void 0 ? void 0 : _g.photoUrl) !== null && _h !== void 0 ? _h : null;
    const afterPhoto = (_k = (_j = after.groupInfo) === null || _j === void 0 ? void 0 : _j.photoUrl) !== null && _k !== void 0 ? _k : null;
    const nameChanged = beforeName !== afterName;
    const photoChanged = beforePhoto !== afterPhoto;
    if (!nameChanged && !photoChanged)
        return;
    const participants = after.participants || [];
    if (participants.length === 0)
        return;
    const update = {};
    if (nameChanged)
        update.name = afterName !== null && afterName !== void 0 ? afterName : 'Group';
    if (photoChanged)
        update.photoUrl = afterPhoto;
    const writes = participants.map((uid) => (b) => b.set(inboxThreadRef(uid, groupId), update, { merge: true }));
    await commitInChunks(writes);
}));
//# sourceMappingURL=membership.js.map