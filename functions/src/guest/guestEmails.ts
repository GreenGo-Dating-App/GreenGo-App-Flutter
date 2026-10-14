/**
 * E-mails to GUESTS (shared-link bookings, no account, no app: e-mail is the
 * only channel). The existing ticket e-mails already reach guests unchanged
 * (emails/ticketEmails.ts resolves a guest key's address through
 * guest_contacts, see shared/guestIdentity.ts):
 *   - paid / free-typed order -> "Your ticket" with every QR (emailTicketsOnOrderPaid)
 *   - experience request / free booking QR (emailBookingQrOnConfirm)
 * This file adds what only guests need:
 *   - free event RSVP -> ticket with the signed RSVP QR ([sendGuestRsvpTicket])
 *   - accepted experience request that must be paid -> "Pay now" link
 *   - declined / expired request, cancelled booking -> notice
 *   - refunded / disputed order -> notice
 *   - event cancelled by the host -> notice to its guest attendees
 * Each is claimed once (email_dispatch), in the guest's page language.
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { HOST } from '../share/sharePreviewCore';
import { emailFrame, detailsTable, formatWhen, hostTimeZone, millis } from '../emails/emailFormat';
import { OutgoingEmail, authEmailOf, escapeHtml, sendEmailOnce } from '../emails/sendEmail';
import { buildTicketEmail, placeOf } from '../emails/ticketEmails';
import { resolveLocale } from '../shared/i18n/recipientLocale';
import { t } from '../shared/i18n';
import { isGuestKey } from '../shared/guestIdentity';
import { eventTicketCode, eventTicketPayload, ticketSecret } from '../checkin/eventCheckin';
import { gt, GuestKey } from './guestI18n';
import { paySig } from './guestModel';
import { guestSigningKey } from './guestKeys';

const db = () => admin.firestore();

export type GuestNoticeKind = 'pay_now' | 'declined' | 'cancelled' | 'refunded';

export interface GuestNoticeModel {
  kind: GuestNoticeKind;
  locale: string;
  to: string;
  title: string;
  when: string | null;
  where: string | null;
  /** pay_now only. */
  payUrl?: string | null;
}

const SUBJECT: Record<GuestNoticeKind, GuestKey> = {
  pay_now: 'guest.mail.payNowSubject',
  declined: 'guest.mail.declinedSubject',
  cancelled: 'guest.mail.cancelledSubject',
  refunded: 'guest.mail.refundedSubject',
};
const BODY: Record<GuestNoticeKind, GuestKey> = {
  pay_now: 'guest.pay.body',
  declined: 'guest.mail.declinedBody',
  cancelled: 'guest.mail.cancelledBody',
  refunded: 'guest.mail.refundedBody',
};

/** Pure (exported for tests): every value escaped, the pay URL only https on our host. */
export function buildGuestNotice(m: GuestNoticeModel): OutgoingEmail {
  const L = m.locale;
  const rows: Array<[string, string | null]> = [
    [t(L, 'emailTicketWhen'), m.when],
    [t(L, 'emailTicketWhere'), m.where],
  ];
  const pay = m.kind === 'pay_now' && m.payUrl && m.payUrl.startsWith(`${HOST}/guest/pay/`) ? m.payUrl : null;
  const button = pay
    ? `<p style="margin:20px 0"><a href="${escapeHtml(pay)}" style="background:#0F9D58;color:#fff;padding:12px 22px;border-radius:24px;text-decoration:none;font-weight:bold">${escapeHtml(gt(L, 'guest.mail.payNowButton'))}</a></p>`
      + `<p style="color:#666;font-size:13px">${escapeHtml(gt(L, 'guest.mail.payNowFooter'))}</p>`
    : '';
  const html = emailFrame(
    `<h2 style="margin:0 0 8px">${escapeHtml(m.title)}</h2>`
    + `<p>${escapeHtml(gt(L, BODY[m.kind]))}</p>`
    + detailsTable(rows)
    + button
    + `<p style="color:#666;font-size:12px">${escapeHtml(gt(L, 'guest.mail.footer'))}</p>`,
  );
  const text = [
    m.title, gt(L, BODY[m.kind]), '',
    ...rows.filter(([, v]) => v).map(([k, v]) => `${k}: ${v}`),
    ...(pay ? ['', `${gt(L, 'guest.mail.payNowButton')}: ${pay}`, gt(L, 'guest.mail.payNowFooter')] : []),
    '', gt(L, 'guest.mail.footer'),
  ].join('\n');
  return { to: [m.to], subject: gt(L, SUBJECT[m.kind], { title: m.title }), html, text };
}

