/**
 * "Your ticket" email to the BUYER when the QR is released:
 *
 *  1. ticket_orders/{orderId} -> status 'paid' (events AND experiences paid
 *     through an order: Stripe / Mercado Pago webhook, organizer-confirmed
 *     link payment, free order). One email per ORDER with every ticket's QR.
 *  2. bookings/{bookingId} whose QR becomes available WITHOUT an order:
 *     confirmed free / cash bookings, and link bookings once the host
 *     confirmed the payment (same rule as getBookingCheckInCode). Online
 *     bookings are covered by (1).
 *
 * The QR images are generated here (emails/qrPng.ts) and embedded as inline
 * CID attachments, so the signed ticket token never reaches a third-party
 * image service. Text is in the BUYER's language, times in the host's zone.
 * Idempotent: email_dispatch/ticket_order_{orderId} / booking_qr_{bookingId}.
 *
 *  3. bookings/{bookingId} request / confirmation emails to BOTH sides (same
 *     trigger): new request -> host (accept / decline before it expires) and
 *     guest (what happens next); confirmed -> host, and the guest when no QR /
 *     order email reaches them at that moment. Each in the RECIPIENT's
 *     language, times in the host's zone. Idempotent:
 *     email_dispatch/booking_{kind}_{bookingId}.
 */
