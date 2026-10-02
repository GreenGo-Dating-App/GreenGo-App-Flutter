"use strict";
/**
 * User experiences — Phase 1 safety rules (PURE: no Firestore access).
 *
 *  - ID document: hosts need an UPLOADED identity document (age-assurance
 *    flow: profiles.ageVerification.status pending|verified) to create an
 *    experience, and an APPROVED one (server-owned profiles.isAgeVerified) to
 *    PUBLISH a listing that takes money (paid, or carrying a paymentLink).
 *    Free listings: uploaded is enough. Drafts may hold a payment link.
 *  - Host agreement: accepted (profiles.hostAgreementVersion >= current)
 *    before the first publish.
 *  - New hosts (< 3 visible reviews across all their experiences, i.e.
 *    profiles.hostRatingCount) may have at most ONE published paid listing.
 *  - Fixed cancellation policies (flexible | moderate | strict) + notes.
 *
 * Mirrored by firestore.rules (user_experiences update) for direct client
 * writes; transitions the rules cannot check (the new-host count) go through
 * the publishUserExperience callable.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.EXPERIENCE_REPORT_TYPES = exports.REPORTS_TO_HIDE = exports.AS_FREE_PATCH = exports.CANCELLATION_NOTES_MAX = exports.DEFAULT_CANCELLATION_POLICY = exports.CANCELLATION_POLICIES = exports.NEW_HOST_MAX_PUBLISHED_PAID = exports.NEW_HOST_MIN_REVIEWS = exports.HOST_AGREEMENT_VERSION = void 0;
exports.normalizeCancellation = normalizeCancellation;
exports.idDocumentState = idDocumentState;
exports.takesPayment = takesPayment;
exports.hostAgreementAccepted = hostAgreementAccepted;
exports.isNewHost = isNewHost;
exports.createBlockReason = createBlockReason;
exports.publishBlockReason = publishBlockReason;
exports.shouldHideForReports = shouldHideForReports;
exports.HOST_AGREEMENT_VERSION = 1;
exports.NEW_HOST_MIN_REVIEWS = 3;
exports.NEW_HOST_MAX_PUBLISHED_PAID = 1;
exports.CANCELLATION_POLICIES = ['flexible', 'moderate', 'strict'];
exports.DEFAULT_CANCELLATION_POLICY = 'moderate';
exports.CANCELLATION_NOTES_MAX = 300;
/**
 * Policy + notes from a payload or stored doc. A legacy free-text
 * `cancellationPolicy` (pre-enum docs) becomes policy 'moderate' with the old
 * text as notes.
 */
function normalizeCancellation(d) {
    const raw = typeof (d === null || d === void 0 ? void 0 : d.cancellationPolicy) === 'string' ? d.cancellationPolicy.trim() : '';
    const notesRaw = typeof (d === null || d === void 0 ? void 0 : d.cancellationNotes) === 'string' ? d.cancellationNotes.trim() : '';
    if (exports.CANCELLATION_POLICIES.includes(raw)) {
        return {
            cancellationPolicy: raw,
            cancellationNotes: notesRaw ? notesRaw.slice(0, exports.CANCELLATION_NOTES_MAX) : null,
        };
    }
    const legacy = notesRaw || raw;
    return {
        cancellationPolicy: exports.DEFAULT_CANCELLATION_POLICY,
        cancellationNotes: legacy ? legacy.slice(0, exports.CANCELLATION_NOTES_MAX) : null,
    };
}
/** Where [profile] stands on the identity document. */
function idDocumentState(profile) {
    var _a;
    if (!profile)
        return 'none';
    if (profile.isAgeVerified === true)
        return 'approved';
    const status = (_a = profile.ageVerification) === null || _a === void 0 ? void 0 : _a.status;
    if (status === 'verified')
        return 'approved';
    if (status === 'pending')
        return 'uploaded';
    return 'none';
}
/** True when the listing takes money from guests (paid, or has a link). */
function takesPayment(e) {
    if (!e)
        return false;
    const pl = e.paymentLink;
    const hasLink = !!pl && typeof pl === 'object' && typeof pl.value === 'string' &&
        pl.value.trim().length > 0;
    return e.isFree !== true || hasLink;
}
function hostAgreementAccepted(profile) {
    var _a;
    return Number((_a = profile === null || profile === void 0 ? void 0 : profile.hostAgreementVersion) !== null && _a !== void 0 ? _a : 0) >= exports.HOST_AGREEMENT_VERSION;
}
function isNewHost(profile) {
    var _a;
    return Number((_a = profile === null || profile === void 0 ? void 0 : profile.hostRatingCount) !== null && _a !== void 0 ? _a : 0) < exports.NEW_HOST_MIN_REVIEWS;
}
/** Why [profile] may not CREATE an experience at all (any status), or null. */
function createBlockReason(profile) {
    if ((profile === null || profile === void 0 ? void 0 : profile.isBanned) === true)
        return 'host_banned';
    if (idDocumentState(profile) === 'none')
        return 'id_document_required';
    return null;
}
/**
 * Why the listing [experience] (as it WILL be) may not be PUBLISHED by
 * [profile], or null. [otherPublishedPaid] = the host's OTHER published
 * PAID listings (isFree false, not counting this one).
 * Admins skip the new-host limit (but not the document rules).
 */
function publishBlockReason(params) {
    const { profile, experience, otherPublishedPaid } = params;
    const base = createBlockReason(profile);
    if (base)
        return base;
    if (!hostAgreementAccepted(profile))
        return 'host_agreement_required';
    if (!takesPayment(experience))
        return null;
    if (idDocumentState(profile) !== 'approved')
        return 'id_document_not_approved';
    if (experience.isFree !== true && (profile === null || profile === void 0 ? void 0 : profile.isAdmin) !== true && isNewHost(profile) &&
        otherPublishedPaid >= exports.NEW_HOST_MAX_PUBLISHED_PAID) {
        return 'new_host_paid_limit';
    }
    return null;
}
/** The fields that turn a listing into a FREE one (the "publish as free" option). */
exports.AS_FREE_PATCH = Object.freeze({
    isFree: true,
    price: 0,
    currency: null,
    paymentLink: null,
});
// ─────────────────────────────────────────────────────────────── reports
exports.REPORTS_TO_HIDE = 3;
/** `reports.type` values that target a user experience. */
exports.EXPERIENCE_REPORT_TYPES = ['user_experience', 'experience'];
/** Whether this many DISTINCT reporters hide a listing currently in [status]. */
function shouldHideForReports(distinctReporters, status) {
    return distinctReporters >= exports.REPORTS_TO_HIDE && status !== 'hidden';
}
//# sourceMappingURL=safety.js.map