/**
 * User experiences — pure server helpers: moderation decisions, rating
 * aggregate math, creation limits and payload validation.
 */
import {
  findProhibitedTerms,
  containsLink,
  moderateCommentText,
  moderateExperienceText,
  reviewStatusFor,
  experienceModerationPatch,
  sanitizeMentions,
  replyRecipients,
} from '../../src/user_experiences/moderation';
import {
  computeAggregateDelta,
  applyAggregateDelta,
  aggregateFromReviews,
  isZeroDelta,
  validRating,
} from '../../src/user_experiences/aggregates';
import {
  maxExperiencesFor,
  canCreateExperience,
  validateExperiencePayload,
  buildSearchKeywords,
} from '../../src/user_experiences/validation';
import { effectiveTier } from '../../src/shared/effectiveTier';

describe('moderation', () => {
  it('matches whole tokens only, case/accent aware', () => {
    expect(findProhibitedTerms('What a SHIT tour')).toEqual(['shit']);
    expect(findProhibitedTerms('Scunthorpe and cocktails')).toEqual([]);
    expect(findProhibitedTerms('quel connard, enculé')).toEqual(
      expect.arrayContaining(['connard', 'enculé']),
    );
    expect(findProhibitedTerms('')).toEqual([]);
    expect(findProhibitedTerms(undefined)).toEqual([]);
  });

  it('detects links', () => {
    expect(containsLink('see https://x.com')).toBe(true);
    expect(containsLink('visit www.example.org')).toBe(true);
    expect(containsLink('great guide, lovely food')).toBe(false);
  });

  it('comment decision: prohibited wins over links', () => {
    expect(moderateCommentText('Lovely evening!')).toEqual({ ok: true });
    expect(moderateCommentText('buy at www.spam.com').reason).toBe('contains_link');
    expect(moderateCommentText('fuck www.spam.com').reason).toBe('prohibited_terms');
    expect(reviewStatusFor('Great')).toBe('visible');
    expect(reviewStatusFor('http://a.b')).toBe('rejected');
  });

  it('experience decision checks every text field but allows links', () => {
    expect(moderateExperienceText({ title: 'Cooking class', description: 'https://ok.com' }).ok)
      .toBe(true);
    expect(moderateExperienceText({ title: 'ok', included: ['water', 'porn'] }).ok).toBe(false);
  });

  it('auto-hides prohibited listings and restores once clean', () => {
    const hidden = experienceModerationPatch({ title: 'merda tour', status: 'published' });
    expect(hidden).toMatchObject({
      status: 'hidden',
      moderation: { auto: true, previousStatus: 'published' },
    });
    // Already hidden → no rewrite (no trigger loop).
    expect(experienceModerationPatch({ title: 'merda', status: 'hidden', moderation: { auto: true } }))
      .toBeNull();
    // Fixed text → restored to the remembered status.
    expect(experienceModerationPatch({
      title: 'Clean tour', status: 'hidden',
      moderation: { auto: true, previousStatus: 'published' },
    })).toEqual({ status: 'published', moderation: null });
    // Admin hide (no auto flag) is never undone.
    expect(experienceModerationPatch({ title: 'Clean', status: 'hidden', moderation: { reason: 'admin' } }))
      .toBeNull();
    expect(experienceModerationPatch({ title: 'Clean', status: 'draft' })).toBeNull();
  });

  it('sanitises mentions and picks reply recipients', () => {
    expect(sanitizeMentions(['a', 'a', 'me', 5, 'b'], 'me')).toEqual(['a', 'b']);
    expect(sanitizeMentions(Array.from({ length: 30 }, (_, i) => `u${i}`), 'x')).toHaveLength(10);
    expect(sanitizeMentions('nope', 'x')).toEqual([]);

    expect(replyRecipients({ replyAuthorId: 'r', reviewAuthorId: 'ra', mentions: ['h'] })).toEqual([
      { uid: 'h', type: 'experience_mention' },
      { uid: 'ra', type: 'experience_reply' },
    ]);
    // Review author mentioned → only the mention notification.
    expect(replyRecipients({ replyAuthorId: 'r', reviewAuthorId: 'ra', mentions: ['ra'] })).toEqual([
      { uid: 'ra', type: 'experience_mention' },
    ]);
    // Replying to your own review notifies nobody extra.
    expect(replyRecipients({ replyAuthorId: 'ra', reviewAuthorId: 'ra', mentions: [] })).toEqual([]);
  });
});

