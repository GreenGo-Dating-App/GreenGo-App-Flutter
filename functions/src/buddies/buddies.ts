/**
 * GreenGo Buddies: callables, background memory/summary jobs and proactive
 * check-ins. All Cloud Functions (no VM). Model calls go through the AI
 * router capability `text_buddies` (default Qwen Flash, admin-configurable).
 *
 *  createBuddy / updateBuddy / deleteBuddy      settings (validated, per-plan limit)
 *  sendBuddyMessage                             one reply: crisis check -> charge
 *                                               (free allowance, then 1 coin) ->
 *                                               model -> rules -> store; refund on failure
 *  clearBuddyChat / forgetBuddyMemory           user control over history + memory
 *  getBuddyStatus                               plan limits + free replies left today
 *  onBuddyJob (Firestore trigger)               long-term memory + rolling summary
 *  buddyCheckIns (hourly)                       the Buddy writes first after inactivity
 *
 * Privacy: only the Buddy settings and the conversation text go to the model
 * provider: never the uid, name, e-mail or profile.
 */
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import '../shared/firebaseAdmin';
import { AppError, handleError } from '../shared/utils';
import { monitored } from '../shared/monitoring';
import { aiConsentVersion, requireAiConsent } from '../shared/aiConsent';
import { effectiveTier, EffectiveTier } from '../shared/effectiveTier';
import { fifoDraw, refusal, REASON, validRequestId, DrawnSlice } from '../coins/ledger';
import { loadConfig } from '../ai/router/config';
import { eligibleChain, generate, translate } from '../ai/router/router';
import { applyReplyRules, fitContext, graphemeLength, graphemes } from '../ai/router/rules';
import { CapabilityRules } from '../ai/router/types';
import { emitNotification } from '../notifications/notifyHelpers';
import { rawText } from '../shared/i18n';
import {
  AVATARS, BUDDY_AVATARS, BUDDIES, BUDDY_LIMIT, BUDDY_REQUESTS, BUDDY_USAGE, BuddyInputError, BuddySettings, COINS_PER_REPLY, REPLIES_PER_COIN,
  FREE_REPLIES_PER_DAY, Language, MemoryFact, USER_MESSAGE_MAX, utcDay, validateSettings,
} from './model';
import { CRISIS_REPLY, FALLBACK_REPLY, isCrisis, isUnsafeReply } from './crisis';
import { checkInPrompt, memoryPrompt, parseJsonObject, replyFormatBlock, summaryPrompt, systemPrompt } from './prompt';

const db = () => admin.firestore();
const TS = () => admin.firestore.Timestamp.now();
const runtime = { memory: '512MiB' as const, timeoutSeconds: 60 };
export const BUDDY_JOBS = 'ai_buddy_jobs';
/** Time between the bubbles of one Buddy turn. */
export const BUBBLE_GAP_MS = 1000;
/** Owner 2026-10-24: 1 bubble per turn, 2 only for a really long answer. */
export const MAX_BUBBLES = 2;
/** Messages per user per 10 minutes (all Buddies). */
export const RATE_LIMIT_10MIN = 30;

const toHttps = (e: unknown) => (e instanceof HttpsError ? e : e instanceof BuddyInputError
  ? new HttpsError('invalid-argument', e.message) : handleError(e));

function callable(name: string, fn: (uid: string, data: any) => Promise<unknown>) {
  return onCall(runtime, monitored(name, async (request: any) => {
    try {
      const uid = request?.auth?.uid;
      if (!uid) throw new HttpsError('unauthenticated', 'Sign in first');
      return await fn(uid as string, request.data ?? {});
    } catch (e) {
      throw toHttps(e);
    }
  }));
}

const ID = /^[A-Za-z0-9_-]{1,64}$/;
const okId = (v: unknown, field = 'buddyId'): string => {
  if (typeof v !== 'string' || !ID.test(v)) throw new HttpsError('invalid-argument', `Invalid ${field}`);
  return v;
};

const buddiesCol = (uid: string) => db().collection(BUDDIES).doc(uid).collection('buddies');
const unavailable = () => new AppError('AI_UNAVAILABLE', 'Your Buddy cannot answer right now. Please try again.', 503,
  { reason: 'AI_UNAVAILABLE' });

/** The avatar must be an active image in buddy_avatars (or a legacy drawn one). */
async function assertAvatar(avatar: string | undefined): Promise<void> {
  if (avatar === undefined || AVATARS.includes(avatar)) return;
  const snap = await db().collection(BUDDY_AVATARS).doc(avatar).get();
  if (!snap.exists || snap.data()?.active === false) throw new HttpsError('invalid-argument', 'Invalid avatar');
}

async function tierOf(uid: string): Promise<EffectiveTier> {
  const p = (await db().collection('profiles').doc(uid).get()).data();
  return effectiveTier(p);
}

/** The oldest [limit] Buddies stay usable after a downgrade; newer ones are locked. */
async function activeBuddyIds(uid: string, tier: EffectiveTier): Promise<Set<string>> {
  const snap = await buddiesCol(uid).orderBy('createdAt', 'asc').limit(BUDDY_LIMIT[tier]).select().get();
  return new Set(snap.docs.map((d) => d.id));
}

const settingsOf = (d: any): BuddySettings => ({
  name: d.name, avatar: d.avatar, topic: d.topic, role: d.role, tone: d.tone, language: d.language,
  level: d.level, cefr: d.cefr ?? null, checkInsEnabled: d.checkInsEnabled !== false,
  chatLanguage: d.chatLanguage ?? d.language,
});

async function rules(): Promise<CapabilityRules> {
  return (await loadConfig()).rules.text_buddies ?? {};
}

/**
 * Throws a clear error when no `text_buddies` provider can serve this user:
 * AI_CONSENT_UPDATE_REQUIRED when the provider needs a newer AI notice (the
 * app then shows the consent sheet again), AI_UNAVAILABLE otherwise.
 */
