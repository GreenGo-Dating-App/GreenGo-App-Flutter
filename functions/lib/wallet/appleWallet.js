"use strict";
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
exports.getAppleWalletPass = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("../shared/utils");
const monitoring_1 = require("../shared/monitoring");
require("../shared/firebaseAdmin");
// ── Secrets (set via `firebase functions:secrets:set <NAME>`) ──────────────
// PEM/DER material is stored base64-encoded in the secret to survive newlines.
const APPLE_PASS_CERT = (0, params_1.defineSecret)('APPLE_PASS_CERT'); // signerCert (PEM, base64)
const APPLE_PASS_KEY = (0, params_1.defineSecret)('APPLE_PASS_KEY'); // signerKey (PEM, base64)
const APPLE_PASS_KEY_PASSPHRASE = (0, params_1.defineSecret)('APPLE_PASS_KEY_PASSPHRASE');
const APPLE_WWDR_CERT = (0, params_1.defineSecret)('APPLE_WWDR_CERT'); // Apple WWDR G4 (PEM, base64)
const APPLE_PASS_TYPE_ID = (0, params_1.defineSecret)('APPLE_PASS_TYPE_ID'); // e.g. pass.com.greengo.eventticket
const APPLE_TEAM_ID = (0, params_1.defineSecret)('APPLE_TEAM_ID'); // 10-char Apple Team ID
/**
 * Loads + decodes the Apple Wallet certificate material from secrets.
 *
 * TODO(provisioning): populate these secrets from the Apple Developer portal —
 * see wallet/README.md. Until then this throws a descriptive error and the
 * client shows the generic `walletError` snackbar.
 */
function loadAppleCredentials() {
    const rawCert = process.env.APPLE_PASS_CERT || '';
    const rawKey = process.env.APPLE_PASS_KEY || '';
    const rawWwdr = process.env.APPLE_WWDR_CERT || '';
    const passTypeIdentifier = process.env.APPLE_PASS_TYPE_ID || '';
    const teamIdentifier = process.env.APPLE_TEAM_ID || '';
    const passphrase = process.env.APPLE_PASS_KEY_PASSPHRASE || '';
    if (!rawCert || !rawKey || !rawWwdr || !passTypeIdentifier || !teamIdentifier) {
        // TODO(provisioning): set these before enabling the Apple Wallet button.
        throw new https_1.HttpsError('failed-precondition', 'Apple Wallet not configured. Provision the Pass Type ID certificate and ' +
            'set APPLE_PASS_CERT, APPLE_PASS_KEY, APPLE_WWDR_CERT, APPLE_PASS_TYPE_ID ' +
            'and APPLE_TEAM_ID (see functions/src/wallet/README.md).');
    }
    // Secrets are stored base64-encoded so multi-line PEMs survive transport.
    const decode = (v) => v.includes('BEGIN') ? v : Buffer.from(v, 'base64').toString('utf8');
    return {
        signerCert: decode(rawCert),
        signerKey: decode(rawKey),
        signerKeyPassphrase: passphrase || undefined,
        wwdr: decode(rawWwdr),
        passTypeIdentifier,
        teamIdentifier,
    };
}
exports.getAppleWalletPass = (0, https_1.onCall)({
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
}, (0, monitoring_1.monitored)('getAppleWalletPass', async (request) => {
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
    // The pass belongs to the caller — never mint someone else's ticket.
    if (userId !== uid) {
        throw new https_1.HttpsError('permission-denied', 'You can only add your own ticket');
    }
    // ── Verify the caller is a *going* attendee of this event ──
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
    // The exact same payload the in-app QR ticket encodes (EventTicketPayload).
    const barcodePayload = `greengo:${JSON.stringify({ e: eventId, u: userId })}`;
    // ── Load + validate certificate material (throws if unconfigured) ──
    const creds = loadAppleCredentials();
    try {
        // Imported lazily so the module still loads if the dependency has not
        // been installed yet (corp network can block `npm install`).
        const { PKPass } = await Promise.resolve().then(() => __importStar(require('passkit-generator')));
        // NOTE(provisioning): a `.pkpass` also needs image assets (icon.png,
        // logo.png, ...). Drop them into functions/src/wallet/models/greengo.pass
        // and load them here as buffers. Empty buffers keep the scaffold building;
        // Apple requires at least icon.png at runtime — see wallet/README.md.
        const modelBuffers = {};
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
        (0, utils_1.logInfo)(`getAppleWalletPass uid=${uid} event=${eventId}`);
        return {
            pkpass: buffer.toString('base64'),
            fileName: `greengo-${eventId}.pkpass`,
        };
    }
    catch (err) {
        if (err instanceof https_1.HttpsError)
            throw err;
        (0, utils_1.logError)(`getAppleWalletPass failed uid=${uid} event=${eventId}`, err);
        throw new https_1.HttpsError('internal', 'Failed to build Apple Wallet pass');
    }
}));
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
//# sourceMappingURL=appleWallet.js.map