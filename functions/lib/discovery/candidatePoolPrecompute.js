"use strict";
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
 * Runs every 30 minutes. Each pool document contains an array of
 * lightweight member entries (userId + scoring metadata) so the
 * Flutter client can filter and score without fetching full profiles.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.getCandidatePoolStats = exports.triggerPoolRecompute = exports.precomputeCandidatePools = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const utils_1 = require("../shared/utils");
const admin = __importStar(require("firebase-admin"));
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
// ───────── Helpers ─────────
function getAgeBucket(age) {
    var _a;
    return (_a = AGE_BUCKETS.find((b) => age >= b.min && age <= b.max)) !== null && _a !== void 0 ? _a : null;
}
function calculateAge(dateOfBirth) {
    const now = new Date();
    let age = now.getFullYear() - dateOfBirth.getFullYear();
    const monthDiff = now.getMonth() - dateOfBirth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < dateOfBirth.getDate())) {
        age--;
    }
    return age;
}
function poolKey(country, gender, bucket) {
    const c = (country || 'Unknown').replace(/[^a-zA-Z]/g, '').substring(0, 30) || 'Unknown';
    const g = (gender || 'Unknown').replace(/[^a-zA-Z]/g, '') || 'Unknown';
    return `${c}_${g}_${bucket.min}-${bucket.max}`;
}
function toPoolMember(doc) {
    var _a, _b, _c, _d, _e, _f;
    const d = doc.data();
    if (!d)
        return null;
    const status = (d.accountStatus || 'active').toLowerCase();
    if (status === 'suspended' || status === 'banned' || status === 'deleted')
        return null;
    // Must be verified and have at least one photo
    const isVerified = d.isVerified === true || d.verificationStatus === 'approved';
    const photoUrls = d.photoUrls;
    if (!isVerified || !photoUrls || photoUrls.length === 0)
        return null;
    // Skip active incognito users
    const isIncognito = d.isIncognito === true;
    if (isIncognito) {
        const expiry = d.incognitoExpiry;
        if (!expiry || expiry.toDate() > new Date())
            return null;
    }
    // Calculate age
    let dob = null;
    if (d.dateOfBirth instanceof admin.firestore.Timestamp) {
        dob = d.dateOfBirth.toDate();
    }
    else if (d.dateOfBirth) {
        dob = new Date(d.dateOfBirth);
    }
    if (!dob || isNaN(dob.getTime()))
        return null;
    const age = calculateAge(dob);
    if (age < 18 || age > 120)
        return null;
    // Resolve effective location (traveler-aware)
    let lat = 0;
    let lng = 0;
    const isTraveler = d.isTraveler === true;
    const travelerExpiry = d.travelerExpiry;
    const isTravelerActive = isTraveler && travelerExpiry && travelerExpiry.toDate() > new Date();
    if (isTravelerActive && d.travelerLocation) {
        lat = (_a = d.travelerLocation.latitude) !== null && _a !== void 0 ? _a : 0;
        lng = (_b = d.travelerLocation.longitude) !== null && _b !== void 0 ? _b : 0;
    }
    else if (d.location) {
        lat = (_c = d.location.latitude) !== null && _c !== void 0 ? _c : 0;
        lng = (_d = d.location.longitude) !== null && _d !== void 0 ? _d : 0;
    }
    // Resolve effective country
    let country = 'Unknown';
    if (isTravelerActive && ((_e = d.travelerLocation) === null || _e === void 0 ? void 0 : _e.country)) {
        country = d.travelerLocation.country;
    }
    else if ((_f = d.location) === null || _f === void 0 ? void 0 : _f.country) {
        country = d.location.country;
    }
    const isBoosted = d.isBoosted === true;
    const boostExpiry = d.boostExpiry;
    const lastSeen = d.lastSeen;
    return {
        userId: doc.id,
        age,
        lat,
        lng,
        interests: d.interests || [],
        languages: d.languages || [],
        isVerified: true,
        isBoosted,
        boostExpiry: boostExpiry ? boostExpiry.toDate().toISOString() : null,
        isOnline: d.isOnline === true,
        lastActive: lastSeen ? lastSeen.toDate().toISOString() : null,
        sexualOrientation: d.sexualOrientation || null,
        hasPhotos: true,
        // We expose `country` and `gender` via the pool key, not per-member
    };
}
// ───────── Core Logic ─────────
async function buildPools() {
    var _a, _b;
    const pools = new Map();
    let lastDoc = null;
    let totalScanned = 0;
    // Paginate through all profiles
    while (true) {
        let query = utils_1.db
            .collection('profiles')
            .limit(SCAN_PAGE_SIZE);
        if (lastDoc) {
            query = query.startAfter(lastDoc);
        }
        const snapshot = await query.get();
        if (snapshot.empty)
            break;
        totalScanned += snapshot.size;
        lastDoc = snapshot.docs[snapshot.docs.length - 1];
        for (const doc of snapshot.docs) {
            const member = toPoolMember(doc);
            if (!member)
                continue;
            const d = doc.data();
            const gender = d.gender || 'Unknown';
            // Determine effective country (same logic as in toPoolMember)
            const isTraveler = d.isTraveler === true;
            const travelerExpiry = d.travelerExpiry;
            const isTravelerActive = isTraveler && travelerExpiry && travelerExpiry.toDate() > new Date();
            let country = 'Unknown';
            if (isTravelerActive && ((_a = d.travelerLocation) === null || _a === void 0 ? void 0 : _a.country)) {
                country = d.travelerLocation.country;
            }
            else if ((_b = d.location) === null || _b === void 0 ? void 0 : _b.country) {
                country = d.location.country;
            }
            const bucket = getAgeBucket(member.age);
            if (!bucket)
                continue;
            const key = poolKey(country, gender, bucket);
            if (!pools.has(key)) {
                pools.set(key, []);
            }
            const members = pools.get(key);
            if (members.length < MAX_POOL_SIZE) {
                members.push(member);
            }
        }
        (0, utils_1.logInfo)(`Pool scan progress: ${totalScanned} profiles scanned, ${pools.size} pools`);
        if (snapshot.size < SCAN_PAGE_SIZE)
            break;
    }
    // Write pools to Firestore using batch writes
    let memberCount = 0;
    const poolEntries = Array.from(pools.entries());
    const batches = (0, utils_1.chunk)(poolEntries, 250); // 500 ops limit, 2 ops per pool (set + potential delete)
    for (const batch of batches) {
        const writeBatch = utils_1.db.batch();
        for (const [key, members] of batch) {
            memberCount += members.length;
            const ref = utils_1.db.collection(POOL_COLLECTION).doc(key);
            writeBatch.set(ref, {
                poolKey: key,
                country: key.split('_')[0],
                gender: key.split('_')[1],
                ageBucket: key.split('_')[2],
                members,
                count: members.length,
                updatedAt: utils_1.FieldValue.serverTimestamp(),
            });
        }
        await writeBatch.commit();
    }
    (0, utils_1.logInfo)(`Pool build complete: ${pools.size} pools, ${memberCount} members from ${totalScanned} profiles`);
    return { poolCount: pools.size, memberCount };
}
// ───────── Exported Functions ─────────
/**
 * Scheduled function: runs every 30 minutes to rebuild candidate pools.
 */
