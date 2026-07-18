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
export function brandPush(
  title?: string,
  body?: string,
  imageUrl?: string,
): { title: string; body: string; imageUrl?: string } {
  const t = (title || '').trim();
  const b = (body || '').trim();
  const description = t && b && t !== b ? `${t}: ${b}` : b || t;
  return {
    title: 'GreenGo',
    body: description,
    ...(imageUrl ? { imageUrl } : {}),
  };
}
