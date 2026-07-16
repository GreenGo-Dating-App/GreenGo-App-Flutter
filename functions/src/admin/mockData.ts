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

    // ── 1:1 conversations + messages (mock users only) ───────────────────
    // Doc shapes mirror conversation_model.toFirestore + message_model.
    const chatPairs = [
      { a: 1, b: 2, business: false },
      { a: 3, b: 4, business: false },
      { a: 1, b: 5, business: true }, // an inquiry into Elena's storefront
    ];
    for (let i = 0; i < chatPairs.length; i++) {
      const p = chatPairs[i];
      const convId = `mock_conv_${i + 1}`;
      const matchId = `mock_match_${i + 1}`;
      const u1 = `mock_user_${p.a}`;
      const u2 = `mock_user_${p.b}`;
      const nameA = users[p.a - 1].name.split(' ')[0];
      const nameB = users[p.b - 1].name.split(' ')[0];
      const convRef = db.collection('conversations').doc(convId);
      const lines: [string, string, string][] = [
        [u1, u2, `Hi ${nameB}! Nice to connect on GreenGo.`],
        [u2, u1, `Hey ${nameA}, likewise! Where are you exploring?`],
        [u1, u2, `Around ${city} this week. Any spots to recommend?`],
        [u2, u1, `Loads! Let's grab a coffee and I'll share. ☕`],
      ];
      const cBatch = db.batch();
      let lastMsg: admin.firestore.DocumentData | null = null;
      let lastSentAt: admin.firestore.Timestamp = ts(now);
      lines.forEach((ln, k) => {
        const [sid, rid, content] = ln;
        const sentAt = ts(
          new Date(now.getTime() - (lines.length - k) * 3600 * 1000),
        );
        cBatch.set(convRef.collection('messages').doc(`m${k + 1}`), {
          matchId,
          conversationId: convId,
          senderId: sid,
          receiverId: rid,
          content,
          type: 'text',
          sentAt,
          status: 'read',
          readAt: sentAt,
          ...mock,
        });
        lastMsg = {
          messageId: `m${k + 1}`,
          senderId: sid,
          receiverId: rid,
          content,
          type: 'text',
          sentAt,
        };
        lastSentAt = sentAt;
      });
      cBatch.set(convRef, {
        matchId,
        userId1: u1,
        userId2: u2,
        lastMessage: lastMsg,
        lastMessageAt: lastSentAt,
        unreadCount: 0,
        isTyping: false,
        typingUserId: null,
        createdAt: ts(now),
        isPinned: false,
        isMuted: false,
        isArchived: false,
        theme: 'gold',
        conversationType: 'match',
        businessInquiry: p.business,
        favorites: {},
        isDeleted: false,
        ...mock,
      });
      await cBatch.commit();
    }

    // ── Group chats + members + per-user inbox threads ───────────────────
    // groups/{id} + members/{uid} + messages/{id} + user_group_inbox mirror.
    const groupDefs = [
      { name: 'Lisbon Explorers', members: [1, 2, 3], lang: 'en' },
      { name: 'Foodie Friends', members: [3, 4, 5], lang: 'pt' },
    ];
    for (let g = 0; g < groupDefs.length; g++) {
      const gd = groupDefs[g];
      const groupId = `mock_group_${g + 1}`;
      const participantUids = gd.members.map((n) => `mock_user_${n}`);
      const creatorUid = participantUids[0];
      const roles: Record<string, string> = {};
      participantUids.forEach((uid, idx) => {
        roles[uid] = idx === 0 ? 'admin' : 'member';
      });
      const gRef = db.collection('groups').doc(groupId);
      const photoUrl = `https://picsum.photos/seed/${groupId}/400/400`;
      const gBatch = db.batch();

      const gMsgs: [string, string][] = [
        [creatorUid, `Welcome to ${gd.name}! 👋`],
        [participantUids[1], `Thanks! Excited to be here.`],
        [
          participantUids[participantUids.length - 1],
          `Hello everyone from ${city}! 🌍`,
        ],
      ];
      let gLastMsg: admin.firestore.DocumentData | null = null;
      let gLastSentAt: admin.firestore.Timestamp = ts(now);
      gMsgs.forEach((m, k) => {
        const [sid, content] = m;
        const sentAt = ts(
          new Date(now.getTime() - (gMsgs.length - k) * 3600 * 1000),
        );
        gBatch.set(gRef.collection('messages').doc(`m${k + 1}`), {
          senderId: sid,
          receiverId: '',
          matchId: groupId,
          content,
          type: 'text',
          status: 'sent',
          sentAt,
          ...mock,
        });
        gLastMsg = {
          messageId: `m${k + 1}`,
          senderId: sid,
          content,
          type: 'text',
          sentAt,
        };
        gLastSentAt = sentAt;
      });

      for (const uid of participantUids) {
        gBatch.set(gRef.collection('members').doc(uid), {
          userId: uid,
          role: roles[uid],
          joinedAt: ts(now),
          lastReadAt: ts(now),
          notificationsEnabled: true,
          leftAt: null,
          ...mock,
        });
      }

      gBatch.set(gRef, {
        conversationType: 'group',
        isGroup: true,
        participants: participantUids,
        groupInfo: {
          name: gd.name,
          createdBy: creatorUid,
          photoUrl,
          description: `${gd.name} — a GreenGo culture circle. (test group)`,
          language: gd.lang,
        },
        roles,
        memberCount: participantUids.length,
        createdBy: creatorUid,
        createdAt: ts(now),
        lastMessage: gLastMsg,
        lastMessageAt: gLastSentAt,
        theme: 'gold',
        isDeleted: false,
        ...mock,
      });

      // Per-user inbox thread — REQUIRED for the group to appear in Exchanges.
      for (const uid of participantUids) {
        gBatch.set(
          db
            .collection('user_group_inbox')
            .doc(uid)
            .collection('threads')
            .doc(groupId),
          {
            groupId,
            name: gd.name,
            photoUrl,
            isGroup: true,
            lastMessagePreview: (gLastMsg as admin.firestore.DocumentData)
              .content,
            lastSenderId: (gLastMsg as admin.firestore.DocumentData).senderId,
            lastMessageAt: gLastSentAt,
            updatedAt: gLastSentAt,
            unreadCount: 0,
            memberCount: participantUids.length,
            pinned: false,
            muted: false,
            ...mock,
          },
        );
      }
      await gBatch.commit();
    }

    // ── Community chat + tips + announcements ────────────────────────────
    // communities/{id}/messages with type ∈ {text, language_tip,
    // cultural_fact, city_tip, announcement}; owner authors them.
    for (let i = 0; i < comms.length; i++) {
      const id = `mock_comm_${i + 1}`;
      const ownerN = (i % users.length) + 1;
      const ownerUid = `mock_user_${ownerN}`;
      const ownerName = users[ownerN - 1].name;
      const cRef = db.collection('communities').doc(id);
      const cmBatch = db.batch();
      const posts: [string, string][] = [
        ['text', `Welcome to ${comms[i][0]}! Introduce yourselves. (test)`],
        ['text', `Great to have everyone here. 🎉`],
        [
          'language_tip',
          `Language tip: in Portuguese, "obrigado/obrigada" means thank you.`,
        ],
        [
          'cultural_fact',
          `Cultural fact: Lisbon's yellow trams date back to 1873.`,
        ],
        [
          'city_tip',
          `City tip: catch the sunset at Miradouro da Senhora do Monte.`,
        ],
        [
          'announcement',
          `📢 Weekly meetup this Saturday at 5pm. Everyone welcome!`,
        ],
      ];
      // Stagger per community so lastActivityAt stays distinct/ordered.
      const base = now.getTime() - i * 2 * 3600 * 1000;
      let cLastContent = '';
      let cLastSentAt: admin.firestore.Timestamp = ts(now);
      posts.forEach((post, k) => {
        const [type, content] = post;
        const sentAt = ts(new Date(base - (posts.length - k) * 1800 * 1000));
        cmBatch.set(cRef.collection('messages').doc(`m${k + 1}`), {
          senderId: ownerUid,
          senderName: ownerName,
          senderPhotoUrl: `https://i.pravatar.cc/500?img=${ownerN + 10}`,
          content,
          sentAt,
          type,
          ...mock,
        });
        cLastContent = content;
        cLastSentAt = sentAt;
      });
      // Denormalized preview/activity (mirrors sendMessage's parent update).
      cmBatch.set(
        cRef,
        {
          lastMessagePreview:
            cLastContent.length > 100
              ? `${cLastContent.slice(0, 100)}...`
              : cLastContent,
          lastActivityAt: cLastSentAt,
        },
        { merge: true },
      );
      // Let the owner post tips/announcements (rules gate on these flags).
      cmBatch.set(
        cRef.collection('members').doc(ownerUid),
        { canWriteTips: true, canWriteAnnouncements: true },
        { merge: true },
      );
      await cmBatch.commit();
    }

    // NOTE: we intentionally do NOT seed mock LIVE events (external_events /
    // ticketmaster). That collection is populated by the real ingester; the
    // "Live Events" tab shows real data. (The 100km display filter was removed
    // because that feed is geographically sparse — see experiences_tab.dart.)

    res.status(200).json({
      batchId,
      users: users.length,
      events: eventTitles.length,
      communities: comms.length,
      conversations: chatPairs.length,
      groups: groupDefs.length,
      communityPosts: comms.length * 6,
      location: { city, country, baseLat, baseLng },
    });
  }),
);