async function requireBuddyProvider(consentVersion: number): Promise<void> {
  const config = await loadConfig();
  if (eligibleChain(config, 'text_buddies', { consentVersion }).length) return;
  const needs = config.routes.text_buddies.chain
    .map((id) => config.providers[id]?.minConsentVersion ?? 0)
    .filter((v) => v > consentVersion);
  if (needs.length) {
    throw new AppError('AI_CONSENT_UPDATE_REQUIRED', 'Please review the updated AI notice to chat with your Buddy.', 403,
      { reason: 'AI_CONSENT_UPDATE_REQUIRED', requiredVersion: Math.min(...needs) });
  }
  throw unavailable();
}

// ------------------------------------------------------------------ status

export async function buddyStatus(uid: string) {
  const tier = await tierOf(uid);
  const [usage, count, root] = await Promise.all([
    db().collection(BUDDY_USAGE).doc(`${uid}_${utcDay()}`).get(),
    buddiesCol(uid).count().get(),
    db().collection(BUDDIES).doc(uid).get(),
  ]);
  const freeLimit = FREE_REPLIES_PER_DAY[tier];
  const used = Number(usage.data()?.freeUsed) || 0;
  return {
    tier,
    buddyLimit: BUDDY_LIMIT[tier],
    buddyCount: count.data().count,
    freeRepliesPerDay: freeLimit,
    freeRepliesLeft: Math.max(0, freeLimit - used),
    coinsPerReply: COINS_PER_REPLY,
    repliesPerCoin: REPLIES_PER_COIN,
    replyCredits: Math.max(0, Math.floor(Number(root.data()?.replyCredits) || 0)),
  };
}

export const getBuddyStatus = callable('getBuddyStatus', (uid) => buddyStatus(uid));

// ------------------------------------------------------------- create / edit

export const createBuddy = callable('createBuddy', async (uid, data) => {
  const s = validateSettings(data.settings ?? data, false) as BuddySettings;
  await assertAvatar(s.avatar);
  const tier = await tierOf(uid);
  const limit = BUDDY_LIMIT[tier];
  const ref = buddiesCol(uid).doc();
  await db().runTransaction(async (tx) => {
    // Count inside the transaction (aggregate queries are not transactional, so
    // the root doc counter is the serialization point).
    const rootRef = db().collection(BUDDIES).doc(uid);
    const root = await tx.get(rootRef);
    const n = Number(root.data()?.buddyCount) || 0;
    if (n >= limit) {
      throw refusal('failed-precondition', REASON.tierRequired,
        `Your plan allows ${limit} Buddy${limit === 1 ? '' : 'ies'}. Upgrade to create more.`, { limit, tier });
    }
    tx.set(rootRef, { uid, buddyCount: n + 1, updatedAt: TS() }, { merge: true });
    tx.set(ref, {
      ...s,
      createdAt: TS(),
      updatedAt: TS(),
      lastMessage: null,
      lastMessageAt: null,
      lastUserMessageAt: null,
      messageCount: 0,
      userMessageCount: 0,
      unansweredCheckIns: 0,
      nextCheckInAt: null,
      memory: [],
      summary: '',
      summaryCoveredUntil: null,
    });
  });
  return { buddyId: ref.id };
});

export const updateBuddy = callable('updateBuddy', async (uid, data) => {
  const buddyId = okId(data.buddyId);
  // Owner 2026-10-24: the Buddy's language is fixed at creation.
  if (data.settings && ['language', 'chatLanguage'].some((k) => Object.prototype.hasOwnProperty.call(data.settings, k))) {
    throw new AppError('LANGUAGE_FIXED', "A Buddy's language cannot be changed after it is created.", 400, { reason: 'LANGUAGE_FIXED' });
  }
  const patch = validateSettings(data.settings ?? {}, true);
  if (!Object.keys(patch).length) throw new HttpsError('invalid-argument', 'Nothing to update');
  await assertAvatar(patch.avatar);
  const ref = buddiesCol(uid).doc(buddyId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Buddy not found');
  const extra: Record<string, unknown> = {};
  if (patch.checkInsEnabled === false) extra.nextCheckInAt = null;
  await ref.update({ ...patch, ...extra, updatedAt: TS() });
  return { ok: true };
});

async function deleteMessages(ref: admin.firestore.DocumentReference) {
  await db().recursiveDelete(ref.collection('messages'));
}

export const deleteBuddy = callable('deleteBuddy', async (uid, data) => {
  const buddyId = okId(data.buddyId);
  const ref = buddiesCol(uid).doc(buddyId);
  if (!(await ref.get()).exists) throw new HttpsError('not-found', 'Buddy not found');
  await deleteMessages(ref);
  await db().runTransaction(async (tx) => {
    const rootRef = db().collection(BUDDIES).doc(uid);
    const root = await tx.get(rootRef);
    tx.delete(ref);
    tx.set(rootRef, { buddyCount: Math.max(0, (Number(root.data()?.buddyCount) || 1) - 1), updatedAt: TS() }, { merge: true });
  });
  await db().collection(BUDDY_JOBS).doc(`${uid}_${buddyId}`).delete().catch(() => undefined);
  return { ok: true };
});

export const clearBuddyChat = callable('clearBuddyChat', async (uid, data) => {
  const buddyId = okId(data.buddyId);
  const ref = buddiesCol(uid).doc(buddyId);
  if (!(await ref.get()).exists) throw new HttpsError('not-found', 'Buddy not found');
  await deleteMessages(ref);
  const forget = data.forgetMemory === true;
  await ref.update({
    lastMessage: null, lastMessageAt: null, messageCount: 0, userMessageCount: 0, summary: '', summaryCoveredUntil: null,
    unansweredCheckIns: 0, nextCheckInAt: null, ...(forget ? { memory: [] } : {}), updatedAt: TS(),
  });
  return { ok: true };
});

/** Deletes one memory fact ([factId]) or all of them (no factId). */
export const forgetBuddyMemory = callable('forgetBuddyMemory', async (uid, data) => {
  const buddyId = okId(data.buddyId);
  const ref = buddiesCol(uid).doc(buddyId);
  await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'Buddy not found');
    const memory: MemoryFact[] = Array.isArray(snap.data()?.memory) ? snap.data()!.memory : [];
    const next = data.factId === undefined ? [] : memory.filter((f) => f.id !== okId(data.factId, 'factId'));
    tx.update(ref, { memory: next, updatedAt: TS() });
  });
  return { ok: true };
});

