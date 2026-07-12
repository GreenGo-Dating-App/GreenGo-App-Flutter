/**
 * Apple Wallet — event ticket .pkpass generator (NEW, isolated module).
 *
 * `getAppleWalletPass` is an authenticated HTTPS callable that builds a signed
 * PassKit **eventTicket** pass for an event the caller is *going* to, and
 * returns it as base64 so the Flutter client can drop it to a temp `.pkpass`
 * file and hand it to iOS (which opens Apple Wallet).
 *
 * The QR/barcode payload is the SAME compact codec the in-app QR ticket uses:
 *   greengo:{"e":"<eventId>","u":"<userId>"}
 * so the organizer's existing scanner validates a Wallet pass identically.
 *
 * PROVISIONING (owner's job — see wallet/README.md): this function is INERT
 * until the Apple Pass Type ID certificate material is supplied via secrets.
 * The code compiles and deploys without them; it throws a descriptive
 * "Apple Wallet not configured" error at call time if any secret is missing.
 */

import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { db, logInfo, logError } from '../shared/utils';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

// ── Secrets (set via `firebase functions:secrets:set <NAME>`) ──────────────
// PEM/DER material is stored base64-encoded in the secret to survive newlines.
const APPLE_PASS_CERT = defineSecret('APPLE_PASS_CERT'); // signerCert (PEM, base64)
const APPLE_PASS_KEY = defineSecret('APPLE_PASS_KEY'); // signerKey (PEM, base64)
const APPLE_PASS_KEY_PASSPHRASE = defineSecret('APPLE_PASS_KEY_PASSPHRASE');
const APPLE_WWDR_CERT = defineSecret('APPLE_WWDR_CERT'); // Apple WWDR G4 (PEM, base64)
const APPLE_PASS_TYPE_ID = defineSecret('APPLE_PASS_TYPE_ID'); // e.g. pass.com.greengo.eventticket
const APPLE_TEAM_ID = defineSecret('APPLE_TEAM_ID'); // 10-char Apple Team ID

interface WalletPassRequest {
  eventId: string;
  userId: string;
}

interface AppleWalletPassResponse {
  /** base64-encoded `.pkpass` bundle. */
  pkpass: string;
  fileName: string;
}

/**
 * Loads + decodes the Apple Wallet certificate material from secrets.
 *
 * TODO(provisioning): populate these secrets from the Apple Developer portal —
 * see wallet/README.md. Until then this throws a descriptive error and the
 * client shows the generic `walletError` snackbar.
 */
function loadAppleCredentials(): {
  signerCert: string;
  signerKey: string;
  signerKeyPassphrase?: string;
  wwdr: string;
  passTypeIdentifier: string;
  teamIdentifier: string;
} {
  const rawCert = process.env.APPLE_PASS_CERT || '';
  const rawKey = process.env.APPLE_PASS_KEY || '';
  const rawWwdr = process.env.APPLE_WWDR_CERT || '';
  const passTypeIdentifier = process.env.APPLE_PASS_TYPE_ID || '';
  const teamIdentifier = process.env.APPLE_TEAM_ID || '';
  const passphrase = process.env.APPLE_PASS_KEY_PASSPHRASE || '';

  if (!rawCert || !rawKey || !rawWwdr || !passTypeIdentifier || !teamIdentifier) {
    // TODO(provisioning): set these before enabling the Apple Wallet button.
    throw new HttpsError(
      'failed-precondition',
      'Apple Wallet not configured. Provision the Pass Type ID certificate and ' +
        'set APPLE_PASS_CERT, APPLE_PASS_KEY, APPLE_WWDR_CERT, APPLE_PASS_TYPE_ID ' +
        'and APPLE_TEAM_ID (see functions/src/wallet/README.md).',
    );
  }

  // Secrets are stored base64-encoded so multi-line PEMs survive transport.
  const decode = (v: string): string =>
    v.includes('BEGIN') ? v : Buffer.from(v, 'base64').toString('utf8');

  return {
    signerCert: decode(rawCert),
    signerKey: decode(rawKey),
    signerKeyPassphrase: passphrase || undefined,
    wwdr: decode(rawWwdr),
    passTypeIdentifier,
    teamIdentifier,
  };
}

