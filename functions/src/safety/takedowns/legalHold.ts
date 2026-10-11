/**
 * CSAE legal hold (US REPORT Act 2024 / 18 USC 2258A(h): preserve 1 year;
 * Brazil Lei 15.211/2025 + ECA: preserve evidence for the Polícia Federal).
 *
 * A hold is opened for the reported account whenever a CSAE case is opened
 * (user report with a CSAE category, or a hash-list match on a public
 * upload). It COPIES, it never moves:
 *
 *   legal_holds/{holdId}                       hold record (superAdmin only)
 *   legal_holds/{holdId}/preserved/{encPath}   snapshots of the account's
 *                                              docs, Auth record, reports,
 *                                              moderation items, access logs
 *   legal_holds/{holdId}/report_packages/{id}  NCMEC / PF report packages
 *   Storage legal_holds/{holdId}/files/<original path>
 *                                              copies of the account's media
 *                                              and of the hidden content
 *
 * Account deletion (deleteMyAccount, website deletion, onUserDeletedCleanup)
 * calls preserveForAccountDeletion() FIRST: the hold is refreshed from the
 * live data before anything is deleted, and the moderation records about the
 * user are skipped (LEGAL_HOLD_KEEP_COLLECTIONS). If the refresh fails the
 * deletion does not run at all (evidence must never be lost by a retry).
 *
 * Nothing here is client-reachable: firestore.rules / storage.rules deny
 * every client access to legal_holds; the admin panel reads holds through
 * safetyAdmin (superAdmin only, audit-logged).
 *
 * Expiry: after holdUntil (+365 days, extendable by a superAdmin) the daily
 * sweep marks the hold `expired_pending_purge` and alerts; it only deletes the
 * preserved material when app_config/safety_settings.autoPurgeExpiredHolds is
 * true (counsel decides; a pending investigation may need longer).
 */

import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import '../../shared/firebaseAdmin';

const db = () => admin.firestore();
const TS = admin.firestore.Timestamp;

export const LEGAL_HOLDS = 'legal_holds';
export const LEGAL_HOLD_DAYS = 365;
const DAY_MS = 86_400_000;
const MAX_FILES_PER_PREFIX = 500;
const MAX_DOCS_PER_QUERY = 200;

/** uid-keyed Storage prefixes copied into the hold. */
export const HOLD_STORAGE_PREFIXES = ['profiles', 'users', 'video_profiles', 'voice_intros', 'communities', 'storefronts'];

/**
 * Collections whose `userId == uid` rows are moderation records about the
 * user. While a hold is active, account deletion leaves them in place.
 */
export const LEGAL_HOLD_KEEP_COLLECTIONS = ['moderation_queue', 'image_moderation', 'user_warnings', 'account_actions', 'user_strikes'];

export function holdIdFor(subjectUid: string | null | undefined, caseId: string): string {
  return subjectUid ? `csae_${subjectUid}` : `csae_case_${caseId}`;
}

export function holdFilePath(holdId: string, originalPath: string): string {
  return `legal_holds/${holdId}/files/${originalPath}`;
}

