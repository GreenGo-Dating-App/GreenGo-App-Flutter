"use strict";
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
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.getGoogleWalletSaveUrl = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const admin = __importStar(require("firebase-admin"));
const jwt = __importStar(require("jsonwebtoken"));
const google_auth_library_1 = require("google-auth-library");
const utils_1 = require("../shared/utils");
const monitoring_1 = require("../shared/monitoring");
require("../shared/firebaseAdmin");
// ── Secrets ────────────────────────────────────────────────────────────────
const GOOGLE_WALLET_ISSUER_ID = (0, params_1.defineSecret)('GOOGLE_WALLET_ISSUER_ID');
const GOOGLE_WALLET_SA_KEY = (0, params_1.defineSecret)('GOOGLE_WALLET_SA_KEY'); // full SA JSON
const WALLET_API_BASE = 'https://walletobjects.googleapis.com/walletobjects/v1';
const WALLET_SCOPE = 'https://www.googleapis.com/auth/wallet_object.issuer';
const SAVE_URL_BASE = 'https://pay.google.com/gp/v/save/';
/**
 * Loads the Google Wallet issuer id + service account from secrets.
 *
 * TODO(provisioning): create a Google Wallet issuer account and a service
 * account key (see wallet/README.md), then set GOOGLE_WALLET_ISSUER_ID and
 * GOOGLE_WALLET_SA_KEY. Until then this throws a descriptive error.
 */
