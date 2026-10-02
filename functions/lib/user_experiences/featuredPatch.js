"use strict";
/** Pure helpers of setExperienceFeatured (no Firebase imports: unit-testable). */
Object.defineProperty(exports, "__esModule", { value: true });
exports.FEATURE_MAX_DAYS = void 0;
exports.featuredPatch = featuredPatch;
exports.FEATURE_MAX_DAYS = 30;
/** Pure: the featured fields for [days] (0 = unfeature), or an error code. */
function featuredPatch(days, nowMs) {
    if (typeof days !== 'number' || !Number.isInteger(days) || days < 0 || days > exports.FEATURE_MAX_DAYS) {
        return { error: 'invalid_days' };
    }
    if (days === 0)
        return { isFeatured: false, featuredUntilMs: null };
    return { isFeatured: true, featuredUntilMs: nowMs + days * 24 * 60 * 60 * 1000 };
}
//# sourceMappingURL=featuredPatch.js.map