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
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { lt, rawText } from '../shared/i18n';
import { monitored } from '../shared/monitoring';
import { resolveActor, emitNotification } from '../notifications/notifyHelpers';
import '../shared/firebaseAdmin';

/** Same cap as the client (Event.maxCoOrganizers) and the rules. */
const MAX_CO_OWNERS = 5;

function idsOf(data: FirebaseFirestore.DocumentData | undefined): string[] {
  const raw = data?.coOrganizerIds;
  if (!Array.isArray(raw)) return [];
  return raw.filter((v): v is string => typeof v === 'string' && v.length > 0);
}

export const onEventCoOwnersChanged = onDocumentWritten(
  { document: 'events/{eventId}', memory: '512MiB' },
  monitored('onEventCoOwnersChanged', async (event) => {
    const after = event.data?.after?.data();
    if (!after) return; // deleted
    const before = event.data?.before?.data();

    const previous = new Set(idsOf(before));
    const organizerId = (after.organizerId as string) || '';
    const added = idsOf(after)
      .filter((uid) => !previous.has(uid) && uid !== organizerId)
      .slice(0, MAX_CO_OWNERS);
    if (added.length === 0) return;

    const eventId = event.params.eventId;
    const name = ((after.title as string) || '').trim();
    const actor = organizerId ? await resolveActor(organizerId) : undefined;

    await Promise.all(
      added.map((uid) =>
        emitNotification({
          recipientId: uid,
          type: 'event_co_owner_added',
          title: name
            ? lt('notifServerAddedYouAsCoOwner', { name })
            : lt('srvAddedYouAsCoOwnerOfEvent'),
          body: name ? rawText(name) : lt('srvAnEvent'),
          data: {
            type: 'event_co_owner_added',
            eventId,
            action: 'open_event',
            ...(organizerId ? { actorId: organizerId } : {}),
          },
          actor,
        }).catch((e) =>
          console.error(`co-owner notify failed ${eventId} -> ${uid}`, e),
        ),
      ),
    );
  }),
);