/** "Pay now" link of an accepted guest booking (capability: HMAC of the id). */
export async function guestPayUrl(bookingId: string, locale: string): Promise<string> {
  const key = await guestSigningKey();
  return `${HOST}/guest/pay/${encodeURIComponent(bookingId)}?t=${paySig(key, bookingId)}&hl=${encodeURIComponent(locale)}`;
}

function outcome(r: Awaited<ReturnType<typeof sendEmailOnce>>): string {
  return r === 'duplicate' ? 'duplicate' : (r.sent ? 'sent' : `not_sent:${r.reason}`);
}

// ─────────────────────────────────────────────────────────── free event RSVP ticket

/** Ticket with the signed RSVP QR (greengo:ev:...) for a guest of a FREE event. */
export async function sendGuestRsvpTicket(eventId: string, ev: Record<string, any>, guestKey: string): Promise<string> {
  const r = await sendEmailOnce(`guest_rsvp_${eventId}_${guestKey}`, async () => {
    const to = await authEmailOf(guestKey);
    if (!to) return null;
    const [locale, secret] = await Promise.all([resolveLocale(guestKey), ticketSecret()]);
    const code = eventTicketCode(secret, eventId, guestKey);
    return buildTicketEmail({
      locale,
      to,
      title: String(ev.title || 'GreenGo'),
      when: formatWhen(millis(ev.startDate), hostTimeZone(ev), locale),
      where: placeOf('event', ev),
      ticketType: null,
      partySize: null,
      bookingCode: code,
      qrs: [{ payload: eventTicketPayload(eventId, guestKey, code), caption: t(locale, 'emailTicketQrCaption', { index: 1, count: 1 }) }],
    });
  }, { type: 'guest_rsvp', eventId });
  return outcome(r);
}

// ─────────────────────────────────────────────────────────── bookings

/** Which notice a guest booking write needs (pure). */
export function guestBookingNotice(before: Record<string, any> | undefined, after: Record<string, any> | undefined): GuestNoticeKind | null {
  if (!after || after.isGuest !== true || !isGuestKey(after.guestId)) return null;
  if (before?.status === after.status) return null;
  const s = after.status;
  if (s === 'confirmed' && after.payment?.mode === 'online' && after.payment?.status !== 'paid') return 'pay_now';
  if (s === 'declined' || s === 'expired') return 'declined';
  if (s === 'cancelled_by_host' || s === 'cancelled_by_guest') return 'cancelled';
  return null;
}

/** Called from emails/ticketEmails.ts handleBookingWrite (the existing bookings trigger). */
export async function handleGuestBookingWrite(
  bookingId: string, before: Record<string, any> | undefined, after: Record<string, any> | undefined,
): Promise<string> {
  const kind = guestBookingNotice(before, after);
  if (!kind) return 'skipped';
  const b = after!;
  const r = await sendEmailOnce(`guest_booking_${kind}_${bookingId}`, async () => {
    const to = await authEmailOf(String(b.guestId));
    if (!to) return null;
    const [locale, exp] = await Promise.all([
      resolveLocale(String(b.guestId)),
      db().collection('user_experiences').doc(String(b.experienceId)).get().then((s) => s.data() || {}).catch(() => ({})),
    ]);
    return buildGuestNotice({
      kind,
      locale,
      to,
      title: String(b.experienceTitle || (exp as any).title || 'GreenGo'),
      when: formatWhen(millis(b.slotStart), hostTimeZone(exp as any), locale),
      where: placeOf('experience', exp as any),
      payUrl: kind === 'pay_now' ? await guestPayUrl(bookingId, locale) : null,
    });
  }, { type: `guest_booking_${kind}`, bookingId });
  return outcome(r);
}

