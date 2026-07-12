/**
 * Google Wallet — event ticket "Save to Google Wallet" link (NEW, isolated).
 *
 * `getGoogleWalletSaveUrl` is an authenticated HTTPS callable that ensures a
 * Google Wallet **EventTicketClass** exists, upserts an **EventTicketObject**
 * for the caller's ticket, then signs a "Save to Google Wallet" JWT and returns
 *   https://pay.google.com/gp/v/save/<jwt>
 * The Flutter client launches that URL (Android/web) to add the pass.
 *
 * The barcode payload matches the in-app QR ticket + the Apple pass:
 *   greengo:{"e":"<eventId>","u":"<userId>"}
 *
 * PROVISIONING (owner's job — see wallet/README.md): INERT until the Google
 * Wallet issuer id + a service-account key are supplied via secrets. Compiles
 * and deploys without them; throws a descriptive "Google Wallet not configured"
 * error at call time if missing.
 */

import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import * as jwt from 'jsonwebtoken';
import { GoogleAuth } from 'google-auth-library';
import { db, logInfo, logError } from '../shared/utils';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

// ── Secrets ────────────────────────────────────────────────────────────────
const GOOGLE_WALLET_ISSUER_ID = defineSecret('GOOGLE_WALLET_ISSUER_ID');
const GOOGLE_WALLET_SA_KEY = defineSecret('GOOGLE_WALLET_SA_KEY'); // full SA JSON

const WALLET_API_BASE = 'https://walletobjects.googleapis.com/walletobjects/v1';
const WALLET_SCOPE = 'https://www.googleapis.com/auth/wallet_object.issuer';
const SAVE_URL_BASE = 'https://pay.google.com/gp/v/save/';

interface WalletPassRequest {
  eventId: string;
  userId: string;
}

interface GoogleWalletSaveResponse {
  saveUrl: string;
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
  [k: string]: unknown;
}

/**
 * Loads the Google Wallet issuer id + service account from secrets.
 *
 * TODO(provisioning): create a Google Wallet issuer account and a service
 * account key (see wallet/README.md), then set GOOGLE_WALLET_ISSUER_ID and
 * GOOGLE_WALLET_SA_KEY. Until then this throws a descriptive error.
 */
function loadGoogleCredentials(): { issuerId: string; sa: ServiceAccount } {
  const issuerId = process.env.GOOGLE_WALLET_ISSUER_ID || '';
  const rawKey = process.env.GOOGLE_WALLET_SA_KEY || '';

  if (!issuerId || !rawKey) {
    // TODO(provisioning): set these before enabling the Google Wallet button.
    throw new HttpsError(
      'failed-precondition',
      'Google Wallet not configured. Provision a Wallet issuer id and a ' +
        'service-account key, then set GOOGLE_WALLET_ISSUER_ID and ' +
        'GOOGLE_WALLET_SA_KEY (see functions/src/wallet/README.md).',
    );
  }

  let sa: ServiceAccount;
  try {
    // The SA JSON may be stored raw or base64-encoded.
    const json = rawKey.trim().startsWith('{')
      ? rawKey
      : Buffer.from(rawKey, 'base64').toString('utf8');
    sa = JSON.parse(json) as ServiceAccount;
  } catch (_e) {
    throw new HttpsError(
      'failed-precondition',
      'GOOGLE_WALLET_SA_KEY is not valid service-account JSON.',
    );
  }
  if (!sa.client_email || !sa.private_key) {
    throw new HttpsError(
      'failed-precondition',
      'GOOGLE_WALLET_SA_KEY is missing client_email / private_key.',
    );
  }
  return { issuerId, sa };
}

