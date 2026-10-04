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
exports.onAttractionRatingWritten = void 0;
/**
 * Attraction user ratings → server-owned aggregate on `attraction_stats`.
 *
 * Users rate a catalogue attraction from its detail page by writing their OWN
 * doc `attraction_ratings/{attractionId}/ratings/{uid}` { stars 1..5,
 * createdAt, updatedAt } (create / change / delete; the rules pin the doc id
 * to the caller's uid). No client may write the aggregate fields
 * (ratingSum / ratingCount / ratingAvg / ratingDist / ratingUpdatedAt); this
 * trigger maintains them exactly once per write event — see
 * attractionRatingAggregate.ts for the model.
 *
 * RETRIES are on: a dropped event (cold-start OOM, contention) would leave the
 * aggregate permanently off. Safe because every event id is claimed in the
 * same transaction that applies its delta.
 */
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
require("../shared/firebaseAdmin");
const attractionRatingAggregate_1 = require("./attractionRatingAggregate");
const db = admin.firestore();
const deps = {
    db,
    serverTimestamp: () => admin.firestore.FieldValue.serverTimestamp(),
};
exports.onAttractionRatingWritten = (0, firestore_1.onDocumentWritten)({
    document: 'attraction_ratings/{attractionId}/ratings/{uid}',
    memory: '512MiB',
    retry: true,
}, (0, monitoring_1.monitored)('onAttractionRatingWritten', async (event) => {
    var _a, _b, _c, _d;
    const attractionId = event.params.attractionId;
    const before = ((_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before) === null || _b === void 0 ? void 0 : _b.exists) ? event.data.before.data() : undefined;
    const after = ((_d = (_c = event.data) === null || _c === void 0 ? void 0 : _c.after) === null || _d === void 0 ? void 0 : _d.exists) ? event.data.after.data() : undefined;
    await (0, attractionRatingAggregate_1.applyRatingEvent)(deps, event.id, attractionId, before === null || before === void 0 ? void 0 : before.stars, after === null || after === void 0 ? void 0 : after.stars);
}));
//# sourceMappingURL=attractionRatings.js.map