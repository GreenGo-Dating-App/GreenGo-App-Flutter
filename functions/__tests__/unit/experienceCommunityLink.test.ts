/**
 * Experiences linked to a community: createUserExperience community
 * validation (same rule as the community Events tab — creator / owner /
 * admin), the pure helpers, and the unlink-on-community-delete cleanup.
 */

// ── In-memory Firestore (just what the callable + cleanup use) ────────────
type Doc = Record<string, unknown>;
const store = new Map<string, Doc>();
const writes: Array<{ path: string; data: Doc }> = [];
let autoId = 0;

function docRef(path: string): any {
  return {
    path,
    id: path.split('/').pop(),
    collection: (name: string) => colRef(`${path}/${name}`),
  };
}
function colRef(path: string): any {
  const filters: Array<[string, unknown]> = [];
  let lim = Infinity;
  const q: any = {
    doc: (id?: string) => docRef(`${path}/${id ?? `auto${++autoId}`}`),
    where: (field: string, _op: string, value: unknown) => {
      filters.push([field, value]);
      return q;
    },
    limit: (n: number) => {
      lim = n;
      return q;
    },
    count: () => ({ __count: true, q }),
    get: async () => {
      const docs = [...store.entries()]
        .filter(([p]) => p.startsWith(`${path}/`) && !p.slice(path.length + 1).includes('/'))
        .filter(([, d]) => filters.every(([f, v]) => d[f] === v))
        .slice(0, lim)
        .map(([p, d]) => ({ id: p.split('/').pop(), ref: docRef(p), data: () => d }));
      return { docs, size: docs.length, empty: docs.length === 0 };
    },
  };
  return q;
}
const DELETE = { __delete: true };
const fakeDb: any = {
  collection: (name: string) => colRef(name),
  runTransaction: async (fn: (tx: any) => Promise<unknown>) => {
    const tx = {
      get: async (ref: any) => {
        if (ref.__count) {
          const n = (await ref.q.get()).size;
          return { data: () => ({ count: n }) };
        }
        const d = store.get(ref.path);
        return { exists: d !== undefined, data: () => d };
      },
      set: (ref: any, data: Doc, opts?: { merge?: boolean }) => {
        writes.push({ path: ref.path, data });
        store.set(ref.path, opts?.merge ? { ...(store.get(ref.path) ?? {}), ...data } : data);
      },
    };
    return fn(tx);
  },
  batch: () => {
    const ops: Array<() => void> = [];
    return {
      update: (ref: any, patch: Doc) => ops.push(() => {
        const next = { ...(store.get(ref.path) ?? {}) };
        for (const [k, v] of Object.entries(patch)) {
          if (v === DELETE) delete next[k];
          else next[k] = v;
        }
        store.set(ref.path, next);
      }),
      commit: async () => ops.forEach((o) => o()),
    };
  },
};

jest.mock('firebase-admin', () => {
  const firestore: any = () => fakeDb;
  firestore.FieldValue = { serverTimestamp: () => 'TS', delete: () => DELETE };
  return {
    apps: [{}],
    initializeApp: jest.fn(),
    firestore,
    storage: jest.fn(),
    auth: jest.fn(),
    messaging: jest.fn(),
  };
});
jest.mock('firebase-functions/v2/https', () => {
  class HttpsError extends Error {
    constructor(public code: string, message: string, public details?: unknown) {
      super(message);
    }
  }
  return { HttpsError, onCall: (_opts: unknown, handler: unknown) => handler };
});
jest.mock('firebase-functions/v2/firestore', () => ({
  onDocumentDeleted: (_opts: unknown, handler: unknown) => handler,
}));
// The ID-document requirement is covered by experienceSafety tests.
jest.mock('../../src/user_experiences/safety', () => ({
  ...jest.requireActual('../../src/user_experiences/safety'),
  createBlockReason: () => null,
}));

import { createUserExperience } from '../../src/user_experiences/createUserExperience';
import {
  communityDisplayName,
  communityPostRefusal,
  requestedCommunityId,
} from '../../src/user_experiences/communityLink';
import { unlinkCommunityExperiences } from '../../src/user_experiences/communityUnlink';

const call = createUserExperience as unknown as (req: unknown) => Promise<any>;

const payload = {
  title: 'Street food walk',
  description: 'Taste the best pastel and caldo de cana around the old market.',
  category: 'foodDrink',
  mainPhotoUrl: 'https://cdn.example.com/a.jpg',
  photoUrls: [],
  included: ['Tastings'],
  notIncluded: [],
  locationName: 'Mercado Municipal, São Paulo',
  durationMinutes: 120,
  languages: ['Portuguese'],
  maxGroupSize: 8,
  isFree: true,
  status: 'draft',
};

beforeEach(() => {
  store.clear();
  writes.length = 0;
  store.set('profiles/host', { membershipTier: 'PLATINUM' });
  store.set('communities/c1', { name: '  Lisbon Foodies  ', createdByUserId: 'creator' });
});

function savedExperience(): Doc | undefined {
  return writes.find((w) => w.path.startsWith('user_experiences/'))?.data;
}

