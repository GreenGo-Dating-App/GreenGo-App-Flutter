/**
 * Data-subject access and portability (P3-2; GDPR Art. 15 and 20, LGPD Art. 18
 * II and V, UK GDPR Art. 15 and 20).
 *
 *  - exportMyData (callable, app + web): signed in within the last 10 minutes,
 *    at most one successful export per 24 h. Builds a ZIP of everything held
 *    about the caller, uploads it to the PRIVATE path
 *    `exports/{uid}/{timestamp}.zip` (default bucket; storage.rules deny all
 *    client access), returns a 24 h signed URL and also emails it (Resend).
 *  - cleanupDataExports (scheduled, daily): deletes export files older than
 *    7 days.
 *
 * WHAT IS IN THE ZIP (driven by ACCOUNT_DATA_INVENTORY, the same list account
 * deletion uses, so a new per-user collection is exported as soon as it is
 * added there):
 *   account/      Auth record (email, phone, providers, dates), profiles/{uid},
 *                 users/{uid}, profiles_private/{uid}, consents/{uid} (+events)
 *   data/         one JSON (and a CSV when there is more than one record) per
 *                 inventory location that holds something
 *   messages/     the messages the CALLER sent (all conversations / groups /
 *                 communities / events), JSON + CSV
 *   conversations/ metadata only of the caller's conversations and groups
 *   media/        the caller's own uploads (profile photos, voice/video intros,
 *                 verification selfies, chat media the caller sent), capped
 *   manifest.json, README.txt
 *
 * WHAT IS LEFT OUT, ON PURPOSE (other people's rights, GDPR Art. 15(4)/20(4),
 * LGPD Art. 18 §... "segredos comercial e industrial" + third-party data):
 *   - messages other people sent, and their names/photos;
 *   - records where the caller is only the OBJECT of someone else's action
 *     (who swiped on / blocked / liked the caller): they would expose the other
 *     person, and "who blocked me" is a safety risk;
 *   - other users' ids anywhere in exported records are replaced by
 *     "other_user" (redactOthers below);
 *   - conversation backups the user made (they contain the other person's
 *     messages; they can be downloaded in-app from the backup feature);
 *   - identity-document images (deleted after the age decision; legacy legal
 *     holds are handled by support).
 */

import { onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { AppError, handleError } from '../shared/utils';
import { monitored } from '../shared/monitoring';
import { sendResendEmail } from '../shared/resendEmail';
import { ZipStreamWriter } from '../shared/zipWriter';
import {
  ACCOUNT_DATA_INVENTORY,
  InventoryEntry,
  SHARED_MEDIA_PREFIXES,
  storagePathFromUrl,
} from './accountDeletion';
import { RECENT_AUTH_SECONDS } from './accountDeletionEndpoints';

const db = () => admin.firestore();
const TS = () => admin.firestore.Timestamp.now();

export const DATA_EXPORTS = 'data_exports';
export const EXPORT_PREFIX = 'exports';
export const EXPORT_RATE_WINDOW_MS = 24 * 60 * 60 * 1000;
export const EXPORT_LINK_TTL_MS = 24 * 60 * 60 * 1000;
export const EXPORT_RETENTION_MS = 7 * 24 * 60 * 60 * 1000;
/** A run that has not finished after this long is considered dead. */
const RUN_STALE_MS = 15 * 60 * 1000;

const PAGE = 500;
/** Per-location cap; beyond it the manifest says the list is truncated. */
const MAX_DOCS_PER_SECTION = 50_000;
const MAX_MESSAGES = 200_000;
const MAX_TREE_DEPTH = 3;
/** Media embedded in the ZIP: per file and in total. */
const MAX_FILE_BYTES = 60 * 1024 * 1024;
const MAX_MEDIA_BYTES = 500 * 1024 * 1024;
/** Stop adding media after this much wall time (function timeout 540 s). */
const MEDIA_DEADLINE_MS = 360_000;

/**
 * Inventory query fields where the caller is the OBJECT of another user's
 * action. Not exported (see header).
 */
export const OBJECT_OF_OTHERS_FIELDS: Record<string, string[]> = {
  user_interactions: ['targetUserId'],
  swipes: ['targetUserId'],
  blockedUsers: ['blockedUserId'],
  user_blocks: ['blockedUserId'],
  photo_likes: ['profileUserId'],
};

/** Storage prefixes of the caller's own uploads that go into media/. */
export const OWN_MEDIA_PREFIXES = [
  'profiles', 'users', 'video_profiles', 'voice_intros', 'verifications', 'verification', 'voice',
  'communities', 'business_verification',
];

// ---------------------------------------------------------------------------
// Serialisation + redaction
// ---------------------------------------------------------------------------

/** Firestore values -> plain JSON. */
export function toPlain(v: any): any {
  if (v === null || v === undefined) return v ?? null;
  if (v instanceof admin.firestore.Timestamp) return v.toDate().toISOString();
  if (v instanceof Date) return v.toISOString();
  if (v instanceof admin.firestore.GeoPoint) return { latitude: v.latitude, longitude: v.longitude };
  if (v instanceof admin.firestore.DocumentReference) return v.path;
  if (Buffer.isBuffer(v)) return v.toString('base64');
  if (typeof v?.toBase64 === 'function') return v.toBase64();
  if (Array.isArray(v)) return v.map(toPlain);
  if (typeof v === 'object') {
    const o: Record<string, any> = {};
    for (const [k, x] of Object.entries(v)) o[k] = toPlain(x);
    return o;
  }
  return v;
}

/** Keys that hold a PERSON's id (a value != caller is replaced). */
const PERSON_ID_KEY = new RegExp(
  '^(?:(?:user|sender|receiver|recipient|target|targetUser|liker|liked|likedUser|blocker|blocked|blockedUser|' +
    'owner|host|guest|participant|member|grantedTo|granted|related|relatedUser|reporter|reported|reportedUser|' +
    'matched|matchedUser|partner|friend|follower|following|author|creator|createdBy|organizer|viewer|other|' +
    'otherUser|from|fromUser|to|toUser|invitedBy|inviter|invitee|referrer|referred|referredUser|reviewer|' +
    'reviewee|visitor|requester|gifter|giftedBy)\\d*(?:Id|Ids|ID|Uid|Uids)\\d*' +
    '|uid|createdBy|invitedBy|blockedBy|reportedBy|grantedBy|giftedBy|sentBy)$',
  'i',
);
const PERSON_LIST_KEYS = new Set([
  'participants', 'participantIds', 'users', 'userIds', 'members', 'memberIds', 'blockedUsers',
  'readBy', 'deliveredTo', 'seenBy', 'likedBy', 'mutedBy', 'archivedBy', 'admins', 'moderators',
]);
/** `<role><Name|Photo...>` fields: dropped unless `<role>Id` is the caller. */
const PERSON_ATTR_KEY = new RegExp(
  '^(user|sender|receiver|recipient|other|otherUser|partner|matched|matchedUser|target|targetUser|liker|reporter|' +
    'reported|host|guest|author|organizer|from|to|related|reviewer|requester|inviter|liked|blocked|creator|owner)' +
    '(\\d*)(?:User)?(Name|DisplayName|Nickname|Username|Photo|PhotoUrl|PhotoURL|Photos|Avatar|AvatarUrl|Email|Phone|Age|Country|Bio)$',
  'i',
);
/** Map keys that look like a Firebase uid. */
const UID_LIKE = /^[A-Za-z0-9]{20,36}$/;
export const OTHER = 'other_user';

/**
 * Removes other people's identifiers from a plain record: person-id fields
 * whose value is not the caller become "other_user", person name/photo fields
 * that belong to someone else are dropped, and map keys that look like
 * another user's uid are replaced.
 */
export function redactOthers(v: any, uid: string, parentKey = ''): any {
  if (Array.isArray(v)) {
    if (PERSON_LIST_KEYS.has(parentKey) || PERSON_ID_KEY.test(parentKey)) {
      return v.map((x) => (typeof x === 'string' && x !== uid ? OTHER : redactOthers(x, uid)));
    }
    return v.map((x) => redactOthers(x, uid));
  }
  if (!v || typeof v !== 'object') {
    if (typeof v === 'string' && parentKey && v !== uid && PERSON_ID_KEY.test(parentKey)) return OTHER;
    return v;
  }
  const out: Record<string, any> = {};
  let n = 0;
  for (const [k, x] of Object.entries(v)) {
    const attr = k.match(PERSON_ATTR_KEY);
    if (attr) {
      // Kept only when the matching id field (senderId, user2Id, fromUserId,
      // ...) in the same record is the caller.
      const ids = [`${attr[1]}${attr[2]}id`, `${attr[1]}${attr[2]}userid`, `${attr[1]}userid`].map((x) => x.toLowerCase());
      const mine = Object.keys(v).some((kk) => ids.includes(kk.toLowerCase()) && v[kk] === uid);
      if (!mine) continue;
    }
    let key = k;
    if (k !== uid && UID_LIKE.test(k) && /[0-9]/.test(k) && /[A-Za-z]/.test(k)) key = `${OTHER}_${++n}`;
    out[key] = redactOthers(x, uid, k);
  }
  return out;
}

/** Flat CSV of records (nested values as JSON). */
export function toCsv(rows: Array<Record<string, any>>): string {
  const cols: string[] = [];
  const seen = new Set<string>();
  for (const r of rows) for (const k of Object.keys(r)) if (!seen.has(k)) { seen.add(k); cols.push(k); }
  const cell = (x: any) => {
    if (x === null || x === undefined) return '';
    let s = typeof x === 'object' ? JSON.stringify(x) : String(x);
    // Spreadsheet formula injection guard.
    if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
    return /[",\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  return '﻿' + [cols.join(','), ...rows.map((r) => cols.map((c) => cell(r[c])).join(','))].join('\r\n') + '\r\n';
}

// ---------------------------------------------------------------------------
// Readers
// ---------------------------------------------------------------------------

interface Section {
  file: string;
  source: string;
  records: Array<Record<string, any>>;
  truncated?: boolean;
}

type Snap = FirebaseFirestore.DocumentSnapshot;

function record(snap: Snap, uid: string, extra: Record<string, any> = {}): Record<string, any> {
  return { _id: snap.id, _path: snap.ref.path.split(uid).join('{you}'), ...extra, ...redactOthers(toPlain(snap.data() || {}), uid) };
}

/** A document and (recursively, bounded) its subcollections. */
async function readTree(ref: FirebaseFirestore.DocumentReference, uid: string, depth: number, out: Array<Record<string, any>>) {
  const snap = await ref.get();
  if (snap.exists) out.push(record(snap, uid));
  if (depth >= MAX_TREE_DEPTH || out.length >= MAX_DOCS_PER_SECTION) return;
  for (const col of await ref.listCollections()) {
    let last: Snap | null = null;
    for (;;) {
      let q = col.orderBy(admin.firestore.FieldPath.documentId()).limit(PAGE);
      if (last) q = q.startAfter(last);
      const page = await q.get();
      for (const d of page.docs) {
        out.push(record(d, uid));
        if (depth + 1 < MAX_TREE_DEPTH) {
          for (const sub of await d.ref.listCollections()) {
            const s = await sub.limit(PAGE).get();
            s.docs.forEach((x) => out.push(record(x, uid)));
          }
        }
      }
      if (page.size < PAGE || out.length >= MAX_DOCS_PER_SECTION) break;
      last = page.docs[page.docs.length - 1];
    }
  }
}

/** Cursor-paged query (nothing is modified, so offsets come from cursors). */
async function readQuery(
  q: FirebaseFirestore.Query,
  each: (d: FirebaseFirestore.QueryDocumentSnapshot) => void,
  max = MAX_DOCS_PER_SECTION,
): Promise<{ count: number; truncated: boolean }> {
  let last: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  let count = 0;
  for (;;) {
    let qq = q.orderBy(admin.firestore.FieldPath.documentId()).limit(PAGE);
    if (last) qq = qq.startAfter(last);
    const page = await qq.get();
    for (const d of page.docs) {
      each(d);
      if (++count >= max) return { count, truncated: true };
    }
    if (page.size < PAGE) return { count, truncated: false };
    last = page.docs[page.docs.length - 1];
  }
}

const safeName = (s: string) => s.replace(/[^A-Za-z0-9_.-]+/g, '_');

/** Conversation / group metadata only (no other members, no previews). */
function conversationMeta(snap: Snap, uid: string): Record<string, any> {
  const d = toPlain(snap.data() || {});
  const members: unknown[] = Array.isArray(d.participants) ? d.participants
    : Array.isArray(d.members) ? d.members : [d.userId1, d.userId2].filter(Boolean);
  const isGroup = d.isGroup === true || snap.ref.parent.id === 'groups';
  const meta: Record<string, any> = {
    _path: snap.ref.path,
    conversationId: snap.id,
    kind: isGroup ? 'group' : 'one_to_one',
    createdAt: d.createdAt ?? null,
    updatedAt: d.updatedAt ?? d.lastMessageAt ?? null,
    participantCount: members.length,
  };
  if (isGroup && typeof d.name === 'string') meta.groupName = d.name;
  if (isGroup && (d.createdBy === uid || d.createdByUserId === uid || d.ownerId === uid)) meta.youCreatedIt = true;
  for (const f of ['mutedBy', 'archivedBy', 'pinnedBy']) {
    if (Array.isArray(d[f])) meta[f.replace('By', '')] = d[f].includes(uid);
  }
  return meta;
}

// ---------------------------------------------------------------------------
// Builder
// ---------------------------------------------------------------------------

export interface ExportResult {
  objectPath: string;
  bytes: number;
  sections: Array<{ file: string; source: string; count: number; truncated?: boolean }>;
  mediaFiles: number;
  mediaNotIncluded: string[];
}

function readme(uid: string, generatedAt: string): string {
  return [
    'GreenGo - your data / seus dados',
    '=================================',
    '',
    `Account: ${uid}`,
    `Generated: ${generatedAt}`,
    '',
    'This archive contains the personal data GreenGo holds about you (GDPR Art. 15 and 20,',
    'LGPD Art. 18). Files:',
    '  account/        your sign-in record, profile, private profile fields, consents',
    '  data/           everything else stored for your account (JSON; CSV for lists)',
    '  messages/       the messages YOU sent (JSON and CSV)',
    '  conversations/  basic information about your conversations and groups',
    '  media/          photos, audio and video you uploaded',
    '  manifest.json   what is in each file, and what was left out and why',
    '',
    'Not included, to protect other people: messages other people sent you, their names',
    'and photos, and records of what other people did about you (for example who blocked',
    'or liked you). Other people\'s ids are shown as "other_user".',
    'Payment records we must keep by law are included as they are stored today.',
    '',
    'Questions: info@greengochat.com',
    '',
    'Este arquivo contem os dados pessoais que o GreenGo mantem sobre voce (LGPD art. 18;',
    'GDPR art. 15 e 20). Por respeito a outras pessoas, nao inclui mensagens enviadas por',
    'outros usuarios nem registros do que outras pessoas fizeram em relacao a voce.',
    'Duvidas: info@greengochat.com',
    '',
  ].join('\n');
}

/**
 * Collects all sections for [uid]. Pure Firestore/Auth reads; nothing is
 * modified. Exported for tests.
 */
export async function collectSections(uid: string): Promise<{ sections: Section[]; mediaPaths: string[] }> {
  const sections: Section[] = [];
  const mediaPaths: string[] = [];
  const add = (file: string, source: string, records: Array<Record<string, any>>, truncated = false) => {
    if (records.length) sections.push({ file, source, records, ...(truncated ? { truncated } : {}) });
  };

  // --- Account ---------------------------------------------------------------
  try {
    const u = await admin.auth().getUser(uid);
    add('account/auth', 'Firebase Authentication', [{
      uid: u.uid,
      email: u.email ?? null,
      emailVerified: u.emailVerified,
      phoneNumber: u.phoneNumber ?? null,
      displayName: u.displayName ?? null,
      photoURL: u.photoURL ?? null,
      disabled: u.disabled,
      signInProviders: u.providerData.map((p) => p.providerId),
      createdAt: u.metadata.creationTime ?? null,
      lastSignInAt: u.metadata.lastSignInTime ?? null,
      lastActiveAt: (u.metadata as any).lastRefreshTime ?? null,
      customClaims: u.customClaims ?? {},
    }]);
  } catch (e: any) {
    if (e?.code !== 'auth/user-not-found') throw e;
  }
  for (const c of ['profiles', 'users', 'profiles_private', 'consents']) {
    const recs: Array<Record<string, any>> = [];
    await readTree(db().collection(c).doc(uid), uid, 0, recs);
    add(`account/${c}`, `${c}/{you}`, recs);
  }

  // --- Inventory ---------------------------------------------------------------
  const convIds = new Map<string, FirebaseFirestore.DocumentReference>();
  const done = new Set<string>(['doc:profiles_private']);
  for (const e of ACCOUNT_DATA_INVENTORY as InventoryEntry[]) {
    switch (e.kind) {
      case 'doc':
      case 'path': {
        const path = e.kind === 'doc' ? `${e.collection}/${uid}` : e.path.replace('{uid}', uid);
        const key = `doc:${e.kind === 'doc' ? e.collection : e.path}`;
        if (done.has(key)) break;
        done.add(key);
        const recs: Array<Record<string, any>> = [];
        await readTree(db().doc(path), uid, e.recursive === false ? MAX_TREE_DEPTH : 0, recs);
        add(`data/${safeName(e.kind === 'doc' ? e.collection : e.path)}`, path.split(uid).join('{you}'), recs);
        break;
      }
      case 'idPrefix': {
        const recs: Array<Record<string, any>> = [];
        const s = await db().collection(e.collection)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAt(`${uid}_`).endAt(`${uid}_`).limit(MAX_DOCS_PER_SECTION).get();
        s.docs.forEach((d) => recs.push(record(d, uid)));
        add(`data/${safeName(e.collection)}__by_id`, `${e.collection}/{you}_*`, recs);
        break;
      }
      case 'query':
      case 'finance': {
        if (e.kind === 'finance' && e.byDocId) {
          const key = `doc:${e.collection}`;
          if (done.has(key)) break;
          done.add(key);
          const recs: Array<Record<string, any>> = [];
          await readTree(db().collection(e.collection).doc(uid), uid, 0, recs);
          add(`data/${safeName(e.collection)}`, `${e.collection}/{you}`, recs);
          break;
        }
        const field = e.field!;
        if (OBJECT_OF_OTHERS_FIELDS[e.collection]?.includes(field)) break;
        const recs: Array<Record<string, any>> = [];
        const arrayContains = e.kind === 'query' && e.arrayContains;
        const r = await readQuery(
          db().collection(e.collection).where(field, arrayContains ? 'array-contains' : '==', uid),
          (d) => recs.push(record(d, uid)),
        );
        add(`data/${safeName(e.collection)}__${safeName(field)}`, `${e.collection} where ${field} = you`, recs, r.truncated);
        break;
      }
      case 'supportChats': {
        const recs: Array<Record<string, any>> = [];
        const msgs: Array<Record<string, any>> = [];
        await readQuery(db().collection('support_chats').where('userId', '==', uid), (d) => recs.push(record(d, uid)));
        for (const c of recs) {
          const ref = db().collection('support_chats').doc(c._id);
          const sub = await ref.collection('messages').limit(MAX_DOCS_PER_SECTION).get();
          sub.docs.forEach((d) => msgs.push(record(d, uid, { ticketId: c._id })));
          await readQuery(db().collection('support_messages').where('conversationId', '==', c._id),
            (d) => msgs.push(record(d, uid, { ticketId: c._id })));
        }
        add('data/support_tickets', 'support_chats where userId = you', recs);
        add('data/support_ticket_messages', 'support messages of your tickets', msgs);
        break;
      }
      case 'group': {
        const recs: Array<Record<string, any>> = [];
        const r = await readQuery(db().collectionGroup(e.group).where(e.field, '==', uid),
          (d) => recs.push(record(d, uid, { parent: d.ref.parent.parent?.path ?? null })));
        add(`data/memberships__${safeName(e.group)}`, `*/${e.group} where ${e.field} = you`, recs, r.truncated);
        break;
      }
      case 'scrub': {
        if (e.collection === 'conversations' || e.collection === 'groups') {
          await readQuery(
            db().collection(e.collection).where(e.field, e.arrayContains ? 'array-contains' : '==', uid),
            (d) => { convIds.set(d.ref.path, d.ref); },
          );
          break;
        }
        const recs: Array<Record<string, any>> = [];
        const r = await readQuery(
          db().collection(e.collection).where(e.field, e.arrayContains ? 'array-contains' : '==', uid),
          (d) => recs.push(record(d, uid)),
        );
        add(`data/${safeName(e.collection)}__${safeName(e.field)}`, `${e.collection} where ${e.field} = you`, recs, r.truncated);
        break;
      }
      case 'anonymise': {
        // The caller's OWN messages (collection group 'messages' = 1:1, groups,
        // communities, events, legacy). Other people's messages are never read.
        const recs: Array<Record<string, any>> = [];
        const base = e.topLevelOnly ? db().collection(e.group) : db().collectionGroup(e.group);
        if (e.group === 'support_messages') break; // covered by supportChats
        const r = await readQuery(base.where(e.field, '==', uid), (d) => {
          const rec = record(d, uid, { conversation: d.ref.parent.parent?.path ?? null });
          recs.push(rec);
          const data = d.data();
          for (const f of ['content', 'imageUrl', 'mediaUrl', 'voiceUrl', 'audioUrl', 'videoUrl', 'fileUrl']) {
            const p = storagePathFromUrl(data[f]);
            if (p && SHARED_MEDIA_PREFIXES.some((pre) => p.startsWith(pre))) mediaPaths.push(p);
          }
        }, MAX_MESSAGES);
        add('messages/my_messages', 'messages you sent (all conversations)', recs, r.truncated);
        break;
      }
      case 'storage': {
        if (e.buckets === 'backup' || !OWN_MEDIA_PREFIXES.includes(e.prefix)) break;
        const [files] = await admin.storage().bucket().getFiles({ prefix: `${e.prefix}/${uid}/`, maxResults: 2000 });
        files.forEach((f) => mediaPaths.push(f.name));
        break;
      }
      // arrayRemove / replaceField: other people's records that mention the
      // caller (e.g. their block lists). Not the caller's data to receive.
      default:
        break;
    }
  }

  const convs: Array<Record<string, any>> = [];
  const refs = Array.from(convIds.values());
  for (let i = 0; i < refs.length; i += 100) {
    const snaps = await db().getAll(...refs.slice(i, i + 100));
    snaps.filter((s) => s.exists).forEach((s) => convs.push(conversationMeta(s, uid)));
  }
  add('conversations/conversations', 'conversations and groups you are in (metadata only)', convs);

  return { sections, mediaPaths: Array.from(new Set(mediaPaths)) };
}

/** Builds the ZIP and uploads it to exports/{uid}/{ts}.zip. */
export async function buildExport(uid: string, ts: number): Promise<ExportResult> {
  const started = Date.now();
  const generatedAt = new Date(ts).toISOString();
  const { sections, mediaPaths } = await collectSections(uid);
  const bucket = admin.storage().bucket();
  const objectPath = `${EXPORT_PREFIX}/${uid}/${ts}.zip`;
  const file = bucket.file(objectPath);
  const out = file.createWriteStream({
    resumable: false,
    metadata: {
      contentType: 'application/zip',
      contentDisposition: `attachment; filename="greengo-data-${generatedAt.slice(0, 10)}.zip"`,
      cacheControl: 'private, no-store',
      metadata: { kind: 'data_export', uid },
    },
  });
  let streamError: Error | null = null;
  out.on('error', (err) => { streamError = err; });
  const zip = new ZipStreamWriter(out);

  const manifest: ExportResult['sections'] = [];
  await zip.add('README.txt', readme(uid, generatedAt));
  for (const s of sections) {
    await zip.add(`${s.file}.json`, JSON.stringify(s.records, null, 2));
    if (s.records.length > 1) await zip.add(`${s.file}.csv`, toCsv(s.records));
    manifest.push({ file: `${s.file}.json`, source: s.source, count: s.records.length, ...(s.truncated ? { truncated: true } : {}) });
    if (streamError) throw streamError;
  }

  let mediaBytes = 0;
  let mediaFiles = 0;
  const notIncluded: string[] = [];
  for (const p of mediaPaths) {
    const shown = p.split(uid).join('{you}');
    if (Date.now() - started > MEDIA_DEADLINE_MS) { notIncluded.push(`${shown} (time limit)`); continue; }
    try {
      const f = bucket.file(p);
      const [meta] = await f.getMetadata();
      const size = Number(meta.size ?? 0);
      if (size > MAX_FILE_BYTES || mediaBytes + size > MAX_MEDIA_BYTES) { notIncluded.push(`${shown} (size limit)`); continue; }
      const [buf] = await f.download();
      mediaBytes += buf.length;
      await zip.add(`media/${shown.replace('{you}', 'you')}`, buf);
      mediaFiles++;
    } catch (e: any) {
      if (e?.code !== 404) notIncluded.push(`${shown} (could not be read)`);
    }
    if (streamError) throw streamError;
  }

  await zip.add('manifest.json', JSON.stringify({
    format: 'greengo-data-export/1',
    account: uid,
    generatedAt,
    sections: manifest,
    media: { included: mediaFiles, bytes: mediaBytes, notIncluded },
    leftOut: [
      'Messages other people sent, and their names and photos (their personal data).',
      'Records where you are only the object of another person\'s action (who swiped on, liked or blocked you).',
      'Conversation backups you created (they contain the other person\'s messages); download them in-app.',
      'Identity-document images (deleted after the age decision).',
    ],
    otherPeople: 'Other users\' ids are replaced by "other_user".',
  }, null, 2));
  await zip.finish();
  if (streamError) throw streamError;
  return { objectPath, bytes: zip.bytesWritten, sections: manifest, mediaFiles, mediaNotIncluded: notIncluded };
}

/** 24 h read link. The emulator has no signer: use its download endpoint. */
export async function exportDownloadUrl(objectPath: string, expiresAtMs: number): Promise<string> {
  const bucket = admin.storage().bucket();
  const emu = process.env.FIREBASE_STORAGE_EMULATOR_HOST || process.env.STORAGE_EMULATOR_HOST;
  if (emu) {
    const host = emu.replace(/^https?:\/\//, '');
    return `http://${host}/v0/b/${bucket.name}/o/${encodeURIComponent(objectPath)}?alt=media`;
  }
  const [url] = await bucket.file(objectPath).getSignedUrl({ action: 'read', expires: expiresAtMs, version: 'v4' });
  return url;
}

function exportEmailHtml(link: string, expiresAt: Date): string {
  const until = expiresAt.toUTCString();
  return `<!DOCTYPE html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="font-family:Helvetica,Arial,sans-serif;background:#0A0A0A;color:#fff;padding:32px">
<div style="max-width:520px;margin:0 auto;background:#1A1A1A;border-radius:16px;padding:32px;border:1px solid #2A2A2A">
<h2 style="margin-top:0">Your GreenGo data is ready</h2>
<p>You asked for a copy of your GreenGo data. Download it with the link below. The link works until ${until} and the file is deleted after 7 days.</p>
<p style="text-align:center;margin:28px 0"><a href="${link}" style="background:#D4AF37;color:#0A0A0A;font-weight:bold;padding:14px 32px;border-radius:12px;text-decoration:none">Download my data</a></p>
<p style="color:#bbb;font-size:13px">Seus dados do GreenGo est&atilde;o prontos. Baixe pelo link acima (v&aacute;lido por 24 horas; o arquivo &eacute; apagado ap&oacute;s 7 dias).</p>
<p style="color:#999;font-size:13px">If you did not ask for this, change your password and contact info@greengochat.com.</p>
</div></body></html>`;
}

// ---------------------------------------------------------------------------
// exportMyData
// ---------------------------------------------------------------------------

/** Claims today's export for [uid]; throws AppError when not allowed. */
async function claimRun(uid: string, now: number): Promise<void> {
  const ref = db().collection(DATA_EXPORTS).doc(uid);
  await db().runTransaction(async (tx) => {
    const d = (await tx.get(ref)).data();
    const running = d?.status === 'running' && now - (d.startedAt?.toMillis?.() ?? 0) < RUN_STALE_MS;
    if (running) {
      throw new AppError('EXPORT_IN_PROGRESS', 'Your data export is already being prepared.', 429,
        { reason: 'EXPORT_IN_PROGRESS' });
    }
    const last = d?.lastSuccessAt?.toMillis?.() ?? 0;
    if (last && now - last < EXPORT_RATE_WINDOW_MS) {
      throw new AppError('RATE_LIMITED', 'You can download your data once every 24 hours.', 429, {
        reason: 'RATE_LIMITED',
        retryAfterSeconds: Math.ceil((last + EXPORT_RATE_WINDOW_MS - now) / 1000),
      });
    }
    tx.set(ref, { status: 'running', startedAt: admin.firestore.Timestamp.fromMillis(now) }, { merge: true });
  });
}

export async function runExportMyData(request: { auth?: { uid?: string; token?: any } }) {
  const uid = request.auth?.uid;
  if (!uid) throw new AppError('UNAUTHENTICATED', 'User must be authenticated', 401);
  const authTime = Number(request.auth?.token?.auth_time);
  if (!Number.isFinite(authTime) || Date.now() / 1000 - authTime > RECENT_AUTH_SECONDS) {
    throw new AppError('REQUIRES_RECENT_LOGIN', 'Please sign in again to download your data.', 401,
      { reason: 'REQUIRES_RECENT_LOGIN', maxAgeSeconds: RECENT_AUTH_SECONDS });
  }

  const now = Date.now();
  await claimRun(uid, now);
  const ref = db().collection(DATA_EXPORTS).doc(uid);
  const runRef = ref.collection('runs').doc(String(now));
  await runRef.set({ requestedAt: admin.firestore.Timestamp.fromMillis(now), status: 'running' });

  try {
    const result = await buildExport(uid, now);
    const expiresAt = now + EXPORT_LINK_TTL_MS;
    const url = await exportDownloadUrl(result.objectPath, Date.now() + EXPORT_LINK_TTL_MS);

    let emailSent = false;
    const email = await admin.auth().getUser(uid).then((u) => u.email, () => undefined);
    if (email) {
      emailSent = (await sendResendEmail(email, 'Your GreenGo data is ready',
        exportEmailHtml(url, new Date(expiresAt)))).emailSent;
    }

    const doneAt = TS();
    await runRef.set({
      status: 'done', completedAt: doneAt, objectPath: result.objectPath, sizeBytes: result.bytes,
      sections: result.sections.length, mediaFiles: result.mediaFiles, emailSent,
      linkExpiresAt: admin.firestore.Timestamp.fromMillis(expiresAt),
      deleteAfter: admin.firestore.Timestamp.fromMillis(now + EXPORT_RETENTION_MS),
    }, { merge: true });
    await ref.set({
      status: 'done', lastSuccessAt: admin.firestore.Timestamp.fromMillis(now), lastObjectPath: result.objectPath,
      count: admin.firestore.FieldValue.increment(1), updatedAt: doneAt,
    }, { merge: true });
    console.log(`exportMyData: ${uid} - ${result.bytes} bytes, ${result.sections.length} sections, ${result.mediaFiles} media`);
    return {
      success: true,
      url,
      expiresAt: new Date(expiresAt).toISOString(),
      sizeBytes: result.bytes,
      emailSent,
    };
  } catch (e: any) {
    // A failed run does not use up the daily export.
    console.error(`exportMyData: failed for ${uid}`, e?.message || e);
    await runRef.set({ status: 'failed', failedAt: TS(), error: String(e?.message || e).slice(0, 300) }, { merge: true })
      .catch(() => undefined);
    await ref.set({ status: 'failed', updatedAt: TS() }, { merge: true }).catch(() => undefined);
    throw new AppError('EXPORT_FAILED', 'We could not prepare your data. Please try again later.', 500,
      { reason: 'EXPORT_FAILED' });
  }
}

export const exportMyData = onCall(
  { memory: '1GiB', timeoutSeconds: 540, maxInstances: 20 },
  monitored('exportMyData', async (request: any) => {
    try {
      return await runExportMyData(request);
    } catch (e) {
      throw handleError(e instanceof AppError ? e
        : new AppError('EXPORT_FAILED', 'We could not prepare your data. Please try again later.', 500, { reason: 'EXPORT_FAILED' }));
    }
  }),
);

// ---------------------------------------------------------------------------
// cleanupDataExports
// ---------------------------------------------------------------------------

const EXPORT_OBJECT = /^exports\/[^/]+\/\d+\.zip$/;

/** Deletes export ZIPs older than 7 days. Returns how many were deleted. */
export async function cleanupExpiredExports(nowMs = Date.now()): Promise<number> {
  const bucket = admin.storage().bucket();
  let deleted = 0;
  let pageToken: string | undefined;
  do {
    const [files, next] = await bucket.getFiles({
      prefix: `${EXPORT_PREFIX}/`, maxResults: 1000, autoPaginate: false, pageToken,
    }) as any;
    for (const f of files as any[]) {
      if (!EXPORT_OBJECT.test(f.name)) continue;
      // The name carries the creation time; metadata is the fallback.
      const ts = Number(f.name.slice(f.name.lastIndexOf('/') + 1, -4));
      const created = Number.isFinite(ts) && ts > 0 ? ts : Date.parse(f.metadata?.timeCreated ?? '');
      if (Number.isFinite(created) && nowMs - created >= EXPORT_RETENTION_MS) {
        await f.delete({ ignoreNotFound: true });
        deleted++;
      }
    }
    pageToken = next?.pageToken;
  } while (pageToken);
  return deleted;
}

export const cleanupDataExports = onSchedule(
  { schedule: 'every day 03:30', timeZone: 'UTC', memory: '512MiB', timeoutSeconds: 540 },
  async () => {
    const n = await cleanupExpiredExports();
    console.log(`cleanupDataExports: deleted ${n} expired export(s)`);
  },
);
