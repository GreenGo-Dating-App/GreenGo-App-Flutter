/**
 * Transactional emails (functions/src/emails): pure parts — subject / link
 * building, CSV escaping, scheduler window, permission predicate, QR encoder,
 * ticket email content, and "no Resend key -> skip, never throw".
 */
import { createHash } from 'crypto';
import {
  DEFAULT_VERIFICATION_RECIPIENT, isNewSubmission, verificationEmailHtml, verificationRecipients,
  verificationReviewLink, verificationSubject,
} from '../../src/emails/verificationSubmittedEmail';
import {
  buildParticipantsCsv, canReceiveList, csvCell, dueWindow, LEAD_MS, participantsDispatchKey, safeFileName,
} from '../../src/emails/participantsList';
import {
  becamePaid, bookingQrReady, buildTicketEmail, orderBookingCode, placeOf, ticketTypeSummary,
} from '../../src/emails/ticketEmails';
import { emailDeps, escapeHtml, sendEmail } from '../../src/emails/sendEmail';
import { encodeQr, qrPng } from '../../src/emails/qrPng';
import { formatWhen, hostTimeZone, joinPlace } from '../../src/emails/emailFormat';
import { idAutoVerifyEnabled } from '../../src/safety/ageAssurance';

const UID = 'AbC123xyzUSERuid0001';

describe('ID verification email', () => {
  test('subject is exactly "DOCUMENTVERIFICATION FOR USER <uid>"', () => {
    expect(verificationSubject(UID)).toBe(`DOCUMENTVERIFICATION FOR USER ${UID}`);
  });

  test('link points at the panel page for that user (encoded), custom https base allowed', () => {
    expect(verificationReviewLink(UID, undefined)).toBe(`https://greengo-chat-admin.web.app/age-verification?user=${UID}`);
    expect(verificationReviewLink('a/b?c', undefined)).toBe('https://greengo-chat-admin.web.app/age-verification?user=a%2Fb%3Fc');
    expect(verificationReviewLink(UID, 'https://panel.example.com/')).toBe(`https://panel.example.com/age-verification?user=${UID}`);
    expect(verificationReviewLink(UID, 'http://evil.example.com')).toContain('https://greengo-chat-admin.web.app/');
  });

  test('recipients: env list (comma / space separated, invalid dropped), default address', () => {
    expect(verificationRecipients(undefined)).toEqual([DEFAULT_VERIFICATION_RECIPIENT]);
    expect(verificationRecipients('')).toEqual(['greengochat.com@gmail.com']);
    expect(verificationRecipients('a@x.com, b@y.org;nope a@x.com')).toEqual(['a@x.com', 'b@y.org']);
    expect(verificationRecipients('not-an-email')).toEqual([DEFAULT_VERIFICATION_RECIPIENT]);
  });

  test('body carries only uid + link (no personal data placeholders)', () => {
    const html = verificationEmailHtml(UID, verificationReviewLink(UID, undefined));
    expect(html).toContain(UID);
    expect(html).toContain('/age-verification?user=');
    expect(html).not.toMatch(/<img/i);
  });

  test('isNewSubmission: pending creation / re-submission only', () => {
    const ts = (ms: number) => ({ toMillis: () => ms });
    expect(isNewSubmission(undefined, { status: 'pending', submittedAt: ts(1) })).toBe(true);
    expect(isNewSubmission({ status: 'rejected' }, { status: 'pending', submittedAt: ts(1) })).toBe(true);
    expect(isNewSubmission({ status: 'pending', submittedAt: ts(1) }, { status: 'pending', submittedAt: ts(1), x: 1 })).toBe(false);
    expect(isNewSubmission({ status: 'pending', submittedAt: ts(1) }, { status: 'pending', submittedAt: ts(2) })).toBe(true);
    expect(isNewSubmission({ status: 'pending' }, { status: 'approved' })).toBe(false);
    expect(isNewSubmission({ status: 'pending' }, undefined)).toBe(false);
  });

  test('auto-verify is OFF unless ID_AUTO_VERIFY=true', () => {
    expect(idAutoVerifyEnabled(undefined)).toBe(false);
    expect(idAutoVerifyEnabled('')).toBe(false);
    expect(idAutoVerifyEnabled('1')).toBe(false);
    expect(idAutoVerifyEnabled('TRUE')).toBe(true);
  });
});

