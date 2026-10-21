/**
 * Reversible effects of a moderation decision (Terms 18.4 c: "We reverse
 * decisions that turn out to be wrong").
 *
 * Every account / content action that goes through the decision path
 * (moderationDecisions.ts createModerationDecision) records WHAT it changed as
 * a list of [DecisionEffect]s on moderation_decisions/{id}.effects. An appeal
 * overturn (appealResolution.ts) or a moderator approving a held upload replays
 * that list backwards with [reverseEffects]. Nothing here guesses: an effect
 * that cannot be undone (a file already deleted, a newer suspension in force)
 * is reported back as an error / skip, never silently "succeeds".
 *
 * Also here, because it is shared by every path that records a violation:
 *   - user_strikes  (repeat-offender counter, Terms 18.6): one doc per
 *     violation, `revoked: true` when a decision is overturned;
 *   - user_warnings (warning records, `revoked` likewise);
 *   - the repeat-offender escalation rule [repeatOffenderEscalation].
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { syncHostExperiencesForBan } from '../user_experiences/hostBan';
import { recordLibraryRestored } from './mediaLibrary';

const db = () => admin.firestore();
const TS = admin.firestore.Timestamp;
const FV = admin.firestore.FieldValue;

export const CONTENT_BACKUPS = 'moderation_content_backups';
export const REPORTER_STANDING = 'reporter_standing';

// ---------------------------------------------------------------------------
// Effect model
// ---------------------------------------------------------------------------

export type DecisionEffect =
  /** Chat / shared-chat message replaced by the placeholder; original in a backup doc. */
  | { type: 'message'; path: string; backupId: string }
  /** Legacy `messages/{id}` soft delete. */
  | { type: 'legacyMessage'; messageId: string }
  /** Event cancelled / experience hidden: previous status restored. */
  | { type: 'listingStatus'; path: string; previousStatus: string | null }
  /** Photo URL removed from users/{uid}.photos (legacy flaggedPhoto). */
  | { type: 'profilePhoto'; userId: string; photoUrl: string }
  /** Upload moved to quarantine/ by the Vision screen. */
  | { type: 'quarantine'; objectPath: string; quarantinePath: string }
  /** Everything a safety case hid (safety/takedowns). */
  | { type: 'safetyCase'; caseId: string }
  | { type: 'suspension'; userId: string }
  | { type: 'ban'; userId: string }
  | { type: 'warning'; userId: string; warningId: string }
  | { type: 'strike'; userId: string; strikeId: string }
  | { type: 'shadowBan'; userId: string }
  | { type: 'verification'; userId: string }
  /** Automatic restriction for report volume (reportingSystem automaticBlockUser). */
  | { type: 'restriction'; userId: string; blockId: string | null }
  /** Reports of this user are not processed (Terms 18.6 / DSA art. 23). */
  | { type: 'reportingSuspension'; userId: string };

export interface ReverseResult {
  reversed: string[];
  skipped: string[];
  errors: string[];
}

// ---------------------------------------------------------------------------
// Account sanctions
// ---------------------------------------------------------------------------

/** Best-effort mirror onto profiles/{uid} (what the admin panel's Users page reads). */
async function mirrorProfile(userId: string, patch: Record<string, unknown>): Promise<void> {
  try {
    await db().collection('profiles').doc(userId).update(patch);
  } catch (e: any) {
    if (e?.code !== 5) console.error(`[effects] could not mirror onto profiles/${userId}:`, e?.message || e);
  }
}

export async function applySuspension(p: {
  userId: string; reason: string; days: number; decisionId: string; by?: string | null; nowMs?: number;
}): Promise<DecisionEffect> {
  const nowMs = p.nowMs ?? Date.now();
  const until = TS.fromMillis(nowMs + Math.max(1, p.days) * 86_400_000);
  await db().collection('users').doc(p.userId).update({
    accountStatus: 'suspended',
    suspensionReason: p.reason,
    suspendedUntil: until,
    suspendedAt: FV.serverTimestamp(),
    suspensionDecisionId: p.decisionId,
    ...(p.by ? { suspendedBy: p.by } : {}),
  });
  await mirrorProfile(p.userId, {
    status: 'suspended',
    suspensionReason: p.reason,
    suspendedAt: FV.serverTimestamp(),
    suspendedUntil: until,
  });
  await syncHostExperiencesForBan(p.userId, true);
  return { type: 'suspension', userId: p.userId };
}

