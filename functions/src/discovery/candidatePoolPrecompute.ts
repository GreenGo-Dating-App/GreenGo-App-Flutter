/**
 * Candidate Pool Pre-computation
 *
 * Scheduled Cloud Function that builds candidate pools grouped by
 * country / gender / age-bucket. Discovery reads from these pools
 * instead of scanning the entire profiles collection.
 *
 * Pool key format: "{country}_{gender}_{ageMin}-{ageMax}"
 * Example: "DE_Female_25-34"
 *
 * Runs every 10 minutes. Each pool document contains an array of
 * lightweight member entries (userId + scoring metadata) so the
 * Flutter client can filter and score without fetching full profiles.
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onCall } from 'firebase-functions/v2/https';
import { db, FieldValue, logInfo, logError, chunk } from '../shared/utils';
import * as admin from 'firebase-admin';

// ───────── Constants ─────────

const AGE_BUCKETS = [
  { min: 18, max: 24 },
  { min: 25, max: 34 },
  { min: 35, max: 44 },
  { min: 45, max: 54 },
  { min: 55, max: 64 },
  { min: 65, max: 99 },
];

/** Max members per pool document (keeps doc size well under 1 MB). */
const MAX_POOL_SIZE = 5000;

/** Page size when scanning the profiles collection. */
const SCAN_PAGE_SIZE = 500;

/** Pool collection name in Firestore. */
const POOL_COLLECTION = 'candidate_pools';

// ───────── Types ─────────

interface PoolMember {
  userId: string;
  age: number;
  lat: number;
  lng: number;
  interests: string[];
  languages: string[];
  isVerified: boolean;
  isBoosted: boolean;
  boostExpiry: string | null;
  isOnline: boolean;
  lastActive: string | null;
  sexualOrientation: string | null;
  hasPhotos: boolean;
}

// ───────── Helpers ─────────

function getAgeBucket(age: number): { min: number; max: number } | null {
  return AGE_BUCKETS.find((b) => age >= b.min && age <= b.max) ?? null;
}

function calculateAge(dateOfBirth: Date): number {
  const now = new Date();
  let age = now.getFullYear() - dateOfBirth.getFullYear();
  const monthDiff = now.getMonth() - dateOfBirth.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < dateOfBirth.getDate())) {
    age--;
  }
  return age;
}

function poolKey(country: string, gender: string, bucket: { min: number; max: number }): string {
  const c = (country || 'Unknown').replace(/[^a-zA-Z]/g, '').substring(0, 30) || 'Unknown';
  const g = (gender || 'Unknown').replace(/[^a-zA-Z]/g, '') || 'Unknown';
  return `${c}_${g}_${bucket.min}-${bucket.max}`;
}

function toPoolMember(doc: admin.firestore.DocumentSnapshot): PoolMember | null {
  const d = doc.data();
  if (!d) return null;

  const status = (d.accountStatus as string || 'active').toLowerCase();
  if (status === 'suspended' || status === 'banned' || status === 'deleted') return null;

  // Must be verified and have at least one photo
  const isVerified = d.isVerified === true || d.verificationStatus === 'approved';
  const photoUrls = d.photoUrls as string[] | undefined;
  if (!isVerified || !photoUrls || photoUrls.length === 0) return null;

  // Skip active incognito users
  const isIncognito = d.isIncognito === true;
  if (isIncognito) {
    const expiry = d.incognitoExpiry as admin.firestore.Timestamp | null;
    if (!expiry || expiry.toDate() > new Date()) return null;
  }

  // Calculate age
  let dob: Date | null = null;
  if (d.dateOfBirth instanceof admin.firestore.Timestamp) {
    dob = d.dateOfBirth.toDate();
  } else if (d.dateOfBirth) {
    dob = new Date(d.dateOfBirth);
  }
  if (!dob || isNaN(dob.getTime())) return null;
  const age = calculateAge(dob);
  if (age < 18 || age > 120) return null;

  // Resolve effective location (traveler-aware)
  let lat = 0;
  let lng = 0;
  const isTraveler = d.isTraveler === true;
  const travelerExpiry = d.travelerExpiry as admin.firestore.Timestamp | null;
  const isTravelerActive =
    isTraveler && travelerExpiry && travelerExpiry.toDate() > new Date();

  if (isTravelerActive && d.travelerLocation) {
    lat = d.travelerLocation.latitude ?? 0;
    lng = d.travelerLocation.longitude ?? 0;
  } else if (d.location) {
    lat = d.location.latitude ?? 0;
    lng = d.location.longitude ?? 0;
  }

  // Resolve effective country
  let country = 'Unknown';
  if (isTravelerActive && d.travelerLocation?.country) {
    country = d.travelerLocation.country;
  } else if (d.location?.country) {
    country = d.location.country;
  }

  const isBoosted = d.isBoosted === true;
  const boostExpiry = d.boostExpiry as admin.firestore.Timestamp | null;
  const lastSeen = d.lastSeen as admin.firestore.Timestamp | null;

  return {
    userId: doc.id,
    age,
    lat,
    lng,
    interests: (d.interests as string[]) || [],
    languages: (d.languages as string[]) || [],
    isVerified: true,
    isBoosted,
    boostExpiry: boostExpiry ? boostExpiry.toDate().toISOString() : null,
    isOnline: d.isOnline === true,
    lastActive: lastSeen ? lastSeen.toDate().toISOString() : null,
    sexualOrientation: (d.sexualOrientation as string) || null,
    hasPhotos: true,
    // We expose `country` and `gender` via the pool key, not per-member
  };
}