// ─────────────────────────────────────────────────────────── orders

/** Paid guest order refunded / disputed -> notice (pure decision). */
export function guestOrderNotice(before: Record<string, any> | undefined, after: Record<string, any> | undefined): GuestNoticeKind | null {
  if (!after || after.isGuest !== true || !isGuestKey(after.buyerId)) return null;
  if (before?.status === after.status) return null;
  if (after.status === 'refunded' || after.status === 'disputed') return 'refunded';
  return null;
}

/** Called from emails/ticketEmails.ts (the existing ticket_orders trigger). */
export async function handleGuestOrderUpdate(
  orderId: string, before: Record<string, any> | undefined, after: Record<string, any> | undefined,
): Promise<string> {
  const kind = guestOrderNotice(before, after);
  if (!kind) return 'skipped';
  const o = after!;
  const r = await sendEmailOnce(`guest_order_${kind}_${orderId}`, async () => {
    const to = await authEmailOf(String(o.buyerId));
    if (!to) return null;
    const col = o.kind === 'experience' ? 'user_experiences' : 'events';
    const [locale, l] = await Promise.all([
      resolveLocale(String(o.buyerId)),
      db().collection(col).doc(String(o.listingId)).get().then((s) => s.data() || {}).catch(() => ({})),
    ]);
    return buildGuestNotice({
      kind, locale, to,
      title: String(o.title || (l as any).title || 'GreenGo'),
      when: formatWhen(millis(o.startsAt), hostTimeZone(l as any), locale),
      where: placeOf(o.kind === 'experience' ? 'experience' : 'event', l as any),
    });
  }, { type: `guest_order_${kind}`, orderId });
  return outcome(r);
}

// ─────────────────────────────────────────────────────────── event cancelled

export function becameCancelled(before: Record<string, any> | undefined, after: Record<string, any> | undefined): boolean {
  return !!before && !!after && before.status !== 'cancelled' && after.status === 'cancelled';
}

/**
 * The host cancelled an event: every GUEST attendee gets a notice (members
 * see it in the app). Paged, indexed query (attendees isGuest ==, single-field).
 */
export async function emailGuestsOfCancelledEvent(eventId: string, ev: Record<string, any>): Promise<number> {
  let sent = 0;
  let last: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  for (;;) {
    let q = db().collection('events').doc(eventId).collection('attendees')
      .where('isGuest', '==', true).orderBy(admin.firestore.FieldPath.documentId()).limit(200);
    if (last) q = q.startAfter(last);
    const page = await q.get();
    for (const d of page.docs) {
      if (!isGuestKey(d.id)) continue;
      const r = await sendEmailOnce(`guest_event_cancelled_${eventId}_${d.id}`, async () => {
        const to = await authEmailOf(d.id);
        if (!to) return null;
        const locale = await resolveLocale(d.id);
        return buildGuestNotice({
          kind: 'cancelled', locale, to, title: String(ev.title || 'GreenGo'),
          when: formatWhen(millis(ev.startDate), hostTimeZone(ev), locale),
          where: placeOf('event', ev),
        });
      }, { type: 'guest_event_cancelled', eventId });
      if (r !== 'duplicate' && r.sent) sent++;
    }
    if (page.size < 200) break;
    last = page.docs[page.docs.length - 1];
  }
  return sent;
}
