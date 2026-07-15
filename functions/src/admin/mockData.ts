/**
 * Mock-data seeder + remover (NEW, isolated module) — testing only.
 *
 * `seedMockData` fills the app with believable, DISCOVERABLE test data:
 *   - 5 Firestore-only fake users (tiers: free / silver / gold / platinum /
 *     platinum+business) — profiles/{uid} + users/{uid}, no Firebase Auth.
 *   - ~6 published public events (future, near the base location).
 *   - ~5 public communities with owner+member docs (so they show in Discover
 *     AND "My Communities").
 * Every doc is tagged `isMock: true` (+ a shared `mockBatchId`) and ids are
 * prefixed `mock_`, so `removeMockData` can delete ONLY this data.
 *
 * Both are token-guarded (?token=...). Location is parameterizable so the fakes
 * appear near the tester's own country/coords:
 *   ?token=...&lat=38.72&lng=-9.14&country=Portugal&city=Lisbon
 */

import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import { geohashEncode } from '../external_events/geohash';
import '../shared/firebaseAdmin';

const db = admin.firestore();
const MOCK_TOKEN = 'greengo-mock-2026';

function ts(d: Date): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(d);
}

function keywords(...parts: string[]): string[] {
  const set = new Set<string>();
  for (const p of parts) {
    for (const tok of (p || '').toLowerCase().split(/[^a-z0-9]+/)) {
      if (tok.length >= 2) set.add(tok);
    }
  }
  return Array.from(set);
}

