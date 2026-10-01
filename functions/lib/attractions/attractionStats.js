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
exports.onAttractionViewRecorded = void 0;
/**
 * Attraction page views — unique viewers per day.
 *
 * Attractions come from a curated static catalogue, so their stats live in a
 * separate collection: `attraction_stats/{attractionId}` { viewCount, updatedAt }.
 *
 * Opening an attraction page makes the client CREATE
 * `attraction_stats/{id}/daily_viewers/{YYYYMMDD}_{uid}` (create-only, the
 * rules pin the id to today's/yesterday's UTC date + the caller's uid). Each
 * such doc is one unique viewer-day, so this trigger simply adds one to the
 * public counter, which no client may write. Bounded: one tiny write per
 * user/day/attraction.
 */
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
require("../shared/firebaseAdmin");
const db = admin.firestore();
exports.onAttractionViewRecorded = (0, firestore_1.onDocumentCreated)({
    document: 'attraction_stats/{attractionId}/daily_viewers/{viewId}',
    memory: '512MiB',
}, (0, monitoring_1.monitored)('onAttractionViewRecorded', async (event) => {
    const attractionId = event.params.attractionId;
    if (!/^[0-9]{1,12}$/.test(attractionId))
        return;
    await db.collection('attraction_stats').doc(attractionId).set({
        viewCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
}));
//# sourceMappingURL=attractionStats.js.map