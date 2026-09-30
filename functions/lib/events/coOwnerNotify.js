"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onEventCoOwnersChanged = void 0;
/**
 * onEventCoOwnersChanged — when an event's `coOrganizerIds` gains someone,
 * tell each NEWLY added co-owner: "<creator> added you as a co-owner of
 * <event>". In-app notification + push via emitNotification (respects the
 * recipient's notification preferences; tapping opens the event through the
 * `eventId` in the data payload).
 *
 * Only the creator can change the co-owner list (firestore.rules), so the
 * creator is the actor. Removals are silent. Re-saving an event with the same
 * list notifies nobody, so the trigger is idempotent per addition.
 */
const firestore_1 = require("firebase-functions/v2/firestore");
const monitoring_1 = require("../shared/monitoring");
const notifyHelpers_1 = require("../notifications/notifyHelpers");
require("../shared/firebaseAdmin");
/** Same cap as the client (Event.maxCoOrganizers) and the rules. */
const MAX_CO_OWNERS = 5;
function idsOf(data) {
    const raw = data === null || data === void 0 ? void 0 : data.coOrganizerIds;
    if (!Array.isArray(raw))
        return [];
    return raw.filter((v) => typeof v === 'string' && v.length > 0);
}
exports.onEventCoOwnersChanged = (0, firestore_1.onDocumentWritten)({ document: 'events/{eventId}', memory: '512MiB' }, (0, monitoring_1.monitored)('onEventCoOwnersChanged', async (event) => {
    var _a, _b, _c, _d;
    const after = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after) === null || _b === void 0 ? void 0 : _b.data();
    if (!after)
        return; // deleted
    const before = (_d = (_c = event.data) === null || _c === void 0 ? void 0 : _c.before) === null || _d === void 0 ? void 0 : _d.data();
    const previous = new Set(idsOf(before));
    const organizerId = after.organizerId || '';
    const added = idsOf(after)
        .filter((uid) => !previous.has(uid) && uid !== organizerId)
        .slice(0, MAX_CO_OWNERS);
    if (added.length === 0)
        return;
    const eventId = event.params.eventId;
    const title = (after.title || '').trim() || 'an event';
    const actor = organizerId ? await (0, notifyHelpers_1.resolveActor)(organizerId) : undefined;
    await Promise.all(added.map((uid) => (0, notifyHelpers_1.emitNotification)({
        recipientId: uid,
        type: 'event_co_owner_added',
        title: `added you as a co-owner of ${title}`,
        body: title,
        data: Object.assign({ type: 'event_co_owner_added', eventId, action: 'open_event' }, (organizerId ? { actorId: organizerId } : {})),
        actor,
    }).catch((e) => console.error(`co-owner notify failed ${eventId} -> ${uid}`, e))));
}));
//# sourceMappingURL=coOwnerNotify.js.map