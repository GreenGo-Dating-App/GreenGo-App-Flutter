"use strict";
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
exports.onProfileBanStateChanged = void 0;
exports.isBannedState = isBannedState;
exports.banPatch = banPatch;
exports.unbanStatus = unbanStatus;
exports.setHostExperiencesBanned = setHostExperiencesBanned;
exports.syncHostExperiencesForBan = syncHostExperiencesForBan;
/**
 * Banned / suspended hosts: hide their experiences; restore them on unban.
 *
 *  - ban:   every experience of the host that is NOT already hidden becomes
 *           status 'hidden' with moderation {reason:'host_banned',
 *           previousStatus}. Text-moderation hides (moderation.auto) and admin
 *           hides are left untouched.
 *  - unban: only experiences hidden with reason 'host_banned' go back to their
 *           previousStatus, and the moderation field is removed. (The text
 *           trigger re-checks the text on that write and re-hides if needed.)
 * Paginated (by document id), idempotent: re-running a ban/unban is a no-op.
 *
 * Called from every server ban/unban path (admin callables, moderation
 * queue) AND from `onProfileBanStateChanged`, which covers admin-panel
 * clients that write profiles.isBanned / accountStatus directly.
 */
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const EXPERIENCES = 'user_experiences';
const PAGE = 300;
/** Pure: is this profile / users doc in a banned-or-suspended state? */
function isBannedState(d) {
    if (!d)
        return false;
    if (d.isBanned === true || d.banned === true)
        return true;
    return d.accountStatus === 'banned' || d.accountStatus === 'suspended';
}
/** Pure: the patch for one experience on ban (null = leave as is). */
function banPatch(exp) {
    if (exp.status === 'hidden')
        return null;
    return {
        status: 'hidden',
        moderation: {
            reason: 'host_banned',
            previousStatus: exp.status === 'published' ? 'published' : 'draft',
        },
    };
}
/** Pure: the status to restore on unban, or null when not hidden by a ban. */
function unbanStatus(exp) {
    const mod = exp.moderation;
    if (exp.status !== 'hidden' || !mod || mod.reason !== 'host_banned')
        return null;
    return mod.previousStatus === 'published' ? 'published' : 'draft';
}
/** Hides (banned=true) or restores (false) all of [hostId]'s experiences. */
async function setHostExperiencesBanned(hostId, banned) {
    if (!hostId)
        return 0;
    const db = admin.firestore();
    let changed = 0;
    let cursor = null;
    for (;;) {
        let q = db.collection(EXPERIENCES)
            .where('hostId', '==', hostId)
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(PAGE);
        if (cursor)
            q = q.startAfter(cursor);
        const page = await q.get();
        const batch = db.batch();
        let ops = 0;
        for (const d of page.docs) {
            const data = d.data();
            if (banned) {
                const p = banPatch(data);
                if (p) {
                    batch.update(d.ref, p);
                    ops++;
                }
            }
            else {
                const st = unbanStatus(data);
                if (st) {
                    batch.update(d.ref, { status: st, moderation: admin.firestore.FieldValue.delete() });
                    ops++;
                }
            }
        }
        if (ops)
            await batch.commit();
        changed += ops;
        if (page.size < PAGE)
            break;
        cursor = page.docs[page.docs.length - 1].id;
    }
    console.log(`setHostExperiencesBanned(${hostId}, ${banned}): ${changed} experiences`);
    return changed;
}
/** Best-effort wrapper for the ban callables (never fails the ban itself). */
async function syncHostExperiencesForBan(hostId, banned) {
    try {
        // Unban from a users-doc callable while the PROFILE is still banned
        // (another ban path): keep them hidden.
        if (!banned) {
            const profile = await admin.firestore().collection('profiles').doc(hostId).get();
            if (isBannedState(profile.data()))
                return;
        }
        await setHostExperiencesBanned(hostId, banned);
    }
    catch (e) {
        console.error(`syncHostExperiencesForBan(${hostId}, ${banned}) failed:`, e);
    }
}
/**
 * profiles/{uid} updates: reacts ONLY when the ban state flips (isBanned /
 * accountStatus). Every other profile write exits after one comparison.
 * 512MiB: the bundle needs ~200MB just to load.
 */
exports.onProfileBanStateChanged = (0, firestore_1.onDocumentUpdated)({ document: 'profiles/{uid}', memory: '512MiB', timeoutSeconds: 300 }, async (event) => {
    var _a, _b;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    const was = isBannedState(before);
    const now = isBannedState(after);
    if (was === now)
        return;
    await setHostExperiencesBanned(event.params.uid, now);
});
//# sourceMappingURL=hostBan.js.map