exports.precomputeCandidatePools = (0, scheduler_1.onSchedule)({
    schedule: 'every 30 minutes',
    timeoutSeconds: 540,
    memory: '1GiB',
}, async () => {
    try {
        (0, utils_1.logInfo)('Starting candidate pool pre-computation');
        const result = await buildPools();
        (0, utils_1.logInfo)(`Candidate pool pre-computation complete`, result);
    }
    catch (error) {
        (0, utils_1.logError)('Candidate pool pre-computation failed', error);
        throw error;
    }
});
/**
 * Callable function: allows admins to trigger a manual pool rebuild.
 */
exports.triggerPoolRecompute = (0, https_1.onCall)({
    memory: '1GiB',
    timeoutSeconds: 540,
}, async (request) => {
    // Only authenticated users can trigger (admin check optional)
    if (!request.auth) {
        throw new Error('Authentication required');
    }
    try {
        (0, utils_1.logInfo)('Manual candidate pool re-computation triggered');
        const result = await buildPools();
        return Object.assign({ success: true }, result);
    }
    catch (error) {
        (0, utils_1.logError)('Manual pool re-computation failed', error);
        throw error;
    }
});
/**
 * Get pool metadata: returns list of all pools with counts.
 */
exports.getCandidatePoolStats = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 30,
}, async (request) => {
    if (!request.auth) {
        throw new Error('Authentication required');
    }
    const snapshot = await utils_1.db.collection(POOL_COLLECTION)
        .select('poolKey', 'count', 'updatedAt')
        .get();
    const pools = snapshot.docs.map((doc) => {
        var _a, _b, _c, _d;
        const data = doc.data();
        return {
            poolKey: data.poolKey,
            count: data.count,
            updatedAt: (_d = (_c = (_b = (_a = data.updatedAt) === null || _a === void 0 ? void 0 : _a.toDate) === null || _b === void 0 ? void 0 : _b.call(_a)) === null || _c === void 0 ? void 0 : _c.toISOString()) !== null && _d !== void 0 ? _d : null,
        };
    });
    return {
        totalPools: pools.length,
        totalMembers: pools.reduce((sum, p) => sum + (p.count || 0), 0),
        pools,
    };
});
//# sourceMappingURL=candidatePoolPrecompute.js.map