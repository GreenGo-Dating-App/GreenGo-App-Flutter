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
exports.onEventCityAlert = exports.syncCitySubscribers = void 0;
exports.normalizeCity = normalizeCity;
/**
 * City event alerts.
 *
 * Users subscribe to cities in `notification_preferences.eventCities` (normalized
 * keys). This module:
 *   1. keeps a per-city subscriber index in sync with those subscriptions, and
 *   2. notifies a city's subscribers when an event (`events/{id}`, community or
 *      business) is published there — push + in-app feed doc.
 *
 * Index shape: `event_city_subscribers/{cityKey}/subscribers/{uid}`.
 * External (bulk-ingested) events are handled by a separate digest, NOT here,
 * to avoid a per-event storm.
 */
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
const brand_1 = require("./brand");
const prefs_1 = require("./prefs");
const pushRuntime_1 = require("../shared/pushRuntime");
require("../shared/firebaseAdmin");
const db = admin.firestore();
const _FROM = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
const _TO = 'aaaaaaceeeeiiiinooooouuuuyy';
/** Mirror of the Flutter `CityNormalizer.normalize`. */
function normalizeCity(raw) {
    let s = (raw || '').trim().toLowerCase();
    let out = '';
    for (const ch of s) {
        const i = _FROM.indexOf(ch);
        out += i >= 0 ? _TO[i] : ch;
    }
    out = out.replace(/[^a-z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();
    return out;
}
/** Title-case a normalized key for display. */
function displayCity(key) {
    return key
        .split(' ')
        .map((w) => (w ? w[0].toUpperCase() + w.slice(1) : w))
        .join(' ');
}
// ── 1. Keep the per-city subscriber index in sync ──────────────────────────
exports.syncCitySubscribers = (0, firestore_1.onDocumentWritten)({
    document: 'notification_preferences/{uid}',
    memory: pushRuntime_1.PUSH_MEMORY,
}, (0, monitoring_1.monitored)('syncCitySubscribers', async (event) => {
    var _a, _b, _c, _d;
    const uid = event.params.uid;
    const before = ((_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data()) === null || _b === void 0 ? void 0 : _b.eventCities) || [];
    const after = ((_d = (_c = event.data) === null || _c === void 0 ? void 0 : _c.after.data()) === null || _d === void 0 ? void 0 : _d.eventCities) || [];
    const beforeSet = new Set(before.map(normalizeCity));
    const afterSet = new Set(after.map(normalizeCity));
    const added = [...afterSet].filter((c) => c && !beforeSet.has(c));
    const removed = [...beforeSet].filter((c) => c && !afterSet.has(c));
    if (added.length === 0 && removed.length === 0)
        return;
    const batch = db.batch();
    for (const city of added) {
        batch.set(db
            .collection('event_city_subscribers')
            .doc(city)
            .collection('subscribers')
            .doc(uid), { subscribedAt: admin.firestore.FieldValue.serverTimestamp() });
    }
    for (const city of removed) {
        batch.delete(db
            .collection('event_city_subscribers')
            .doc(city)
            .collection('subscribers')
            .doc(uid));
    }
    await batch.commit();
}));
// ── 2. Notify a city's subscribers about a new event ────────────────────────
const SUB_PAGE = 400;
const FCM_CHUNK = 500;
/**
 * Fan out to everyone subscribed to [cityKey]. Writes an in-app feed doc AND a
 * push for each recipient. Respects the `events` preference and excludes
 * [exclude] (e.g. community members already notified). Paginated + chunked.
 */
async function notifyCity(cityKey, opts) {
    var _a;
    const subsCol = db
        .collection('event_city_subscribers')
        .doc(cityKey)
        .collection('subscribers');
    const title = `New event in ${opts.cityDisplay}`;
    const body = opts.eventTitle;
    const data = { action: 'event', eventId: opts.eventId, city: cityKey };
    let last;
    // eslint-disable-next-line no-constant-condition
    while (true) {
        let q = subsCol
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(SUB_PAGE);
        if (last)
            q = q.startAfter(last);
        const page = await q.get();
        if (page.empty)
            break;
        last = page.docs[page.docs.length - 1];
        let uids = page.docs.map((d) => d.id);
        if (opts.exclude)
            uids = uids.filter((u) => !opts.exclude.has(u));
        if (uids.length === 0)
            continue;
        const allowed = await (0, prefs_1.filterUidsByPref)(uids, 'events');
        const recipients = uids.filter((u) => allowed.has(u));
        if (recipients.length === 0)
            continue;
        // In-app feed docs (batched).
        const batch = db.batch();
        for (const uid of recipients) {
            batch.set(db.collection('notifications').doc(), {
                userId: uid,
                type: 'city_event',
                title,
                message: body,
                body,
                data,
                isRead: false,
                pushSent: true, // we push below; keep the parity trigger off this doc
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        await batch.commit();
        // Push.
        const userDocs = await Promise.all(recipients.map((u) => db.collection('users').doc(u).get()));
        const tokens = [];
        for (const ud of userDocs) {
            const t = (_a = ud.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
            if (t)
                tokens.push(t);
        }
        for (let i = 0; i < tokens.length; i += FCM_CHUNK) {
            const chunk = tokens.slice(i, i + FCM_CHUNK);
            try {
                await admin.messaging().sendEachForMulticast({
                    tokens: chunk,
                    notification: (0, brand_1.brandPush)(title, body, opts.imageUrl),
                    data,
                    android: {
                        priority: 'high',
                        collapseKey: `city_${cityKey}`,
                        notification: {
                            sound: 'default',
                            channelId: 'greengo_notifications',
                            tag: `city_${cityKey}`,
                        },
                    },
                    apns: { payload: { aps: { sound: 'default', badge: 1 } } },
                });
            }
            catch (e) {
                console.error('notifyCity push failed', cityKey, e);
            }
        }
    }
}
/**
 * Fire a city alert when an event is published with a city. Covers community
 * AND business events (both live in `events/{id}`). Guarded by a `cityAlertSent`
 * flag so it sends exactly once (create-as-published or draft→published).
 */
exports.onEventCityAlert = (0, firestore_1.onDocumentWritten)({
    document: 'events/{eventId}',
    memory: pushRuntime_1.PUSH_MEMORY,
}, (0, monitoring_1.monitored)('onEventCityAlert', async (event) => {
    var _a;
    const after = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after.data();
    if (!after)
        return; // deleted
    if (after.status !== 'published')
        return;
    if (after.cityAlertSent === true)
        return;
    const cityRaw = after.city || '';
    if (!cityRaw)
        return;
    // City alerts are for COMMUNITY events only — business/external events do
    // NOT trigger them.
    const communityId = after.communityId || '';
    if (!communityId)
        return;
    const cityKey = normalizeCity(cityRaw);
    if (!cityKey)
        return;
    // Claim the send atomically to avoid double-fire on rapid writes.
    const ref = event.data.after.ref;
    try {
        await db.runTransaction(async (tx) => {
            var _a;
            const fresh = await tx.get(ref);
            if (((_a = fresh.data()) === null || _a === void 0 ? void 0 : _a.cityAlertSent) === true) {
                throw new Error('already-sent');
            }
            tx.update(ref, { cityAlertSent: true });
        });
    }
    catch (e) {
        return; // already sent or lost the race
    }
    // Exclude community members who already got the community fan-out.
    // Paginated + capped (20×500) so a huge community never loads all members
    // into memory; beyond the cap a rare overlap is acceptable.
    const exclude = new Set();
    try {
        const membersCol = db
            .collection('communities')
            .doc(communityId)
            .collection('members');
        let last;
        for (let pages = 0; pages < 20; pages++) {
            let q = membersCol
                .orderBy(admin.firestore.FieldPath.documentId())
                .limit(500);
            if (last)
                q = q.startAfter(last);
            const page = await q.get();
            if (page.empty)
                break;
            page.docs.forEach((d) => exclude.add(d.id));
            last = page.docs[page.docs.length - 1];
            if (page.size < 500)
                break;
        }
    }
    catch (_b) {
        // best-effort; overlap is acceptable if this fails
    }
    await notifyCity(cityKey, {
        eventId: event.params.eventId,
        eventTitle: after.title || 'New event',
        cityDisplay: displayCity(cityKey),
        imageUrl: after.imageUrl || after.coverImage,
        exclude,
    });
}));
//# sourceMappingURL=cityAlerts.js.map