export const seedMockData = onRequest(
  { memory: '512MiB', timeoutSeconds: 300 },
  monitored('seedMockData', async (req, res) => {
    if (req.query.token !== MOCK_TOKEN) {
      res.status(403).send('forbidden');
      return;
    }
    const now = new Date();
    const batchId = `mock_${now.getTime()}`;
    const baseLat = parseFloat((req.query.lat as string) || '38.7223');
    const baseLng = parseFloat((req.query.lng as string) || '-9.1393');
    const country = (req.query.country as string) || 'Portugal';
    const city = (req.query.city as string) || 'Lisbon';
    const countryLower = country.toLowerCase();

    const mock = { isMock: true, mockBatchId: batchId };
    const nearby = (i: number) => ({
      latitude: baseLat + (i - 2) * 0.01,
      longitude: baseLng + (i - 2) * 0.01,
    });

    // ── 5 users ──────────────────────────────────────────────────────────
    const dob = (age: number) =>
      ts(new Date(now.getFullYear() - age, 5, 15));
    const users = [
      { n: 1, name: 'Ava Reyes', tier: 'FREE', sub: 'basic', gender: 'Female', age: 27, business: false },
      { n: 2, name: 'Bruno Costa', tier: 'SILVER', sub: 'silver', gender: 'Male', age: 31, business: false },
      { n: 3, name: 'Clara Nunes', tier: 'GOLD', sub: 'gold', gender: 'Female', age: 29, business: false },
      { n: 4, name: 'Diego Alves', tier: 'PLATINUM', sub: 'platinum', gender: 'Male', age: 34, business: false },
      { n: 5, name: 'Elena Marco', tier: 'PLATINUM', sub: 'platinum', gender: 'Female', age: 33, business: true },
    ];

    let batch = db.batch();
    for (const u of users) {
      const uid = `mock_user_${u.n}`;
      const loc = nearby(u.n);
      batch.set(db.collection('profiles').doc(uid), {
        userId: uid,
        displayName: u.name,
        nickname: `mock_${u.name.split(' ')[0].toLowerCase()}`,
        dateOfBirth: dob(u.age),
        gender: u.gender,
        accountStatus: 'active',
        isBanned: false,
        isGhostMode: false,
        isIncognito: false,
        isBoosted: false,
        isTraveler: false,
        photoUrls: [`https://i.pravatar.cc/500?img=${u.n + 10}`],
        bio: `Hi, I'm ${u.name.split(' ')[0]} — here to explore GreenGo. (test account)`,
        interests: ['Coffee', 'Travel', 'Music', 'Food'],
        languages: ['en', 'pt'],
        preferredLanguages: ['en'],
        location: {
          latitude: loc.latitude,
          longitude: loc.longitude,
          city,
          country,
          countryLower,
          displayAddress: `${city}, ${country}`,
        },
        createdAt: ts(now),
        updatedAt: ts(now),
        isComplete: true,
        verificationStatus: 'approved',
        isAdmin: false,
        isSupport: false,
        membershipTier: u.tier,
        hasBaseMembership: u.tier !== 'FREE',
        isOnline: false,
        showOnMap: true,
        globeDiscoverability: 'approximate',
        isBusiness: u.business,
        ...(u.business
          ? {
              businessName: 'Elena’s Cafe',
              businessCategory: 'Cafe',
              businessVerified: true,
              coverImageUrl: `https://picsum.photos/seed/${uid}_cover/1000/500`,
              storefrontBio: 'A cozy corner cafe. (test storefront)',
              galleryImages: [
                `https://picsum.photos/seed/${uid}_g1/600/400`,
                `https://picsum.photos/seed/${uid}_g2/600/400`,
              ],
            }
          : {}),
        ...mock,
      });
      batch.set(db.collection('users').doc(uid), {
        email: `${uid}@mock.greengo.test`,
        membershipTier: u.sub,
        approvalStatus: 'approved',
        accessDate: ts(new Date(now.getTime() - 30 * 24 * 3600 * 1000)),
        hasEarlyAccess: false,
        notificationsEnabled: false,
        createdAt: ts(now),
        updatedAt: ts(now),
        ...mock,
      });
    }
    await batch.commit();

    // ── ~6 events (future, published, public) ───────────────────────────
    const eventTitles = [
      ['Rooftop Language Exchange', 'social', 3],
      ['Sunset Food Tour', 'food', 5],
      ['Live Jazz Night', 'music', 7],
      ['Morning Coffee Meetup', 'social', 2],
      ['City Photo Walk', 'outdoor', 9],
      ['Startup Networking Drinks', 'business', 12],
    ] as const;
    batch = db.batch();
    eventTitles.forEach((e, idx) => {
      const id = `mock_event_${idx + 1}`;
      const organizer = users[idx % users.length];
      const start = new Date(now.getTime() + e[2] * 24 * 3600 * 1000);
      const end = new Date(start.getTime() + 3 * 3600 * 1000);
      const loc = nearby(idx % 5);
      batch.set(db.collection('events').doc(id), {
        organizerId: `mock_user_${(idx % users.length) + 1}`,
        organizerName: organizer.name,
        title: e[0],
        description: `${e[0]} in ${city}. Join us! (test event)`,
        category: e[1],
        imageUrl: `https://picsum.photos/seed/${id}/900/600`,
        photoUrls: [],
        startDate: ts(start),
        endDate: ts(end),
        locationName: `${city} Venue ${idx + 1}`,
        latitude: loc.latitude,
        longitude: loc.longitude,
        geohash: geohashEncode(loc.latitude, loc.longitude),
        address: `${city}, ${country}`,
        maxAttendees: 50,
        price: 0,
        currency: 'EUR',
        status: 'published',
        tags: [e[1]],
        city,
        country,
        attendeeCount: 0,
        likeCount: 0,
        visibility: 'public',
        createdAt: ts(now),
        updatedAt: ts(now),
        searchKeywords: keywords(e[0], city, country, e[1]),
        ...mock,
      });
    });
    await batch.commit();

    // ── ~5 communities + owner/member docs ───────────────────────────────
    const comms = [
      ['Lisbon Coffee Lovers', 'general', ['en', 'pt']],
      ['Language Exchange Hub', 'languageCircle', ['en', 'es', 'pt']],
      ['Foodies of the City', 'culturalInterest', ['en']],
      ['Weekend Hikers', 'general', ['en', 'pt']],
      ['Digital Nomads', 'general', ['en']],
    ] as const;
    for (let i = 0; i < comms.length; i++) {
      const id = `mock_comm_${i + 1}`;
      const ownerN = (i % users.length) + 1;
      const ownerUid = `mock_user_${ownerN}`;
      const owner = users[ownerN - 1];
      const cRef = db.collection('communities').doc(id);
      await cRef.set({
        name: comms[i][0],
        description: `${comms[i][0]} — a place to connect. (test community)`,
        type: comms[i][1],
        imageUrl: `https://picsum.photos/seed/${id}/800/500`,
        createdByUserId: ownerUid,
        createdByName: owner.name,
        createdAt: ts(now),
        memberCount: 3,
        languages: comms[i][2],
        tags: ['community', 'test'],
        isPublic: true,
        city,
        country,
        lastMessagePreview: 'Welcome to the community!',
        lastActivityAt: ts(new Date(now.getTime() - i * 3600 * 1000)),
        ...mock,
      });
      // Owner + two members (so it shows in "My Communities" for the owner).
      const memberUids = [
        ownerUid,
        `mock_user_${((ownerN) % users.length) + 1}`,
        `mock_user_${((ownerN + 1) % users.length) + 1}`,
      ];
      const mBatch = db.batch();
      memberUids.forEach((uid, mi) => {
        const u = users[parseInt(uid.split('_')[2], 10) - 1];
        mBatch.set(cRef.collection('members').doc(uid), {
          userId: uid,
          displayName: u.name,
          photoUrl: `https://i.pravatar.cc/500?img=${u.n + 10}`,
          role: mi === 0 ? 'owner' : 'member',
          joinedAt: ts(now),
          languages: ['en'],
          isLocalGuide: false,
          isMuted: false,
          isBanned: false,
          canWriteTips: false,
          canWriteAnnouncements: false,
          ...mock,
        });
      });
      await mBatch.commit();
    }

    res.status(200).json({
      batchId,
      users: users.length,
      events: eventTitles.length,
      communities: comms.length,
      location: { city, country, baseLat, baseLng },
    });
  }),
);

export const removeMockData = onRequest(
  { memory: '512MiB', timeoutSeconds: 300 },
  monitored('removeMockData', async (req, res) => {
    if (req.query.token !== MOCK_TOKEN) {
      res.status(403).send('forbidden');
      return;
    }

    let deleted = 0;

    async function deleteQuery(
      q: admin.firestore.Query,
    ): Promise<void> {
      // eslint-disable-next-line no-constant-condition
      while (true) {
        const snap = await q.limit(300).get();
        if (snap.empty) break;
        const b = db.batch();
        for (const d of snap.docs) b.delete(d.ref);
        await b.commit();
        deleted += snap.size;
        if (snap.size < 300) break;
      }
    }

    // Subcollections first (so parent deletion doesn't orphan them).
    await deleteQuery(
      db.collectionGroup('members').where('isMock', '==', true),
    );
    await deleteQuery(
      db.collectionGroup('attendees').where('isMock', '==', true),
    );
    // Top-level collections.
    for (const col of ['communities', 'events', 'profiles', 'users']) {
      await deleteQuery(db.collection(col).where('isMock', '==', true));
    }

    res.status(200).json({ deleted });
  }),
);