export async function applyBan(p: {
  userId: string; reason: string; decisionId: string; by?: string | null;
}): Promise<DecisionEffect> {
  await db().collection('users').doc(p.userId).update({
    accountStatus: 'banned',
    banReason: p.reason,
    bannedAt: FV.serverTimestamp(),
    banDecisionId: p.decisionId,
    ...(p.by ? { bannedBy: p.by } : {}),
  });
  try {
    await admin.auth().updateUser(p.userId, { disabled: true });
  } catch (e: any) {
    if (e?.code !== 'auth/user-not-found') throw e;
  }
  await mirrorProfile(p.userId, {
    status: 'banned',
    banReason: p.reason,
    bannedAt: FV.serverTimestamp(),
  });
  await syncHostExperiencesForBan(p.userId, true);
  return { type: 'ban', userId: p.userId };
}

// ---------------------------------------------------------------------------
// Strikes + warnings (Terms 18.6 repeat offenders)
// ---------------------------------------------------------------------------

/** Violations counted for repeat-offender escalation: the last 12 months. */
export const REPEAT_WINDOW_DAYS = 365;
/** Violations (warnings + removals + sanctions) within the window that trigger escalation. */
export const REPEAT_STRIKE_THRESHOLD = 3;
export const ESCALATION_FIRST_DAYS = 7;
export const ESCALATION_REPEAT_DAYS = 30;
/** Bounded reads: a user with more than this in a year is escalated anyway. */
const COUNT_LIMIT = 50;

export type StrikeKind = 'warning' | 'content_removal' | 'suspension' | 'ban' | 'ncii' | 'csae' | 'escalation';

