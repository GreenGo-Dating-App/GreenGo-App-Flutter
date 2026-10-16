/**
 * Terms 17/18 (DSA arts. 17, 20, 23): pure logic of the statement of reasons,
 * appeals, repeat offenders and abusive reporters. No network, no emulator.
 */
process.env.TICKET_QR_SIGNING_KEY = 'unit-test-signing-key-0123456789abcdef0123456789';

import {
  appealLinkFor, appealSignature, automatedText, automationFor, buildDecisionEmail, contentReferenceFor,
  contentText, excerptOf, reasonText, resetAppealKey, verifyAppealSignature, actionText,
} from '../../src/safety/moderationDecisions';
import {
  ESCALATION_FIRST_DAYS, ESCALATION_REPEAT_DAYS, parseEffects, repeatOffenderEscalation,
} from '../../src/safety/moderationEffects';
import {
  ABUSE_WINDOW_DAYS, evaluateReporter, isDismissed, MIN_DISMISSED,
} from '../../src/safety/reporterStanding';
import { originalDeciders, parseResolution } from '../../src/safety/appealResolution';
import { appealFormBody, renderAppealPage } from '../../src/safety/appealPage';
import { quarantineQueueId, reasonCodeForVision } from '../../src/safety/moderateUploadedImage';
import { shouldCountUnfounded } from '../../src/safety/reportPipeline';
import { functionsBaseUrl } from '../../src/ticket_payments/config';

const DAY = 86_400_000;

describe('statement of reasons: content reference (Terms 18.3)', () => {
  test('message report: type + excerpt of the reported message', () => {
    const r = contentReferenceFor({
      source: { collection: 'message_reports' },
      contentRef: { type: 'message', id: 'm1', path: 'conversations/c/messages/m1' },
      content: { text: 'you   are\nterrible' },
    });
    expect(r).toEqual({ type: 'message', id: 'm1', excerpt: 'you are terrible' });
  });
  test("a user_reports item never shows the REPORTER's description", () => {
    const r = contentReferenceFor({
      source: { collection: 'user_reports' },
      contentRef: { type: 'message', id: 'm1', path: 'conversations/c/messages/m1' },
      content: { text: 'reporter wrote this about him' },
    });
    expect(r.excerpt).toBeNull();
    expect(r.type).toBe('message');
  });
  test('profile reports name the profile without id; vision items name the photo', () => {
    expect(contentReferenceFor({ source: { collection: 'user_reports' }, contentRef: { type: 'user', id: 'u1' } }))
      .toEqual({ type: 'profile', id: null, excerpt: null });
    expect(contentReferenceFor({ itemType: 'quarantinedImage', objectPath: 'profiles/u1/photos/a.jpg' }))
      .toEqual({ type: 'photo', id: 'a.jpg', excerpt: null });
  });
  test('excerpts are short and never a media URL', () => {
    expect(excerptOf('x'.repeat(500))!.length).toBe(140);
    expect(excerptOf('https://firebasestorage.googleapis.com/x.jpg')).toBeNull();
    expect(excerptOf('   ')).toBeNull();
  });
  test('localized labels', () => {
    expect(contentText('en', { type: 'message', id: 'm1', excerpt: 'hi' })).toBe('Message: "hi"');
    expect(contentText('de', { type: 'photo', id: 'a.jpg', excerpt: null })).toBe('Foto (a.jpg)');
    expect(actionText('it', 'banUser')).not.toBe(actionText('en', 'banUser'));
    expect(reasonText('en', 'unfounded_reports')).toBe('Repeated clearly unfounded reports');
    expect(reasonText('en', 'whatever')).toBe(reasonText('en', 'other'));
  });
});

describe('automated tools flag (Terms 17.1 b / 18.3)', () => {
  test('keyword screen, Vision and hash matches are automated; user reports are not', () => {
    expect(automationFor({ itemType: 'autoTextFlag', source: { collection: 'auto_text' } })).toEqual({ detection: 'keyword', decision: false });
    expect(automationFor({ itemType: 'quarantinedImage' }).detection).toBe('vision');
    expect(automationFor({ source: { collection: 'hash_match' } }).detection).toBe('hash');
    expect(automationFor({ source: { collection: 'user_reports' } })).toEqual({ detection: null, decision: false });
  });
  test('texts', () => {
    expect(automatedText('en', { detection: null, decision: false })).toMatch(/No automated tools/);
    expect(automatedText('en', { detection: 'keyword', decision: false })).toMatch(/flagged/);
    expect(automatedText('en', { detection: 'vision', decision: true })).toMatch(/held it back/);
  });
});

