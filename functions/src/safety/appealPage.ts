/**
 * Web appeal page (Terms 18.4 a: appeal "in the app or by replying to our
 * notice"; DSA art. 20). A banned user's Firebase Auth account is disabled,
 * so the app is closed to them: the statement-of-reasons EMAIL carries a
 * signed link to this page (moderationDecisions.ts appealLinkFor):
 *
 *   GET  /moderationAppeal?d=<decisionId>&s=<sig>&hl=<locale>
 *        -> the statement of reasons + a form (or why it can't be appealed)
 *   POST same URL, form fields d, s, hl, reason
 *        -> submitAppealForDecision(decision.userId, ..., channel 'web')
 *
 * The signature (HMAC over decision id + user id) is the capability: no
 * sign-in. Server-rendered HTML, every value escaped, no JavaScript at all
 * (CSP script-src 'none' via GUEST_SECURITY_HEADERS), same-origin POST only.
 */
import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { AppLocale, t as tr } from '../shared/i18n';
import { monitored } from '../shared/monitoring';
import { bcp47, escapeHtml as e, pickLocale } from '../share/sharePreviewCore';
import { GUEST_SECURITY_HEADERS } from '../guest/guestPages';
import { originAllowed } from '../guest/guestModel';
import { functionsBaseUrl } from '../ticket_payments/config';
import {
  APPEAL_MAX_CHARS, APPEAL_MIN_CHARS, actionText, automatedText, contentText, MODERATION_DECISIONS, reasonText,
  submitAppealForDecision, verifyAppealSignature,
} from './moderationDecisions';

const ID_RE = /^[A-Za-z0-9_~.:-]{1,1400}$/;

export interface AppealPageView {
  locale: AppLocale;
  facts: Array<[string, string]>;
  /** Form shown when the decision can still be appealed. */
  form: { action: string; d: string; s: string; deadline: string } | null;
  /** Status / result message (shown instead of, or above, the form). */
  message: string | null;
  error: boolean;
}

function layout(locale: AppLocale, title: string, body: string): string {
  return `<!doctype html>
<html lang="${e(bcp47(locale))}"><head><meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<meta name="robots" content="noindex,nofollow" />
<title>${e(title)}</title>
<style>
body{margin:0;background:#0d0d0d;color:#f2f2f2;font:16px/1.5 -apple-system,Segoe UI,Roboto,Arial,sans-serif}
main{max-width:560px;margin:0 auto;padding:24px 16px}
h1{font-size:22px;color:#d4af37;margin:0 0 16px}
dl{margin:0 0 16px}dt{color:#9a9a9a;font-size:13px;margin-top:10px}dd{margin:2px 0 0}
textarea{width:100%;box-sizing:border-box;min-height:140px;background:#1a1a1a;color:#f2f2f2;border:1px solid #333;border-radius:8px;padding:10px;font:inherit}
button{margin-top:12px;background:#d4af37;color:#0d0d0d;border:0;border-radius:8px;padding:12px 18px;font-weight:bold;font-size:16px}
.note{color:#bdbdbd}.error{color:#ff6b6b}.small{color:#9a9a9a;font-size:13px;margin-top:24px}
</style></head><body><main>${body}</main></body></html>`;
}

/** Pure (exported for tests). */
export function renderAppealPage(v: AppealPageView): string {
  const L = v.locale;
  const title = tr(L, 'srvAppealPageTitle');
  const facts = v.facts.length
    ? `<dl>${v.facts.map(([k, val]) => `<dt>${e(k)}</dt><dd>${e(val)}</dd>`).join('')}</dl>` : '';
  const msg = v.message ? `<p class="${v.error ? 'error' : 'note'}"${v.error ? ' role="alert"' : ''}>${e(v.message)}</p>` : '';
  const form = v.form
    ? `<p class="note">${e(tr(L, 'moderationDecisionAppealUntil', { date: v.form.deadline }))}</p>
<form method="post" action="${e(v.form.action)}">
<input type="hidden" name="d" value="${e(v.form.d)}" />
<input type="hidden" name="s" value="${e(v.form.s)}" />
<input type="hidden" name="hl" value="${e(L)}" />
<label for="reason">${e(tr(L, 'moderationDecisionAppealHint'))}</label>
<textarea id="reason" name="reason" required minlength="${APPEAL_MIN_CHARS}" maxlength="${APPEAL_MAX_CHARS}"></textarea>
<button type="submit">${e(tr(L, 'moderationDecisionAppealSubmit'))}</button>
</form>` : '';
  const body = `<h1>${e(title)}</h1>${msg}${facts}${form}<p class="small">${e(tr(L, 'moderationDecisionOtherOptions'))}</p>`;
  return layout(L, title, body);
}

interface Loaded { decision: Record<string, any>; userId: string }

async function load(d: unknown, s: unknown): Promise<Loaded | null> {
  if (typeof d !== 'string' || !ID_RE.test(d)) return null;
  const decision = (await admin.firestore().collection(MODERATION_DECISIONS).doc(d).get()).data();
  if (!decision || typeof decision.userId !== 'string') return null;
  if (!(await verifyAppealSignature(d, decision.userId, s))) return null;
  return { decision, userId: decision.userId };
}

function factsOf(L: AppLocale, d: Record<string, any>): Array<[string, string]> {
  const out: Array<[string, string]> = [
    [tr(L, 'moderationDecisionActionLabel'), actionText(L, d.action)],
    [tr(L, 'moderationDecisionContentLabel'), contentText(L, d.contentRef)],
    [tr(L, 'moderationDecisionReasonLabel'), reasonText(L, d.reasonCode)],
  ];
  if (typeof d.explanation === 'string' && d.explanation.trim()) out.push([tr(L, 'moderationDecisionExplanationLabel'), d.explanation]);
  out.push([tr(L, 'moderationDecisionAutomatedLabel'),
    automatedText(L, { detection: d.automatedDetection ?? null, decision: d.automatedDecision === true })]);
  return out;
}