function loadGoogleCredentials() {
    const issuerId = process.env.GOOGLE_WALLET_ISSUER_ID || '';
    const rawKey = process.env.GOOGLE_WALLET_SA_KEY || '';
    if (!issuerId || !rawKey) {
        // TODO(provisioning): set these before enabling the Google Wallet button.
        throw new https_1.HttpsError('failed-precondition', 'Google Wallet not configured. Provision a Wallet issuer id and a ' +
            'service-account key, then set GOOGLE_WALLET_ISSUER_ID and ' +
            'GOOGLE_WALLET_SA_KEY (see functions/src/wallet/README.md).');
    }
    let sa;
    try {
        // The SA JSON may be stored raw or base64-encoded.
        const json = rawKey.trim().startsWith('{')
            ? rawKey
            : Buffer.from(rawKey, 'base64').toString('utf8');
        sa = JSON.parse(json);
    }
    catch (_e) {
        throw new https_1.HttpsError('failed-precondition', 'GOOGLE_WALLET_SA_KEY is not valid service-account JSON.');
    }
    if (!sa.client_email || !sa.private_key) {
        throw new https_1.HttpsError('failed-precondition', 'GOOGLE_WALLET_SA_KEY is missing client_email / private_key.');
    }
    return { issuerId, sa };
}
exports.getGoogleWalletSaveUrl = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 30,
    secrets: [GOOGLE_WALLET_ISSUER_ID, GOOGLE_WALLET_SA_KEY],
}, (0, monitoring_1.monitored)('getGoogleWalletSaveUrl', async (request) => {
    var _a, _b, _c;
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'You must be signed in to add a pass');
    }
    const uid = request.auth.uid;
    const eventId = String(((_a = request.data) === null || _a === void 0 ? void 0 : _a.eventId) || '').trim();
    const userId = String(((_b = request.data) === null || _b === void 0 ? void 0 : _b.userId) || '').trim();
    if (!eventId || !userId) {
        throw new https_1.HttpsError('invalid-argument', 'eventId and userId are required');
    }
    if (userId !== uid) {
        throw new https_1.HttpsError('permission-denied', 'You can only add your own ticket');
    }
    // ── Verify the caller is a *going* attendee ──
    const eventRef = utils_1.db.collection('events').doc(eventId);
    const [eventSnap, attendeeSnap] = await Promise.all([
        eventRef.get(),
        eventRef.collection('attendees').doc(userId).get(),
    ]);
    if (!eventSnap.exists) {
        throw new https_1.HttpsError('not-found', 'Event not found');
    }
    if (!attendeeSnap.exists || ((_c = attendeeSnap.data()) === null || _c === void 0 ? void 0 : _c.status) !== 'going') {
        throw new https_1.HttpsError('permission-denied', 'You must be going to this event to add its ticket');
    }
    const event = eventSnap.data();
    const title = event.title || 'GreenGo Event';
    const venue = event.locationName ||
        event.address ||
        event.city ||
        '';
    const startDate = toDate(event.startDate);
    const endDate = toDate(event.endDate);
    const barcodePayload = `greengo:${JSON.stringify({ e: eventId, u: userId })}`;
    // ── Load credentials (throws if unconfigured) ──
    const { issuerId, sa } = loadGoogleCredentials();
    // Stable, issuer-namespaced ids. Google requires ids of the form
    // `<issuerId>.<suffix>` where suffix is [A-Za-z0-9._-].
    const safe = (s) => s.replace(/[^A-Za-z0-9._-]/g, '_');
    const classId = `${issuerId}.greengo_event_${safe(eventId)}`;
    const objectId = `${issuerId}.greengo_ticket_${safe(eventId)}_${safe(userId)}`;
    try {
        const auth = new google_auth_library_1.GoogleAuth({
            credentials: { client_email: sa.client_email, private_key: sa.private_key },
            scopes: [WALLET_SCOPE],
        });
        const client = await auth.getClient();
        // ── Ensure the EventTicketClass exists (create-or-ignore) ──
        const eventClass = {
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
            eventClass.dateTime = Object.assign({ start: startDate.toISOString() }, (endDate ? { end: endDate.toISOString() } : {}));
        }
        await upsertWalletResource(client, `${WALLET_API_BASE}/eventTicketClass`, classId, eventClass);
        // ── Upsert the EventTicketObject (this user's ticket) ──
        const eventObject = {
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
        (0, utils_1.logInfo)(`getGoogleWalletSaveUrl uid=${uid} event=${eventId}`);
        return { saveUrl: `${SAVE_URL_BASE}${token}` };
    }
    catch (err) {
        if (err instanceof https_1.HttpsError)
            throw err;
        (0, utils_1.logError)(`getGoogleWalletSaveUrl failed uid=${uid} event=${eventId}`, err);
        throw new https_1.HttpsError('internal', 'Failed to build Google Wallet save link');
    }
}));
/**
 * Idempotently creates a Wallet class/object: try GET, PATCH if it exists,
 * otherwise POST. Uses the authenticated GoogleAuth client's request().
 */
async function upsertWalletResource(
// eslint-disable-next-line @typescript-eslint/no-explicit-any
client, collectionUrl, resourceId, body) {
    var _a;
    const resourceUrl = `${collectionUrl}/${encodeURIComponent(resourceId)}`;
    try {
        await client.request({ url: resourceUrl, method: 'GET' });
        // Exists → patch to keep event details fresh.
        await client.request({ url: resourceUrl, method: 'PATCH', data: body });
    }
    catch (err) {
        const status = (_a = err === null || err === void 0 ? void 0 : err.response) === null || _a === void 0 ? void 0 : _a.status;
        if (status === 404) {
            await client.request({ url: collectionUrl, method: 'POST', data: body });
        }
        else {
            throw err;
        }
    }
}
/** Coerces a Firestore Timestamp / ISO string / millis into a Date (or null). */
function toDate(value) {
    if (!value)
        return null;
    if (value instanceof admin.firestore.Timestamp)
        return value.toDate();
    if (value instanceof Date)
        return value;
    if (typeof value === 'number')
        return new Date(value);
    if (typeof value === 'string') {
        const d = new Date(value);
        return isNaN(d.getTime()) ? null : d;
    }
    return null;
}
//# sourceMappingURL=googleWallet.js.map