/// READ-ONLY diagnostic — inspects the REAL ticketmaster external_events so we
/// can see which client filter (date / distance / coords) hides them.
/// ?token=...&lat=&lng=  (lat/lng default to Los Angeles)
export const diagLiveEvents = onRequest(
  { memory: '512MiB', timeoutSeconds: 120 },
  monitored('diagLiveEvents', async (req, res) => {
    if (req.query.token !== MOCK_TOKEN) {
      res.status(403).send('forbidden');
      return;
    }
    const lat = parseFloat((req.query.lat as string) || '34.0522');
    const lng = parseFloat((req.query.lng as string) || '-118.2437');
    const source = (req.query.source as string) || 'ticketmaster';
    const now = new Date();
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    const iso = /^\d{4}-\d{2}-\d{2}$/;
    const km = (a: number, b: number, c: number, d: number): number => {
      const R = 6371;
      const dLat = ((c - a) * Math.PI) / 180;
      const dLng = ((d - b) * Math.PI) / 180;
      const s =
        Math.sin(dLat / 2) ** 2 +
        Math.cos((a * Math.PI) / 180) *
          Math.cos((c * Math.PI) / 180) *
          Math.sin(dLng / 2) ** 2;
      return R * 2 * Math.atan2(Math.sqrt(s), Math.sqrt(1 - s));
    };

    const snap = await db
      .collection('external_events')
      .where('source', '==', source)
      .limit(500)
      .get();
    let withDate = 0;
    let validIso = 0;
    let futureDated = 0;
    let withCoords = 0;
    let within100km = 0;
    let futureAnd100km = 0;
    const cities: Record<string, number> = {};
    const samples: unknown[] = [];
    for (const d of snap.docs) {
      const x = d.data();
      const sd = x.startDate as string | null | undefined;
      const hasDate = sd != null && sd !== '';
      const validDate = hasDate && iso.test(sd as string);
      const future = validDate && (sd as string) >= todayStr;
      const hasCoords = typeof x.lat === 'number' && typeof x.lng === 'number';
      const near = hasCoords && km(lat, lng, x.lat, x.lng) <= 100;
      if (hasDate) withDate++;
      if (validDate) validIso++;
      if (future) futureDated++;
      if (hasCoords) withCoords++;
      if (near) within100km++;
      if (future && near) futureAnd100km++;
      const city = (x.city as string) || '(none)';
      cities[city] = (cities[city] || 0) + 1;
      if (samples.length < 8) {
        samples.push({
          id: d.id,
          startDate: sd ?? null,
          lat: x.lat ?? null,
          lng: x.lng ?? null,
          city: x.city ?? null,
          distKm: hasCoords ? Math.round(km(lat, lng, x.lat, x.lng)) : null,
        });
      }
    }
    res.status(200).json({
      source,
      today: todayStr,
      near: { lat, lng },
      total: snap.size,
      withDate,
      validIso,
      futureDated,
      pastOrUndated: snap.size - futureDated,
      withCoords,
      within100km,
      futureAnd100km,
      topCities: Object.entries(cities)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 10),
      samples,
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

    // Subcollections first (so parent deletion doesn't orphan them). The
    // collectionGroup queries span every parent: `members` covers community +
    // group members; `messages` covers conversation + group + community
    // messages/tips/announcements; `threads` covers the group inbox mirror.
    await deleteQuery(
      db.collectionGroup('members').where('isMock', '==', true),
    );
    await deleteQuery(
      db.collectionGroup('attendees').where('isMock', '==', true),
    );
    await deleteQuery(
      db.collectionGroup('messages').where('isMock', '==', true),
    );
    await deleteQuery(
      db.collectionGroup('threads').where('isMock', '==', true),
    );
    // Top-level collections.
    for (const col of [
      'communities',
      'events',
      'profiles',
      'users',
      'conversations',
      'groups',
      'external_events',
    ]) {
      await deleteQuery(db.collection(col).where('isMock', '==', true));
    }

    res.status(200).json({ deleted });
  }),
);
