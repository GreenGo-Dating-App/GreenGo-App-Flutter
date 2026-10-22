/**
 * Community text guard (Apple 4.3(b), App Review 2026-10-22).
 *
 * GreenGo is for friendship, culture and networking. Community names,
 * descriptions and rules are written by users and could drift into dating
 * wording, which App Review reads as "a dating app". This module:
 *
 *  - findDatingTerms(text): the dating phrases found in a text, multilingual
 *    (en/pt/es/it/fr/de). Matching is on normalised WORDS (lowercase, accents
 *    folded, punctuation split; same tokens as community search), never on
 *    substrings, so "date" of an event, "update", "candidate" or
 *    "Partnerschaft" never match. A term is a sequence of words; a word ending
 *    in "*" matches any word starting with it ("namor*" = namoro, namorar,
 *    namorada...). EXCEPTIONS remove known innocent phrases ("carbon dating",
 *    "dating back to", "Romance languages").
 *  - onCommunityTextWritten: on create and on any change of name /
 *    description / rules / tags, a hit creates ONE low-priority
 *    `moderation_queue` item (itemType 'communityText'; doc id derived from
 *    the community and the matched text, so re-saving the same text never
 *    duplicates it). Nothing is blocked.
 *
 * The app shows a gentle warning while typing, with the SAME lists:
 * lib/features/communities/domain/community_text_guard.dart. Both sides are
 * checked against test/fixtures/community_dating_terms.json (lists + vectors).
 *
 * Cost: the community doc is also rewritten on every chat message
 * (lastActivityAt / lastMessagePreview). Those invocations compare four
 * fields of before/after in memory and return: no reads, no writes.
 */
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import '../shared/firebaseAdmin';
import { searchTokens } from './searchKeywords';

/** Dating phrases. KEEP IN SYNC with community_text_guard.dart + the fixture. */
export const DATING_TERMS: readonly string[] = [
  // English
  'dating*', 'speed dating', 'online dating', 'romance', 'romantic partner*',
  'romantic relationship*', 'romantic date*', 'hookup*', 'hook up', 'hook ups',
  'one night stand*', 'friends with benefits', 'fwb', 'find love', 'finding love',
  'looking for love', 'find true love', 'soulmate*', 'soul mate*',
  'find a boyfriend', 'find a girlfriend', 'looking for a boyfriend',
  'looking for a girlfriend', 'get a girlfriend', 'get a boyfriend',
  'find a wife', 'find a husband', 'looking for a wife', 'looking for a husband',
  'meet singles', 'for singles', 'singles night*', 'singles party', 'singles event*',
  'flirt*', 'sugar daddy', 'sugar daddies', 'sugar baby', 'sugar babies',
  'sugar mommy', 'casual sex', 'casual encounter*', 'nsfw',
  // Portuguese
  'namor*', 'paquer*', 'encontro romantico', 'encontros romanticos',
  'encontro amoroso', 'encontros amorosos', 'relacionamento serio',
  'alma gemea', 'pegacao', 'sexo casual', 'encontrar o amor', 'achar o amor',
  'encontrar um amor', 'procurando amor', 'para solteiros', 'encontro de solteiros',
  'ficar com gringo*', 'ficar com gringa*', 'procuro esposa', 'procuro marido',
  // Spanish
  'citas romanticas', 'cita romantica', 'app de citas', 'aplicacion de citas',
  'pagina de citas', 'sitio de citas', 'busco pareja', 'buscar pareja',
  'encontrar pareja', 'conocer pareja', 'ligar con', 'ligoteo', 'media naranja',
  'encontrar el amor', 'busco novia', 'busco novio', 'encontrar novia',
  'encontrar novio', 'conseguir novia', 'conseguir novio', 'para solteros',
  // Italian
  'appuntamenti romantici', 'appuntamento romantico', 'incontri romantici',
  'incontri per single', 'incontri single', 'anima gemella', 'trovare l amore',
  'cerco fidanzata', 'cerco fidanzato', 'trovare una fidanzata',
  'trovare un fidanzato', 'rimorchiare',
  // French
  'rencontre amoureuse', 'rencontres amoureuses', 'site de rencontre*',
  'rencontres coquines', 'rencontre coquine', 'trouver l amour', 'ame soeur',
  'plan cul', 'drague*', 'pour celibataires', 'rencontre celibataire*',
  'rencontres celibataire*', 'petit ami', 'petite amie',
  // German
  'partnersuch*', 'partnerborse*', 'partnervermittlung*', 'singleborse*',
  'liebe finden', 'die liebe finden', 'feste freundin', 'festen freund',
  'romantische treffen', 'seitensprung*', 'sexdate*', 'blind date*',
];

/** Innocent phrases that contain a term; a hit inside one is ignored. */
export const DATING_TERM_EXCEPTIONS: readonly string[] = [
  'carbon dating', 'radiocarbon dating', 'dating back', 'dating from', 'dating to',
  'romance language*', 'romance studies', 'romance philology', 'romance novel*',
  'romance book*', 'romance literature', 'romance linguistics',
];