function deadlineText(L: AppLocale, d: Record<string, any>): string {
  const ms = d.appealDeadline instanceof admin.firestore.Timestamp ? d.appealDeadline.toMillis() : 0;
  return new Intl.DateTimeFormat(bcp47(L), { dateStyle: 'long', timeZone: 'UTC' }).format(new Date(ms));
}

/** Status message for a decision that cannot take a new appeal, else null. */
function closedMessage(L: AppLocale, d: Record<string, any>, nowMs: number): string | null {
  if (d.appealStatus) return tr(L, 'moderationDecisionAppealAlready');
  const deadline = d.appealDeadline instanceof admin.firestore.Timestamp ? d.appealDeadline.toMillis() : 0;
  if (d.appealable !== true || nowMs > deadline) return tr(L, 'moderationDecisionAppealClosed');
  return null;
}

export async function appealPageGet(q: Record<string, unknown>, L: AppLocale, nowMs = Date.now()): Promise<{ status: number; html: string }> {
  const loaded = await load(q.d, q.s);
  if (!loaded) {
    return { status: 400, html: renderAppealPage({ locale: L, facts: [], form: null, message: tr(L, 'srvAppealPageInvalid'), error: true }) };
  }
  const d = loaded.decision;
  const closed = closedMessage(L, d, nowMs);
  return {
    status: 200,
    html: renderAppealPage({
      locale: L,
      facts: factsOf(L, d),
      form: closed ? null : { action: `${functionsBaseUrl()}/moderationAppeal`, d: String(q.d), s: String(q.s), deadline: deadlineText(L, d) },
      message: closed,
      error: false,
    }),
  };
}

export async function appealPagePost(body: Record<string, unknown>, L: AppLocale, nowMs = Date.now()): Promise<{ status: number; html: string }> {
  const loaded = await load(body.d, body.s);
  if (!loaded) {
    return { status: 400, html: renderAppealPage({ locale: L, facts: [], form: null, message: tr(L, 'srvAppealPageInvalid'), error: true }) };
  }
  const d = loaded.decision;
  const reason = typeof body.reason === 'string' ? body.reason.trim() : '';
  const again = (message: string, status = 400) => ({
    status,
    html: renderAppealPage({
      locale: L, facts: factsOf(L, d),
      form: closedMessage(L, d, nowMs) ? null : { action: `${functionsBaseUrl()}/moderationAppeal`, d: String(body.d), s: String(body.s), deadline: deadlineText(L, d) },
      message, error: true,
    }),
  });
  if (reason.length < APPEAL_MIN_CHARS) return again(tr(L, 'moderationDecisionAppealTooShort'));
  try {
    await submitAppealForDecision(loaded.userId, { decisionId: body.d, appealReason: reason.slice(0, APPEAL_MAX_CHARS) }, nowMs, 'web');
  } catch (err: any) {
    const code = err?.code;
    const msg = code === 'already-exists' ? tr(L, 'moderationDecisionAppealAlready')
      : code === 'failed-precondition' ? tr(L, 'moderationDecisionAppealClosed')
        : code === 'invalid-argument' ? tr(L, 'moderationDecisionAppealTooShort')
          : tr(L, 'moderationDecisionAppealError');
    if (!['already-exists', 'failed-precondition', 'invalid-argument'].includes(code)) {
      console.error('[appealPage] submit failed:', err?.message || err);
    }
    return { status: code === 'already-exists' || code === 'failed-precondition' ? 409 : 400, html: renderAppealPage({ locale: L, facts: factsOf(L, d), form: null, message: msg, error: true }) };
  }
  return {
    status: 200,
    html: renderAppealPage({ locale: L, facts: factsOf(L, d), form: null, message: tr(L, 'moderationDecisionAppealSent'), error: false }),
  };
}

/** Flat string fields only (url-encoded form). */
export function appealFormBody(raw: unknown): Record<string, unknown> | null {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return null;
  const out: Record<string, unknown> = {};
  for (const k of ['d', 's', 'hl', 'reason']) {
    const v = (raw as Record<string, unknown>)[k];
    if (v === undefined) continue;
    if (typeof v !== 'string' || v.length > (k === 'reason' ? APPEAL_MAX_CHARS * 2 : 1500)) return null;
    out[k] = v;
  }
  return out;
}

export const moderationAppeal = onRequest(
  { memory: '512MiB', timeoutSeconds: 60, invoker: 'public' },
  monitored('moderationAppeal', async (req, res) => {
    const send = (r: { status: number; html: string }) => {
      res.set(GUEST_SECURITY_HEADERS);
      res.status(r.status).type('html').send(r.html);
    };
    const body = req.method === 'POST' ? appealFormBody(req.body) : {};
    const L = pickLocale(req.get('accept-language'), (req.query as any).hl ?? body?.hl);
    if (req.method === 'GET' || req.method === 'HEAD') {
      send(await appealPageGet(req.query as Record<string, unknown>, L));
      return;
    }
    if (req.method !== 'POST') {
      res.set('Allow', 'GET, HEAD, POST');
      res.status(405).send('method not allowed');
      return;
    }
    // CSRF: only this page may post.
    if (!body || !originAllowed(req.get('origin'), req.get('referer'), [functionsBaseUrl()])) {
      send({ status: 403, html: renderAppealPage({ locale: L, facts: [], form: null, message: tr(L, 'srvAppealPageInvalid'), error: true }) });
      return;
    }
    send(await appealPagePost(body, L));
  }),
);
