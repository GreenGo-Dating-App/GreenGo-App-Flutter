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

export async function handleBookingWrite(
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