type Pattern = string[];

function compile(list: readonly string[]): Pattern[] {
  return list.map((t) => t.split(' ').filter((w) => w.length > 0));
}

const TERMS = compile(DATING_TERMS);
const EXCEPTIONS = compile(DATING_TERM_EXCEPTIONS);

function wordMatches(pattern: string, word: string): boolean {
  return pattern.endsWith('*') ? word.startsWith(pattern.slice(0, -1)) : word === pattern;
}

function matchAt(tokens: string[], i: number, p: Pattern): boolean {
  if (i + p.length > tokens.length) return false;
  for (let k = 0; k < p.length; k++) if (!wordMatches(p[k], tokens[i + k])) return false;
  return true;
}

/** The dating terms (as listed) found in [text]; [] when none. */
export function findDatingTerms(text: unknown): string[] {
  const tokens = searchTokens(text);
  if (tokens.length === 0) return [];
  const covered = new Array<boolean>(tokens.length).fill(false);
  for (let i = 0; i < tokens.length; i++) {
    for (const e of EXCEPTIONS) {
      if (matchAt(tokens, i, e)) for (let k = 0; k < e.length; k++) covered[i + k] = true;
    }
  }
  const found: string[] = [];
  TERMS.forEach((p, idx) => {
    for (let i = 0; i < tokens.length; i++) {
      if (!matchAt(tokens, i, p)) continue;
      let allCovered = true;
      for (let k = 0; k < p.length; k++) if (!covered[i + k]) allCovered = false;
      if (allCovered) continue;
      found.push(DATING_TERMS[idx]);
      return;
    }
  });
  return found;
}

/** The user-written community fields that are checked. */
export const GUARDED_FIELDS = ['name', 'description', 'rules', 'tags'] as const;

function fieldText(data: Record<string, any> | undefined, field: string): string {
  const v = data?.[field];
  if (typeof v === 'string') return v;
  if (Array.isArray(v)) return v.filter((x) => typeof x === 'string').join(' ');
  return '';
}

/** Hits per field of [data] (only fields with hits). */
export function datingHitsForCommunity(
  data: Record<string, any> | undefined,
): Record<string, string[]> {
  const out: Record<string, string[]> = {};
  for (const f of GUARDED_FIELDS) {
    const hits = findDatingTerms(fieldText(data, f));
    if (hits.length > 0) out[f] = hits;
  }
  return out;
}

/** True when a guarded field differs between [before] and [after]. */
export function guardedTextChanged(
  before: Record<string, any> | undefined,
  after: Record<string, any> | undefined,
): boolean {
  if (!after) return false;
  if (!before) return true;
  return GUARDED_FIELDS.some((f) => fieldText(before, f) !== fieldText(after, f));
}

/**
 * The moderation_queue item for a flagged community, or null. Same shape as
 * the other queue producers (itemType / itemId / userId / priority /
 * metadata / addedAt / assignedTo / status).
 */
export function communityTextQueueItem(
  communityId: string,
  after: Record<string, any> | undefined,
): { id: string; data: Record<string, any> } | null {
  const hits = datingHitsForCommunity(after);
  const fields = Object.keys(hits);
  if (fields.length === 0) return null;
  const texts = GUARDED_FIELDS.map((f) => fieldText(after, f)).join('\u0000');
  const hash = crypto.createHash('sha256').update(texts, 'utf8').digest('hex').slice(0, 16);
  const id = `communityText_${communityId}_${hash}`;
  return {
    id,
    data: {
      queueId: id,
      itemType: 'communityText',
      itemId: communityId,
      userId: typeof after?.createdByUserId === 'string' ? after.createdByUserId : null,
      priority: 'low',
      status: 'pending',
      assignedTo: null,
      metadata: {
        reason: 'possible_dating_wording',
        contentType: 'community',
        communityName: fieldText(after, 'name').slice(0, 200),
        fields,
        matchedTerms: hits,
        // Short excerpts so the reviewer sees the context without opening it.
        excerpts: Object.fromEntries(fields.map((f) => [f, fieldText(after, f).slice(0, 500)])),
        isPublic: after?.isPublic !== false,
      },
    },
  };
}

export const onCommunityTextWritten = onDocumentWritten(
  { document: 'communities/{communityId}', memory: '512MiB' },
  async (event) => {
    const before = event.data?.before?.exists ? event.data.before.data() : undefined;
    const after = event.data?.after?.exists ? event.data.after.data() : undefined;
    // Chat activity rewrites the doc constantly: leave without any I/O.
    if (!guardedTextChanged(before, after)) return;
    const item = communityTextQueueItem(event.params.communityId, after);
    if (!item) return;
    const ref = admin.firestore().collection('moderation_queue').doc(item.id);
    try {
      // create(): the same text flagged before is not queued again.
      await ref.create({ ...item.data, addedAt: admin.firestore.FieldValue.serverTimestamp() });
    } catch (e: any) {
      if (e?.code === 6 || /already exists/i.test(String(e?.message))) return;
      throw e;
    }
  },
);