export const getAppleWalletPass = onCall<WalletPassRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 30,
    secrets: [
      APPLE_PASS_CERT,
      APPLE_PASS_KEY,
      APPLE_PASS_KEY_PASSPHRASE,
      APPLE_WWDR_CERT,
      APPLE_PASS_TYPE_ID,
      APPLE_TEAM_ID,
    ],
  },
  monitored('getAppleWalletPass', async (
    request: CallableRequest<WalletPassRequest>,
  ): Promise<AppleWalletPassResponse> => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'You must be signed in to add a pass');
    }
    const uid = request.auth.uid;
    const eventId = String(request.data?.eventId || '').trim();
    const userId = String(request.data?.userId || '').trim();

    if (!eventId || !userId) {
      throw new HttpsError('invalid-argument', 'eventId and userId are required');
    }
    // The pass belongs to the caller — never mint someone else's ticket.
    if (userId !== uid) {
      throw new HttpsError('permission-denied', 'You can only add your own ticket');
    }

    // ── Verify the caller is a *going* attendee of this event ──
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

    // The exact same payload the in-app QR ticket encodes (EventTicketPayload).
    const barcodePayload = `greengo:${JSON.stringify({ e: eventId, u: userId })}`;

    // ── Load + validate certificate material (throws if unconfigured) ──
    const creds = loadAppleCredentials();

    try {
      // Imported lazily so the module still loads if the dependency has not
      // been installed yet (corp network can block `npm install`).
      const { PKPass } = await import('passkit-generator');

      // NOTE(provisioning): a `.pkpass` also needs image assets (icon.png,
      // logo.png, ...). Drop them into functions/src/wallet/models/greengo.pass
      // and load them here as buffers. Empty buffers keep the scaffold building;
      // Apple requires at least icon.png at runtime — see wallet/README.md.
      const modelBuffers: { [key: string]: Buffer } = {};

      const pass = new PKPass(modelBuffers, {
        wwdr: creds.wwdr,
        signerCert: creds.signerCert,
        signerKey: creds.signerKey,
        signerKeyPassphrase: creds.signerKeyPassphrase,
      }, {
        formatVersion: 1,
        passTypeIdentifier: creds.passTypeIdentifier,
        teamIdentifier: creds.teamIdentifier,
        organizationName: 'GreenGo',
        serialNumber: `${eventId}.${userId}`,
        description: title,
        foregroundColor: 'rgb(255,255,255)',
        backgroundColor: 'rgb(26,26,26)',
        labelColor: 'rgb(212,175,55)',
      });

      // Mark as an event ticket and attach the scannable barcode.
      pass.type = 'eventTicket';
      pass.setBarcodes({
        message: barcodePayload,
        format: 'PKBarcodeFormatQR',
        messageEncoding: 'iso-8859-1',
        altText: title,
      });

      pass.primaryFields.push({ key: 'event', label: 'EVENT', value: title });
      if (startDate) {
        pass.secondaryFields.push({
          key: 'date',
          label: 'DATE',
          value: startDate.toISOString(),
          dateStyle: 'PKDateStyleMedium',
          timeStyle: 'PKDateStyleShort',
        });
      }
      if (venue) {
        pass.secondaryFields.push({ key: 'venue', label: 'VENUE', value: venue });
      }

      const buffer = pass.getAsBuffer();
      logInfo(`getAppleWalletPass uid=${uid} event=${eventId}`);
      return {
        pkpass: buffer.toString('base64'),
        fileName: `greengo-${eventId}.pkpass`,
      };
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      logError(`getAppleWalletPass failed uid=${uid} event=${eventId}`, err);
      throw new HttpsError('internal', 'Failed to build Apple Wallet pass');
    }
  }),
);

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