describe('participants CSV', () => {
  test('csvCell quotes commas / quotes / newlines / edge spaces and neutralises formulas', () => {
    expect(csvCell('Anna')).toBe('Anna');
    expect(csvCell('Doe, Jane')).toBe('"Doe, Jane"');
    expect(csvCell('say "hi"')).toBe('"say ""hi"""');
    expect(csvCell('two\nlines')).toBe('"two\nlines"');
    expect(csvCell(' pad')).toBe('" pad"');
    expect(csvCell('=HYPERLINK("x")')).toBe('"\'=HYPERLINK(""x"")"');
    expect(csvCell('+123')).toBe("'+123");
    expect(csvCell('-1')).toBe("'-1");
    expect(csvCell('@cmd')).toBe("'@cmd");
    expect(csvCell(null)).toBe('');
    expect(csvCell(3)).toBe('3');
    expect(csvCell('Zoë 日本')).toBe('Zoë 日本');
  });

  test('CSV: BOM, localized header + statuses, CRLF rows', () => {
    const csv = buildParticipantsCsv('it', [
      { name: 'Rossi, Mario', email: 'm@x.it', bookingCode: 'GG-ABC234', ticket: 'VIP × 2 (2)', status: 'paid' },
      { name: 'Anna', email: '', bookingCode: 'K7Q2M9PX', ticket: '3', status: 'checked_in' },
    ]);
    expect(csv.startsWith('﻿')).toBe(true);
    const lines = csv.slice(1).split('\r\n');
    expect(lines[0]).toBe('Nome,Email,Codice di prenotazione,Tipo di biglietto / persone,Stato');
    expect(lines[1]).toBe('"Rossi, Mario",m@x.it,GG-ABC234,VIP × 2 (2),pagato');
    expect(lines[2]).toBe('Anna,,K7Q2M9PX,3,check-in fatto');
    expect(lines[3]).toBe('');
    expect(buildParticipantsCsv('en', []).slice(1)).toBe('Name,Email,Booking code,Ticket type / party size,Status\r\n');
  });

  test('scheduler window is (now, now + 1h]; dispatch key is per listing start', () => {
    expect(LEAD_MS).toBe(3600000);
    expect(dueWindow(1000)).toEqual({ from: 1000, to: 1000 + 3600000 });
    expect(participantsDispatchKey('event', 'e1', 5)).toBe('participants_event_e1_5');
    expect(participantsDispatchKey('experience', 'x', 5)).not.toBe(participantsDispatchKey('experience', 'x', 6));
  });

  test('permission predicate: organizer / co-organizer / host only', () => {
    const ev = { organizerId: 'o', coOrganizerIds: ['c1'] };
    expect(canReceiveList('event', 'o', ev)).toBe(true);
    expect(canReceiveList('event', 'c1', ev)).toBe(true);
    expect(canReceiveList('event', 'x', ev)).toBe(false);
    expect(canReceiveList('event', 'o', undefined)).toBe(false);
    expect(canReceiveList('experience', 'h', { hostId: 'h' })).toBe(true);
    expect(canReceiveList('experience', 'o', { hostId: 'h', organizerId: 'o' })).toBe(false);
    expect(canReceiveList('event', '', { organizerId: '' })).toBe(false);
  });

  test('file name is safe', () => {
    expect(safeFileName('Fête à Paris / 2026')).toBe('participants-Fete-a-Paris-2026.csv');
    expect(safeFileName('???')).toBe('participants-list.csv');
  });
});

