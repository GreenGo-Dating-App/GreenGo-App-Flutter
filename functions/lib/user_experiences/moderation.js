"use strict";
/**
 * User experiences — server-side text moderation (PURE: no Firestore access).
 *
 * The client blocks prohibited text before submitting
 * (`ContentFilterService.findProhibitedTerms`), but the client can be bypassed,
 * so every review / reply / experience write is re-checked here by a trigger.
 *
 * The term list is a 1:1 port of the client's curated list in
 * lib/core/services/content_filter_service.dart (`_prohibitedTerms`), matched
 * the same way: lower-cased, split on anything that is not a latin letter
 * (a-z + à-ÿ), whole-token comparison — so "Scunthorpe"-style substrings never
 * trigger. KEEP BOTH LISTS IN SYNC.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.PROHIBITED_TERMS = void 0;
exports.findProhibitedTerms = findProhibitedTerms;
exports.containsLink = containsLink;
exports.findContactInfo = findContactInfo;
exports.moderateCommentText = moderateCommentText;
exports.moderateExperienceText = moderateExperienceText;
exports.reviewStatusFor = reviewStatusFor;
exports.experienceModerationPatch = experienceModerationPatch;
exports.sanitizeMentions = sanitizeMentions;
exports.replyRecipients = replyRecipients;
exports.PROHIBITED_TERMS = new Set([
    // explicit sexual (EN)
    'porn', 'porno', 'xxx', 'nude', 'nudes', 'nsfw', 'blowjob', 'handjob',
    'cum', 'dick', 'cock', 'pussy', 'boobs', 'tits', 'horny', 'escort',
    'hooker', 'whore', 'slut', 'milf', 'gangbang', 'creampie', 'deepthroat',
    // hate / slurs / discrimination (EN, curated)
    'nigger', 'nigga', 'faggot', 'fag', 'retard', 'kike', 'spic', 'chink',
    'tranny', 'dyke', 'coon', 'wetback', 'raghead', 'paki', 'gook',
    // violent / extremist
    'rape', 'rapist', 'nazi', 'kkk', 'pedo', 'pedophile',
    // generic profanity (EN)
    'fuck', 'fucking', 'shit', 'bitch', 'asshole', 'cunt', 'bastard',
    'motherfucker',
    // Italian
    'puttana', 'troia', 'cazzo', 'figa', 'stronzo', 'merda', 'frocio',
    // Spanish
    'puta', 'polla', 'coño', 'mierda', 'maricon', 'maricón', 'cabron',
    // French
    'pute', 'salope', 'bite', 'merde', 'pédé', 'enculé', 'connard',
    // German
    'hure', 'fotze', 'schlampe', 'schwuchtel', 'scheisse', 'scheiße',
    // Portuguese
    'caralho', 'buceta', 'foda', 'viado',
]);
/** Prohibited terms found in [text] (deduplicated); empty when clean. */
function findProhibitedTerms(text) {
    if (typeof text !== 'string' || text.length === 0)
        return [];
    const tokens = text.toLowerCase().split(/[^a-zà-ÿ]+/);
    const hits = new Set();
    for (const t of tokens) {
        if (t && exports.PROHIBITED_TERMS.has(t))
            hits.add(t);
    }
    return Array.from(hits);
}
/** Reviews and replies are text only: any http(s):// or www. link rejects. */
const LINK_RE = /(https?:\/\/|\bwww\.)/i;
function containsLink(text) {
    return typeof text === 'string' && LINK_RE.test(text);
}
const EMAIL_RE = /[a-z0-9._%+-]+@[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}/i;
/** 9+ digits joined only by spaces, dots, dashes or parentheses (phones, CPF). */
const PHONE_RE = /(?:\+\s*)?\d(?:[\s().-]{0,3}\d){8,}/;
/** CNPJ: 12.345.678/0001-90 (the slash breaks the phone rule). */
const CNPJ_RE = /\b\d{2}\.?\d{3}\.?\d{3}\/\d{4}-?\d{2}\b/;
/** PIX random key (UUID v4 shape). */
const UUID_RE = /\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/i;
/** @handle (Instagram / Telegram / PayPal …), not an e-mail. */
const HANDLE_RE = /(?:^|[\s(,;:])@[a-z0-9_][a-z0-9_.]{2,}/i;
/** Off-platform payment / contact phrases (lower-case, accents kept). */
const PAYMENT_PHRASES = [
    'whatsapp', 'whats app', 'wa.me', 'telegram', 't.me/', 'signal me',
    'pay me', 'paga-me', 'me paga', 'me pague', 'pague-me', 'pagame', 'págame',
    'pagami', 'paie-moi', 'payez-moi', 'bezahl mich', 'zahl mir',
    'paypal.me', '@paypal', 'venmo.com', 'cash.app', 'cashapp', 'zelle',
    'western union', 'chave pix', 'pix key', 'clé pix', 'clave pix', 'iban',
];
/** Kinds of contact / payment info found in [text]; empty when clean. */
function findContactInfo(text) {
    if (typeof text !== 'string' || text.trim().length === 0)
        return [];
    const out = new Set();
    const lower = text.toLowerCase();
    if (EMAIL_RE.test(text))
        out.add('email');
    if (PHONE_RE.test(text))
        out.add('phone');
    if (CNPJ_RE.test(text) || UUID_RE.test(text))
        out.add('pix_key');
    // A handle that is really an e-mail's domain part was caught above.
    if (HANDLE_RE.test(text.replace(EMAIL_RE, ' ')))
        out.add('handle');
    if (PAYMENT_PHRASES.some((p) => lower.includes(p)))
        out.add('payment_phrase');
    return Array.from(out);
}
/**
 * Review comment / reply text decision. Prohibited language wins over links
 * (it is the more serious reason and the one shown to admins).
 */
function moderateCommentText(text) {
    const terms = findProhibitedTerms(text);
    if (terms.length > 0)
        return { ok: false, reason: 'prohibited_terms', terms };
    if (containsLink(text))
        return { ok: false, reason: 'contains_link' };
    const contact = findContactInfo(text);
    if (contact.length > 0)
        return { ok: false, reason: 'contact_info', terms: contact };
    return { ok: true };
}
/**
 * Experience text decision: title, description, included / not-included
 * items, meeting point, availability and cancellation notes. Links are
 * allowed here (hosts may reference a venue site); prohibited language and
 * off-platform contact / payment info (phones, e-mails, handles, PIX keys)
 * hide the listing. The paymentLink field is exempt.
 */
function moderateExperienceText(data) {
    if (!data)
        return { ok: true };
    const parts = [
        data.title,
        data.description,
        data.meetingPoint,
        data.availability,
        // Legacy free-text policy (pre-enum docs) and the new host notes.
        data.cancellationPolicy,
        data.cancellationNotes,
        ...(Array.isArray(data.included) ? data.included : []),
        ...(Array.isArray(data.notIncluded) ? data.notIncluded : []),
    ];
    // NOT data.paymentLink: the one sanctioned payment destination.
    const terms = new Set();
    for (const p of parts)
        for (const t of findProhibitedTerms(p))
            terms.add(t);
    if (terms.size > 0) {
        return { ok: false, reason: 'prohibited_terms', terms: Array.from(terms) };
    }
    const contact = new Set();
    for (const p of parts)
        for (const k of findContactInfo(p))
            contact.add(k);
    if (contact.size > 0) {
        return { ok: false, reason: 'contact_info', terms: Array.from(contact) };
    }
    return { ok: true };
}
/** Review status the trigger should store for [comment]. */
function reviewStatusFor(comment) {
    return moderateCommentText(comment).ok ? 'visible' : 'rejected';
}
/**
 * The status/moderation patch an experience needs after a write, or null when
 * nothing has to change (keeps the trigger from re-writing — and re-firing —
 * forever).
 *
 *  - prohibited text on a draft/published listing → status 'hidden' with
 *    `moderation.auto = true` and the previous status remembered;
 *  - an AUTO-hidden listing whose text is clean again → restored to the
 *    remembered status (an admin hide, `auto` absent/false, is never undone);
 *  - otherwise → null.
 */
function experienceModerationPatch(data) {
    var _a;
    if (!data)
        return null;
    const status = typeof data.status === 'string' ? data.status : 'draft';
    const mod = (data.moderation && typeof data.moderation === 'object')
        ? data.moderation
        : null;
    const decision = moderateExperienceText(data);
    if (!decision.ok) {
        if (status === 'hidden')
            return null; // already hidden (auto or admin)
        return {
            status: 'hidden',
            moderation: {
                auto: true,
                reason: decision.reason,
                terms: (_a = decision.terms) !== null && _a !== void 0 ? _a : [],
                previousStatus: status === 'published' ? 'published' : 'draft',
            },
        };
    }
    if (status === 'hidden' && (mod === null || mod === void 0 ? void 0 : mod.auto) === true) {
        const prev = mod.previousStatus === 'published' ? 'published' : 'draft';
        return { status: prev, moderation: null };
    }
    return null;
}
/**
 * Mentions as stored on a reply, sanitised: strings only, no duplicates, not
 * the author, at most [max] (the rules also cap the list at 10).
 */
function sanitizeMentions(mentions, authorId, max = 10) {
    if (!Array.isArray(mentions))
        return [];
    const out = [];
    for (const m of mentions) {
        if (typeof m !== 'string' || m.length === 0 || m.length > 128)
            continue;
        if (m === authorId || out.includes(m))
            continue;
        out.push(m);
        if (out.length >= max)
            break;
    }
    return out;
}
/**
 * Who a new reply notifies: every (sanitised) mention as 'experience_mention',
 * plus the review author as 'experience_reply' when they were not mentioned
 * and did not write the reply themselves.
 */
function replyRecipients(params) {
    const mentions = sanitizeMentions(params.mentions, params.replyAuthorId);
    const out = mentions.map((uid) => ({ uid, type: 'experience_mention' }));
    const ra = params.reviewAuthorId;
    if (ra && ra !== params.replyAuthorId && !mentions.includes(ra)) {
        out.push({ uid: ra, type: 'experience_reply' });
    }
    return out;
}
//# sourceMappingURL=moderation.js.map