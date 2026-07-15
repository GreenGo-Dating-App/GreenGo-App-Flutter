"use strict";
/**
 * Scheduled-event auto-publish (NEW, isolated module) — #17.
 *
 * Scheduled events (`status: 'scheduled'`, `publishAt` set) currently go "live"
 * purely via client-side query filtering (`publishAt <= now`), with NO doc write.
 * Because nothing writes the doc, the `onUpdate → published` transition never
 * fires, so a scheduled BUSINESS event never pushes to followers and a scheduled
 * COMMUNITY event never pushes to members.
 *
 * This scheduled function periodically flips DUE scheduled events
 * (`publishAt <= now`) to `status: 'published'` — a real doc write — which then
 * triggers the existing follower fan-out (business_new_event.ts) and community
 * fan-out (communities/eventFanout.ts) via their onUpdate handlers. Idempotent:
 * only events still in `scheduled` are flipped, and each fan-out has its own
 * one-time claim flag.
 *
 * Needs composite index events(status ASC, publishAt ASC).
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
exports.autoPublishScheduledEvents = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
require("../shared/firebaseAdmin");
const db = admin.firestore();
const PAGE = 300;
exports.autoPublishScheduledEvents = (0, scheduler_1.onSchedule)('every 15 minutes', (0, monitoring_1.monitored)('autoPublishScheduledEvents', async () => {
    const now = admin.firestore.Timestamp.now();
    let flipped = 0;
    // Page through due scheduled events.
    // eslint-disable-next-line no-constant-condition
    while (true) {
        const snap = await db
            .collection('events')
            .where('status', '==', 'scheduled')
            .where('publishAt', '<=', now)
            .orderBy('publishAt', 'asc')
            .limit(PAGE)
            .get();
        if (snap.empty)
            break;
        const batch = db.batch();
        for (const doc of snap.docs) {
            batch.update(doc.ref, {
                status: 'published',
                autoPublishedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        await batch.commit();
        flipped += snap.size;
        if (snap.size < PAGE)
            break;
    }
    if (flipped > 0) {
        console.log(`autoPublishScheduledEvents: published ${flipped} event(s)`);
    }
}));
//# sourceMappingURL=autoPublish.js.map