describe('ticket email', () => {
  test('helpers', () => {
    expect(orderBookingCode('ord1', { code: 'GG-ABCDEF' })).toBe('GG-ABCDEF');
    expect(orderBookingCode('ord1', { code: null })).toBe('ord1');
    expect(ticketTypeSummary([{ ticketTypeName: 'VIP' }, { ticketTypeName: 'VIP' }, { ticketTypeName: 'General' }])).toBe('VIP × 2, General × 1');
    expect(ticketTypeSummary([{ ticketTypeName: null }])).toBeNull();
    expect(placeOf('event', { locationName: 'Bar X', address: 'Via Roma 1', city: 'Roma' })).toBe('Bar X, Via Roma 1, Roma');
    expect(placeOf('experience', { meetingPoint: 'Fountain', locationName: 'Roma', city: 'roma' })).toBe('Fountain, Roma');
    expect(joinPlace(['', null, ' a '])).toBe('a');
    expect(becamePaid({ status: 'pending' }, { status: 'paid' })).toBe(true);
    expect(becamePaid({ status: 'paid' }, { status: 'paid' })).toBe(false);
    expect(becamePaid(undefined, { status: 'pending' })).toBe(false);
  });

  test('bookingQrReady mirrors getBookingCheckInCode (online handled by the order email)', () => {
    expect(bookingQrReady({ status: 'confirmed', payment: { mode: 'free' } })).toBe(true);
    expect(bookingQrReady({ status: 'confirmed', payment: { mode: 'cash' } })).toBe(true);
    expect(bookingQrReady({ status: 'confirmed', payment: { mode: 'link' } })).toBe(false);
    expect(bookingQrReady({ status: 'confirmed', payment: { mode: 'link', hostConfirmedPaidAt: 1 } })).toBe(true);
    expect(bookingQrReady({ status: 'confirmed', payment: { mode: 'online', status: 'paid' } })).toBe(false);
    expect(bookingQrReady({ status: 'requested', payment: { mode: 'free' } })).toBe(false);
    expect(bookingQrReady(undefined)).toBe(false);
  });

  test('host time zone + recipient locale formatting', () => {
    const ms = Date.UTC(2026, 10, 14, 18, 30); // 14 Nov 2026 18:30 UTC
    const de = formatWhen(ms, 'Europe/Rome', 'de');
    expect(de).toContain('19:30');
    expect(de).toContain('November');
    expect(de).toContain('(Europe/Rome)');
    expect(formatWhen(ms, 'America/Sao_Paulo', 'pt_BR')).toContain('15:30');
    expect(formatWhen(ms, 'Not/AZone', 'en')).toContain('(UTC)');
    expect(formatWhen(null, 'UTC', 'en')).toBe('-');
    expect(hostTimeZone({ availabilityRules: { timezone: 'Asia/Tokyo' } })).toBe('Asia/Tokyo');
    expect(hostTimeZone({ timezone: 'Europe/Lisbon' })).toBe('Europe/Lisbon');
    expect(hostTimeZone({})).toBe('UTC');
  });

  test('localized subject, escaped title, one inline QR PNG per ticket, token only inside the images', () => {
    const payloads = ['greengo:tk:ord1_1.SIGNATURE_ONE', 'greengo:tk:ord1_2.SIGNATURE_TWO'];
    const msg = buildTicketEmail({
      locale: 'de', to: 'buyer@example.com', title: '<b>Jazz</b> & more', when: 'Sa., 19:30 (Europe/Rome)',
      where: 'Bar X', ticketType: 'VIP × 2', partySize: 2, bookingCode: 'GG-ABC234',
      qrs: payloads.map((p, i) => ({ payload: p, caption: `Ticket ${i + 1} von 2` })),
    });
    expect(msg.subject).toBe('Dein Ticket für <b>Jazz</b> & more');
    expect(msg.html).toContain('&lt;b&gt;Jazz&lt;/b&gt; &amp; more');
    expect(msg.html).toContain('Buchungscode');
    expect(msg.html).toContain('GG-ABC234');
    expect(msg.html).toContain('cid:ticket-qr-1');
    expect(msg.html).toContain('cid:ticket-qr-2');
    expect(msg.attachments).toHaveLength(2);
    expect(msg.attachments![0]).toMatchObject({ contentId: 'ticket-qr-1', contentType: 'image/png', filename: 'ticket-1.png' });
    expect(msg.attachments![0].content.subarray(0, 8).toString('hex')).toBe('89504e470d0a1a0a');
    expect(msg.html + msg.text).not.toContain('SIGNATURE_ONE');
  });
});

