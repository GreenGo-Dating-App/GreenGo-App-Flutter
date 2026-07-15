"use strict";
/**
 * Group cascade cleanup (NEW, isolated module).
 *
 * When a group doc is deleted (an admin permanently deletes the group from the
 * client — the client can only delete the top-level `groups/{groupId}` doc,
 * since security rules scope the members/messages subcollections to their own
 * owner/sender), this trigger recursively removes the orphaned subcollections
 * (members, messages) plus each member's private inbox thread, using the Admin
 * SDK (which bypasses rules).
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
exports.onGroupDeleted = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
require("../shared/firebaseAdmin");
const db = admin.firestore();
const PAGE = 400;
async function deleteCollection(ref) {
    // eslint-disable-next-line no-constant-condition
    while (true) {
        const snap = await ref.limit(PAGE).get();
        if (snap.empty)
            break;
        const batch = db.batch();
        for (const d of snap.docs)
            batch.delete(d.ref);
        await batch.commit();
        if (snap.size < PAGE)
            break;
    }
}
exports.onGroupDeleted = (0, firestore_1.onDocumentDeleted)('groups/{groupId}', (0, monitoring_1.monitored)('onGroupDeleted', async (event) => {
    var _a;
    const groupId = event.params.groupId;
    const before = ((_a = event.data) === null || _a === void 0 ? void 0 : _a.data()) || {};
    const groupRef = db.collection('groups').doc(groupId);
    // Subcollections under the (now-deleted) group doc.
    await deleteCollection(groupRef.collection('members'));
    await deleteCollection(groupRef.collection('messages'));
    // Each participant's private inbox thread for this group.
    const participants = Array.isArray(before.participants)
        ? before.participants
        : [];
    for (let i = 0; i < participants.length; i += PAGE) {
        const chunk = participants.slice(i, i + PAGE);
        const batch = db.batch();
        for (const uid of chunk) {
            batch.delete(db
                .collection('user_group_inbox')
                .doc(uid)
                .collection('threads')
                .doc(groupId));
        }
        await batch.commit();
    }
    console.log(`onGroupDeleted: cleaned up group ${groupId}`);
}));
//# sourceMappingURL=groupCleanup.js.map