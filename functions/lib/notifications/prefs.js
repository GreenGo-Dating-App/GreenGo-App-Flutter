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
exports.categoryForType = categoryForType;
exports.shouldNotify = shouldNotify;
exports.filterUidsByPref = filterUidsByPref;
/**
 * Notification preference gate.
 *
 * Reads `notification_preferences/{uid}` and decides whether a push of a given
 * category should be delivered. Honors the master toggle + per-category flags +
 * quiet hours (evaluated in the user's local time via a stored UTC offset).
 *
 * Fail-OPEN: on a missing doc or read error we return `true` so a transient
 * problem never silently drops notifications. Categories default to enabled.
 */
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const db = admin.firestore();
/**
 * Per-category default (used when the user has NO prefs doc, or the specific
 * category key is absent). Only exchanges, groups, community announcements and
 * event chats are ON by default; business chat, community chat and tips are OFF
 * until the user opts in. Legacy buckets default ON (fail-open).
 */
const CATEGORY_DEFAULTS = {
    exchanges: true,
    groups: true,
    business: false,
    eventsChat: true,
    communityChat: false,
    announcements: true,
    tips: false,
    // legacy
    messages: true,
    events: true,
    communities: true,
    social: true,
    account: true,
};
function defaultFor(category) {
    var _a;
    return (_a = CATEGORY_DEFAULTS[category]) !== null && _a !== void 0 ? _a : true;
}
/** Map a notification `type`/`action` string to its preference category. */
function categoryForType(type) {
    const t = (type || '').toLowerCase();
    if (t.includes('group'))
        return 'groups';
    if (t.includes('business') || t.includes('biz'))
        return 'business';
    if (t.includes('announce'))
        return 'announcements';
    if (t.includes('tip'))
        return 'tips';
    if (t.includes('event') && (t.includes('message') || t.includes('chat'))) {
        return 'eventsChat';
    }
    if (t.includes('communit') && (t.includes('message') || t.includes('chat'))) {
        return 'communityChat';
    }
    if (t.includes('message') || t.includes('chat') || t.includes('support')) {
        return 'exchanges';
    }
    if (t.includes('event') ||
        t.includes('rsvp') ||
        t.includes('attend') ||
        t.includes('reminder') ||
        t.includes('member') ||
        t.includes('communit')) {
        return 'announcements';
    }
    if (t.includes('approv') ||
        t.includes('verif') ||
        t.includes('account') ||
        t.includes('admin') ||
        t.includes('broadcast')) {
        return 'account';
    }
    return 'social';
}
function inQuietHours(start, end, tzOffsetMinutes) {
    if (!start || !end)
        return false;
    const [sh] = start.split(':').map(Number);
    const [eh] = end.split(':').map(Number);
    if (Number.isNaN(sh) || Number.isNaN(eh))
        return false;
    // Local hour = UTC hour + offset.
    const utcHour = new Date(Date.now()).getUTCHours();
    const localHour = (((utcHour + Math.round(tzOffsetMinutes / 60)) % 24) + 24) % 24;
    // Overnight window (e.g. 22 → 08) vs same-day window.
    return sh > eh ? localHour >= sh || localHour < eh : localHour >= sh && localHour < eh;
}
/** Whether to send `uid` a push of `category`. Never throws. */
async function shouldNotify(uid, category) {
    if (!uid)
        return false;
    try {
        const snap = await db.collection('notification_preferences').doc(uid).get();
        if (!snap.exists)
            return defaultFor(category);
        const d = snap.data() || {};
        if (d.pushEnabled === false)
            return false;
        const cats = (d.categories || {});
        const raw = cats[category];
        // Absent key → per-category default; explicit false → blocked.
        const catAllowed = raw === undefined ? defaultFor(category) : raw !== false;
        if (!catAllowed)
            return false;
        if (d.quietHoursEnabled === true &&
            inQuietHours(d.quietHoursStart, d.quietHoursEnd, Number(d.tzOffsetMinutes) || 0)) {
            return false;
        }
        return true;
    }
    catch (_a) {
        return true;
    }
}
/**
 * Filter a list of recipient uids to those who accept `category`, for multicast
 * fan-outs. Batched pref reads (chunks of 300 via `getAll`). Fail-open per uid.
 */
async function filterUidsByPref(uids, category) {
    const allowed = new Set();
    if (uids.length === 0)
        return allowed;
    const CHUNK = 300;
    for (let i = 0; i < uids.length; i += CHUNK) {
        const slice = uids.slice(i, i + CHUNK);
        try {
            const refs = slice.map((u) => db.collection('notification_preferences').doc(u));
            const snaps = await db.getAll(...refs);
            snaps.forEach((snap, idx) => {
                const uid = slice[idx];
                if (!snap.exists) {
                    if (defaultFor(category))
                        allowed.add(uid);
                    return;
                }
                const d = snap.data() || {};
                if (d.pushEnabled === false)
                    return;
                const cats = (d.categories || {});
                const raw = cats[category];
                const catAllowed = raw === undefined ? defaultFor(category) : raw !== false;
                if (!catAllowed)
                    return;
                if (d.quietHoursEnabled === true &&
                    inQuietHours(d.quietHoursStart, d.quietHoursEnd, Number(d.tzOffsetMinutes) || 0)) {
                    return;
                }
                allowed.add(uid);
            });
        }
        catch (_a) {
            // Fail-open: allow this chunk on error.
            slice.forEach((u) => allowed.add(u));
        }
    }
    return allowed;
}
//# sourceMappingURL=prefs.js.map