describe('QR encoder', () => {
  // Hashes of PNGs that an independent decoder (zxing-cpp) read back correctly.
  test('known-good output (decoded by zxing-cpp) stays byte-identical', () => {
    const h = (s: string) => createHash('sha256').update(qrPng(s, 4)).digest('hex');
    expect(h('greengo:checkin:bk_0123456789abcdef0123456789ab:ABCD2345'))
      .toBe('931ecd3b43668add9d6f5e26f499f3a0c172241a1817bdc3404b82ac521da9f1');
    expect(h('y'.repeat(213))).toBe('3059c1fd9ae805215377252e49b1d72c8c6fc6acc61df567b9ac46775358a1e0');
  });

  test('version grows with payload; finder patterns present; > 213 bytes refused', () => {
    expect(encodeQr('A')).toHaveLength(21);
    expect(encodeQr('y'.repeat(213))).toHaveLength(57);
    const m = encodeQr('greengo:tk:x');
    const n = m.length;
    for (const [x, y] of [[0, 0], [n - 7, 0], [0, n - 7]]) {
      expect(m[y][x]).toBe(true);
      expect(m[y + 1][x + 1]).toBe(false);
      expect(m[y + 3][x + 3]).toBe(true);
    }
    expect(() => encodeQr('y'.repeat(214))).toThrow(/too long/);
  });
});

describe('sendEmail without a Resend key', () => {
  const realDb = emailDeps.db;
  const realFetch = emailDeps.fetch;
  afterEach(() => { emailDeps.db = realDb; emailDeps.fetch = realFetch; delete process.env.RESEND_API_KEY; });

  test('logs and returns not_configured; never calls Resend, never throws', async () => {
    delete process.env.RESEND_API_KEY;
    emailDeps.db = (() => ({ doc: () => ({ get: async () => ({ data: () => ({ senderEmail: 'x@y.z' }) }) }) })) as any;
    const fetch = jest.fn();
    emailDeps.fetch = fetch as any;
    await expect(sendEmail({ to: ['a@b.co'], subject: 's', html: 'h' })).resolves.toEqual({ sent: false, reason: 'not_configured' });
    expect(fetch).not.toHaveBeenCalled();
  });

  test('settings read failure is tolerated; env key sends with inline attachment fields', async () => {
    process.env.RESEND_API_KEY = 're_env';
    emailDeps.db = (() => ({ doc: () => ({ get: async () => { throw new Error('offline'); } }) })) as any;
    const fetch = jest.fn(async () => ({ ok: true, status: 200 }));
    emailDeps.fetch = fetch as any;
    const r = await sendEmail({
      to: ['a@b.co', 'bad'], subject: 's', html: 'h',
      attachments: [{ filename: 'q.png', content: Buffer.from('x'), contentType: 'image/png', contentId: 'cid1' }],
    });
    expect(r).toEqual({ sent: true });
    const body = JSON.parse((fetch.mock.calls[0] as any)[1].body);
    expect(body.to).toEqual(['a@b.co']);
    expect(body.attachments[0]).toEqual({ filename: 'q.png', content: 'eA==', content_type: 'image/png', content_id: 'cid1' });
  });

  test('no valid recipient -> no_recipient', async () => {
    await expect(sendEmail({ to: ['nope'], subject: 's', html: 'h' })).resolves.toEqual({ sent: false, reason: 'no_recipient' });
  });

  test('escapeHtml', () => {
    expect(escapeHtml(`<a href="x">'&`)).toBe('&lt;a href=&quot;x&quot;&gt;&#39;&amp;');
  });
});