// ------------------------------------------------------------------ messages

interface ChargePlan {
  /** free = daily allowance; credit = a prepaid reply; coin = 1 coin debited for REPLIES_PER_COIN replies. */
  kind: 'free' | 'credit' | 'coin';
  drawn: DrawnSlice[];
  transactionId: string | null;
  freeLeft: number;
  balance: number | null;
  /** Prepaid replies left after this one. */
  credits: number;
}

/**
 * Rate limit + free allowance, else a prepaid reply credit, else a 1-coin
 * debit that buys REPLIES_PER_COIN replies (owner 2026-10-24: 0.2 coins per
 * reply; coin balances stay whole numbers) + idempotency claim, in ONE
 * transaction. Credits live on ai_buddies/{uid}.replyCredits (server-only).
 */
async function reserveCharge(uid: string, tier: EffectiveTier, buddyId: string, requestId: string): Promise<ChargePlan> {
  const nowMs = Date.now();
  const usageRef = db().collection(BUDDY_USAGE).doc(`${uid}_${utcDay(nowMs)}`);
  const reqRef = db().collection(BUDDY_REQUESTS).doc(`${uid}_${requestId}`);
  const balanceRef = db().collection('coinBalances').doc(uid);
  const rootRef = db().collection(BUDDIES).doc(uid);
  const window = `rl_${Math.floor(nowMs / 600_000)}`;
  return db().runTransaction(async (tx) => {
    const [usage, req, bal, root] = await Promise.all([tx.get(usageRef), tx.get(reqRef), tx.get(balanceRef), tx.get(rootRef)]);
    if (req.exists) throw new AppError('DUPLICATE_REQUEST', 'This message is already being answered.', 409, { reason: 'DUPLICATE_REQUEST' });
    const u = usage.data() ?? {};
    if ((Number(u[window]) || 0) >= RATE_LIMIT_10MIN) {
      throw new AppError('RATE_LIMITED', 'You are sending messages too fast. Take a short break.', 429, { reason: 'RATE_LIMITED' });
    }
    const freeLimit = FREE_REPLIES_PER_DAY[tier];
    const used = Number(u.freeUsed) || 0;
    const credits = Math.max(0, Math.floor(Number(root.data()?.replyCredits) || 0));
    const plan: ChargePlan = { kind: 'free', drawn: [], transactionId: null, freeLeft: 0, balance: null, credits };
    const usageUpdate: Record<string, unknown> = {
      uid, day: utcDay(nowMs), [window]: (Number(u[window]) || 0) + 1, updatedAt: TS(),
      expireAt: admin.firestore.Timestamp.fromMillis(nowMs + 3 * 864e5),
    };
    if (used < freeLimit) {
      usageUpdate.freeUsed = used + 1;
      plan.freeLeft = freeLimit - used - 1;
    } else if (credits > 0) {
      plan.kind = 'credit';
      plan.credits = credits - 1;
      tx.set(rootRef, { replyCredits: credits - 1, updatedAt: TS() }, { merge: true });
      usageUpdate.paidReplies = (Number(u.paidReplies) || 0) + 1;
    } else {
      const b = bal.data() ?? {};
      const total = Number(b.totalCoins) || 0;
      if (total < 1) {
        throw refusal('failed-precondition', REASON.insufficientCoins,
          `You used today's free Buddy replies. More replies cost ${COINS_PER_REPLY} coins each (1 coin = ${REPLIES_PER_COIN} replies).`,
          { required: 1, available: Math.max(0, total), freeRepliesPerDay: freeLimit, coinsPerReply: COINS_PER_REPLY, repliesPerCoin: REPLIES_PER_COIN });
      }
      const { batches, drawn } = fifoDraw(b.coinBatches, 1);
      const txnRef = db().collection('coinTransactions').doc();
      tx.set(balanceRef, {
        userId: uid, totalCoins: total - 1,
        spentCoins: (Number(b.spentCoins) || 0) + 1, coinBatches: batches, lastUpdated: TS(),
      }, { merge: true });
      tx.set(txnRef, {
        userId: uid, type: 'debit', amount: 1, balanceAfter: total - 1,
        reason: 'featurePurchase', relatedId: buddyId, relatedUserId: null,
        metadata: { feature: 'buddy_replies', replies: REPLIES_PER_COIN, requestId, source: 'sendBuddyMessage' }, createdAt: TS(),
      });
      // This reply uses one of the REPLIES_PER_COIN; the rest stay prepaid.
      tx.set(rootRef, { uid, replyCredits: REPLIES_PER_COIN - 1, updatedAt: TS() }, { merge: true });
      usageUpdate.paidReplies = (Number(u.paidReplies) || 0) + 1;
      usageUpdate.coinsSpent = (Number(u.coinsSpent) || 0) + 1;
      Object.assign(plan, { kind: 'coin', drawn, transactionId: txnRef.id, balance: total - 1, credits: REPLIES_PER_COIN - 1 });
    }
    tx.set(usageRef, usageUpdate, { merge: true });
    tx.create(reqRef, {
      uid, buddyId, status: 'pending', charge: plan.kind, transactionId: plan.transactionId,
      createdAt: TS(), expireAt: admin.firestore.Timestamp.fromMillis(nowMs + 7 * 864e5),
    });
    return plan;
  });
}

/**
 * Gives back what reserveCharge took when the model fails: the daily free
 * reply, or one prepaid reply credit (also when this reply had just bought a
 * pack: the coin stays spent, the user keeps all REPLIES_PER_COIN replies).
 */
