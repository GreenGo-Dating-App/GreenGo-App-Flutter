/**
 * User experiences — Phase 1 safety (pure): contact-info detection (shared
 * fixture with the Dart mirror), cancellation policy normalisation, ID
 * document / agreement / new-host publish rules, report auto-hide threshold.
 */
import {
  findContactInfo,
  moderateCommentText,
  moderateExperienceText,
  experienceModerationPatch,
} from '../../src/user_experiences/moderation';
import {
  normalizeCancellation,
  idDocumentState,
  takesPayment,
  createBlockReason,
  publishBlockReason,
  shouldHideForReports,
  HOST_AGREEMENT_VERSION,
} from '../../src/user_experiences/safety';
import { validateExperiencePayload } from '../../src/user_experiences/validation';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const fixture = require('../fixtures/contact_info_cases.json') as {
  cases: Array<{ text: string; kinds: string[] }>;
};

describe('contact info (shared fixture)', () => {
  it.each(fixture.cases.map((c) => [c.text, c.kinds] as [string, string[]]))(
    '%s',
    (text, kinds) => {
      expect(findContactInfo(text).sort()).toEqual([...kinds].sort());
    },
  );

  it('reviews / replies with contact info are rejected as contact_info', () => {
    expect(moderateCommentText('Great host, call 11 98765-4321').reason).toBe('contact_info');
    expect(moderateCommentText('Great host!').ok).toBe(true);
  });

  it('experience text is checked, the paymentLink field is exempt', () => {
    const base = {
      title: 'Cooking class',
      description: 'A lovely evening cooking pasta together.',
      included: ['dinner'],
      paymentLink: { type: 'pix', value: 'maria@example.com' },
    };
    expect(moderateExperienceText(base).ok).toBe(true);
    expect(moderateExperienceText({ ...base, meetingPoint: 'WhatsApp me' }).reason)
      .toBe('contact_info');
    expect(moderateExperienceText({ ...base, cancellationNotes: 'mail a@b.co' }).reason)
      .toBe('contact_info');
    expect(moderateExperienceText({ ...base, included: ['dinner', '@maria_tours'] }).ok)
      .toBe(false);
    const hidden = experienceModerationPatch({
      ...base,
      status: 'published',
      description: 'pay me on paypal please, thank you',
    });
    expect(hidden).toMatchObject({
      status: 'hidden',
      moderation: { auto: true, reason: 'contact_info' },
    });
  });
});

describe('cancellation policy', () => {
  it('keeps a valid enum + trims notes to 300', () => {
    expect(normalizeCancellation({ cancellationPolicy: 'strict', cancellationNotes: ' x ' }))
      .toEqual({ cancellationPolicy: 'strict', cancellationNotes: 'x' });
    expect(normalizeCancellation({
      cancellationPolicy: 'flexible',
      cancellationNotes: 'n'.repeat(400),
    }).cancellationNotes).toHaveLength(300);
  });

  it('defaults to moderate; legacy free text becomes the notes', () => {
    expect(normalizeCancellation({}))
      .toEqual({ cancellationPolicy: 'moderate', cancellationNotes: null });
    expect(normalizeCancellation({ cancellationPolicy: 'Full refund 2 days before' }))
      .toEqual({ cancellationPolicy: 'moderate', cancellationNotes: 'Full refund 2 days before' });
  });

  it('validation stores the normalised pair', () => {
    const v = validateExperiencePayload({ cancellationPolicy: 'bogus' });
    expect(v.data.cancellationPolicy).toBe('moderate');
    expect(v.data.cancellationNotes).toBe('bogus');
  });
});