import { onDocumentUpdated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { t } from '../shared/i18n';
import { resolveLocale } from '../shared/i18n/recipientLocale';
import { checkInCode, checkInQrPayload } from '../experience_bookings/model';
import { checkInSecret } from '../experience_bookings/service';
import { qrPng } from './qrPng';
import { authEmailOf, EmailAttachment, escapeHtml, OutgoingEmail, sendEmailOnce } from './sendEmail';
import { detailsTable, emailFrame, formatWhen, hostTimeZone, joinPlace, millis } from './emailFormat';

const db = () => admin.firestore();

export interface TicketEmailQr {
  payload: string;
  caption: string;
}

export interface TicketEmailModel {
  locale: string;
  to: string;
  title: string;
  when: string;
  where: string | null;
  ticketType: string | null;
  partySize: number | null;
  bookingCode: string;
  qrs: TicketEmailQr[];
}

/** Booking code shown to the buyer AND in the organizer's participants CSV. */
export function orderBookingCode(orderId: string, order: Record<string, any> | undefined): string {
  return typeof order?.code === 'string' && order.code ? order.code : orderId;
}

/** "VIP × 2, General × 1" from the issued tickets (null when untyped). */
export function ticketTypeSummary(tickets: Array<Record<string, any>>): string | null {
  const counts = new Map<string, number>();
  for (const tk of tickets) {
    const name = typeof tk.ticketTypeName === 'string' && tk.ticketTypeName.trim() ? tk.ticketTypeName.trim() : null;
    if (!name) continue;
    counts.set(name, (counts.get(name) || 0) + 1);
  }
  if (!counts.size) return null;
  return [...counts.entries()].map(([n, c]) => `${n} × ${c}`).join(', ');
}

export function placeOf(kind: 'event' | 'experience', l: Record<string, any> | undefined): string | null {
  if (!l) return null;
  return kind === 'event'
    ? joinPlace([l.locationName, l.address, l.city])
    : joinPlace([l.meetingPoint, l.locationName, l.city]);
}

/** Build the email (pure apart from PNG generation; exported for tests). */
export function buildTicketEmail(m: TicketEmailModel): OutgoingEmail {
  const L = m.locale;
  const attachments: EmailAttachment[] = m.qrs.map((q, i) => ({
    filename: `ticket-${i + 1}.png`,
    content: qrPng(q.payload, 8),
    contentType: 'image/png',
    contentId: `ticket-qr-${i + 1}`,
  }));
  const qrHtml = m.qrs.map((q, i) =>
    '<div style="text-align:center;margin:16px 0;padding:12px;border:1px solid #ddd;border-radius:8px">'
    + `<div style="font-weight:bold;margin-bottom:8px">${escapeHtml(q.caption)}</div>`
    + `<img src="cid:ticket-qr-${i + 1}" alt="QR" width="260" height="260" style="display:block;margin:0 auto;width:260px;height:260px"/>`
    + '</div>').join('');
  const rows: Array<[string, string | null]> = [
    [t(L, 'emailTicketWhen'), m.when],
    [t(L, 'emailTicketWhere'), m.where],
    [t(L, 'emailTicketTypeLabel'), m.ticketType],
    [t(L, 'emailTicketPartySizeLabel'), m.partySize !== null ? String(m.partySize) : null],
    [t(L, 'emailTicketCodeLabel'), m.bookingCode],
  ];
  const html = emailFrame(
    `<h2 style="margin:0 0 8px">${escapeHtml(m.title)}</h2>`
    + `<p>${escapeHtml(t(L, 'emailTicketIntro'))}</p>`
    + detailsTable(rows)
    + qrHtml
    + `<p style="color:#666;font-size:13px">${escapeHtml(t(L, 'emailTicketFooter'))}</p>`,
  );
  const text = [
    m.title, t(L, 'emailTicketIntro'), '',
    ...rows.filter(([, v]) => v).map(([k, v]) => `${k}: ${v}`),
    '', t(L, 'emailTicketFooter'),
  ].join('\n');
  return { to: [m.to], subject: t(L, 'emailTicketSubject', { title: m.title }), html, text, attachments };
}

// ─────────────────────────────────────────────────────────── 1. paid orders

export function becamePaid(before: Record<string, any> | undefined, after: Record<string, any> | undefined): boolean {
  return after?.status === 'paid' && before?.status !== 'paid';
}

export async function handleTicketOrderUpdate(
  orderId: string,
  before: Record<string, any> | undefined,
  after: Record<string, any> | undefined,
): Promise<string> {
  if (!becamePaid(before, after)) return 'skipped';
  const o = after!;
  const r = await sendEmailOnce(`ticket_order_${orderId}`, async () => {
    const to = await authEmailOf(String(o.buyerId || ''));
    if (!to) return null;
    const kind: 'event' | 'experience' = o.kind === 'experience' ? 'experience' : 'event';
    const ids: string[] = Array.isArray(o.ticketIds) && o.ticketIds.length ? o.ticketIds : (o.ticketId ? [o.ticketId] : []);
    const [locale, listingSnap, bookingSnap, ...ticketSnaps] = await Promise.all([
      resolveLocale(String(o.buyerId)),
      db().collection(kind === 'event' ? 'events' : 'user_experiences').doc(String(o.listingId)).get(),
      kind === 'experience' && o.bookingId ? db().collection('bookings').doc(String(o.bookingId)).get() : Promise.resolve(null),
      ...ids.map((id) => db().collection('tickets').doc(id).get()),
    ]);
    const tickets = ticketSnaps.map((s) => s.data()).filter((x) => x && x.status === 'valid' && typeof x.qrPayload === 'string') as Array<Record<string, any>>;
    if (!tickets.length) return null;
    const l = listingSnap.data() || {};
    const b = bookingSnap?.data();
    const startMs = millis(b?.slotStart) ?? millis(o.startsAt) ?? millis(l.startDate);
    const partySize = kind === 'experience'
      ? Math.max(1, Number(b?.guests) || Number(o.partySize) || 1)
      : (tickets.length > 1 ? tickets.length : null);
    return buildTicketEmail({
      locale,
      to,
      title: String(o.title || l.title || b?.experienceTitle || 'GreenGo'),
      when: formatWhen(startMs, hostTimeZone(l), locale),
      where: placeOf(kind, l),
      ticketType: ticketTypeSummary(tickets),
      partySize,
      bookingCode: orderBookingCode(orderId, o),
      qrs: tickets.map((tk, i) => ({
        payload: tk.qrPayload,
        caption: t(locale, 'emailTicketQrCaption', { index: i + 1, count: tickets.length }),
      })),
    });
  }, { type: 'ticket_order', orderId });
  return r === 'duplicate' ? 'duplicate' : (r.sent ? 'sent' : `not_sent:${r.reason}`);
}

// ─────────────────────────────────────────── 2. bookings without an order

/** Does this booking expose an HMAC check-in QR (not an order ticket)? */
export function bookingQrReady(b: Record<string, any> | undefined): boolean {
  if (!b || b.status !== 'confirmed') return false;
  const mode = b.payment?.mode;
  if (mode === 'online') return false; // ticket order email covers it
  if (mode === 'link') return !!b.payment?.hostConfirmedPaidAt;
  return true; // free / cash / legacy without payment info
}

/** QR ticket email for a booking without an order (free / cash / paid link). */
export async function sendBookingQrEmail(
  bookingId: string,
  before: Record<string, any> | undefined,
  after: Record<string, any> | undefined,
): Promise<string> {
  if (!bookingQrReady(after) || bookingQrReady(before)) return 'skipped';
  const b = after!;
  const r = await sendEmailOnce(`booking_qr_${bookingId}`, async () => {
    const to = await authEmailOf(String(b.guestId || ''));
    if (!to) return null;
    const [locale, expSnap, secret] = await Promise.all([
      resolveLocale(String(b.guestId)),
      db().collection('user_experiences').doc(String(b.experienceId)).get(),
      checkInSecret(),
    ]);
    const l = expSnap.data() || {};
    const code = checkInCode(secret, bookingId);
    return buildTicketEmail({
      locale,
      to,
      title: String(b.experienceTitle || l.title || 'GreenGo'),
      when: formatWhen(millis(b.slotStart), hostTimeZone(l), locale),
      where: placeOf('experience', l),
      ticketType: null,
      partySize: Math.max(1, Number(b.guests) || 1),
      bookingCode: code,
      qrs: [{ payload: checkInQrPayload(bookingId, code), caption: t(locale, 'emailTicketQrCaption', { index: 1, count: 1 }) }],
    });
  }, { type: 'booking_qr', bookingId });
  return r === 'duplicate' ? 'duplicate' : (r.sent ? 'sent' : `not_sent:${r.reason}`);
}

// ─────────────────────────── 3. booking request / confirmation (both sides)

/**
 * request_host     new request -> the host, to accept / decline before expiry
 * request_guest    new request -> the guest, "what happens next"
 * confirmed_host   booking became confirmed -> the host
 * confirmed_guest  booking became confirmed and NO other email reaches the
 *                  guest now: not a QR booking (free / cash / paid link, see
 *                  [bookingQrReady]) and not an already-paid online booking
 *                  (the ticket order email). Covers link bookings awaiting the
 *                  host's payment confirmation and online bookings still to pay.
 */
export type BookingEmailKind = 'request_host' | 'request_guest' | 'confirmed_host' | 'confirmed_guest';

export function bookingEmailKinds(
  before: Record<string, any> | undefined,
  after: Record<string, any> | undefined,
): BookingEmailKind[] {
  if (!after) return [];
  const out: BookingEmailKind[] = [];
  if (after.status === 'requested' && before?.status !== 'requested') out.push('request_host', 'request_guest');
  if (after.status === 'confirmed' && before?.status !== 'confirmed') {
    out.push('confirmed_host');
    const onlinePaid = after.payment?.mode === 'online' && after.payment?.status === 'paid';
    if (!bookingQrReady(after) && !onlinePaid) out.push('confirmed_guest');
  }
  return out;
}

export function bookingEmailKey(kind: BookingEmailKind, bookingId: string): string {
  return `booking_${kind}_${bookingId}`;
}

export interface BookingEmailModel {
  kind: BookingEmailKind;
  locale: string;
  to: string;
  title: string;
  when: string;
  where: string | null;
  partySize: number;
  /** Guest display name (host emails). */
  guestName: string | null;
  /** Request expiry, formatted (request_host). */
  respondBy: string | null;
  /** How to pay, already localized (confirmed_guest). */
  payHint: string | null;
}

/** Build a booking request / confirmation email (pure; exported for tests). */
export function buildBookingEmail(m: BookingEmailModel): OutgoingEmail {
  const L = m.locale;
  const forHost = m.kind === 'request_host' || m.kind === 'confirmed_host';
  const name = m.guestName || t(L, 'srvSomeone');
  const subject = m.kind === 'request_host'
    ? t(L, 'emailBookingRequestHostSubject', { title: m.title })
    : m.kind === 'request_guest'
      ? t(L, 'emailBookingRequestGuestSubject', { title: m.title })
      : t(L, 'emailBookingConfirmedSubject', { title: m.title });
  const intro = m.kind === 'request_host'
    ? t(L, 'emailBookingRequestHostIntro', { name })
    : m.kind === 'request_guest'
      ? t(L, 'emailBookingRequestGuestIntro')
      : m.kind === 'confirmed_host'
        ? t(L, 'emailBookingConfirmedHostIntro', { name })
        : t(L, 'emailBookingConfirmedGuestIntro');
  const next = m.kind === 'request_host'
    ? t(L, 'emailBookingRequestHostAction')
    : m.kind === 'request_guest'
      ? t(L, 'emailBookingRequestGuestNext')
      : m.kind === 'confirmed_guest' ? m.payHint : null;
  const rows: Array<[string, string | null]> = [
    [t(L, 'emailTicketWhen'), m.when],
    [t(L, 'emailTicketWhere'), m.where],
    [t(L, 'emailTicketPartySizeLabel'), String(m.partySize)],
    [t(L, 'emailBookingGuestLabel'), forHost ? name : null],
    [t(L, 'emailBookingRespondByLabel'), m.kind === 'request_host' ? m.respondBy : null],
  ];
  const footer = t(L, 'emailBookingFooter');
  const html = emailFrame(
    `<h2 style="margin:0 0 8px">${escapeHtml(m.title)}</h2>`
    + `<p>${escapeHtml(intro)}</p>`
    + detailsTable(rows)
    + (next ? `<p style="font-weight:bold">${escapeHtml(next)}</p>` : '')
    + `<p style="color:#666;font-size:13px">${escapeHtml(footer)}</p>`,
  );
  const text = [
    m.title, intro, '',
    ...rows.filter(([, v]) => v).map(([k, v]) => `${k}: ${v}`),
    ...(next ? ['', next] : []),
    '', footer,
  ].join('\n');
  return { to: [m.to], subject, html, text };
}

/** Pay instruction for a confirmed guest (same keys as the push body). */
export function bookingPayHint(locale: string, b: Record<string, any>, title: string): string | null {
  const mode = b.payment?.mode;
  if (mode === 'link') return t(locale, 'srvBookingPayLink', { title });
  if (mode === 'online') return t(locale, 'srvBookingPayOnline', { title });
  if (mode === 'cash') return t(locale, 'srvBookingPayCash', { title });
  return null;
}

async function profileName(uid: string): Promise<string | null> {
  if (!uid) return null;
  try {
    const p = (await db().collection('profiles').doc(uid).get()).data();
    const n = String(p?.displayName ?? p?.nickname ?? p?.name ?? '').trim();
    return n ? n.slice(0, 80) : null;
  } catch {
    return null;
  }
}

export async function sendBookingStatusEmails(
  bookingId: string,
  before: Record<string, any> | undefined,
  after: Record<string, any> | undefined,
): Promise<string[]> {
  const kinds = bookingEmailKinds(before, after);
  if (!kinds.length) return [];
  const b = after!;
  // Shared by every email of this write (listing for zone / place, guest
  // name), loaded once and only when an email is actually built.
  let shared: Promise<{ l: Record<string, any>; guestName: string | null }> | null = null;
  const load = () => (shared ??= Promise.all([
    db().collection('user_experiences').doc(String(b.experienceId)).get()
      .then((s) => (s.data() || {}) as Record<string, any>)
      .catch(() => ({} as Record<string, any>)),
    profileName(String(b.guestId || '')),
  ]).then(([l, guestName]) => ({ l, guestName })));
  const results = await Promise.allSettled(kinds.map(async (kind) => {
    const recipient = String((kind.endsWith('_host') ? b.hostId : b.guestId) || '');
    const r = await sendEmailOnce(bookingEmailKey(kind, bookingId), async () => {
      const to = await authEmailOf(recipient);
      if (!to) return null;
      const [locale, { l, guestName }] = await Promise.all([resolveLocale(recipient), load()]);
      const tz = hostTimeZone(l);
      const title = String(b.experienceTitle || l.title || 'GreenGo');
      const expiresMs = millis(b.requestExpiresAt);
      return buildBookingEmail({
        kind,
        locale,
        to,
        title,
        when: formatWhen(millis(b.slotStart), tz, locale),
        where: placeOf('experience', l),
        partySize: Math.max(1, Number(b.guests) || 1),
        guestName,
        respondBy: kind === 'request_host' && expiresMs !== null ? formatWhen(expiresMs, tz, locale) : null,
        payHint: kind === 'confirmed_guest' ? bookingPayHint(locale, b, title) : null,
      });
    }, { type: `booking_${kind}`, bookingId });
    return `${kind}:${r === 'duplicate' ? 'duplicate' : (r.sent ? 'sent' : `not_sent:${r.reason}`)}`;
  }));
  return results.map((x, i) => {
    if (x.status === 'fulfilled') return x.value;
    console.error(`[email] booking ${kinds[i]} for ${bookingId} failed:`, (x.reason as Error)?.message || x.reason);
    return `${kinds[i]}:error`;
  });
}

/**
 * Every booking write: the guest's QR ticket (when it becomes available) and
 * the request / confirmation emails to host and guest. Each email is claimed
 * once (email_dispatch), so trigger retries never duplicate.
 */
export async function handleBookingWrite(
  bookingId: string,
  before: Record<string, any> | undefined,
  after: Record<string, any> | undefined,
): Promise<string> {
  const [qr, status] = await Promise.allSettled([
    sendBookingQrEmail(bookingId, before, after),
    sendBookingStatusEmails(bookingId, before, after),
  ]);
  const parts: string[] = [];
  if (qr.status === 'fulfilled') parts.push(`qr:${qr.value}`);
  else {
    console.error(`[email] booking qr for ${bookingId} failed:`, (qr.reason as Error)?.message || qr.reason);
    parts.push('qr:error');
  }
  if (status.status === 'fulfilled') parts.push(...status.value);
  return parts.join(',');
}

export const emailTicketsOnOrderPaid = onDocumentUpdated(
  { document: 'ticket_orders/{orderId}', memory: '512MiB', timeoutSeconds: 120 },
  async (event) => {
    await handleTicketOrderUpdate(event.params.orderId, event.data?.before?.data(), event.data?.after?.data());
  },
);

export const emailBookingQrOnConfirm = onDocumentWritten(
  { document: 'bookings/{bookingId}', memory: '512MiB', timeoutSeconds: 120 },
  async (event) => {
    await handleBookingWrite(event.params.bookingId, event.data?.before?.data(), event.data?.after?.data());
  },
);
