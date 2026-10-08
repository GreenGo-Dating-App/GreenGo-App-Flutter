/**
 * unsubscribeMarketing (P2-5b): the target of the "Unsubscribe" link and of
 * the List-Unsubscribe header in every marketing e-mail.
 *
 *   GET  ?u=<uid>&t=<token>   confirmation page with ONE button (a GET never
 *                             changes anything: mail scanners prefetch links)
 *   POST ?u=<uid>&t=<token>   records the opt-out (form button, or the
 *                             RFC 8058 one-click POST from the mail client)
 *
 * The token is a stateless HMAC of the uid (shared/marketingConsent.ts); a
 * wrong token gets the same neutral page, so the endpoint cannot be used to
 * probe uids.
 */
import { onRequest } from 'firebase-functions/v2/https';
import { logInfo, logError } from '../shared/utils';
import { recordMarketingOptOut, verifyUnsubscribeToken, PRIVACY_POLICY_URL } from '../shared/marketingConsent';

const esc = (s: string) => s.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);

function page(title: string, body: string): string {
  return '<!doctype html><html><head><meta charset="utf-8">' +
    '<meta name="viewport" content="width=device-width, initial-scale=1">' +
    `<title>${esc(title)}</title>` +
    '<style>body{font-family:Arial,sans-serif;max-width:520px;margin:40px auto;padding:0 16px;color:#222}' +
    'button{padding:12px 24px;font-size:16px;cursor:pointer}</style></head><body>' +
    `<h1>${esc(title)}</h1>${body}` +
    `<p style="margin-top:32px;font-size:13px"><a href="${PRIVACY_POLICY_URL}">Privacy Policy</a></p>` +
    '</body></html>';
}

export async function handleUnsubscribe(req: any, res: any): Promise<void> {
  const q = { ...(req.query || {}), ...(typeof req.body === 'object' && req.body ? req.body : {}) };
  const uid = String(q.u ?? '');
  const token = String(q.t ?? '');
  res.set('Cache-Control', 'no-store');
  res.set('X-Robots-Tag', 'noindex');
  const valid = verifyUnsubscribeToken(uid, token);

  if (req.method === 'GET') {
    if (!valid) {
      res.status(400).type('html').send(page('Link not valid',
        '<p>This unsubscribe link is not valid. You can turn marketing e-mails off in the app under Settings.</p>'));
      return;
    }
    res.status(200).type('html').send(page('Unsubscribe from GreenGo marketing e-mails',
      '<p>Press the button to stop receiving news, digests and offers by e-mail. ' +
      'Account and security e-mails are not affected.</p>' +
      `<form method="POST" action="?u=${encodeURIComponent(uid)}&t=${encodeURIComponent(token)}">` +
      '<button type="submit">Unsubscribe</button></form>'));
    return;
  }
  if (req.method !== 'POST') {
    res.status(405).send('Method not allowed');
    return;
  }
  if (!valid) {
    res.status(400).type('html').send(page('Link not valid',
      '<p>This unsubscribe link is not valid. You can turn marketing e-mails off in the app under Settings.</p>'));
    return;
  }
  try {
    await recordMarketingOptOut(uid, 'unsubscribe_link');
    logInfo(`unsubscribeMarketing: opt-out recorded for ${uid}`);
    res.status(200).type('html').send(page('You are unsubscribed',
      '<p>You will no longer receive marketing e-mails from GreenGo. You can opt in again in the app.</p>'));
  } catch (e) {
    logError('unsubscribeMarketing failed', e);
    res.status(500).type('html').send(page('Something went wrong', '<p>Please try again later.</p>'));
  }
}

export const unsubscribeMarketing = onRequest(
  { memory: '512MiB', timeoutSeconds: 30, invoker: 'public' },
  handleUnsubscribe,
);