const enc = (path: string) => path.replace(/\//g, '~').slice(0, 1400);

/** Firestore values -> JSON-safe snapshot (timestamps as ISO strings). */
function plain(v: any): any {
  if (v === null || v === undefined) return v ?? null;
  if (v instanceof admin.firestore.Timestamp) return v.toDate().toISOString();
  if (v instanceof admin.firestore.DocumentReference) return v.path;
  if (v instanceof admin.firestore.GeoPoint) return { lat: v.latitude, lng: v.longitude };
  if (Buffer.isBuffer(v)) return `<${v.length} bytes>`;
  if (Array.isArray(v)) return v.map(plain);
  if (typeof v === 'object') {
    const o: Record<string, any> = {};
    for (const [k, x] of Object.entries(v)) o[k] = plain(x);
    return o;
  }
  return v;
}

async function snapshotDoc(holdId: string, snap: FirebaseFirestore.DocumentSnapshot): Promise<boolean> {
  if (!snap.exists) return false;
  await db().collection(LEGAL_HOLDS).doc(holdId).collection('preserved').doc(enc(snap.ref.path)).set({
    path: snap.ref.path,
    data: plain(snap.data()),
    capturedAt: TS.now(),
  });
  return true;
}

/** Copies one Storage object into the hold (idempotent). Returns false when missing. */
export async function copyIntoHold(holdId: string, path: string): Promise<boolean> {
  const bucket = admin.storage().bucket();
  const src = bucket.file(path);
  const [exists] = await src.exists();
  if (!exists) return false;
  await src.copy(bucket.file(holdFilePath(holdId, path.replace(/^legal_holds\/[^/]+\/files\//, ''))));
  return true;
}

/**
 * Snapshots everything we hold about [uid] into the hold: profile docs, the
 * Auth record, reports about them, moderation items, access logs (when the
 * BR-09 access log exists) and their uid-keyed Storage files.
 */
export async function preserveSubject(holdId: string, uid: string): Promise<{ docs: number; files: number }> {
  let docs = 0;
  let files = 0;
  for (const path of [`users/${uid}`, `profiles/${uid}`, `profiles_private/${uid}`, `age_assurance/${uid}`]) {
    if (await snapshotDoc(holdId, await db().doc(path).get())) docs++;
  }
  const queries: Array<[string, string]> = [
    ['moderation_queue', 'userId'], ['moderation_queue', 'reportedUserId'], ['user_reports', 'reportedUserId'],
    ['message_reports', 'reportedUserId'], ['reports', 'reportedUserId'], ['image_moderation', 'userId'],
    ['identity_verifications', 'userId'], ['user_strikes', 'userId'],
    // Marco Civil access log (audit BR-09; not built yet): preserved when present.
    ['access_logs', 'userId'],
  ];
  for (const [col, field] of queries) {
    const s = await db().collection(col).where(field, '==', uid).limit(MAX_DOCS_PER_QUERY).get();
    for (const d of s.docs) if (await snapshotDoc(holdId, d)) docs++;
  }
  try {
    const u = await admin.auth().getUser(uid);
    await db().collection(LEGAL_HOLDS).doc(holdId).collection('preserved').doc('auth_user').set({
      path: `auth/${uid}`,
      data: {
        uid: u.uid,
        email: u.email ?? null,
        emailVerified: u.emailVerified,
        phoneNumber: u.phoneNumber ?? null,
        displayName: u.displayName ?? null,
        disabled: u.disabled,
        creationTime: u.metadata.creationTime ?? null,
        lastSignInTime: u.metadata.lastSignInTime ?? null,
        lastRefreshTime: u.metadata.lastRefreshTime ?? null,
        providerIds: (u.providerData || []).map((p) => p.providerId),
      },
      capturedAt: TS.now(),
    });
    docs++;
  } catch (e: any) {
    if (e?.code !== 'auth/user-not-found') throw e;
  }
  const bucket = admin.storage().bucket();
  for (const p of HOLD_STORAGE_PREFIXES) {
    const [fs] = await bucket.getFiles({ prefix: `${p}/${uid}/`, maxResults: MAX_FILES_PER_PREFIX });
    for (const f of fs) {
      await f.copy(bucket.file(holdFilePath(holdId, f.name)));
      files++;
    }
  }
  return { docs, files };
}

/**
 * Opens (or extends) the hold for a CSAE case and preserves the subject's
 * data plus [extraFiles] (the hidden content). One hold per subject.
 */
export async function ensureLegalHold(p: {
  subjectUid: string | null;
  caseId: string;
  reason: string;
  createdBy: string;
  extraFiles?: string[];
  nowMs?: number;
}): Promise<string> {
  const nowMs = p.nowMs ?? Date.now();
  const holdId = holdIdFor(p.subjectUid, p.caseId);
  const ref = db().collection(LEGAL_HOLDS).doc(holdId);
  await db().runTransaction(async (tx) => {
    const cur = (await tx.get(ref)).data();
    const until = Math.max(cur?.holdUntil?.toMillis?.() ?? 0, nowMs + LEGAL_HOLD_DAYS * DAY_MS);
    tx.set(ref, {
      holdId,
      kind: 'csae',
      subjectUid: p.subjectUid ?? null,
      status: 'active',
      caseIds: admin.firestore.FieldValue.arrayUnion(p.caseId),
      reason: p.reason.slice(0, 300),
      access: 'superAdmin',
      holdUntil: TS.fromMillis(until),
      updatedAt: TS.fromMillis(nowMs),
      ...(cur ? {} : { createdAt: TS.fromMillis(nowMs), createdBy: p.createdBy }),
    }, { merge: true });
  });
  let docs = 0;
  let files = 0;
  if (p.subjectUid) ({ docs, files } = await preserveSubject(holdId, p.subjectUid));
  for (const f of p.extraFiles || []) if (await copyIntoHold(holdId, f)) files++;
  await ref.set({
    preservedAt: TS.now(),
    preservedDocs: admin.firestore.FieldValue.increment(docs),
    preservedFiles: admin.firestore.FieldValue.increment(files),
  }, { merge: true });
  return holdId;
}

/** Active holds whose subject is [uid]. */
export async function activeHoldsFor(uid: string, nowMs = Date.now()): Promise<FirebaseFirestore.QueryDocumentSnapshot[]> {
  const s = await db().collection(LEGAL_HOLDS).where('subjectUid', '==', uid).limit(20).get();
  return s.docs.filter((d) => {
    const st = d.data().status;
    return st === 'active' || st === 'expired_pending_purge' || (d.data().holdUntil?.toMillis?.() ?? 0) > nowMs;
  });
}

/**
 * Called by account deletion BEFORE anything is deleted. Refreshes every
 * active hold of [uid] from the live data. Returns true when the account is
 * under a hold. Throws when preservation fails (the caller must then abort).
 */
export async function preserveForAccountDeletion(uid: string): Promise<boolean> {
  const holds = await activeHoldsFor(uid);
  if (holds.length === 0) return false;
  for (const h of holds) {
    const r = await preserveSubject(h.id, uid);
    await h.ref.set({
      subjectDeletionRequestedAt: TS.now(),
      preservedAt: TS.now(),
      preservedDocs: admin.firestore.FieldValue.increment(r.docs),
      preservedFiles: admin.firestore.FieldValue.increment(r.files),
    }, { merge: true });
  }
  return true;
}

// ---------------------------------------------------------------------------
// Report package (NCMEC CyberTipline / Polícia Federal / SaferNet)
// ---------------------------------------------------------------------------

export type Authority = 'NCMEC' | 'PF_BR' | 'SAFERNET';
export const AUTHORITIES: Authority[] = ['NCMEC', 'PF_BR', 'SAFERNET'];

const AUTHORITY_INFO: Record<Authority, { name: string; submit: string; checklist: string[] }> = {
  NCMEC: {
    name: 'NCMEC CyberTipline (US, 18 USC 2258A)',
    submit: 'https://report.cybertip.org/ (ESP portal / API - registered ESP account required)',
    checklist: [
      'Sign in to the ESP CyberTipline portal (ESP registration is an owner step, see runbook).',
      'Incident type: child pornography (possession, manufacture, distribution) or enticement / sexual exploitation as applicable.',
      'Upload the preserved files from Storage legal_holds/<holdId>/files/ via the portal (never by email).',
      'Fill reported-person identifiers (uid, email, phone, IPs with timestamps, account creation time).',
      'Record the CyberTipline report number here with "Mark reported".',
    ],
  },
  PF_BR: {
    name: 'Polícia Federal - Brasil (Lei 15.211/2025, ECA arts. 241-A ss.)',
    submit: 'https://www.gov.br/pf/pt-br/canais_atendimento/denuncia (canal de denúncias de crimes cibernéticos / CSAE)',
    checklist: [
      'Use the PF online reporting channel for child sexual abuse material (or the channel defined by Decreto 12.882/2026).',
      'Attach this package (metadata) and coordinate secure delivery of the preserved media - do NOT email images.',
      'Keep the protocol number and record it with "Mark reported".',
    ],
  },
  SAFERNET: {
    name: 'SaferNet Brasil - Central Nacional de Denúncias',
    submit: 'https://new.safernet.org.br/denuncie',
    checklist: [
      'Report the URL / content identifiers (SaferNet forwards to the Ministério Público Federal / PF).',
      'Do not upload images; give identifiers and the preserved-evidence reference.',
      'Record the protocol number with "Mark reported".',
    ],
  },
};

const iso = (v: any): string | null => (v?.toDate ? v.toDate().toISOString() : typeof v === 'string' ? v : null);

/**
 * Builds the report package for a CSAE case from the case, its legal hold
 * and the preserved snapshots. Stored under the hold; returned to the
 * superAdmin. Nothing is sent anywhere.
 */
export async function buildReportPackage(p: {
  caseId: string;
  caseData: Record<string, any>;
  authority: Authority;
  generatedBy: string;
}): Promise<{ packageId: string; holdId: string | null; pkg: Record<string, any> }> {
  const c = p.caseData;
  const holdId: string | null = c.legalHoldId ?? null;
  const preserved = holdId
    ? (await db().collection(LEGAL_HOLDS).doc(holdId).collection('preserved').limit(500).get()).docs.map((d) => d.data())
    : [];
  const byPath = (prefix: string) => preserved.filter((x) => typeof x.path === 'string' && x.path.startsWith(prefix));
  const authUser = preserved.find((x) => x.path?.startsWith('auth/'))?.data ?? null;
  const profile = byPath('profiles/')[0]?.data ?? null;
  const user = byPath('users/')[0]?.data ?? null;
  const accessLogs = byPath('access_logs/').map((x) => ({
    ip: x.data?.ip ?? x.data?.ipAddress ?? null,
    port: x.data?.port ?? null,
    at: x.data?.timestamp ?? x.data?.createdAt ?? null,
    event: x.data?.event ?? null,
  }));
  const audit = (await db().collection('safety_cases').doc(p.caseId).collection('audit').orderBy('at').limit(200).get())
    .docs.map((d) => ({ ...plain(d.data()), id: d.id }));
  let files: Array<Record<string, any>> = [];
  if (holdId) {
    const [fs] = await admin.storage().bucket().getFiles({ prefix: `legal_holds/${holdId}/files/`, maxResults: 500 });
    files = fs.map((f) => ({
      legalHoldPath: f.name,
      originalPath: f.name.replace(`legal_holds/${holdId}/files/`, ''),
      contentType: f.metadata?.contentType ?? null,
      size: Number(f.metadata?.size ?? 0),
      md5Base64: f.metadata?.md5Hash ?? null,
      storedAt: f.metadata?.timeCreated ?? null,
    }));
  }
  const hiddenHashes = (Array.isArray(c.hidden) ? c.hidden : [])
    .filter((h: any) => h?.hashes)
    .map((h: any) => ({ originalPath: h.path, sha256: h.hashes.sha256, md5: h.hashes.md5, sha1: h.hashes.sha1 }));

  const pkg = {
    packageVersion: 1,
    generatedAt: new Date().toISOString(),
    generatedBy: p.generatedBy,
    authority: { code: p.authority, ...AUTHORITY_INFO[p.authority] },
    reportingProvider: {
      name: 'GreenGo (greengochat.com)',
      contactEmail: 'info@greengochat.com',
      note: 'Fill the ESP id / CNPJ and the legal contact from the runbook before submitting.',
    },
    incident: {
      caseId: p.caseId,
      kind: c.kind,
      source: c.source,
      detectedVia: c.hashMatch ? `hash match (${c.hashMatch.list}, ${c.hashMatch.how})` : c.source,
      reasonCode: c.reasonCode ?? 'csae',
      reportedAt: iso(c.createdAt),
      contentHiddenAt: iso(c.hiddenAt),
      sourceReport: c.sourceReport ?? null,
    },
    reportedPerson: {
      uid: c.reportedUserId ?? null,
      email: authUser?.email ?? user?.email ?? null,
      phone: authUser?.phoneNumber ?? null,
      displayName: profile?.displayName ?? authUser?.displayName ?? null,
      nickname: profile?.nickname ?? null,
      accountCreatedAt: authUser?.creationTime ?? null,
      lastSignInAt: authUser?.lastSignInTime ?? null,
      country: profile?.location?.country ?? null,
      ipLogs: accessLogs.length ? accessLogs : 'not available - access logging (audit BR-09) not enabled when the content was uploaded',
    },
    content: { files, hashes: hiddenHashes, contentRefs: c.contentRefs ?? [] },
    legalHold: holdId ? { holdId, storagePrefix: `legal_holds/${holdId}/files/` } : null,
    timeline: audit,
    previousReports: c.reportedTo ?? [],
  };
  const ref = holdId
    ? db().collection(LEGAL_HOLDS).doc(holdId).collection('report_packages').doc()
    : db().collection('safety_cases').doc(p.caseId).collection('report_packages').doc();
  await ref.set({ ...pkg, caseId: p.caseId, createdAt: TS.now() });
  return { packageId: ref.id, holdId, pkg };
}

// ---------------------------------------------------------------------------
// Expiry
// ---------------------------------------------------------------------------

export async function runLegalHoldExpirySweep(nowMs = Date.now(), autoPurge = false): Promise<{ expired: string[]; purged: string[] }> {
  const s = await db().collection(LEGAL_HOLDS)
    .where('status', '==', 'active')
    .where('holdUntil', '<=', TS.fromMillis(nowMs))
    .limit(50)
    .get();
  const expired: string[] = [];
  const purged: string[] = [];
  for (const d of s.docs) {
    if (!autoPurge) {
      await d.ref.update({ status: 'expired_pending_purge', expiredAt: TS.fromMillis(nowMs) });
      expired.push(d.id);
      continue;
    }
    const [fs] = await admin.storage().bucket().getFiles({ prefix: `legal_holds/${d.id}/` });
    for (const f of fs) await f.delete({ ignoreNotFound: true });
    for (const sub of ['preserved', 'report_packages']) await db().recursiveDelete(d.ref.collection(sub));
    const uid = d.data().subjectUid;
    await d.ref.set({
      status: 'purged',
      purgedAt: TS.fromMillis(nowMs),
      subjectUid: null,
      subjectUidHash: uid ? crypto.createHash('sha256').update(`legal-hold:${uid}`).digest('hex') : null,
    }, { merge: true });
    purged.push(d.id);
  }
  return { expired, purged };
}
