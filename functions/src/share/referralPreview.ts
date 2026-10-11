/**
 * `/r/{CODE}` invite-link page for the `sharePreview` function (see
 * referralPreviewCore.ts). Isolated from sharePreview.ts: the only coupling
 * is one dispatch line there.
 *
 * Reads: referral_codes/{CODE} -> profiles/{ownerId} (public display name
 * only). CDN-cacheable per language (Vary: Accept-Language).
 */
import type { Request } from 'firebase-functions/v2/https';
import type { Response } from 'express';
import { admin } from '../shared/firebaseAdmin';
import {
  buildReferralPreview,
  inviterPublicName,
  localeFromAcceptLanguage,
  parseReferralPath,
  renderReferralHtml,
} from './referralPreviewCore';

const REFERRAL_HTML_CACHE = 'public, max-age=300, s-maxage=1800';

async function inviterName(code: string): Promise<string> {
  try {
    const db = admin.firestore();
    const codeSnap = await db.collection('referral_codes').doc(code).get();
    const ownerId = codeSnap.exists ? codeSnap.get('ownerId') : null;
    if (typeof ownerId !== 'string' || !ownerId) return '';
    const profile = await db.collection('profiles').doc(ownerId).get();
    return inviterPublicName(profile.exists ? (profile.data() as Record<string, unknown>) : null);
  } catch {
    return '';
  }
}

/** Handles `/r/{CODE}`; returns false for any other path (caller continues). */
export async function handleReferralPreview(req: Request, res: Response): Promise<boolean> {
  const parts = req.path.split('/').filter(Boolean);
  if (parts[0] !== 'r') return false;
  const code = parseReferralPath(req.path);
  if (!code) {
    res.redirect(302, 'https://greengo-chat.web.app');
    return true;
  }
  const locale = localeFromAcceptLanguage(req.get('accept-language'));
  const preview = buildReferralPreview(code, await inviterName(code), locale);
  res.set('Cache-Control', REFERRAL_HTML_CACHE);
  res.set('Vary', 'Accept-Language');
  res.type('html').send(renderReferralHtml(preview));
  return true;
}
