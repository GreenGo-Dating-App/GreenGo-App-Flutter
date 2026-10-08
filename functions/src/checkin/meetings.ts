/**
 * "Met in person" — proof that two members were physically together.
 *
 * Written ONLY by the server, and only from a successful QR check-in:
 *   - experience booking check-in  → host ↔ guest
 *   - event ticket check-in        → organizer ↔ attendee (and the scanning
 *                                     co-organizer ↔ attendee)
 *
 * Shape (no client writes; members read their own pairs):
 *   met_in_person/{pairId}                    pairId = sorted "uidA_uidB"
 *     { users: [uidA, uidB], count, verifiedCount, firstMetAt, lastMetAt,
 *       lastContext: { type, contextId, title } }
 *   met_in_person/{pairId}/encounters/{type}_{contextId}
 *     { type: 'event' | 'experience', contextId, title, verified, at, byUid }
 *
 * Idempotent per (pair, context): scanning the same ticket twice, or a retried
 * callable, never counts a second meeting. `verified` is false only for the
 * legacy unsigned event tickets accepted during the transition — the meeting
 * is still recorded, but it does not count towards `verifiedCount`.
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';

export const MET_IN_PERSON = 'met_in_person';
export const ENCOUNTERS = 'encounters';

export type MeetingType = 'event' | 'experience';

export interface MeetingContext {
  type: MeetingType;
  contextId: string;
  title?: string;
  verified: boolean;
  byUid: string;
}

export function pairIdOf(a: string, b: string): string {
  return [a, b].sort().join('_');
}

export function encounterIdOf(type: MeetingType, contextId: string): string {
  return `${type}_${contextId}`;
}

/**
 * Records that [a] and [b] met. Returns true when this is a NEW encounter,
 * false when it was already recorded (or a and b are the same person).
 * Never throws: a failure here must not undo a check-in that succeeded.
 */
export async function recordMeeting(
  a: string,
  b: string,
  ctx: MeetingContext,
  db: FirebaseFirestore.Firestore = admin.firestore(),
): Promise<boolean> {
  if (!a || !b || a === b) return false;
  const pairId = pairIdOf(a, b);
  const pairRef = db.collection(MET_IN_PERSON).doc(pairId);
  const encRef = pairRef.collection(ENCOUNTERS).doc(encounterIdOf(ctx.type, ctx.contextId));
  try {
    return await db.runTransaction(async (tx) => {
      const [enc, pair] = await Promise.all([tx.get(encRef), tx.get(pairRef)]);
      if (enc.exists) return false;
      const now = admin.firestore.Timestamp.now();
      const title = (ctx.title ?? '').slice(0, 140);
      tx.create(encRef, {
        type: ctx.type,
        contextId: ctx.contextId,
        title,
        verified: ctx.verified,
        byUid: ctx.byUid,
        at: now,
      });
      const inc = admin.firestore.FieldValue.increment;
      tx.set(
        pairRef,
        {
          users: [a, b].sort(),
          count: inc(1),
          verifiedCount: inc(ctx.verified ? 1 : 0),
          lastMetAt: now,
          ...(pair.exists ? {} : { firstMetAt: now }),
          lastContext: { type: ctx.type, contextId: ctx.contextId, title },
        },
        { merge: true },
      );
      return true;
    });
  } catch (e) {
    console.error(`[met_in_person] record ${pairId} ${ctx.type}:${ctx.contextId} failed:`, e);
    return false;
  }
}