describe('rating aggregates', () => {
  const v = (rating: number) => ({ rating, status: 'visible' });

  it('validRating accepts integers 1..5 only', () => {
    expect(validRating(1)).toBe(1);
    expect(validRating(5)).toBe(5);
    expect(validRating(0)).toBeNull();
    expect(validRating(3.5)).toBeNull();
    expect(validRating('4')).toBeNull();
  });

  it('create / update / delete / reject deltas', () => {
    expect(computeAggregateDelta(null, v(4))).toEqual({ sum: 4, count: 1, dist: { '4': 1 } });
    expect(computeAggregateDelta(v(4), v(2))).toEqual({ sum: -2, count: 0, dist: { '4': -1, '2': 1 } });
    expect(computeAggregateDelta(v(4), null)).toEqual({ sum: -4, count: -1, dist: { '4': -1 } });
    expect(computeAggregateDelta(v(4), { rating: 4, status: 'rejected' }))
      .toEqual({ sum: -4, count: -1, dist: { '4': -1 } });
    // Not yet moderated (no status) counts for nothing.
    expect(isZeroDelta(computeAggregateDelta(null, { rating: 5 }))).toBe(true);
    expect(isZeroDelta(computeAggregateDelta(v(3), v(3)))).toBe(true);
  });

  it('applies deltas and keeps avg/dist consistent', () => {
    let agg = applyAggregateDelta({}, computeAggregateDelta(null, v(5)));
    agg = applyAggregateDelta(agg as any, computeAggregateDelta(null, v(4)));
    agg = applyAggregateDelta(agg as any, computeAggregateDelta(null, v(4)));
    expect(agg).toEqual({
      ratingSum: 13, ratingCount: 3, ratingAvg: 4.33, reviewCount: 3,
      ratingDist: { '1': 0, '2': 0, '3': 0, '4': 2, '5': 1 },
    });
    agg = applyAggregateDelta(agg as any, computeAggregateDelta(v(5), null));
    expect(agg.ratingAvg).toBe(4);
    expect(agg.ratingCount).toBe(2);
  });

  it('never goes negative and resets to zero when empty', () => {
    const agg = applyAggregateDelta({ ratingSum: 3, ratingCount: 1 }, { sum: -8, count: -3, dist: { '5': -2 } });
    expect(agg).toEqual({
      ratingSum: 0, ratingCount: 0, ratingAvg: 0, reviewCount: 0,
      ratingDist: { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 },
    });
  });

  it('out-of-order deltas converge to the recomputed aggregate', () => {
    const d1 = computeAggregateDelta(null, v(2));
    const d2 = computeAggregateDelta(v(2), v(5)); // edit
    const d3 = computeAggregateDelta(null, v(3));
    let a = applyAggregateDelta({}, d3);
    a = applyAggregateDelta(a as any, d1);
    a = applyAggregateDelta(a as any, d2);
    expect(a).toEqual(aggregateFromReviews([v(5), v(3)]));
  });
});

describe('creation limits', () => {
  const future = new Date(Date.now() + 86400000).toISOString();
  const past = new Date(Date.now() - 86400000).toISOString();

  it('limits per effective tier', () => {
    expect(maxExperiencesFor('FREE')).toBe(1);
    expect(maxExperiencesFor('SILVER')).toBe(5);
    expect(maxExperiencesFor('GOLD')).toBe(10);
    expect(maxExperiencesFor('PLATINUM')).toBeNull();
    expect(maxExperiencesFor('TEST')).toBeNull();
    expect(maxExperiencesFor('FREE', true)).toBeNull();
  });

  it('an expired Silver counts as Free', () => {
    const expired = effectiveTier({ membershipTier: 'SILVER', membershipEndDate: past });
    const active = effectiveTier({ membershipTier: 'SILVER', membershipEndDate: future });
    // Free allows 1, Silver 5: with 1 experience an expired Silver is blocked.
    expect(canCreateExperience(expired, 0)).toBe(true);
    expect(canCreateExperience(expired, 1)).toBe(false);
    expect(canCreateExperience(active, 1)).toBe(true);
    expect(canCreateExperience(active, 5)).toBe(false);
  });

  it('downgraded hosts over the limit just cannot create more', () => {
    expect(canCreateExperience('GOLD', 12)).toBe(false);
    expect(canCreateExperience('PLATINUM', 999)).toBe(true);
  });
});