export async function recordStrike(p: {
  userId: string; decisionId: string; kind: StrikeKind; nowMs?: number;
}): Promise<DecisionEffect> {
  const strikeId = `${p.decisionId}_${p.userId}`.replace(/\//g, '_').slice(0, 1400);
  const ref = db().collection('user_strikes').doc(strikeId);
  // Idempotent per decision: a retried action never counts twice.
  const created = await db().runTransaction(async (tx) => {
    if ((await tx.get(ref)).exists) return false;
    tx.set(ref, {
      userId: p.userId,
      decisionId: p.decisionId,
      kind: p.kind,
      at: TS.fromMillis(p.nowMs ?? Date.now()),
      revoked: false,
    });
    return true;
  });
  if (created && p.kind !== 'escalation') {
    await db().collection('users').doc(p.userId).set({ safetyStrikes: FV.increment(1) }, { merge: true })
      .catch((e) => console.error('[effects] strike counter failed', e?.message || e));
  }
  return { type: 'strike', userId: p.userId, strikeId };
}

export async function recordWarning(p: {
  userId: string; reason: string; description: string; severity: string; decisionId: string; by?: string | null;
}): Promise<DecisionEffect> {
  const ref = await db().collection('user_warnings').add({
    userId: p.userId,
    reason: p.reason,
    description: p.description,
    severity: p.severity,
    decisionId: p.decisionId,
    issuedBy: p.by ?? null,
    issuedAt: FV.serverTimestamp(),
    acknowledged: false,
    acknowledgedAt: null,
    revoked: false,
  });
  return { type: 'warning', userId: p.userId, warningId: ref.id };
}

export interface OffenderHistory {
  /** Violations in the window, the current one included. */
  violations: number;
  /** Warnings in the window issued BEFORE the current action. */
  priorWarnings: number;
  /** Escalation suspensions already applied in the window. */
  priorEscalations: number;
  /** The account is already suspended / banned. */
  alreadyRestricted: boolean;
}

/**
 * Terms 18.6: "If someone often posts clearly illegal Content, we suspend
 * their account after a warning." Often = [REPEAT_STRIKE_THRESHOLD]
 * violations in 12 months; never without a prior warning; the second
 * escalation in the window is longer. Pure.
 */
export function repeatOffenderEscalation(h: OffenderHistory): { days: number } | null {
  if (h.alreadyRestricted) return null;
  if (h.violations < REPEAT_STRIKE_THRESHOLD || h.priorWarnings < 1) return null;
  return { days: h.priorEscalations > 0 ? ESCALATION_REPEAT_DAYS : ESCALATION_FIRST_DAYS };
}

/** Bounded per-user indexed reads (user_strikes userId+at, user_warnings userId+issuedAt). */
export async function offenderHistory(userId: string, currentWarningId: string | null, nowMs = Date.now()): Promise<OffenderHistory> {
  const since = TS.fromMillis(nowMs - REPEAT_WINDOW_DAYS * 86_400_000);
  const [strikes, warnings, user] = await Promise.all([
    db().collection('user_strikes').where('userId', '==', userId).where('at', '>=', since)
      .orderBy('at', 'desc').limit(COUNT_LIMIT).get(),
    db().collection('user_warnings').where('userId', '==', userId).where('issuedAt', '>=', since)
      .orderBy('issuedAt', 'desc').limit(COUNT_LIMIT).get(),
    db().collection('users').doc(userId).get(),
  ]);
  let violations = 0;
  let priorEscalations = 0;
  for (const d of strikes.docs) {
    const s = d.data();
    if (s.revoked === true) continue;
    if (s.kind === 'escalation') priorEscalations++;
    else violations++;
  }
  const priorWarnings = warnings.docs.filter((d) => d.id !== currentWarningId && d.data().revoked !== true).length;
  const status = user.data()?.accountStatus;
  return { violations, priorWarnings, priorEscalations, alreadyRestricted: status === 'suspended' || status === 'banned' };
}

// ---------------------------------------------------------------------------
// Content
// ---------------------------------------------------------------------------

const MESSAGE_TEXT_FIELDS = ['content', 'text', 'caption'];

/**
 * Saves what a message removal overwrites, so an overturn can put it back.
 * Server-only collection; expires (TTL on expireAt) after the appeal window.
 */
export async function backupMessage(backupId: string, path: string, data: Record<string, unknown>, expireAtMs: number): Promise<void> {
  const original: Record<string, unknown> = {};
  for (const f of [...MESSAGE_TEXT_FIELDS, 'isDeletedForEveryone', 'isDeleted', 'tr', 'trHash']) {
    if (f in data) original[f] = data[f];
  }
  const sysKey = (data.metadata as Record<string, unknown> | undefined)?.systemKey;
  await db().collection(CONTENT_BACKUPS).doc(backupId).set({
    path,
    original,
    presentFields: Object.keys(original),
    hadSystemKey: typeof sysKey === 'string' ? sysKey : null,
    createdAt: TS.now(),
    expireAt: TS.fromMillis(expireAtMs),
  });
}

/** Copies a quarantined upload back to its original path (Vision false positive). */
export async function restoreQuarantined(objectPath: string, quarantinePath: string): Promise<'restored' | 'missing'> {
  const bucket = admin.storage().bucket();
  const held = bucket.file(quarantinePath);
  const [exists] = await held.exists();
  if (!exists) return 'missing';
  // The copy re-fires moderateUploadedImage. It skips exactly this object
  // GENERATION (a later re-upload to the same path is a new generation and
  // is screened as usual); restorePending covers the race where the trigger
  // runs before the generation is recorded.
  const verdictRef = db().collection('image_moderation').doc(objectPath.replace(/\//g, '~'));
  await verdictRef.set({ restorePending: true, objectPath }, { merge: true });
  const [copy] = await held.copy(bucket.file(objectPath));
  let generation: string | null = null;
  let custom: Record<string, string> = {};
  try {
    const [meta] = await copy.getMetadata();
    generation = meta.generation !== undefined ? String(meta.generation) : null;
    custom = (meta.metadata || {}) as Record<string, string>;
  } catch {
    generation = null;
  }
  // The hold rotated the download token (quarantineObject) so the old URL
  // could not open the quarantined copy. Put the original token back: every
  // place that already stored the URL works again.
  if (typeof custom.heldDownloadToken === 'string' && custom.heldDownloadToken) {
    try {
      await copy.setMetadata({ metadata: { firebaseStorageDownloadTokens: custom.heldDownloadToken, heldDownloadToken: null } });
      custom = { ...custom, firebaseStorageDownloadTokens: custom.heldDownloadToken };
      delete custom.heldDownloadToken;
    } catch (e) {
      console.error(`[restoreQuarantined] token restore failed for ${objectPath}:`, e);
    }
  }
  await verdictRef.set({
    status: 'approved',
    objectPath,
    reasons: [],
    restorePending: false,
    moderatorApproved: true,
    approvedGeneration: generation,
    restoredAt: FV.serverTimestamp(),
    checkedAt: FV.serverTimestamp(),
    expiresAt: TS.fromMillis(Date.now() + 24 * 3600 * 1000),
  }, { merge: true });
  await held.delete({ ignoreNotFound: true });
  // "My pictures": the image is usable again (status approved + URL).
  try {
    await recordLibraryRestored({ bucket: bucket.name, objectPath, generation, meta: custom });
  } catch (e) {
    console.error(`[restoreQuarantined] library update failed for ${objectPath}:`, e);
  }
  return 'restored';
}

// ---------------------------------------------------------------------------
// Reversal
// ---------------------------------------------------------------------------

function label(e: DecisionEffect): string {
  switch (e.type) {
    case 'message': case 'listingStatus': return `${e.type}:${e.path}`;
    case 'legacyMessage': return `${e.type}:${e.messageId}`;
    case 'quarantine': return `${e.type}:${e.objectPath}`;
    case 'safetyCase': return `${e.type}:${e.caseId}`;
    case 'profilePhoto': return `${e.type}:${e.userId}`;
    default: return `${e.type}:${(e as { userId: string }).userId}`;
  }
}

async function liftAccountStatus(userId: string, kind: 'suspension' | 'ban', decisionId: string): Promise<'lifted' | 'superseded' | 'not_active'> {
  const ref = db().collection('users').doc(userId);
  const u = (await ref.get()).data();
  if (!u) return 'not_active';
  const ownerField = kind === 'ban' ? 'banDecisionId' : 'suspensionDecisionId';
  // A newer sanction from ANOTHER decision stays in force.
  if (typeof u[ownerField] === 'string' && u[ownerField] !== decisionId) return 'superseded';
  const wanted = kind === 'ban' ? 'banned' : 'suspended';
  if (u.accountStatus !== wanted) return 'not_active';
  const patch: Record<string, unknown> = {
    accountStatus: 'active',
    [ownerField]: FV.delete(),
    liftedAt: FV.serverTimestamp(),
    liftedByDecisionId: decisionId,
  };
  if (kind === 'ban') Object.assign(patch, { banReason: null, unbannedAt: FV.serverTimestamp() });
  else Object.assign(patch, { suspensionReason: null, suspendedUntil: null, unsuspendedAt: FV.serverTimestamp() });
  await ref.update(patch);
  if (kind === 'ban') {
    try {
      await admin.auth().updateUser(userId, { disabled: false });
    } catch (e: any) {
      if (e?.code !== 'auth/user-not-found') throw e;
    }
  }
  await mirrorProfile(userId, kind === 'ban'
    ? { status: 'active', banReason: null }
    : { status: 'active', suspensionReason: null, suspendedUntil: null });
  await syncHostExperiencesForBan(userId, false);
  return 'lifted';
}

async function reverseOne(e: DecisionEffect, decisionId: string): Promise<'reversed' | string> {
  switch (e.type) {
    case 'suspension':
    case 'ban': {
      const r = await liftAccountStatus(e.userId, e.type, decisionId);
      return r === 'lifted' ? 'reversed' : r;
    }
    case 'warning':
      await db().collection('user_warnings').doc(e.warningId).set(
        { revoked: true, revokedAt: FV.serverTimestamp(), revokedByDecisionId: decisionId }, { merge: true });
      return 'reversed';
    case 'strike': {
      const ref = db().collection('user_strikes').doc(e.strikeId);
      const was = await db().runTransaction(async (tx) => {
        const s = await tx.get(ref);
        if (!s.exists || s.data()?.revoked === true) return null;
        tx.update(ref, { revoked: true, revokedAt: TS.now() });
        return s.data()?.kind as string;
      });
      if (was && was !== 'escalation') {
        await db().collection('users').doc(e.userId).set({ safetyStrikes: FV.increment(-1) }, { merge: true });
      }
      return was ? 'reversed' : 'not_active';
    }
    case 'shadowBan':
      await db().collection('users').doc(e.userId).update({ isShadowBanned: false, visibilityReduction: 0, shadowBanLiftedAt: FV.serverTimestamp() });
      return 'reversed';
    case 'verification':
      await db().collection('users').doc(e.userId).update({ verificationRequired: false });
      return 'reversed';
    case 'restriction': {
      const ref = db().collection('users').doc(e.userId);
      const u = (await ref.get()).data();
      if (u?.accountStatus === 'restricted') await ref.update({ accountStatus: 'active', restrictionReason: null });
      if (e.blockId) await db().collection('user_blocks').doc(e.blockId).set({ isActive: false, liftedAt: FV.serverTimestamp() }, { merge: true });
      return 'reversed';
    }
    case 'reportingSuspension':
      await db().collection(REPORTER_STANDING).doc(e.userId).set(
        { suspendedUntil: null, suspensionLiftedAt: FV.serverTimestamp(), suspensionLiftedByDecisionId: decisionId }, { merge: true });
      return 'reversed';
    case 'legacyMessage':
      await db().collection('messages').doc(e.messageId).update({ deleted: false, deletedBy: FV.delete(), deletedAt: FV.delete() });
      return 'reversed';
    case 'profilePhoto':
      await db().collection('users').doc(e.userId).update({ photos: FV.arrayUnion(e.photoUrl) });
      return 'reversed';
    case 'listingStatus': {
      const snap = await db().doc(e.path).get();
      if (!snap.exists) return 'missing';
      await snap.ref.update({
        status: e.previousStatus ?? 'published',
        moderation: FV.delete(),
      });
      return 'reversed';
    }
    case 'message': {
      const b = (await db().collection(CONTENT_BACKUPS).doc(e.backupId).get()).data();
      if (!b) return 'backup_missing';
      const snap = await db().doc(e.path).get();
      if (!snap.exists) return 'missing';
      const present = new Set<string>(b.presentFields || []);
      const patch: Record<string, unknown> = { ...(b.original || {}), moderation: FV.delete(), deletedAt: FV.delete() };
      for (const f of ['isDeletedForEveryone', 'isDeleted', ...MESSAGE_TEXT_FIELDS]) {
        if (!present.has(f)) patch[f] = FV.delete();
      }
      patch['metadata.systemKey'] = b.hadSystemKey ? b.hadSystemKey : FV.delete();
      await snap.ref.update(patch);
      await db().collection(CONTENT_BACKUPS).doc(e.backupId).delete().catch(() => undefined);
      return 'reversed';
    }
    case 'quarantine': {
      const r = await restoreQuarantined(e.objectPath, e.quarantinePath);
      return r === 'restored' ? 'reversed' : 'file_missing';
    }
    case 'safetyCase': {
      const { restoreContent, SAFETY_CASES } = await import('./takedowns/safetyCases');
      const caseRef = db().collection(SAFETY_CASES).doc(e.caseId);
      const c = (await caseRef.get()).data();
      if (!c) return 'missing';
      const bucket = admin.storage().bucket();
      const hidden = (c.hidden || []) as Array<Record<string, any>>;
      // A confirmed removal deleted the held files: re-linking a profile URL
      // to a missing file would show a broken photo, so only what still
      // exists is restored.
      const restorable: any[] = [];
      const lost: string[] = [];
      for (const h of hidden) {
        if (h.type === 'storage' && h.holdPath) {
          if ((await bucket.file(h.holdPath).exists())[0]) restorable.push(h);
          else lost.push(h.path);
        } else if (h.type !== 'profileRef') {
          restorable.push(h);
        }
      }
      for (const h of hidden) {
        if (h.type !== 'profileRef') continue;
        const urls = (h.urls || []) as string[];
        if (lost.length === 0 || !urls.length) restorable.push(h);
      }
      const errors = await restoreContent(e.caseId, restorable as any);
      await caseRef.update({ status: 'restored', restoredByAppealDecisionId: decisionId, updatedAt: TS.now() });
      if (lost.length || errors.length) return `partial:${[...lost.map((p) => `lost:${p}`), ...errors].join(';').slice(0, 300)}`;
      return 'reversed';
    }
  }
}

/** Reverses [effects] (latest first). Never throws; per-effect outcome returned. */
export async function reverseEffects(effects: DecisionEffect[], decisionId: string): Promise<ReverseResult> {
  const out: ReverseResult = { reversed: [], skipped: [], errors: [] };
  for (const e of [...effects].reverse()) {
    try {
      const r = await reverseOne(e, decisionId);
      if (r === 'reversed') out.reversed.push(label(e));
      else if (r.startsWith('partial:')) {
        out.reversed.push(label(e));
        out.errors.push(`${label(e)}:${r}`);
      } else out.skipped.push(`${label(e)}:${r}`);
    } catch (err: any) {
      console.error(`[effects] reversing ${label(e)} failed:`, err?.message || err);
      out.errors.push(`${label(e)}:${String(err?.message || err).slice(0, 200)}`);
    }
  }
  return out;
}

/** Effects of a decision as stored (defensive parse of Firestore data). */
export function parseEffects(raw: unknown): DecisionEffect[] {
  if (!Array.isArray(raw)) return [];
  return raw.filter((e): e is DecisionEffect => !!e && typeof e === 'object' && typeof (e as any).type === 'string');
}