export const getGoogleWalletSaveUrl = onCall<WalletPassRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 30,
    secrets: [GOOGLE_WALLET_ISSUER_ID, GOOGLE_WALLET_SA_KEY],
  },
  monitored('getGoogleWalletSaveUrl', async (
    request: CallableRequest<WalletPassRequest>,
  ): Promise<GoogleWalletSaveResponse> => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'You must be signed in to add a pass');
    }
    const uid = request.auth.uid;
    const eventId = String(request.data?.eventId || '').trim();
    const userId = String(request.data?.userId || '').trim();

    if (!eventId || !userId) {
      throw new HttpsError('invalid-argument', 'eventId and userId are required');
    }
    if (userId !== uid) {
      throw new HttpsError('permission-denied', 'You can only add your own ticket');
    }

    // ── Verify the caller is a *going* attendee ──
    const eventRef = db.collection('events').doc(eventId);
    const [eventSnap, attendeeSnap] = await Promise.all([
      eventRef.get(),
      eventRef.collection('attendees').doc(userId).get(),
    ]);
    if (!eventSnap.exists) {
      throw new HttpsError('not-found', 'Event not found');
    }
    if (!attendeeSnap.exists || attendeeSnap.data()?.status !== 'going') {
      throw new HttpsError(
        'permission-denied',
        'You must be going to this event to add its ticket',
      );
    }

    const event = eventSnap.data() as Record<string, unknown>;
    const title = (event.title as string) || 'GreenGo Event';
    const venue =
      (event.locationName as string) ||
      (event.address as string) ||
      (event.city as string) ||
      '';
    const startDate = toDate(event.startDate);
    const endDate = toDate(event.endDate);
    const barcodePayload = `greengo:${JSON.stringify({ e: eventId, u: userId })}`;

    // ── Load credentials (throws if unconfigured) ──
    const { issuerId, sa } = loadGoogleCredentials();

    // Stable, issuer-namespaced ids. Google requires ids of the form
    // `<issuerId>.<suffix>` where suffix is [A-Za-z0-9._-].
    const safe = (s: string): string => s.replace(/[^A-Za-z0-9._-]/g, '_');
    const classId = `${issuerId}.greengo_event_${safe(eventId)}`;
    const objectId = `${issuerId}.greengo_ticket_${safe(eventId)}_${safe(userId)}`;

    try {
      const auth = new GoogleAuth({
        credentials: { client_email: sa.client_email, private_key: sa.private_key },
        scopes: [WALLET_SCOPE],
      });
      const client = await auth.getClient();

      // ── Ensure the EventTicketClass exists (create-or-ignore) ──
      const eventClass: Record<string, unknown> = {
        id: classId,
        issuerName: 'GreenGo',
        reviewStatus: 'UNDER_REVIEW',
        eventName: {
          defaultValue: { language: 'en-US', value: title },
        },
      };
      if (venue) {
        eventClass.venue = {
          name: { defaultValue: { language: 'en-US', value: venue } },
          address: { defaultValue: { language: 'en-US', value: venue } },
        };
      }
      if (startDate) {
        eventClass.dateTime = {
          start: startDate.toISOString(),
          ...(endDate ? { end: endDate.toISOString() } : {}),
        };
      }

      await upsertWalletResource(client, `${WALLET_API_BASE}/eventTicketClass`, classId, eventClass);

      // ── Upsert the EventTicketObject (this user's ticket) ──
      const eventObject: Record<string, unknown> = {
        id: objectId,
        classId,
        state: 'ACTIVE',
        barcode: {
          type: 'QR_CODE',
          value: barcodePayload,
          alternateText: title,
        },
      };
      await upsertWalletResource(client, `${WALLET_API_BASE}/eventTicketObject`, objectId, eventObject);

      // ── Build + sign the "Save to Google Wallet" JWT ──
      const claims = {
        iss: sa.client_email,
        aud: 'google',
        typ: 'savetowallet',
        iat: Math.floor(Date.now() / 1000),
        payload: {
          eventTicketObjects: [{ id: objectId, classId }],
        },
      };
      const token = jwt.sign(claims, sa.private_key, { algorithm: 'RS256' });

      logInfo(`getGoogleWalletSaveUrl uid=${uid} event=${eventId}`);
      return { saveUrl: `${SAVE_URL_BASE}${token}` };
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      logError(`getGoogleWalletSaveUrl failed uid=${uid} event=${eventId}`, err);
      throw new HttpsError('internal', 'Failed to build Google Wallet save link');
    }
  }),
);

/**
 * Idempotently creates a Wallet class/object: try GET, PATCH if it exists,
 * otherwise POST. Uses the authenticated GoogleAuth client's request().
 */
async function upsertWalletResource(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  client: any,
  collectionUrl: string,
  resourceId: string,
  body: Record<string, unknown>,
): Promise<void> {
  const resourceUrl = `${collectionUrl}/${encodeURIComponent(resourceId)}`;
  try {
    await client.request({ url: resourceUrl, method: 'GET' });
    // Exists → patch to keep event details fresh.
    await client.request({ url: resourceUrl, method: 'PATCH', data: body });
  } catch (err: unknown) {
    const status = (err as { response?: { status?: number } })?.response?.status;
    if (status === 404) {
      await client.request({ url: collectionUrl, method: 'POST', data: body });
    } else {
      throw err;
    }
  }
}

/** Coerces a Firestore Timestamp / ISO string / millis into a Date (or null). */
function toDate(value: unknown): Date | null {
  if (!value) return null;
  if (value instanceof admin.firestore.Timestamp) return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === 'number') return new Date(value);
  if (typeof value === 'string') {
    const d = new Date(value);
    return isNaN(d.getTime()) ? null : d;
  }
  return null;
}
