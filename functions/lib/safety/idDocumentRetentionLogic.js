"use strict";
/**
 * ID-document retention — PURE decision logic (no Firebase access), so it can
 * be unit-tested. The I/O lives in idDocumentRetention.ts.
 *
 * Policy (DRAFT — lawyer review: LGPD art. 7 IX legitimate interest /
 * GDPR Art. 6(1)(f), fraud prevention):
 *   - the CURRENT identity document of an account is kept server-side
 *     (`id_documents/{uid}/…`, no client access) while the account exists;
 *   - a REPLACED document is kept for 30 days after the replacement;
 *   - on ACCOUNT DELETION every document is moved to `retention/{uid}/…` and
 *     kept for 30 days after the deletion;
 *   - then it is permanently erased by `purgeRetainedIdDocuments`, unless an
 *     admin placed a `legalHold` (e.g. an open scam report).
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.DAY_MS = exports.RETENTION_DAYS = void 0;
exports.purgeAfterMs = purgeAfterMs;
exports.entryPaths = entryPaths;
exports.isDueForPurge = isDueForPurge;
exports.planPurgePage = planPurgePage;
exports.mergeAccountRetention = mergeAccountRetention;
exports.retentionPathFor = retentionPathFor;
exports.idVerifiedFlagFor = idVerifiedFlagFor;
exports.idVerifiedFlagNeedsRepair = idVerifiedFlagNeedsRepair;
exports.RETENTION_DAYS = 30;
exports.DAY_MS = 24 * 60 * 60 * 1000;
/** When a document retained at [retainedAtMs] may be purged. */
function purgeAfterMs(retainedAtMs, days = exports.RETENTION_DAYS) {
    return retainedAtMs + days * exports.DAY_MS;
}
/** Storage paths of an entry, sanitised (strings only, de-duplicated). */
function entryPaths(entry) {
    if (!Array.isArray(entry.storagePaths))
        return [];
    const out = [];
    for (const p of entry.storagePaths) {
        if (typeof p === 'string' && p.length > 0 && !out.includes(p))
            out.push(p);
    }
    return out;
}
/**
 * Whether [entry] must be purged now. A legal hold always wins; an entry with
 * an unreadable purge date is NEVER purged automatically (keep + log rather
 * than erase evidence by accident).
 */
function isDueForPurge(entry, nowMs) {
    if (entry.legalHold === true)
        return false;
    if (entry.purgeAfterMs === null || !Number.isFinite(entry.purgeAfterMs))
        return false;
    return entry.purgeAfterMs <= nowMs;
}
/**
 * Plans one page of the purge. The query already selects `purgeAfter <= now`
 * ordered by purgeAfter; held entries stay in that range forever, so the
 * caller pages past them with [cursor] instead of re-reading page 1.
 */
function planPurgePage(page, nowMs, pageSize) {
    const due = [];
    let held = 0;
    let notDue = 0;
    for (const e of page) {
        if (isDueForPurge(e, nowMs))
            due.push(e);
        else if (e.legalHold === true)
            held++;
        else
            notDue++;
    }
    return {
        due,
        held,
        notDue,
        cursor: page.length ? page[page.length - 1].id : null,
        done: page.length < pageSize,
    };
}
/**
 * The single 'account-deleted' entry for [uid], merged with any entries it
 * supersedes (earlier 'replaced' ones, or a previous run of the deletion
 * hook): union of paths, the LATEST purge date, and a hold if any had one.
 */
function mergeAccountRetention(movedPaths, deletedAtMs, existing) {
    const paths = [...new Set(movedPaths.filter((p) => typeof p === 'string' && p))];
    let purge = purgeAfterMs(deletedAtMs);
    let hold = false;
    for (const e of existing) {
        for (const p of entryPaths(e)) {
            // Paths still under the live prefix were moved by this run.
            if (!p.startsWith('id_documents/') && !paths.includes(p))
                paths.push(p);
        }
        if (e.purgeAfterMs !== null && Number.isFinite(e.purgeAfterMs)) {
            purge = Math.max(purge, e.purgeAfterMs);
        }
        if (e.legalHold === true)
            hold = true;
    }
    return { storagePaths: paths, purgeAfterMs: purge, legalHold: hold };
}
/** `id_documents/{uid}/x.jpg` → `retention/{uid}/x.jpg`. */
function retentionPathFor(livePath, uid) {
    var _a;
    const prefix = `id_documents/${uid}/`;
    const name = livePath.startsWith(prefix) ? livePath.slice(prefix.length) : (_a = livePath.split('/').pop()) !== null && _a !== void 0 ? _a : livePath;
    return `retention/${uid}/${name}`;
}
/**
 * The value `profiles.isAgeVerified` must hold for an `ageVerification`
 * status. It is the ONE "ID verified" flag (badge source of truth): true only
 * for an APPROVED identity document. A ban does not change it — the client
 * hides the badge for inactive (banned/suspended) accounts instead, so an
 * unban does not require re-verification.
 */
function idVerifiedFlagFor(ageVerification) {
    if (!ageVerification || typeof ageVerification !== 'object')
        return false;
    return ageVerification.status === 'verified';
}
/** Whether a stored flag differs from what the status implies. */
function idVerifiedFlagNeedsRepair(profile) {
    if (!profile)
        return false;
    const want = idVerifiedFlagFor(profile.ageVerification);
    return (profile.isAgeVerified === true) !== want;
}
//# sourceMappingURL=idDocumentRetentionLogic.js.map