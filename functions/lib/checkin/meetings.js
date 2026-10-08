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
exports.ENCOUNTERS = exports.MET_IN_PERSON = void 0;
exports.pairIdOf = pairIdOf;
exports.encounterIdOf = encounterIdOf;
exports.recordMeeting = recordMeeting;
/**
 * "Met in person" — proof that two members were physically together.
 *
 * Written ONLY by the server, and only from a successful QR check-in:
 *   - experience booking check-in  → host ↔ guest
 *   - event ticket check-in        → organizer ↔ attendee (and the scanning
 *                                     co-organizer ↔ attendee)
 *
 * Shape (no client writes; members read their own pairs):
 *   met_in_person/{pairId}                    pairId = sorted "uidA_uidB"
 *     { users: [uidA, uidB], count, verifiedCount, firstMetAt, lastMetAt,
 *       lastContext: { type, contextId, title } }
 *   met_in_person/{pairId}/encounters/{type}_{contextId}
 *     { type: 'event' | 'experience', contextId, title, verified, at, byUid }
 *
 * Idempotent per (pair, context): scanning the same ticket twice, or a retried
 * callable, never counts a second meeting. `verified` is false only for the
 * legacy unsigned event tickets accepted during the transition — the meeting
 * is still recorded, but it does not count towards `verifiedCount`.
 */
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
exports.MET_IN_PERSON = 'met_in_person';
exports.ENCOUNTERS = 'encounters';
function pairIdOf(a, b) {
    return [a, b].sort().join('_');
}
function encounterIdOf(type, contextId) {
    return `${type}_${contextId}`;
}
/**
 * Records that [a] and [b] met. Returns true when this is a NEW encounter,
 * false when it was already recorded (or a and b are the same person).
 * Never throws: a failure here must not undo a check-in that succeeded.
 */
async function recordMeeting(a, b, ctx, db = admin.firestore()) {
    if (!a || !b || a === b)
        return false;
    const pairId = pairIdOf(a, b);
    const pairRef = db.collection(exports.MET_IN_PERSON).doc(pairId);
    const encRef = pairRef.collection(exports.ENCOUNTERS).doc(encounterIdOf(ctx.type, ctx.contextId));
    try {
        return await db.runTransaction(async (tx) => {
            var _a;
            const [enc, pair] = await Promise.all([tx.get(encRef), tx.get(pairRef)]);
            if (enc.exists)
                return false;
            const now = admin.firestore.Timestamp.now();
            const title = ((_a = ctx.title) !== null && _a !== void 0 ? _a : '').slice(0, 140);
            tx.create(encRef, {
                type: ctx.type,
                contextId: ctx.contextId,
                title,
                verified: ctx.verified,
                byUid: ctx.byUid,
                at: now,
            });
            const inc = admin.firestore.FieldValue.increment;
            tx.set(pairRef, Object.assign(Object.assign({ users: [a, b].sort(), count: inc(1), verifiedCount: inc(ctx.verified ? 1 : 0), lastMetAt: now }, (pair.exists ? {} : { firstMetAt: now })), { lastContext: { type: ctx.type, contextId: ctx.contextId, title } }), { merge: true });
            return true;
        });
    }
    catch (e) {
        console.error(`[met_in_person] record ${pairId} ${ctx.type}:${ctx.contextId} failed:`, e);
        return false;
    }
}
//# sourceMappingURL=meetings.js.map