// ───────── Core Logic ─────────

async function buildPools(): Promise<{ poolCount: number; memberCount: number }> {
  const pools = new Map<string, PoolMember[]>();
  let lastDoc: admin.firestore.DocumentSnapshot | null = null;
  let totalScanned = 0;

  // Paginate through all profiles
  while (true) {
    let query: admin.firestore.Query = db
      .collection('profiles')
      .limit(SCAN_PAGE_SIZE);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();
    if (snapshot.empty) break;

    totalScanned += snapshot.size;
    lastDoc = snapshot.docs[snapshot.docs.length - 1];

    for (const doc of snapshot.docs) {
      const member = toPoolMember(doc);
      if (!member) continue;

      const d = doc.data();
      const gender = (d.gender as string) || 'Unknown';

      // Determine effective country (same logic as in toPoolMember)
      const isTraveler = d.isTraveler === true;
      const travelerExpiry = d.travelerExpiry as admin.firestore.Timestamp | null;
      const isTravelerActive =
        isTraveler && travelerExpiry && travelerExpiry.toDate() > new Date();
      let country = 'Unknown';
      if (isTravelerActive && d.travelerLocation?.country) {
        country = d.travelerLocation.country;
      } else if (d.location?.country) {
        country = d.location.country;
      }

      const bucket = getAgeBucket(member.age);
      if (!bucket) continue;

      const key = poolKey(country, gender, bucket);
      if (!pools.has(key)) {
        pools.set(key, []);
      }
      const members = pools.get(key)!;
      if (members.length < MAX_POOL_SIZE) {
        members.push(member);
      }
    }

    logInfo(`Pool scan progress: ${totalScanned} profiles scanned, ${pools.size} pools`);

    if (snapshot.size < SCAN_PAGE_SIZE) break;
  }

  // Write pools to Firestore using batch writes
  let memberCount = 0;
  const poolEntries = Array.from(pools.entries());
  const batches = chunk(poolEntries, 250); // 500 ops limit, 2 ops per pool (set + potential delete)

  for (const batch of batches) {
    const writeBatch = db.batch();

    for (const [key, members] of batch) {
      memberCount += members.length;
      const ref = db.collection(POOL_COLLECTION).doc(key);
      writeBatch.set(ref, {
        poolKey: key,
        country: key.split('_')[0],
        gender: key.split('_')[1],
        ageBucket: key.split('_')[2],
        members,
        count: members.length,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    await writeBatch.commit();
  }

  logInfo(`Pool build complete: ${pools.size} pools, ${memberCount} members from ${totalScanned} profiles`);

  return { poolCount: pools.size, memberCount };
}

// ───────── Exported Functions ─────────

/**
 * Scheduled function: runs every 10 minutes to rebuild candidate pools.
 */
export const precomputeCandidatePools = onSchedule(
  {
    schedule: 'every 10 minutes',
    timeoutSeconds: 540,
    memory: '1GiB',
  },
  async () => {
    try {
      logInfo('Starting candidate pool pre-computation');
      const result = await buildPools();
      logInfo(`Candidate pool pre-computation complete`, result);
    } catch (error) {
      logError('Candidate pool pre-computation failed', error);
      throw error;
    }
  }
);

/**
 * Callable function: allows admins to trigger a manual pool rebuild.
 */
export const triggerPoolRecompute = onCall(
  {
    memory: '1GiB',
    timeoutSeconds: 540,
  },
  async (request) => {
    // Only authenticated users can trigger (admin check optional)
    if (!request.auth) {
      throw new Error('Authentication required');
    }

    try {
      logInfo('Manual candidate pool re-computation triggered');
      const result = await buildPools();
      return { success: true, ...result };
    } catch (error) {
      logError('Manual pool re-computation failed', error);
      throw error;
    }
  }
);

/**
 * Get pool metadata: returns list of all pools with counts.
 */
export const getCandidatePoolStats = onCall(
  {
    memory: '256MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    if (!request.auth) {
      throw new Error('Authentication required');
    }

    const snapshot = await db.collection(POOL_COLLECTION)
      .select('poolKey', 'count', 'updatedAt')
      .get();

    const pools = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        poolKey: data.poolKey,
        count: data.count,
        updatedAt: data.updatedAt?.toDate?.()?.toISOString() ?? null,
      };
    });

    return {
      totalPools: pools.length,
      totalMembers: pools.reduce((sum, p) => sum + (p.count || 0), 0),
      pools,
    };
  }
);
