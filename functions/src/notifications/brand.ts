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
/**
 * Chat-message pushes (product decision 2026-10-03): the title is the
 * SENDER's name and the body is the message itself (or a media label), not
 * the uniform "GreenGo" branding.
 */
export function messagePush(
  senderName: string,
  preview: string,
  imageUrl?: string,
): { title: string; body: string; imageUrl?: string } {
  const title = (senderName || '').trim() || 'GreenGo';
  const raw = (preview || '').replace(/\s+/g, ' ').trim();
  const body = raw.length > 180 ? `${raw.substring(0, 177)}...` : raw;
  return { title, body, ...(imageUrl ? { imageUrl } : {}) };
}

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
