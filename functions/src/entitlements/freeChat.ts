/**
 * Free chats: an account without Base may chat with FREE_DAILY_CHATS people
 * per UTC day (owner rule 2026-10-13, "give a taste of the app").
 *
 * The app calls `claimFreeChat({ conversationId })` before the first message
 * it sends in a 1:1 conversation that day. The conversation id is added to
 * `entitlement_usage/{uid}.freeChatConvs` (reset every UTC day); the Firestore
 * rules (`freeChatOk`) let a member without Base post in a conversation only
 * when its id is in today's list. Re-claiming a conversation already in the
 * list is free, so replying all day to the same 3 people costs nothing.
 *
 * Scale: one callable per free user per new partner per day (at most 3 that
 * succeed), one transaction on the user's own usage doc. No per-message
 * trigger. Joining events / booking experiences is NOT unlocked here.
 */
import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { monitored } from '../shared/monitoring';
import { hasBaseAccess } from '../shared/effectiveTier';
import { FREE_DAILY_CHATS, USAGE_COLLECTION, utcDayStartMs } from '../shared/tierLimits';
import { isSupportConversation } from './usage';

const db = admin.firestore();

export interface FreeChatDecision {
  allowed: boolean;
  /** Today's list after the claim (unchanged when refused). */
  convs: string[];
  /** True when the conversation was added by this claim. */
  added: boolean;
}

/** Today's free-chat conversation ids stored in `usage` ([] from an earlier day). */
export function freeChatsToday(usage: Record<string, any> | undefined, nowMs: number): string[] {
  if (!usage || usage.freeChatDayStartMs !== utcDayStartMs(nowMs)) return [];
  const list = usage.freeChatConvs;
  return Array.isArray(list) ? list.filter((x: unknown) => typeof x === 'string') : [];
}

/** Pure decision: may `conversationId` be (or stay) one of today's free chats? */
export function decideFreeChat(
  usage: Record<string, any> | undefined,
  conversationId: string,
  nowMs: number,
  limit: number = FREE_DAILY_CHATS,
): FreeChatDecision {
  const convs = freeChatsToday(usage, nowMs);
  if (convs.includes(conversationId)) return { allowed: true, convs, added: false };
  if (convs.length >= limit) return { allowed: false, convs, added: false };
  return { allowed: true, convs: [...convs, conversationId], added: true };
}

/** A plain two-person conversation the caller belongs to. */
export function isOneToOneMember(c: Record<string, any> | undefined, uid: string): boolean {
  if (!c || isSupportConversation(c)) return false;
  const a = c.userId1, b = c.userId2;
  if (typeof a !== 'string' || typeof b !== 'string' || !a || !b || a === b) return false;
  const participants = c.participants;
  if (Array.isArray(participants) && participants.length > 2) return false;
  return uid === a || uid === b;
}

export const claimFreeChat = onCall(
  { memory: '512MiB', timeoutSeconds: 30 },
  monitored('claimFreeChat', async (request: any) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
    const conversationId = request.data?.conversationId;
    if (typeof conversationId !== 'string' || !conversationId || conversationId.includes('/')
        || conversationId.length > 200) {
      throw new HttpsError('invalid-argument', 'conversationId is required.');
    }

    const [profileSnap, convSnap] = await Promise.all([
      db.collection('profiles').doc(uid).get(),
      db.collection('conversations').doc(conversationId).get(),
    ]);
    if (hasBaseAccess(profileSnap.data())) {
      return { allowed: true, unlimited: true, limit: FREE_DAILY_CHATS, used: 0 };
    }
    if (!convSnap.exists || !isOneToOneMember(convSnap.data(), uid)) {
      throw new HttpsError('failed-precondition', 'base_membership_required',
        { code: 'base_membership_required' });
    }

    const usageRef = db.collection(USAGE_COLLECTION).doc(uid);
    const decision = await db.runTransaction(async (tx) => {
      const u = await tx.get(usageRef);
      const nowMs = Date.now();
      const d = decideFreeChat(u.data(), conversationId, nowMs);
      if (d.added) {
        tx.set(usageRef, {
          freeChatDayStartMs: utcDayStartMs(nowMs),
          freeChatConvs: d.convs,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }
      return d;
    });
    return {
      allowed: decision.allowed,
      unlimited: false,
      limit: FREE_DAILY_CHATS,
      used: decision.convs.length,
      added: decision.added,
    };
  }),
);