async function refundCharge(uid: string, requestId: string, plan: ChargePlan): Promise<void> {
  const reqRef = db().collection(BUDDY_REQUESTS).doc(`${uid}_${requestId}`);
  const usageRef = db().collection(BUDDY_USAGE).doc(`${uid}_${utcDay()}`);
  const rootRef = db().collection(BUDDIES).doc(uid);
  try {
    await db().runTransaction(async (tx) => {
      const req = await tx.get(reqRef);
      if (req.data()?.status !== 'pending') return;
      if (plan.kind === 'free') {
        tx.set(usageRef, { freeUsed: admin.firestore.FieldValue.increment(-1) }, { merge: true });
      } else {
        tx.set(rootRef, { replyCredits: admin.firestore.FieldValue.increment(1), updatedAt: TS() }, { merge: true });
        tx.set(usageRef, { paidReplies: admin.firestore.FieldValue.increment(-1) }, { merge: true });
      }
      // Free the request id so the app can retry the same message.
      tx.delete(reqRef);
    });
  } catch (e: any) {
    console.error('sendBuddyMessage: refund failed', e?.message ?? e);
  }
}

type Turn = { role: 'user' | 'assistant'; content: string };

async function recentTurns(ref: admin.firestore.DocumentReference, n: number): Promise<{ turns: Turn[]; times: number[] }> {
  const snap = await ref.collection('messages').orderBy('createdAt', 'desc').limit(n).get();
  const docs = snap.docs.reverse();
  return {
    turns: docs.map((d) => ({ role: d.data().role === 'user' ? 'user' : 'assistant', content: String(d.data().text ?? '') }) as Turn),
    times: docs.map((d) => d.data().createdAt?.toMillis?.() ?? 0),
  };
}

export async function handleSendBuddyMessage(uid: string, data: any) {
  const buddyId = okId(data.buddyId);
  if (!validRequestId(data.requestId)) throw new HttpsError('invalid-argument', 'Invalid requestId');
  const requestId = data.requestId as string;
  if (typeof data.text !== 'string' || !data.text.trim()) throw new HttpsError('invalid-argument', 'text is required');
  const text = data.text.trim();
  if (Array.from(text).length > USER_MESSAGE_MAX) {
    throw new AppError('TEXT_TOO_LONG', `Messages to a Buddy can be at most ${USER_MESSAGE_MAX} characters.`, 400, { max: USER_MESSAGE_MAX });
  }

  // A retried call whose reply was already stored gets the same answer.
  const done = await db().collection(BUDDY_REQUESTS).doc(`${uid}_${requestId}`).get();
  if (done.exists && done.data()?.status === 'done') return done.data()!.result;

  const consentVersion = await requireAiConsent(uid);
  const ref = buddiesCol(uid).doc(buddyId);
  const [snap, tier] = await Promise.all([ref.get(), tierOf(uid)]);
  if (!snap.exists) throw new HttpsError('not-found', 'Buddy not found');
  if (!(await activeBuddyIds(uid, tier)).has(buddyId)) {
    throw refusal('failed-precondition', REASON.tierRequired, 'This Buddy is locked on your current plan.', { tier });
  }
  const buddy = settingsOf(snap.data());
  const lang = buddy.language as Language;
  const r = await rules();
  const now = Date.now();

  // Crisis: fixed caring reply with helplines; no model, no charge.
  if (isCrisis(text)) {
    const reply = CRISIS_REPLY[lang] ?? CRISIS_REPLY.en;
    const tr = await translateTurn(buddy, text, [reply], consentVersion).catch(() => ({ user: null, replies: [null] }));
    await storeExchange(uid, ref, snap.data(), text, [reply], 'safety', 'none', requestId, r, now, undefined, [], tr);
    const status = await buddyStatus(uid);
    const result = {
      reply, replies: [reply], kind: 'safety', charged: 'none', freeRepliesLeft: status.freeRepliesLeft,
      userTranslation: tr.user?.text ?? null, translations: tr.replies.map((x) => x?.text ?? null),
    };
    return result;
  }

  await requireBuddyProvider(consentVersion);
  const plan = await reserveCharge(uid, tier, buddyId, requestId);

  let reply: string;
  let parsed: ParsedReply = { messages: [], keywords: [] };
  try {
    const history = await recentTurns(ref, Math.max(2, r.contextMessages ?? 12));
    const turns = fitContext([...history.turns, { role: 'user', content: text } as Turn],
      Math.max(2, (r.contextMessages ?? 12) + 1), r.contextChars ?? 2400);
    const d = snap.data() ?? {};
    const memory: MemoryFact[] = Array.isArray(d.memory) ? d.memory : [];
    const system = `${systemPrompt(buddy, r, memory, String(d.summary ?? ''))}\n\n${replyFormatBlock(r.maxOutputChars ?? 200)}`;
    const out = await generate('text_buddies', { system, messages: turns, json: true },
      { consentVersion }, { rawReply: true, rules: { maxTokens: Math.max(r.maxTokens ?? 120, 1000) } });
    parsed = parseBuddyReply(out.text, r, FALLBACK_REPLY[lang] ?? FALLBACK_REPLY.en);
    reply = parsed.messages.join('\n');
  } catch (e: any) {
    console.warn('sendBuddyMessage: model failed', e?.message ?? e);
    await refundCharge(uid, requestId, plan);
    throw unavailable();
  }

  const result = {
    reply,
    replies: parsed.messages,
    keywords: parsed.keywords,
    kind: 'chat',
    charged: plan.kind,
    freeRepliesLeft: plan.freeLeft,
    ...(plan.balance !== null ? { coinBalance: plan.balance } : {}),
    ...(plan.kind !== 'free' ? { replyCredits: plan.credits } : {}),
  };
  const tr = await translateTurn(buddy, text, parsed.messages, consentVersion);
  const translated = {
    ...result,
    userTranslation: tr.user?.text ?? null,
    translations: tr.replies.map((x) => x?.text ?? null),
  };
  await storeExchange(uid, ref, snap.data(), text, parsed.messages, 'chat', plan.kind, requestId, r, now, translated, parsed.keywords, tr);
  return translated;
}

