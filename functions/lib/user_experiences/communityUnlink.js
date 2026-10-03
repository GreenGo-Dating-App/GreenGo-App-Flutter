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
exports.onCommunityDeletedUnlinkExperiences = exports.MAX_ROUNDS = exports.UNLINK_PAGE = void 0;
exports.unlinkCommunityExperiences = unlinkCommunityExperiences;
/**
 * Community deleted → its experiences are KEPT (they belong to their hosts,
 * with their bookings and reviews) and simply unlinked: `communityId` and
 * `communityName` are removed so they no longer point at a missing community.
 *
 * Scale: pages of UNLINK_PAGE docs, one batched write per page. The query is
 * re-run from the source each round (each round consumes what it matched, so
 * an offset would skip docs) and bounded by MAX_ROUNDS.
 */
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
exports.UNLINK_PAGE = 400;
exports.MAX_ROUNDS = 250; // 100k linked experiences per deleted community
/** Unlinks every experience of [communityId]; returns how many were updated. */
async function unlinkCommunityExperiences(db, communityId, pageSize = exports.UNLINK_PAGE) {
    let total = 0;
    for (let round = 0; round < exports.MAX_ROUNDS; round++) {
        const snap = await db
            .collection('user_experiences')
            .where('communityId', '==', communityId)
            .limit(pageSize)
            .get();
        if (snap.empty)
            break;
        const batch = db.batch();
        for (const d of snap.docs) {
            batch.update(d.ref, {
                communityId: admin.firestore.FieldValue.delete(),
                communityName: admin.firestore.FieldValue.delete(),
            });
        }
        await batch.commit();
        total += snap.size;
        if (snap.size < pageSize)
            break;
    }
    return total;
}
exports.onCommunityDeletedUnlinkExperiences = (0, firestore_1.onDocumentDeleted)({ document: 'communities/{communityId}', memory: '512MiB', timeoutSeconds: 300 }, async (event) => {
    const { communityId } = event.params;
    try {
        const n = await unlinkCommunityExperiences(admin.firestore(), communityId);
        if (n > 0)
            console.log(`community ${communityId} deleted: unlinked ${n} experiences`);
    }
    catch (e) {
        console.error(`unlink experiences of deleted community ${communityId} failed:`, e);
        throw e; // let the retry policy (if enabled) re-run it; idempotent
    }
});
//# sourceMappingURL=communityUnlink.js.map