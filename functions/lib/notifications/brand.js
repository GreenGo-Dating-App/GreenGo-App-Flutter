"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.brandPush = brandPush;
/**
 * App-wide push branding.
 *
 * Every user-facing FCM push shows a uniform title — "GreenGo" — and folds the
 * previous title + body into the body so no information is lost:
 *   title "New event in Rome" + body "Jazz Night"  ->  "New event in Rome: Jazz Night"
 *
 * Use for the TOP-LEVEL `notification` object of a message (the one the OS
 * displays). The `android.notification` sub-block does not carry title/body and
 * is left untouched.
 */
function brandPush(title, body, imageUrl) {
    const t = (title || '').trim();
    const b = (body || '').trim();
    const description = t && b && t !== b ? `${t}: ${b}` : b || t;
    return Object.assign({ title: 'GreenGo', body: description }, (imageUrl ? { imageUrl } : {}));
}
//# sourceMappingURL=brand.js.map