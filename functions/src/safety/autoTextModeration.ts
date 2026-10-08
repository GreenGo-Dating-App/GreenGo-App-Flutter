/**
 * P2-8b: server-side text screening of messages in SHARED chats (community,
 * group and event chats). 1:1 conversations are not screened.
 *
 * FLAG-FOR-REVIEW ONLY. A hit creates one moderation_queue item (source
 * 'auto_text', reportPipeline.enqueueAutoTextFlag); nothing is hidden, nobody
 * is warned, suspended or banned automatically. A moderator decides through
 * the normal queue (takeModerationAction), which then sends the affected
 * user the statement of reasons (DSA art. 17) with an appeal option.
 *
 * COST: no paid API. The screen is a local keyword/regex pass (the existing
 * `moderateText` callable calls Cloud Natural Language per message, which is
 * not affordable on every chat message). Bounded work per message: only the
 * first MAX_SCREEN_CHARS characters are read, only text-bearing messages are
 * screened, and one sender can create at most MAX_FLAGS_PER_SENDER_PER_DAY
 * non-P0 queue items per UTC day (child-safety hits are never capped).
 */
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { monitored } from '../shared/monitoring';
import { CSAE_PATTERN, ReasonCode, enqueueAutoTextFlag, normalizeReasonText, priorityFor } from './reportPipeline';

const db = admin.firestore();
const OPTS = { memory: '512MiB' as const, timeoutSeconds: 30 };

export const MAX_SCREEN_CHARS = 4000;
export const MAX_FLAGS_PER_SENDER_PER_DAY = 20;

/**
 * Ordered by severity; the first matching rule wins. Patterns run on
 * accent-stripped lowercase text and are deliberately narrow (multi-word
 * phrases) to keep false positives - and moderator load - low.
 */
const RULES: [ReasonCode, RegExp][] = [
  ['csae', CSAE_PATTERN],
  ['threats', /\b(i(?: will|'ll| am going to| gonna) (?:kill|hurt|stab|shoot|rape) (?:you|u)\b|kill yourself|kys\b|ti ammazzo|ti uccido|te voy a matar|te mato|je vais te tuer|ich bring(?:e)? dich um|vou te matar|eu te mato)/],
  ['sexual_content', /\b(send (?:me )?(?:your )?nudes|nudes? for (?:money|coins)|selling (?:my )?nudes|onlyfans\.com\/)/],
  ['scam', /\b(western union|moneygram|gift ?cards? (?:code|number)|send (?:me )?(?:the )?(?:money|bitcoin|btc|usdt|crypto)|investment opportunity|guaranteed (?:profit|return)s?|double your (?:money|bitcoin|crypto))\b/],
  ['off_platform_payment', /\b(pay (?:me )?(?:via|by|with|on) (?:paypal|revolut|venmo|cash ?app|zelle|pix|bank transfer|wire transfer)|my (?:paypal|iban|pix key|revolut) is)\b/],
];

/** Pure: the reason code + matched snippets, or null when the text is clean. */
export function screenText(raw: unknown): { reasonCode: ReasonCode; matched: string[] } | null {
  if (typeof raw !== 'string' || !raw.trim()) return null;
  const text = normalizeReasonText(raw.slice(0, MAX_SCREEN_CHARS));
  for (const [code, re] of RULES) {
    const m = text.match(re);
    if (m) return { reasonCode: code, matched: [m[0].slice(0, 80)] };
  }
  return null;
}

/** Text of a chat message, whichever field this chat type uses. */
export function messageText(msg: Record<string, unknown>): string | null {
  const type = typeof msg.type === 'string' ? msg.type : 'text';
  if (['image', 'video', 'voice', 'audio', 'system', 'sticker', 'gif', 'location'].includes(type)) {
    // Media messages may still carry a caption.
    const cap = msg.caption;
    return typeof cap === 'string' && cap ? cap : null;
  }
  for (const k of ['text', 'content', 'message']) {
    const v = msg[k];
    if (typeof v === 'string' && v) return v;
  }
  return null;
}

/** Per-sender daily cap on non-P0 flags (transactional counter). */
async function underDailyCap(senderId: string, nowMs: number): Promise<boolean> {
  const day = new Date(nowMs).toISOString().slice(0, 10).replace(/-/g, '');
  const ref = db.collection('auto_text_quota').doc(`${senderId}_${day}`);
  return db.runTransaction(async (tx) => {
    const cur = Number((await tx.get(ref)).data()?.count ?? 0);
    if (cur >= MAX_FLAGS_PER_SENDER_PER_DAY) return false;
    tx.set(ref, {
      count: cur + 1,
      senderId,
      // TTL field (configure a TTL policy on auto_text_quota.expireAt).
      expireAt: admin.firestore.Timestamp.fromMillis(nowMs + 2 * 86_400_000),
    }, { merge: true });
    return true;
  });
}

/** Screens one created message; exported for tests. Returns the queue id or null. */
export async function screenChatMessage(
  chatType: 'community' | 'group' | 'event',
  chatId: string,
  messageId: string,
  path: string,
  msg: Record<string, unknown> | undefined,
  nowMs: number = Date.now(),
): Promise<boolean> {
  if (!msg) return false;
  const senderId = typeof msg.senderId === 'string' ? msg.senderId : '';
  if (!senderId || senderId === 'system') return false;
  const text = messageText(msg);
  if (!text) return false;
  const hit = screenText(text);
  if (!hit) return false;
  if (priorityFor(hit.reasonCode) !== 'P0' && !(await underDailyCap(senderId, nowMs))) {
    console.warn(`[autoText] daily flag cap reached for ${senderId}; ${path} not queued`);
    return false;
  }
  return enqueueAutoTextFlag({
    path, chatType, chatId, messageId, senderId, text: text.slice(0, MAX_SCREEN_CHARS),
    reasonCode: hit.reasonCode, matched: hit.matched,
  }, nowMs);
}

export const screenCommunityMessage = onDocumentCreated(
  { document: 'communities/{communityId}/messages/{messageId}', ...OPTS },
  monitored('screenCommunityMessage', async (event) => {
    const { communityId, messageId } = event.params as Record<string, string>;
    await screenChatMessage('community', communityId, messageId,
      `communities/${communityId}/messages/${messageId}`, event.data?.data());
  }),
);

export const screenGroupMessage = onDocumentCreated(
  { document: 'groups/{groupId}/messages/{messageId}', ...OPTS },
  monitored('screenGroupMessage', async (event) => {
    const { groupId, messageId } = event.params as Record<string, string>;
    await screenChatMessage('group', groupId, messageId,
      `groups/${groupId}/messages/${messageId}`, event.data?.data());
  }),
);

export const screenEventMessage = onDocumentCreated(
  { document: 'events/{eventId}/messages/{messageId}', ...OPTS },
  monitored('screenEventMessage', async (event) => {
    const { eventId, messageId } = event.params as Record<string, string>;
    await screenChatMessage('event', eventId, messageId,
      `events/${eventId}/messages/${messageId}`, event.data?.data());
  }),
);
