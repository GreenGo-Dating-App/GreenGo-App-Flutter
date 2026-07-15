"use strict";
/**
 * ONE-TIME backfill (NEW, isolated module).
 *
 * Older communities were created without adding the creator to the `members`
 * subcollection (fixed going forward in the client's createCommunity). Those
 * communities are missing from the creator's "My Communities" and the creator
 * can't post tips/announcements (rules gate on an existing member doc). This
 * callable-by-URL function walks every community and, when the creator has no
 * member doc, creates one as OWNER. Idempotent — safe to run more than once.
 *
 * Guarded by a shared secret passed as `?token=...` so it can't be triggered
 * anonymously. Invoke once after deploy, then it can be removed.
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
exports.backfillCommunityCreatorMembers = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
require("../shared/firebaseAdmin");
const db = admin.firestore();
// Change this before deploying if you want a different one-time token.
const BACKFILL_TOKEN = 'greengo-backfill-2026';
exports.backfillCommunityCreatorMembers = (0, https_1.onRequest)({ memory: '512MiB', timeoutSeconds: 300 }, (0, monitoring_1.monitored)('backfillCommunityCreatorMembers', async (req, res) => {
    var _a, _b;
    if (req.query.token !== BACKFILL_TOKEN) {
        res.status(403).send('forbidden');
        return;
    }
    let scanned = 0;
    let created = 0;
    let lastId;
    // eslint-disable-next-line no-constant-condition
    while (true) {
        let q = db
            .collection('communities')
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(300);
        if (lastId)
            q = q.startAfter(lastId);
        const snap = await q.get();
        if (snap.empty)
            break;
        lastId = snap.docs[snap.docs.length - 1].id;
        for (const doc of snap.docs) {
            scanned++;
            const c = doc.data();
            const creatorId = c.createdByUserId || '';
            if (!creatorId)
                continue;
            const memberRef = doc.ref.collection('members').doc(creatorId);
            const existing = await memberRef.get();
            if (existing.exists)
                continue;
            // Resolve the creator's display name for the member doc.
            let displayName = c.createdByName || '';
            if (!displayName) {
                const p = await db.collection('profiles').doc(creatorId).get();
                displayName =
                    ((_a = p.data()) === null || _a === void 0 ? void 0 : _a.displayName) ||
                        ((_b = p.data()) === null || _b === void 0 ? void 0 : _b.nickname) ||
                        'Owner';
            }
            await memberRef.set({
                userId: creatorId,
                displayName,
                photoUrl: null,
                role: 'owner',
                joinedAt: admin.firestore.Timestamp.now(),
                languages: [],
                isLocalGuide: false,
                isMuted: false,
                isBanned: false,
                canWriteTips: false,
                canWriteAnnouncements: false,
            });
            created++;
        }
        if (snap.size < 300)
            break;
    }
    res.status(200).json({ scanned, created });
}));
//# sourceMappingURL=backfillCreatorMembers.js.map