describe('community link helpers', () => {
  it('parses the requested community id', () => {
    expect(requestedCommunityId(undefined)).toBeNull();
    expect(requestedCommunityId(null)).toBeNull();
    expect(requestedCommunityId('  ')).toBeNull();
    expect(requestedCommunityId(' c1 ')).toBe('c1');
    expect(requestedCommunityId(42)).toBe('invalid');
    expect(requestedCommunityId('a/b')).toBe('invalid');
    expect(requestedCommunityId('x'.repeat(129))).toBe('invalid');
    expect(requestedCommunityId('__id__')).toBe('invalid');
  });

  it('mirrors the community Events tab rule: creator, owner or admin', () => {
    const c = { createdByUserId: 'creator' };
    expect(communityPostRefusal('u', null, null)).toBe('community_not_found');
    expect(communityPostRefusal('creator', c, null)).toBeNull();
    expect(communityPostRefusal('u', c, { role: 'owner' })).toBeNull();
    expect(communityPostRefusal('u', c, { role: 'admin' })).toBeNull();
    expect(communityPostRefusal('u', c, { role: 'member' })).toBe('community_not_allowed');
    expect(communityPostRefusal('u', c, null)).toBe('community_not_allowed');
  });

  it('denormalises a trimmed, bounded community name', () => {
    expect(communityDisplayName({ name: '  A  ' })).toBe('A');
    expect(communityDisplayName({ name: '' })).toBeNull();
    expect(communityDisplayName({ name: 'x'.repeat(300) })).toHaveLength(120);
  });
});

describe('createUserExperience with communityId', () => {
  it('creates an unlinked experience when no community is requested', async () => {
    const r = await call({ auth: { uid: 'host' }, data: payload });
    expect(r.status).toBe('draft');
    const e = savedExperience()!;
    expect(e).not.toHaveProperty('communityId');
    expect(e).not.toHaveProperty('communityName');
  });

  it('links the community for its creator (server-set name)', async () => {
    store.set('profiles/creator', { membershipTier: 'PLATINUM' });
    await call({
      auth: { uid: 'creator' },
      data: { ...payload, communityId: 'c1', communityName: 'Spoofed' },
    });
    const e = savedExperience()!;
    expect(e.communityId).toBe('c1');
    expect(e.communityName).toBe('Lisbon Foodies');
    expect(e.status).toBe('draft');
    expect(e.hostId).toBe('creator');
  });

  it('links the community for an admin member', async () => {
    store.set('communities/c1/members/host', { role: 'admin' });
    await call({ auth: { uid: 'host' }, data: { ...payload, communityId: 'c1' } });
    expect(savedExperience()!.communityId).toBe('c1');
  });

  it('refuses a plain member with community_not_allowed', async () => {
    store.set('communities/c1/members/host', { role: 'member' });
    await expect(
      call({ auth: { uid: 'host' }, data: { ...payload, communityId: 'c1' } }),
    ).rejects.toMatchObject({ code: 'permission-denied', details: { code: 'community_not_allowed' } });
    expect(savedExperience()).toBeUndefined();
    expect(store.get('user_experience_counts/host')).toBeUndefined();
  });

  it('refuses a non-member and a missing community', async () => {
    await expect(
      call({ auth: { uid: 'host' }, data: { ...payload, communityId: 'c1' } }),
    ).rejects.toMatchObject({ details: { code: 'community_not_allowed' } });
    await expect(
      call({ auth: { uid: 'host' }, data: { ...payload, communityId: 'nope' } }),
    ).rejects.toMatchObject({ code: 'not-found', details: { code: 'community_not_found' } });
  });

  it('refuses a malformed community id', async () => {
    await expect(
      call({ auth: { uid: 'host' }, data: { ...payload, communityId: 'a/b' } }),
    ).rejects.toMatchObject({ code: 'invalid-argument', details: { code: 'invalid_community' } });
  });

  it('still validates the payload before the community', async () => {
    await expect(
      call({ auth: { uid: 'host' }, data: { ...payload, title: 'x', communityId: 'c1' } }),
    ).rejects.toMatchObject({ details: { code: 'invalid_experience' } });
  });
});

describe('unlinkCommunityExperiences', () => {
  it('keeps the experiences and clears the link, paging until done', async () => {
    for (let i = 0; i < 5; i++) {
      store.set(`user_experiences/e${i}`, { communityId: 'c1', communityName: 'A', title: `t${i}` });
    }
    store.set('user_experiences/other', { communityId: 'c2', communityName: 'B' });
    const n = await unlinkCommunityExperiences(fakeDb, 'c1', 2);
    expect(n).toBe(5);
    for (let i = 0; i < 5; i++) {
      const d = store.get(`user_experiences/e${i}`)!;
      expect(d.title).toBe(`t${i}`);
      expect(d).not.toHaveProperty('communityId');
      expect(d).not.toHaveProperty('communityName');
    }
    expect(store.get('user_experiences/other')!.communityId).toBe('c2');
  });
});