describe('signed appeal link (web path for banned users)', () => {
  beforeEach(() => resetAppealKey());
  test('valid only for the same decision AND user', async () => {
    const s = await appealSignature('d1', 'u1');
    expect(s).toHaveLength(43);
    expect(await verifyAppealSignature('d1', 'u1', s)).toBe(true);
    expect(await verifyAppealSignature('d1', 'u2', s)).toBe(false);
    expect(await verifyAppealSignature('d2', 'u1', s)).toBe(false);
    expect(await verifyAppealSignature('d1', 'u1', s.slice(0, 42) + (s[42] === 'A' ? 'B' : 'A'))).toBe(false);
    expect(await verifyAppealSignature('d1', 'u1', undefined)).toBe(false);
  });
  test('link points at the moderationAppeal function', async () => {
    const link = await appealLinkFor('user_reports__r1', 'u1', 'pt_BR');
    expect(link.startsWith(`${functionsBaseUrl()}/moderationAppeal?d=user_reports__r1&s=`)).toBe(true);
    expect(link).toContain('hl=pt_BR');
  });
});

describe('statement-of-reasons email', () => {
  const base = {
    locale: 'en', to: 'u@example.com', action: 'banUser', reasonCode: 'harassment',
    explanation: '<script>alert(1)</script> repeated insults', contentRef: { type: 'message' as const, id: 'm1', excerpt: '<b>x</b>' },
    automated: { detection: 'keyword' as const, decision: false }, appealable: true,
    appealDeadlineMs: Date.UTC(2027, 3, 17), role: 'affected' as const,
  };
  test('every value escaped; all five art. 17 elements; appeal button', () => {
    const m = buildDecisionEmail({ ...base, appealUrl: `${functionsBaseUrl()}/moderationAppeal?d=x&s=y` });
    expect(m.html).not.toContain('<script>');
    expect(m.html).toContain('&lt;script&gt;');
    expect(m.html).not.toContain('<b>x</b>');
    for (const s of ['Account banned', 'Content concerned', 'Harassment or bullying', 'Automated tools flagged', 'Appeal this decision', '17 April 2027']) {
      expect(m.html).toContain(s);
    }
    expect(m.html).toContain('href="https://us-central1-');
    expect(m.subject).toMatch(/moderation decision/);
  });
  test('a foreign link is never rendered', () => {
    const m = buildDecisionEmail({ ...base, appealUrl: 'https://evil.example/phish' });
    expect(m.html).not.toContain('evil.example');
  });
  test('not appealable -> no button', () => {
    const m = buildDecisionEmail({ ...base, appealable: false, appealUrl: null });
    expect(m.html).not.toContain('Appeal this decision');
  });
});

describe('repeat offenders (Terms 18.6: suspend after a warning)', () => {
  const h = { violations: 3, priorWarnings: 1, priorEscalations: 0, alreadyRestricted: false };
  test('3 violations in 12 months after a prior warning -> 7-day suspension', () => {
    expect(repeatOffenderEscalation(h)).toEqual({ days: ESCALATION_FIRST_DAYS });
  });
  test('never without a prior warning', () => {
    expect(repeatOffenderEscalation({ ...h, priorWarnings: 0, violations: 9 })).toBeNull();
  });
  test('below the threshold, or already suspended -> nothing', () => {
    expect(repeatOffenderEscalation({ ...h, violations: 2 })).toBeNull();
    expect(repeatOffenderEscalation({ ...h, alreadyRestricted: true })).toBeNull();
  });
  test('second escalation in the window is longer', () => {
    expect(repeatOffenderEscalation({ ...h, priorEscalations: 1 })).toEqual({ days: ESCALATION_REPEAT_DAYS });
  });
});

describe('abusive reporters (Terms 18.6 / DSA art. 23)', () => {
  const now = Date.UTC(2026, 9, 16);
  const clean = { warnedAtMs: null, suspendedUntilMs: null, reviewPending: false };
  test('often = >=10 dismissed AND >=80% of the decided reports', () => {
    expect(evaluateReporter({ dismissed: MIN_DISMISSED, actioned: 2, dismissedSinceWarning: 0 }, clean, now)).toBe('warn');
    expect(evaluateReporter({ dismissed: 9, actioned: 0, dismissedSinceWarning: 0 }, clean, now)).toBe('none');
    expect(evaluateReporter({ dismissed: 10, actioned: 3, dismissedSinceWarning: 0 }, clean, now)).toBe('none'); // 77%
  });
  test('warning first; a moderator review only if it continues after the warning', () => {
    const warned = { ...clean, warnedAtMs: now - 5 * DAY };
    expect(evaluateReporter({ dismissed: 12, actioned: 0, dismissedSinceWarning: 4 }, warned, now)).toBe('none');
    expect(evaluateReporter({ dismissed: 12, actioned: 0, dismissedSinceWarning: 5 }, warned, now)).toBe('review');
    expect(evaluateReporter({ dismissed: 12, actioned: 0, dismissedSinceWarning: 9 }, { ...warned, reviewPending: true }, now)).toBe('none');
  });
  test('an old warning does not count; a suspended reporter is not re-evaluated', () => {
    expect(evaluateReporter({ dismissed: 12, actioned: 0, dismissedSinceWarning: 12 }, { ...clean, warnedAtMs: now - 200 * DAY }, now)).toBe('warn');
    expect(evaluateReporter({ dismissed: 99, actioned: 0, dismissedSinceWarning: 99 }, { ...clean, suspendedUntilMs: now + DAY }, now)).toBe('none');
    expect(ABUSE_WINDOW_DAYS).toBe(30);
  });
  test('isDismissed', () => {
    expect(isDismissed({ status: 'pending' })).toBeNull();
    expect(isDismissed({ status: 'resolved', action: 'dismiss' })).toBe(true);
    expect(isDismissed({ status: 'resolved', action: 'approve' })).toBe(true);
    expect(isDismissed({ status: 'resolved', action: 'banUser' })).toBe(false);
    expect(isDismissed({ status: 'completed', resolvedAction: 'removeContent' })).toBe(false);
  });
  test('shouldCountUnfounded: real reporter, transition to a no-violation close', () => {
    const before = { status: 'pending', source: { collection: 'user_reports' }, reporterId: 'r1' };
    expect(shouldCountUnfounded(before, { ...before, status: 'resolved', action: 'dismiss' })).toBe(true);
    expect(shouldCountUnfounded(before, { ...before, status: 'resolved', action: 'banUser' })).toBe(false);
    expect(shouldCountUnfounded(before, { ...before, reporterId: 'anonymous', status: 'resolved', action: 'dismiss' })).toBe(false);
    expect(shouldCountUnfounded({ ...before, status: 'resolved' }, { ...before, status: 'resolved', action: 'dismiss' })).toBe(false);
  });
});

