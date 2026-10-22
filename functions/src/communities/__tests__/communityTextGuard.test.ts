/**
 * Community text guard (Apple 4.3(b)): multilingual dating-term matcher,
 * shared vectors with the app, and the moderation_queue item shape.
 */
import * as fs from 'fs';
import * as path from 'path';

const created: { id: string; data: any }[] = [];
let createFails: any = null;

jest.mock('firebase-admin', () => {
  const db: any = {
    collection: (c: string) => ({
      doc: (id: string) => ({
        create: async (data: any) => {
          if (createFails) throw createFails;
          created.push({ id: `${c}/${id}`, data });
        },
      }),
    }),
  };
  const firestoreFn: any = () => db;
  firestoreFn.FieldValue = { serverTimestamp: () => 'TS' };
  return {
    apps: [{}],
    initializeApp: jest.fn(),
    firestore: firestoreFn,
    storage: () => ({}),
    auth: () => ({}),
    messaging: () => ({}),
  };
});

import {
  DATING_TERMS,
  DATING_TERM_EXCEPTIONS,
  communityTextQueueItem,
  findDatingTerms,
  guardedTextChanged,
  onCommunityTextWritten,
} from '../communityTextGuard';

const fixture = JSON.parse(
  fs.readFileSync(
    path.join(__dirname, '..', '..', '..', '..', 'test', 'fixtures', 'community_dating_terms.json'),
    'utf8',
  ),
);

describe('findDatingTerms', () => {
  it('lists are identical to the shared fixture (app parity)', () => {
    expect([...DATING_TERMS]).toEqual(fixture.terms);
    expect([...DATING_TERM_EXCEPTIONS]).toEqual(fixture.exceptions);
  });

  for (const v of fixture.vectors as { text: string; expected: string[] }[]) {
    it(`${v.expected.length ? 'flags' : 'ignores'}: ${v.text}`, () => {
      const hits = findDatingTerms(v.text);
      if (v.expected.length === 0) expect(hits).toEqual([]);
      else expect(hits).toEqual(expect.arrayContaining(v.expected));
    });
  }

  it('non-strings and empty text are safe', () => {
    expect(findDatingTerms(undefined)).toEqual([]);
    expect(findDatingTerms('')).toEqual([]);
    expect(findDatingTerms(42)).toEqual([]);
  });

  it('an exception does not hide a real hit elsewhere in the text', () => {
    expect(findDatingTerms('Carbon dating talk, then speed dating')).toContain('dating*');
  });
});

describe('queue item', () => {
  it('low priority communityText item, deterministic id, excerpts per field', () => {
    const data = {
      name: 'Gringos Rio',
      description: 'Quer namorar um gringo?',
      rules: 'Be kind',
      createdByUserId: 'owner1',
    };
    const a = communityTextQueueItem('c1', data)!;
    const b = communityTextQueueItem('c1', { ...data })!;
    expect(a.id).toBe(b.id);
    expect(a.id.startsWith('communityText_c1_')).toBe(true);
    expect(a.data).toMatchObject({
      itemType: 'communityText',
      itemId: 'c1',
      userId: 'owner1',
      priority: 'low',
      status: 'pending',
      assignedTo: null,
      metadata: { fields: ['description'], matchedTerms: { description: ['namor*'] } },
    });
    expect(communityTextQueueItem('c1', { name: 'Hiking club', description: 'Weekend trails' })).toBeNull();
  });

  it('only name / description / rules / tags changes count (not chat activity)', () => {
    const base = { name: 'A', description: 'B', lastActivityAt: 1 };
    expect(guardedTextChanged(base, { ...base, lastActivityAt: 2, lastMessagePreview: 'x' })).toBe(false);
    expect(guardedTextChanged(base, { ...base, description: 'C' })).toBe(true);
    expect(guardedTextChanged(base, { ...base, rules: 'new rules' })).toBe(true);
    expect(guardedTextChanged(undefined, base)).toBe(true);
    expect(guardedTextChanged(base, undefined)).toBe(false);
  });
});

describe('onCommunityTextWritten', () => {
  const run = (before: any, after: any) =>
    (onCommunityTextWritten as any).run({
      params: { communityId: 'c9' },
      data: {
        before: { exists: !!before, data: () => before },
        after: { exists: !!after, data: () => after },
      },
    });

  beforeEach(() => {
    created.length = 0;
    createFails = null;
  });

  it('queues a flagged create', async () => {
    await run(undefined, { name: 'Partnersuche Berlin', description: '' });
    expect(created).toHaveLength(1);
    expect(created[0].id).toMatch(/^moderation_queue\/communityText_c9_/);
    expect(created[0].data.addedAt).toBe('TS');
  });

  it('chat activity on a flagged community writes nothing', async () => {
    const d = { name: 'Paquera SP', description: '' };
    await run(d, { ...d, lastActivityAt: 5 });
    expect(created).toHaveLength(0);
  });

  it('clean text writes nothing; an already queued text is not an error', async () => {
    await run(undefined, { name: 'Book club', description: 'Romance novels and more' });
    expect(created).toHaveLength(0);
    createFails = Object.assign(new Error('6 ALREADY_EXISTS: already exists'), { code: 6 });
    await expect(run({ name: 'x' }, { name: 'Dating night' })).resolves.toBeUndefined();
  });
});
