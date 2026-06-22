"use strict";
/**
 * Maintains the denormalized `likeCount` on an event whenever a per-user like
 * doc is created or deleted under `events/{eventId}/likes/{userId}`.
 *
 * Scales to millions: the client only writes its own like doc; the count is
 * a single atomic FieldValue.increment here, and the "Popular" sort reads the
 * denormalized field (no fan-in reads). Isolated to the events feature — does
 * not touch any existing collection.
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
exports.onEventLikeDeleted = exports.onEventLikeCreated = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const db = admin.firestore();
async function bump(eventId, delta) {
    try {
        await db
            .collection('events')
            .doc(eventId)
            .set({ likeCount: admin.firestore.FieldValue.increment(delta) }, { merge: true });
    }
    catch (e) {
        console.error(`likeCount bump failed for ${eventId} (${delta}):`, e);
    }
}
exports.onEventLikeCreated = (0, firestore_1.onDocumentCreated)('events/{eventId}/likes/{userId}', async (event) => {
    await bump(event.params.eventId, 1);
});
exports.onEventLikeDeleted = (0, firestore_1.onDocumentDeleted)('events/{eventId}/likes/{userId}', async (event) => {
    await bump(event.params.eventId, -1);
});
//# sourceMappingURL=likes.js.map