describe('appeal resolution input (Terms 18.4 b-c)', () => {
  test('outcomes and the written explanation are required', () => {
    expect(() => parseResolution({ outcome: 'maybe', explanation: 'reasons here' })).toThrow(/outcome/);
    expect(() => parseResolution({ outcome: 'upheld', explanation: 'no' })).toThrow(/explanation/);
    expect(parseResolution({ outcome: 'overturned', explanation: '  Wrong call.  ' }))
      .toEqual({ outcome: 'overturned', explanation: 'Wrong call.', replacement: null });
  });
  test('partial overturn needs a milder replacement measure', () => {
    expect(() => parseResolution({ outcome: 'partially_overturned', explanation: 'Too harsh.' })).toThrow(/replacementAction/);
    expect(() => parseResolution({ outcome: 'partially_overturned', explanation: 'Too harsh.', replacementAction: 'suspendUser', durationDays: 0 }))
      .toThrow(/durationDays/);
    expect(parseResolution({ outcome: 'partially_overturned', explanation: 'Too harsh.', replacementAction: 'suspendUser', durationDays: 3 }).replacement)
      .toEqual({ action: 'suspendUser', days: 3 });
    expect(parseResolution({ outcome: 'partially_overturned', explanation: 'Too harsh.', replacementAction: 'issueWarning' }).replacement)
      .toEqual({ action: 'issueWarning', days: 0 });
  });
  test('original deciders exclude "system" and include legacy report moderators', () => {
    expect([...originalDeciders({ decidedBy: 'mod1', confirmedBy: 'mod2' }, { originalDecidedBy: 'mod1' })].sort()).toEqual(['mod1', 'mod2']);
    expect([...originalDeciders({ decidedBy: 'system' }, {})]).toEqual([]);
    expect([...originalDeciders(null, {}, { assignedModeratorId: 'mod9' })]).toEqual(['mod9']);
  });
  test('parseEffects drops malformed entries', () => {
    expect(parseEffects([{ type: 'ban', userId: 'u' }, null, 3, { nope: 1 }])).toEqual([{ type: 'ban', userId: 'u' }]);
    expect(parseEffects(undefined)).toEqual([]);
  });
});

describe('web appeal page', () => {
  test('escapes everything and has no script', () => {
    const html = renderAppealPage({
      locale: 'en',
      facts: [['Action taken', '<img src=x onerror=alert(1)>']],
      form: { action: `${functionsBaseUrl()}/moderationAppeal`, d: 'd"1', s: 'sig', deadline: '17 April 2027' },
      message: null,
      error: false,
    });
    expect(html).not.toMatch(/<script/i);
    expect(html).not.toContain('<img');
    expect(html).toContain('value="d&quot;1"');
    expect(html).toContain('You can appeal until 17 April 2027.');
    expect(html).toContain('name="reason"');
  });
  test('form body: only known flat string fields', () => {
    expect(appealFormBody({ d: 'a', s: 'b', reason: 'c', extra: 'x' })).toEqual({ d: 'a', s: 'b', reason: 'c' });
    expect(appealFormBody({ d: ['a'] })).toBeNull();
    expect(appealFormBody(null)).toBeNull();
  });
});

describe('Vision hold', () => {
  test('reason codes: sexual/violence are rule breaches, a missing face is not', () => {
    expect(reasonCodeForVision(['adult'])).toBe('sexual_content');
    expect(reasonCodeForVision(['racy', 'no_face'])).toBe('sexual_content');
    expect(reasonCodeForVision(['violence'])).toBe('violence');
    expect(reasonCodeForVision(['no_face'])).toBeNull();
  });
  test('one queue item per object generation', () => {
    expect(quarantineQueueId('profiles/u/p.jpg', 17)).toBe('image__profiles~u~p.jpg__17');
    expect(quarantineQueueId('profiles/u/p.jpg', undefined)).toBe('image__profiles~u~p.jpg__0');
  });
});
