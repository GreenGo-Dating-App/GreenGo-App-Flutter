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

  // The title is always "GreenGo", so whatever the caller passed as a title has
  // to move into the body or it is lost. Joining them blindly is what produced
  // notifications that said the same thing twice - "Maria: Maria sent you a
  // message" - so the halves are only joined when they actually add up to
  // something, and never when one already contains the other.
  const norm = (v: string) => v.toLowerCase().replace(/\s+/g, ' ').trim();
  let description: string;
  if (!t) {
    description = b;
  } else if (!b) {
    description = t;
  } else if (norm(b).includes(norm(t))) {
    description = b;
  } else if (norm(t).includes(norm(b))) {
    description = t;
  } else {
    description = `${t}: ${b}`;
  }
  return {
    title: 'GreenGo',
    body: description,
    ...(imageUrl ? { imageUrl } : {}),
  };
}
