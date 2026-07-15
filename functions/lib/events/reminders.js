"use strict";
/**
 * Event reminders (NEW, isolated module).
 *
 * Hourly scheduled function with THREE reminder windows for events an attendee
 * has joined: 24h before, 6h before, and "just started". Each window fires at
 * most once (per-window flags `reminded24h`/`reminded6h`/`remindedStart`), pushes
 * an FCM reminder AND writes an in-app `notifications` doc (so it shows on the
 * notifications page). Single-field startDate range query (no composite index);
 * status + flags filtered in code.
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
const monitoring_1 = require("../shared/monitoring");
require("../shared/firebaseAdmin");
const db = admin.firestore();
const FCM_CHUNK = 500;
const HOUR = 60 * 60 * 1000;
async function fanOutReminder(eventId, eventRef, title, body, flag) {
    var _a;
    const attendeesSnap = await eventRef.collection('attendees').get();
    const recipientIds = attendeesSnap.docs
        .filter((d) => {
        const a = d.data();
        return a.muteNotifications !== true && !a.leftAt;
    })
        .map((d) => d.id);
    // Claim the window flag first (idempotent across retries).
    await eventRef.update({ [flag]: true });
    if (recipientIds.length === 0)
        return;
    const dataPayload = { type: 'event_reminder', eventId, action: 'open_event' };
    // FCM.
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
                notification: { title: `⏰ ${title}`, body },
                data: dataPayload,
                android: { priority: 'high' },
            });
        }
        catch (err) {
            console.error('Event reminder FCM failed', eventId, err);
        }
    }
    // In-app docs (batched).
    let batch = db.batch();
    let ops = 0;
    const commits = [];
    for (const uid of recipientIds) {
        batch.set(db.collection('notifications').doc(), {
            userId: uid,
            type: 'event_reminder',
            title,
            message: body,
            body,
            data: dataPayload,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            // Attendees were already multicast above — skip the parity trigger.
            pushSent: true,
        });
        if (++ops >= 450) {
            commits.push(batch.commit());
            batch = db.batch();
            ops = 0;
        }
    }
    if (ops > 0)
        commits.push(batch.commit());
    await Promise.all(commits);
}
exports.sendEventReminders = (0, scheduler_1.onSchedule)('every 60 minutes', (0, monitoring_1.monitored)('sendEventReminders', async () => {
    var _a, _b;
    const nowMs = admin.firestore.Timestamp.now().toMillis();
    // Cover all three windows: started (up to 1h ago) → 24h ahead.
    const from = admin.firestore.Timestamp.fromMillis(nowMs - HOUR);
    const to = admin.firestore.Timestamp.fromMillis(nowMs + 24 * HOUR);
    const snap = await db
        .collection('events')
        .where('startDate', '>=', from)
        .where('startDate', '<=', to)
        .get();
    for (const doc of snap.docs) {
        const e = doc.data();
        if (e.status !== 'published')
            continue;
        const startMs = (_b = (_a = e.startDate) === null || _a === void 0 ? void 0 : _a.toMillis) === null || _b === void 0 ? void 0 : _b.call(_a);
        if (!startMs)
            continue;
        const title = e.title || 'Event';
        const dt = startMs - nowMs; // ms until start (negative = already started)
        try {
            if (dt <= 0 && dt > -HOUR && e.remindedStart !== true) {
                await fanOutReminder(doc.id, doc.ref, title, 'is starting now — enjoy!', 'remindedStart');
            }
            else if (dt > 0 && dt <= 6 * HOUR && e.reminded6h !== true) {
                await fanOutReminder(doc.id, doc.ref, title, 'starts in about 6 hours', 'reminded6h');
            }
            else if (dt > 6 * HOUR && dt <= 24 * HOUR && e.reminded24h !== true) {
                await fanOutReminder(doc.id, doc.ref, title, 'is tomorrow — see you there!', 'reminded24h');
            }
        }
        catch (err) {
            console.error('sendEventReminders event failed', doc.id, err);
        }
    }
}));
//# sourceMappingURL=reminders.js.map