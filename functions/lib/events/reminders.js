"use strict";
/**
 * Event reminders (NEW, isolated module).
 *
 * Hourly scheduled function: finds events starting within the next 24h that
 * haven't been reminded yet, and pushes an FCM reminder to their attendees
 * (excluding muted / left). Marks `reminderSent` to avoid duplicates.
 *
 * Uses a single-field startDate range query (no composite index); status and
 * reminderSent are filtered in code.
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
exports.sendEventReminders = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const db = admin.firestore();
const FCM_CHUNK = 500;
exports.sendEventReminders = (0, scheduler_1.onSchedule)('every 60 minutes', async () => {
    var _a;
    const now = admin.firestore.Timestamp.now();
    const in24h = admin.firestore.Timestamp.fromMillis(now.toMillis() + 24 * 60 * 60 * 1000);
    const snap = await db
        .collection('events')
        .where('startDate', '>=', now)
        .where('startDate', '<=', in24h)
        .get();
    for (const doc of snap.docs) {
        const e = doc.data();
        if (e.status !== 'published')
            continue;
        if (e.reminderSent === true)
            continue;
        const title = e.title || 'Event';
        const attendeesSnap = await doc.ref.collection('attendees').get();
        const recipientIds = attendeesSnap.docs
            .filter((d) => {
            const a = d.data();
            if (a.muteNotifications === true)
                return false;
            if (a.leftAt)
                return false;
            return true;
        })
            .map((d) => d.id);
        if (recipientIds.length > 0) {
            const tokenDocs = await Promise.all(recipientIds.map((u) => db.collection('users').doc(u).get()));
            const tokens = [];
            for (const td of tokenDocs) {
                const t = (_a = td.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
                if (t)
                    tokens.push(t);
            }
            for (let i = 0; i < tokens.length; i += FCM_CHUNK) {
                const chunk = tokens.slice(i, i + FCM_CHUNK);
                try {
                    await admin.messaging().sendEachForMulticast({
                        tokens: chunk,
                        notification: {
                            title: `⏰ ${title}`,
                            body: 'Starting soon — see you there!',
                        },
                        data: { type: 'event_reminder', eventId: doc.id },
                        android: { priority: 'high' },
                    });
                }
                catch (err) {
                    console.error('Event reminder FCM failed', doc.id, err);
                }
            }
        }
        await doc.ref.update({ reminderSent: true });
    }
});
//# sourceMappingURL=reminders.js.map