describe('payload validation', () => {
  const good = {
    title: 'Street food walk',
    description: 'Taste the best pastel and caldo de cana around the old market.',
    category: 'foodDrink',
    mainPhotoUrl: 'https://cdn.example.com/a.jpg',
    photoUrls: ['https://cdn.example.com/b.jpg'],
    included: ['Tastings', 'Water'],
    notIncluded: ['Transport'],
    locationName: 'Mercado Municipal, São Paulo',
    city: 'São Paulo',
    country: 'Brazil',
    lat: -23.54,
    lng: -46.63,
    geohash: '6gyf4',
    durationMinutes: 120,
    languages: ['Portuguese', 'English'],
    maxGroupSize: 8,
    minGroupSize: 2,
    price: 50,
    currency: 'R$',
    isFree: false,
    paymentLink: { type: 'pix', value: 'host@example.com' },
    status: 'published',
    // Server-owned junk must be ignored.
    ratingSum: 500,
    ratingCount: 100,
    hostId: 'someone-else',
  };

  it('accepts a complete payload and drops server-owned fields', () => {
    const r = validateExperiencePayload(good);
    expect(r.errors).toEqual([]);
    expect(r.ok).toBe(true);
    expect(r.data.ratingSum).toBeUndefined();
    expect(r.data.hostId).toBeUndefined();
    expect(r.data.status).toBe('published');
    expect(r.data.searchKeywords).toEqual(expect.arrayContaining(['street', 'food', 'paulo']));
  });

  it('flags each invalid field', () => {
    const r = validateExperiencePayload({
      ...good,
      title: 'abc',
      description: 'short',
      category: 'dating',
      mainPhotoUrl: '',
      photoUrls: Array.from({ length: 9 }, () => 'https://x.y/z.jpg'),
      included: [],
      durationMinutes: 5,
      languages: [],
      maxGroupSize: 0,
      paymentLink: { type: 'paypal', value: 'not a url' },
    });
    expect(r.ok).toBe(false);
    expect(r.errors).toEqual(expect.arrayContaining([
      'title', 'description', 'category', 'mainPhotoUrl', 'photoUrls',
      'included', 'durationMinutes', 'languages', 'maxGroupSize', 'paymentLink',
    ]));
  });

  it('requires a payment link unless free', () => {
    expect(validateExperiencePayload({ ...good, paymentLink: null }).errors).toContain('paymentLink');
    const free = validateExperiencePayload({ ...good, isFree: true, paymentLink: null, price: 99 });
    expect(free.ok).toBe(true);
    expect(free.data.price).toBe(0);
    expect(free.data.currency).toBeNull();
  });

  it('requestToBook is kept only as a strict boolean (default false)', () => {
    expect(validateExperiencePayload(good).data.requestToBook).toBe(false);
    expect(validateExperiencePayload({ ...good, requestToBook: true }).data.requestToBook).toBe(true);
    expect(validateExperiencePayload({ ...good, requestToBook: 'yes' }).data.requestToBook).toBe(false);
  });

  it('payment methods: cash and/or link for paid, none for free', () => {
    const cash = validateExperiencePayload({ ...good, paymentMethods: ['cash'], paymentLink: null });
    expect(cash.ok).toBe(true);
    expect(cash.data.paymentMethods).toEqual(['cash']);
    expect(cash.data.paymentLink).toBeNull();
    // a link sent with cash only is dropped
    const cashOnly = validateExperiencePayload({ ...good, paymentMethods: ['cash'] });
    expect(cashOnly.data.paymentLink).toBeNull();
    const both = validateExperiencePayload({ ...good, paymentMethods: ['link', 'cash', 'bogus'] });
    expect(both.ok).toBe(true);
    expect(both.data.paymentMethods).toEqual(['cash', 'link']);
    expect(both.data.paymentLink).not.toBeNull();
    expect(validateExperiencePayload({ ...good, paymentMethods: ['link'], paymentLink: null }).errors)
      .toContain('paymentLink');
    expect(validateExperiencePayload({ ...good, paymentMethods: [] }).errors)
      .toContain('paymentMethods');
    // older clients (no field) = link
    expect(validateExperiencePayload(good).data.paymentMethods).toEqual(['link']);
    const free = validateExperiencePayload({ ...good, isFree: true, paymentMethods: ['cash'] });
    expect(free.data.paymentMethods).toEqual([]);
    expect(free.data.paymentLink).toBeNull();
  });

  it('min group size must not exceed max', () => {
    expect(validateExperiencePayload({ ...good, minGroupSize: 20 }).errors).toContain('minGroupSize');
    expect(validateExperiencePayload({ ...good, minGroupSize: null }).ok).toBe(true);
  });

  it('a status other than published is stored as draft (never hidden)', () => {
    expect(validateExperiencePayload({ ...good, status: 'hidden' }).data.status).toBe('draft');
  });

  it('search keywords are lower-cased, deduplicated tokens', () => {
    expect(buildSearchKeywords(['Hello, World!', 'hello', null])).toEqual(['hello', 'world']);
  });
});