export interface BuddyKeyword { type: 'city' | 'attraction' | 'country'; name: string }
export interface ParsedReply { messages: string[]; keywords: BuddyKeyword[] }

/** Closed JSON string literals after "messages": [ (salvages a reply cut off mid-JSON). */
function salvageMessages(raw: string): string[] {
  const at = raw.indexOf('"messages"');
  if (at < 0) return [];
  const rest = raw.slice(at + 10);
  const lb = rest.indexOf('[');
  if (lb < 0) return [];
  const out: string[] = [];
  const re = /"((?:[^"\\]|\\.)*)"/g;
  const body = rest.slice(lb + 1);
  const end = body.indexOf(']');
  const scope = end >= 0 ? body.slice(0, end) : body;
  let m: RegExpExecArray | null;
  while ((m = re.exec(scope)) !== null) {
    try { out.push(JSON.parse(`"${m[1]}"`)); } catch { /* skip */ }
  }
  return out;
}

/**
 * Splits [text] into chat bubbles of at most [max] graphemes WITHOUT losing or
 * cutting words: whole sentences are packed together; a sentence longer than
 * [max] continues in the next bubble at a word boundary (no ellipsis).
 */
export function splitIntoBubbles(text: string, max: number): string[] {
  const t = text.trim();
  if (graphemeLength(t) <= max) return t ? [t] : [];
  const sentences = t.match(/[^.!?…。！？]+[.!?…。！？]+["')\]]*\s*|[^.!?…。！？]+$/g) ?? [t];
  const bubbles: string[] = [];
  let cur = '';
  const push = () => { if (cur.trim()) bubbles.push(cur.trim()); cur = ''; };
  for (const sRaw of sentences) {
    const s = sRaw.trim();
    if (!s) continue;
    if (graphemeLength(s) > max) {
      push();
      let rest = s;
      while (graphemeLength(rest) > max) {
        const g = graphemes(rest);
        const head = g.slice(0, max).join('');
        const cut = head.search(/\s\S*$/);
        const piece = cut > 0 ? head.slice(0, cut) : head;
        bubbles.push(piece.trim());
        rest = rest.slice(piece.length).trim();
      }
      cur = rest;
      continue;
    }
    if (graphemeLength(cur ? `${cur} ${s}` : s) > max) push();
    cur = cur ? `${cur} ${s}` : s;
  }
  push();
  return bubbles;
}

/**
 * The model's JSON reply -> 1-3 chat bubbles (owner 2026-10-24: never
 * truncated, max 200 chars each, blocks of 1-3 messages). Markdown and links
 * stripped; a long message is split at sentence boundaries into more bubbles
 * (never cut with an ellipsis); beyond 3 bubbles whole bubbles are dropped.
 * Raw JSON is never shown: a reply cut off mid-JSON keeps its complete
 * messages; unparseable JSON becomes [fallback]. Every bubble is screened.
 */
export function parseBuddyReply(raw: string, r: CapabilityRules, fallback: string): ParsedReply {
  const max = r.maxOutputChars ?? 200;
  const j = parseJsonObject(raw);
  const looksJson = /^\s*[{[]/.test(raw) || raw.includes('"messages"');
  let list: unknown[] = Array.isArray(j?.messages) ? j.messages
    : typeof j?.message === 'string' ? [j.message]
    : looksJson ? salvageMessages(raw) : [raw];
  if (!list.length) list = [fallback];
  const bubbles: string[] = [];
  const extraKeywords: unknown[] = [];
  for (const m of list) {
    if (typeof m !== 'string') continue;
    // The model sometimes puts its JSON (e.g. the keywords) inside a message:
    // never show it; keep its keywords as metadata.
    if (/^\s*[{[]/.test(m) || /"(keywords|messages)"\s*:/.test(m)) {
      const inner = parseJsonObject(m);
      if (Array.isArray(inner?.keywords)) extraKeywords.push(...inner.keywords);
      continue;
    }
    const clean = applyReplyRules(m.replace(/<\/?[a-z]*\s*\/?>/gi, ' '), { stripMarkdown: true, stripLinks: true });
    for (const b of splitIntoBubbles(clean.text, max)) {
      if (bubbles.length >= MAX_BUBBLES) break;
      const banned = applyReplyRules(b, { bannedTerms: r.bannedTerms }).banned;
      const text = isUnsafeReply(b, banned) ? fallback : b;
      if (!bubbles.includes(text)) bubbles.push(text);
    }
  }
  if (!bubbles.length) bubbles.push(fallback);
  const keywords: BuddyKeyword[] = [...(Array.isArray(j?.keywords) ? j.keywords : []), ...extraKeywords]
    .filter((k: any) => k && typeof k.name === 'string' && ['city', 'attraction', 'country'].includes(k.type))
    .slice(0, 10)
    .map((k: any) => ({ type: k.type, name: String(k.name).trim().slice(0, 80) }))
    .filter((k: BuddyKeyword) => k.name && bubbles.some((m) => m.toLowerCase().includes(k.name.toLowerCase())));
  return { messages: bubbles, keywords };
}

/** Normalised for evidence matching: NFC, lower case, collapsed spaces, no edge punctuation. */
const normEvidence = (s: string) => s.normalize('NFC').toLowerCase().replace(/\s+/g, ' ').replace(/^[\s"'.,!?;:]+|[\s"'.,!?;:]+$/g, '').trim();

/**
 * Keeps only memory facts whose evidence is the user's exact words (owner
 * 2026-10-24: memory must be 100% accurate). A fact passes when its evidence
 * (>= 3 chars) appears in one of [userTexts], or when the same fact with the
 * same evidence was already stored (verified earlier).
 */
export function verifyMemoryFacts(raw: unknown, userTexts: string[], previous: MemoryFact[], maxFacts: number): MemoryFact[] {
  const hay = userTexts.map(normEvidence);
  const prev = new Map(previous.map((f) => [normEvidence(f.text), f]));
  const out: MemoryFact[] = [];
  for (const f of Array.isArray(raw) ? raw : []) {
    if (!f || typeof f !== 'object') continue;
    const text = typeof (f as any).fact === 'string' ? (f as any).fact.trim().slice(0, 120) : '';
    const evidence = typeof (f as any).evidence === 'string' ? (f as any).evidence.trim().slice(0, 300) : '';
    if (!text || !evidence) continue;
    const ev = normEvidence(evidence);
    const old = prev.get(normEvidence(text));
    const fromUser = ev.length >= 3 && hay.some((h) => h.includes(ev));
    const kept = old && old.evidence && normEvidence(old.evidence) === ev;
    if (!fromUser && !kept) continue;
    const id = factId(text);
    if (out.some((x) => x.id === id)) continue;
    out.push({ id, text, evidence, at: old?.at ?? Date.now() });
    if (out.length >= maxFacts) break;
  }
  return out;
}

export interface StoredTranslation { text: string; lang: string }

/**
 * True when a "translation" only differs by case, accents, punctuation or
 * spacing (the text already was in the target language): not shown.
 */
export function nearlySame(a: string, b: string): boolean {
  const n = (s: string) => s.normalize('NFD').replace(/\p{M}/gu, '').toLowerCase().replace(/[^\p{L}\p{N}]+/gu, '');
  return n(a) === n(b);
}
const baseLang = (c: string) => c.toLowerCase().replace(/_/g, '-').split('-')[0];
const routerLang = (c: string) => c.replace('_', '-');

/**
 * Owner 2026-10-24: every message is translated ONCE, when it is created,
 * into the Buddy's fixed chatLanguage and stored on the message (no
 * per-device or per-language re-translation). Nothing is translated when the
 * chat language is the Buddy's language (pt / pt_BR count as the same), or
 * when a user message already is in it. Best effort: a failure never blocks
 * the reply (the message simply has no translation).
 */
export async function translateTurn(b: BuddySettings, userText: string | null, replies: string[], consentVersion: number):
  Promise<{ user: StoredTranslation | null; replies: (StoredTranslation | null)[] }> {
  const target = b.chatLanguage ?? b.language;
  const none = { user: null, replies: replies.map(() => null) };
  // Owner 2026-10-24: never translate Italian into Italian, English into
  // English...: a chat read in the Buddy's own language translates nothing.
  if (!target || baseLang(target) === baseLang(b.language)) return none;
  const out: { user: StoredTranslation | null; replies: (StoredTranslation | null)[] } = { user: null, replies: replies.map(() => null) };
  try {
    if (replies.length && baseLang(target) !== baseLang(b.language)) {
      const r = await translate('translate_chat', replies, routerLang(target), { consentVersion }, { source: routerLang(b.language) });
      r.items.forEach((it, i) => {
        if (it && !it.sameLanguage && it.text.trim() && !nearlySame(it.text, replies[i])) out.replies[i] = { text: it.text, lang: target };
      });
    }
    if (userText && userText.trim()) {
      const r = await translate('translate_chat', [userText], routerLang(target), { consentVersion }, {});
      const it = r.items[0];
      const detected = it?.detectedLanguage ?? null;
      const sameAsTarget = detected ? baseLang(detected) === baseLang(target) : false;
      if (it && !it.sameLanguage && !sameAsTarget && it.text.trim() && !nearlySame(it.text, userText)) {
        out.user = { text: it.text, lang: target };
      }
    }
  } catch (e: any) {
    console.warn('buddy translateTurn failed', e?.message ?? e);
  }
  return out;
}

/** Writes the user message + the Buddy's 1-3 reply messages and updates the Buddy (one batch). */
async function storeExchange(uid: string, ref: admin.firestore.DocumentReference, d: any, userText: string, replies: string[],
  kind: 'chat' | 'safety', charged: 'free' | 'coin' | 'credit' | 'none', requestId: string, r: CapabilityRules, nowMs: number,
  result?: unknown, keywords: BuddyKeyword[] = [],
  tr: { user: StoredTranslation | null; replies: (StoredTranslation | null)[] } = { user: null, replies: [] }) {
  const batch = db().batch();
  const tUser = admin.firestore.Timestamp.fromMillis(nowMs);
  const base = Math.max(nowMs + 1, Date.now());
  batch.set(ref.collection('messages').doc(), {
    role: 'user', text: userText, kind: 'chat', charged: 'none', createdAt: tUser,
    ...(tr.user ? { translation: tr.user } : {}),
  });
  replies.forEach((text, i) => {
    const kw = keywords.filter((k) => text.toLowerCase().includes(k.name.toLowerCase()));
    batch.set(ref.collection('messages').doc(), {
      role: 'buddy', text, kind,
      // The turn is charged once: on its first message.
      charged: i === 0 ? charged : 'none',
      ...(kw.length ? { keywords: kw } : {}),
      ...(tr.replies[i] ? { translation: tr.replies[i] } : {}),
      // Owner 2026-10-24: bubbles 1 s apart (fixed order; the app reveals them one by one).
      createdAt: admin.firestore.Timestamp.fromMillis(base + i * BUBBLE_GAP_MS),
    });
  });
  const reply = replies[replies.length - 1];
  const tBuddy = admin.firestore.Timestamp.fromMillis(base + (replies.length - 1) * BUBBLE_GAP_MS);
  const userCount = (Number(d?.userMessageCount) || 0) + 1;
  const msgCount = (Number(d?.messageCount) || 0) + 1 + replies.length;
  const checkIn = r.checkInsEnabled !== false && d?.checkInsEnabled !== false;
  batch.update(ref, {
    lastMessage: reply.slice(0, 200),
    lastMessageAt: tBuddy,
    lastUserMessageAt: tUser,
    messageCount: msgCount,
    userMessageCount: userCount,
    unansweredCheckIns: 0,
    nextCheckInAt: checkIn ? admin.firestore.Timestamp.fromMillis(nowMs + (r.checkInAfterHours ?? 24) * 3600_000) : null,
    updatedAt: TS(),
  });
  if (result !== undefined) {
    batch.set(db().collection(BUDDY_REQUESTS).doc(`${uid}_${requestId}`), { status: 'done', result, doneAt: TS() }, { merge: true });
  }
  // Background memory / summary work (onBuddyJob), only when due.
  const memoryDue = (r.memoryEvery ?? 6) > 0 && userCount % (r.memoryEvery ?? 6) === 0;
  const summaryDue = (r.summaryEvery ?? 20) > 0 && msgCount > (r.contextMessages ?? 12) && msgCount % (r.summaryEvery ?? 20) < 2;
  if (kind === 'chat' && (memoryDue || summaryDue)) {
    batch.set(db().collection(BUDDY_JOBS).doc(`${uid}_${ref.id}`), {
      uid, buddyId: ref.id, memory: memoryDue, summary: summaryDue, at: TS(),
    }, { merge: true });
  }
  await batch.commit();
}

export const sendBuddyMessage = callable('sendBuddyMessage', handleSendBuddyMessage);

// ------------------------------------------------------- memory + summary job

const factId = (text: string) => crypto.createHash('sha256').update(text.toLowerCase()).digest('hex').slice(0, 12);

export async function runBuddyJob(uid: string, buddyId: string, job: { memory?: boolean; summary?: boolean }) {
  const ref = buddiesCol(uid).doc(buddyId);
  const snap = await ref.get();
  if (!snap.exists) return;
  const d = snap.data() ?? {};
  const r = await rules();
  const consentVersion = await aiConsentVersion(uid);
  const jsonRules = { maxTokens: 1200, temperature: 0.2, maxOutputChars: undefined, stripMarkdown: false, stripLinks: false };
  const update: Record<string, unknown> = {};

  if (job.memory && (r.memoryMaxFacts ?? 20) > 0) {
    const { turns } = await recentTurns(ref, Math.max(6, (r.memoryEvery ?? 6) * 2 + 2));
    try {
      const out = await generate('text_buddies', {
        messages: [{ role: 'user', content: memoryPrompt(Array.isArray(d.memory) ? d.memory : [], turns, r.memoryMaxFacts ?? 20) }],
        json: true,
      }, { consentVersion }, { rawReply: true, rules: jsonRules });
      const facts = parseJsonObject(out.text)?.facts;
      if (Array.isArray(facts)) {
        // Only facts whose evidence is the user's exact words survive.
        const userTexts = turns.filter((x) => x.role === 'user').map((x) => x.content);
        update.memory = verifyMemoryFacts(facts, userTexts, Array.isArray(d.memory) ? d.memory : [], r.memoryMaxFacts ?? 20);
      }
    } catch (e: any) {
      console.warn('buddy memory job failed', e?.message ?? e);
    }
  }

  if (job.summary) {
    const keep = r.contextMessages ?? 12;
    const snapMsgs = await ref.collection('messages').orderBy('createdAt', 'desc').limit(keep + (r.summaryEvery ?? 20) + 10).get();
    const older = snapMsgs.docs.slice(keep).reverse()
      .filter((m) => {
        const covered = d.summaryCoveredUntil?.toMillis?.() ?? 0;
        return (m.data().createdAt?.toMillis?.() ?? 0) > covered;
      });
    if (older.length) {
      try {
        const out = await generate('text_buddies', {
          messages: [{
            role: 'user',
            content: summaryPrompt(String(d.summary ?? ''),
              older.map((m) => ({ role: m.data().role, content: String(m.data().text ?? '') })), r.summaryMaxChars ?? 600),
          }],
          json: true,
        }, { consentVersion }, { rawReply: true, rules: jsonRules });
        const summary = parseJsonObject(out.text)?.summary;
        if (typeof summary === 'string' && summary.trim()) {
          update.summary = summary.trim().slice(0, r.summaryMaxChars ?? 600);
          update.summaryCoveredUntil = older[older.length - 1].data().createdAt;
        }
      } catch (e: any) {
        console.warn('buddy summary job failed', e?.message ?? e);
      }
    }
  }
  if (Object.keys(update).length) await ref.update(update);
}

export const onBuddyJob = onDocumentWritten({ document: `${BUDDY_JOBS}/{jobId}`, memory: '512MiB', timeoutSeconds: 120 },
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;
    const j = after.data() ?? {};
    if (!j.uid || !j.buddyId || (!j.memory && !j.summary)) return;
    // Claim the job first so a burst of messages runs it once.
    await after.ref.delete().catch(() => undefined);
    await runBuddyJob(String(j.uid), String(j.buddyId), { memory: !!j.memory, summary: !!j.summary });
  });

// ------------------------------------------------------------------ check-ins

/** Local hour of a user from the notification prefs offset (default UTC). */
export function localHour(nowMs: number, tzOffsetMinutes: number): number {
  return new Date(nowMs + tzOffsetMinutes * 60_000).getUTCHours();
}

/** Milliseconds until the next local [startHour]:00 (0 if inside the window). */
export function msUntilWindow(nowMs: number, tzOffsetMinutes: number, startHour: number, endHour: number): number {
  const h = localHour(nowMs, tzOffsetMinutes);
  if (h >= startHour && h < endHour) return 0;
  const local = new Date(nowMs + tzOffsetMinutes * 60_000);
  const next = new Date(local);
  next.setUTCMinutes(0, 0, 0);
  next.setUTCHours(startHour);
  if (next.getTime() <= local.getTime()) next.setUTCDate(next.getUTCDate() + 1);
  return next.getTime() - local.getTime();
}

export type CheckInDecision =
  | { action: 'send' }
  | { action: 'stop' }
  | { action: 'later'; atMs: number };

/** Pure eligibility rule (tested): daytime, one per user per day, stop after N unanswered. */
export function checkInDecision(p: {
  nowMs: number; unanswered: number; maxUnanswered: number; userCheckInDay: string | null;
  tzOffsetMinutes: number; startHour: number; endHour: number;
}): CheckInDecision {
  if (p.unanswered >= p.maxUnanswered) return { action: 'stop' };
  if (p.userCheckInDay === utcDay(p.nowMs)) return { action: 'later', atMs: p.nowMs + 6 * 3600_000 };
  const wait = msUntilWindow(p.nowMs, p.tzOffsetMinutes, p.startHour, p.endHour);
  if (wait > 0) return { action: 'later', atMs: p.nowMs + wait + Math.floor(Math.random() * 3600_000) };
  return { action: 'send' };
}

async function checkInOne(doc: admin.firestore.QueryDocumentSnapshot, r: CapabilityRules, sentToday: Set<string>) {
  const uid = doc.ref.parent.parent?.id;
  if (!uid) return;
  const d = doc.data();
  const nowMs = Date.now();
  const [root, prefs, consentVersion] = await Promise.all([
    db().collection(BUDDIES).doc(uid).get(),
    db().collection('notification_preferences').doc(uid).get(),
    aiConsentVersion(uid),
  ]);
  const decision = checkInDecision({
    nowMs,
    unanswered: Number(d.unansweredCheckIns) || 0,
    maxUnanswered: r.checkInMaxUnanswered ?? 3,
    userCheckInDay: sentToday.has(uid) ? utcDay(nowMs) : (root.data()?.lastCheckInDay ?? null),
    tzOffsetMinutes: Number(prefs.data()?.tzOffsetMinutes) || 0,
    startHour: r.checkInStartHour ?? 9,
    endHour: r.checkInEndHour ?? 21,
  });
  if (decision.action === 'stop') {
    await doc.ref.update({ nextCheckInAt: null });
    return;
  }
  if (decision.action === 'later') {
    await doc.ref.update({ nextCheckInAt: admin.firestore.Timestamp.fromMillis(decision.atMs) });
    return;
  }
  const config = await loadConfig();
  if (!eligibleChain(config, 'text_buddies', { consentVersion }).length) {
    // No provider for this user (e.g. old AI notice): wait until they write again.
    await doc.ref.update({ nextCheckInAt: null });
    return;
  }
  const buddy = settingsOf(d);
  const lang = buddy.language as Language;
  const { turns } = await recentTurns(doc.ref, 6);
  const lastUser = d.lastUserMessageAt?.toMillis?.() ?? nowMs;
  const p = checkInPrompt(buddy, r, Array.isArray(d.memory) ? d.memory : [], String(d.summary ?? ''), turns,
    (nowMs - lastUser) / 3600_000, Number(d.unansweredCheckIns) || 0);
  let text: string;
  try {
    const out = await generate('text_buddies', { system: p.system, messages: [{ role: 'user', content: p.user }] }, { consentVersion });
    if (isUnsafeReply(out.text, out.banned)) throw new Error('unsafe reply');
    text = out.text;
  } catch (e: any) {
    console.warn('buddyCheckIns: generation failed', e?.message ?? e);
    await doc.ref.update({ nextCheckInAt: admin.firestore.Timestamp.fromMillis(nowMs + 6 * 3600_000) });
    return;
  }
  const unanswered = (Number(d.unansweredCheckIns) || 0) + 1;
  const batch = db().batch();
  const at = TS();
  // Free and never counted: kind 'checkin', charged 'none'.
  const tr = await translateTurn(buddy, null, [text], consentVersion);
  batch.set(doc.ref.collection('messages').doc(), {
    role: 'buddy', text, kind: 'checkin', charged: 'none', createdAt: at,
    ...(tr.replies[0] ? { translation: tr.replies[0] } : {}),
  });
  batch.update(doc.ref, {
    lastMessage: text.slice(0, 200), lastMessageAt: at, messageCount: admin.firestore.FieldValue.increment(1),
    unansweredCheckIns: unanswered,
    // Back off: 24h, then 48h, then 96h ...
    nextCheckInAt: admin.firestore.Timestamp.fromMillis(nowMs + (r.checkInAfterHours ?? 24) * 3600_000 * 2 ** unanswered),
  });
  batch.set(db().collection(BUDDIES).doc(uid), { lastCheckInDay: utcDay(nowMs) }, { merge: true });
  await batch.commit();
  sentToday.add(uid);
  await emitNotification({
    recipientId: uid,
    type: 'buddy_checkin',
    title: rawText(buddy.name),
    body: rawText(text),
    data: { type: 'buddy_checkin', buddyId: doc.id },
  }).catch(() => undefined);
  void lang;
}

export async function runBuddyCheckIns(maxDocs = 2000): Promise<number> {
  const r = await rules();
  if (r.checkInsEnabled === false) return 0;
  const sentToday = new Set<string>();
  let processed = 0;
  let last: admin.firestore.QueryDocumentSnapshot | null = null;
  const deadline = Date.now() + 8 * 60_000;
  while (processed < maxDocs && Date.now() < deadline) {
    let q = db().collectionGroup('buddies')
      .where('checkInsEnabled', '==', true)
      .where('nextCheckInAt', '<=', TS())
      .orderBy('nextCheckInAt', 'asc')
      .limit(100);
    if (last) q = q.startAfter(last);
    const page = await q.get();
    if (page.empty) break;
    for (let i = 0; i < page.docs.length; i += 5) {
      await Promise.all(page.docs.slice(i, i + 5).map((doc) =>
        checkInOne(doc, r, sentToday).catch((e) => console.warn('buddyCheckIns: item failed', e?.message ?? e))));
    }
    processed += page.size;
    last = page.docs[page.docs.length - 1];
    if (page.size < 100) break;
  }
  return processed;
}

export const buddyCheckIns = onSchedule({ schedule: 'every 60 minutes', memory: '512MiB', timeoutSeconds: 540 },
  async () => {
    const n = await runBuddyCheckIns();
    console.log(`buddyCheckIns: processed ${n}`);
  });
