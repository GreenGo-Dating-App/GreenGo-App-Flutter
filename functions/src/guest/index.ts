/**
 * Guest booking from a shared link (owner spec 2026-10-14).
 *
 * Flow:
 *  1. Anyone opens a shared /e/{id}, /x/{id} or /a/{id} link (sharePreview).
 *     For a guest-viewable listing the landing offers two choices:
 *     "Open in the GreenGo app" (greengo:// then the store on phones, the web
 *     app on desktop: unchanged member behaviour) or "Continue as guest".
 *  2. "Continue as guest" -> /guest/{kind}/{id} (this function, via the
 *     Hosting rewrite /guest/**): a server-rendered, read-only page of THAT
 *     listing only (no browsing, no search, no other content). Attractions
 *     are read-only. When the host switched "Guests allowed to book" on
 *     (public events / published experiences only), the page has a form:
 *     first name, surname, e-mail, consent, tickets / time + party size.
 *  3. POST: Origin check (CSRF) + signed form token (expiry, min fill time,
 *     idempotency nonce) + honeypot + rate limits (IP, e-mail, listing) +
 *     strict validation, then server-side re-checks of the listing:
 *       - free event  -> attendee doc + seat in one transaction, ticket e-mail
 *                        with the signed RSVP QR;
 *       - paid event  -> ticket_payments createTicketCheckout (THE same
 *                        checkout as members: price, capacity holds, per-buyer
 *                        limit, Stripe / Mercado Pago instant only, Track 1's
 *                        buyer-paid fee) -> hosted checkout; the existing
 *                        webhooks mark the order paid and the existing ticket
 *                        e-mail sends the QRs;
 *       - experience  -> createBooking request; the host accepts in the app;
 *                        the guest gets a "Pay now" link by e-mail (or the QR
 *                        right away when free).
 *  4. Refunds / disputes, declined / expired / cancelled requests and events
 *     cancelled by the host are e-mailed to the guest (./guestEmails.ts).
 *
 * Identity, storage, retention: shared/guestIdentity.ts and ./guestService.ts.
 * The guest's e-mail lives only in guest_contacts/{guestKey} (server-only,
 * TTL expireAt = last booking + 400 days). The host sees the guest's NAME in
 * the app and, as for member ticket buyers, the e-mail in the participants
 * CSV (for entry); other attendees see the name only. Logs never contain
 * names or e-mail addresses.
 *
 * Deploy BY NAME: guestBooking, emailGuestsOnEventCancelled (+ the changed
 * existing functions listed in the release notes).
 */
import { onRequest } from 'firebase-functions/v2/https';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';
import { monitored } from '../shared/monitoring';
import { functionsBaseUrl } from '../ticket_payments/config';
import { pickLocale } from '../share/sharePreviewCore';
import { clientIp, originAllowed, parseGuestPath } from './guestModel';
import { GUEST_SECURITY_HEADERS, renderMessagePage, renderUnavailablePage } from './guestPages';
import { gt } from './guestI18n';
import {
  PageResponse, guestListingPage, guestPayPage, guestPaySubmit, guestReturnPage, guestSubmit,
} from './guestService';
import { becameCancelled, emailGuestsOfCancelledEvent } from './guestEmails';

const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');
const MAX_FIELDS = 60;

/** Flat string fields only (url-encoded form); anything else is refused. */
export function formBody(raw: unknown): Record<string, unknown> | null {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return null;
  const keys = Object.keys(raw as object);
  if (keys.length > MAX_FIELDS) return null;
  const out: Record<string, unknown> = {};
  for (const k of keys) {
    const v = (raw as Record<string, unknown>)[k];
    if (typeof v !== 'string' || v.length > 600) return null;
    out[k] = v;
  }
  return out;
}

export const guestBooking = onRequest(
  { memory: '512MiB', timeoutSeconds: 60, invoker: 'public', secrets: [STRIPE_SECRET_KEY] },
  monitored('guestBooking', async (req, res) => {
    const send = (r: PageResponse) => {
      res.set(GUEST_SECURITY_HEADERS);
      res.status(r.status).type('html').send(r.html);
    };
    const body = req.method === 'POST' ? formBody(req.body) : {};
    const locale = pickLocale(req.get('accept-language'), req.query.hl ?? body?.hl);
    const route = parseGuestPath(req.path);
    if (!route) {
      send({ status: 404, html: renderUnavailablePage(locale) });
      return;
    }

    if (req.method === 'GET' || req.method === 'HEAD') {
      const q = req.query as Record<string, unknown>;
      if (route.route === 'listing') send(await guestListingPage(route.kind, route.id, locale));
      else if (route.route === 'done') send(await guestReturnPage(route.id, q, locale));
      else send(await guestPayPage(route.id, q, locale));
      return;
    }
    if (req.method !== 'POST') {
      res.set('Allow', 'GET, HEAD, POST');
      res.status(405).send('method not allowed');
      return;
    }

    // CSRF: only our own pages may post (plus the direct function origin).
    if (!body || !originAllowed(req.get('origin'), req.get('referer'), [functionsBaseUrl()])) {
      send({
        status: 403,
        html: renderMessagePage(locale, gt(locale, 'guest.err.generic'), gt(locale, 'guest.err.expired'), { error: true }),
      });
      return;
    }
    const ip = clientIp(req.headers as Record<string, unknown>, req.ip);
    if (route.route === 'listing') send(await guestSubmit({ kind: route.kind, id: route.id, locale, body, ip }));
    else if (route.route === 'pay') send(await guestPaySubmit(route.id, body, locale, ip));
    else send({ status: 405, html: renderUnavailablePage(locale) });
  }),
);

/** Host cancelled an event -> its guest attendees are told by e-mail (members see it in the app). */
export const emailGuestsOnEventCancelled = onDocumentUpdated(
  { document: 'events/{eventId}', memory: '512MiB', timeoutSeconds: 300 },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!becameCancelled(before, after)) return;
    await emailGuestsOfCancelledEvent(event.params.eventId, after as Record<string, any>);
  },
);