describe('ID document + publish rules', () => {
  // Paid listings need an ACTIVE business account (isBusiness + Platinum).
  const business = { isBusiness: true, membershipTier: 'PLATINUM', membershipEndDate: new Date('2100-01-01T00:00:00Z') };
  const approved = {
    isAgeVerified: true,
    ageVerification: { status: 'verified' },
    hostAgreementVersion: HOST_AGREEMENT_VERSION,
    ...business,
  };
  const pending = {
    ageVerification: { status: 'pending' },
    hostAgreementVersion: HOST_AGREEMENT_VERSION,
    ...business,
  };
  const paid = { isFree: false, price: 50, paymentLink: { type: 'pix', value: 'k' } };
  const free = { isFree: true, price: 0, paymentLink: null };

  it('document state', () => {
    expect(idDocumentState(null)).toBe('none');
    expect(idDocumentState({ ageVerification: { status: 'declared' } })).toBe('none');
    expect(idDocumentState({ ageVerification: { status: 'rejected' } })).toBe('none');
    expect(idDocumentState(pending)).toBe('uploaded');
    expect(idDocumentState(approved)).toBe('approved');
  });

  it('takes payment = paid OR has a link', () => {
    expect(takesPayment(paid)).toBe(true);
    expect(takesPayment(free)).toBe(false);
    expect(takesPayment({ isFree: true, paymentLink: { type: 'pix', value: 'tip' } })).toBe(true);
  });

  it('create needs an uploaded document; banned hosts never', () => {
    expect(createBlockReason({ ageVerification: { status: 'declared' } }))
      .toBe('id_document_required');
    expect(createBlockReason(pending)).toBeNull();
    expect(createBlockReason({ ...approved, isBanned: true })).toBe('host_banned');
  });

  it('publish: agreement, then approval for paid, then the new-host limit', () => {
    expect(publishBlockReason({
      profile: { ...pending, hostAgreementVersion: 0 }, experience: free, otherPublishedPaid: 0,
    })).toBe('host_agreement_required');
    expect(publishBlockReason({ profile: pending, experience: free, otherPublishedPaid: 0 }))
      .toBeNull();
    expect(publishBlockReason({ profile: pending, experience: paid, otherPublishedPaid: 0 }))
      .toBe('id_document_not_approved');
    expect(publishBlockReason({ profile: approved, experience: paid, otherPublishedPaid: 0 }))
      .toBeNull();
    expect(publishBlockReason({ profile: approved, experience: paid, otherPublishedPaid: 1 }))
      .toBe('new_host_paid_limit');
    // 3 visible reviews lift the limit; admins skip it
    expect(publishBlockReason({
      profile: { ...approved, hostRatingCount: 3 }, experience: paid, otherPublishedPaid: 4,
    })).toBeNull();
    expect(publishBlockReason({
      profile: { ...approved, isAdmin: true }, experience: paid, otherPublishedPaid: 4,
    })).toBeNull();
    // free listings are never limited
    expect(publishBlockReason({ profile: approved, experience: free, otherPublishedPaid: 9 }))
      .toBeNull();
  });

  it('paid listings only for an ACTIVE business account', () => {
    const personal = { ...approved, isBusiness: false };
    expect(publishBlockReason({ profile: personal, experience: paid, otherPublishedPaid: 0 }))
      .toBe('business_required');
    // a payment link alone also takes money
    expect(publishBlockReason({
      profile: personal, experience: { ...free, paymentLink: { type: 'pix', value: 'k' } },
      otherPublishedPaid: 0,
    })).toBe('business_required');
    // business whose Platinum lapsed: paused
    const lapsed = { ...approved, membershipEndDate: new Date('2001-01-01T00:00:00Z') };
    expect(publishBlockReason({ profile: lapsed, experience: paid, otherPublishedPaid: 0 }))
      .toBe('business_required');
    // Platinum without the business flag is not enough
    expect(publishBlockReason({
      profile: { ...approved, isBusiness: undefined }, experience: paid, otherPublishedPaid: 0,
    })).toBe('business_required');
    // free listings: everyone
    expect(publishBlockReason({ profile: personal, experience: free, otherPublishedPaid: 0 }))
      .toBeNull();
  });
});

describe('report auto-hide', () => {
  it('hides at 3 distinct reporters, once', () => {
    expect(shouldHideForReports(2, 'published')).toBe(false);
    expect(shouldHideForReports(3, 'published')).toBe(true);
    expect(shouldHideForReports(3, 'draft')).toBe(true);
    expect(shouldHideForReports(4, 'hidden')).toBe(false);
  });
});
