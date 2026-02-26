"use strict";
/**
 * Purchase Verification — Google Play & App Store
 *
 * SETUP REQUIRED:
 *
 * 1. Google Play Developer API:
 *    - Google Play Console → Settings → API Access → Link your Firebase project
 *    - Grant your Firebase service account (PROJECT_ID@appspot.gserviceaccount.com)
 *      the "View financial data" and "Manage orders" permissions
 *
 * 2. Apple App Store:
 *    - Install: npm install @apple/app-store-server-library
 *    - Set APPLE_APP_ID in functions/.env (numeric ID from App Store Connect → App Information)
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyGooglePlayPurchase = verifyGooglePlayPurchase;
exports.verifyAppStorePurchase = verifyAppStorePurchase;
const googleapis_1 = require("googleapis");
const axios_1 = __importDefault(require("axios"));
const utils_1 = require("./utils");
const PACKAGE_NAME = 'com.greengochat.greengochatapp';
const BUNDLE_ID = 'com.greengochat.greengochatapp';
// ========== GOOGLE PLAY VERIFICATION ==========
let androidPublisherClient = null;
async function getAndroidPublisher() {
    if (androidPublisherClient)
        return androidPublisherClient;
    const auth = new googleapis_1.google.auth.GoogleAuth({
        scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });
    androidPublisherClient = googleapis_1.google.androidpublisher({ version: 'v3', auth });
    return androidPublisherClient;
}
/**
 * Verify a Google Play managed product (consumable) purchase.
 *
 * @param productId  The product ID (e.g. "greengo_coins_100")
 * @param token      The purchase token from PurchaseDetails.verificationData.serverVerificationData
 */
async function verifyGooglePlayPurchase(productId, token) {
    try {
        const publisher = await getAndroidPublisher();
        const result = await publisher.purchases.products.get({
            packageName: PACKAGE_NAME,
            productId,
            token,
        });
        // purchaseState: 0 = Purchased, 1 = Canceled, 2 = Pending
        const purchaseState = result.data.purchaseState;
        if (purchaseState === 0) {
            (0, utils_1.logInfo)(`Google Play purchase verified: productId=${productId}`);
            return { verified: true, transactionId: result.data.orderId || undefined };
        }
        (0, utils_1.logInfo)(`Google Play purchase state=${purchaseState} for productId=${productId}`);
        return { verified: false, error: `Purchase state: ${purchaseState}` };
    }
    catch (error) {
        const msg = (error === null || error === void 0 ? void 0 : error.message) || String(error);
        // Distinguish API-not-configured errors from actual invalid purchases.
        // Common causes: project not linked, service account lacks permissions,
        // androidpublisher API not enabled.
        const isApiError = msg.includes('forbidden') ||
            msg.includes('Forbidden') ||
            msg.includes('403') ||
            msg.includes('401') ||
            msg.includes('not enabled') ||
            msg.includes('has not been used') ||
            msg.includes('PERMISSION_DENIED') ||
            msg.includes('accessNotConfigured');
        if (isApiError) {
            (0, utils_1.logError)('Google Play API not configured — purchase accepted without server verification. ' +
                'Set up API Access in Google Play Console to enable verification.', msg);
            return { verified: true, apiUnavailable: true };
        }
        (0, utils_1.logError)('Google Play verification error:', msg);
        return { verified: false, error: msg };
    }
}
// ========== APP STORE (iOS) VERIFICATION ==========
let cachedAppleRootCerts = null;
/**
 * Fetch and cache Apple root CA certificates for JWS verification.
 */
async function getAppleRootCerts() {
    if (cachedAppleRootCerts)
        return cachedAppleRootCerts;
    const certUrls = [
        'https://www.apple.com/certificateauthority/AppleRootCA-G3.cer',
        'https://www.apple.com/appleca/AppleIncRootCertificate.cer',
    ];
    const certs = [];
    for (const url of certUrls) {
        try {
            const response = await axios_1.default.get(url, {
                responseType: 'arraybuffer',
                timeout: 10000,
            });
            certs.push(Buffer.from(response.data));
        }
        catch (err) {
            (0, utils_1.logError)(`Failed to fetch Apple cert from ${url}:`, err === null || err === void 0 ? void 0 : err.message);
        }
    }
    if (certs.length === 0) {
        throw new Error('Could not fetch any Apple root certificates');
    }
    cachedAppleRootCerts = certs;
    return certs;
}
/**
 * Verify an App Store StoreKit 2 JWS signed transaction.
 *
 * @param signedTransaction  The JWS string from PurchaseDetails.verificationData.serverVerificationData
 * @param expectedProductId  The product ID to match against the decoded transaction
 * @param appAppleId         Numeric Apple App ID from App Store Connect
 */
async function verifyAppStorePurchase(signedTransaction, expectedProductId, appAppleId) {
    if (!appAppleId || appAppleId === 0) {
        (0, utils_1.logError)('APPLE_APP_ID not configured — set it in functions/.env');
        return { verified: false, error: 'APPLE_APP_ID not configured' };
    }
    try {
        const { SignedDataVerifier, Environment } = await Promise.resolve().then(() => __importStar(require('@apple/app-store-server-library')));
        const rootCerts = await getAppleRootCerts();
        let transaction;
        // Try production first, fall back to sandbox for TestFlight / sandbox testers
        try {
            const verifier = new SignedDataVerifier(rootCerts, true, Environment.PRODUCTION, BUNDLE_ID, appAppleId);
            transaction = await verifier.verifyAndDecodeTransaction(signedTransaction);
        }
        catch (_a) {
            (0, utils_1.logInfo)('Production verification failed, trying Sandbox...');
            const sandboxVerifier = new SignedDataVerifier(rootCerts, true, Environment.SANDBOX, BUNDLE_ID, appAppleId);
            transaction = await sandboxVerifier.verifyAndDecodeTransaction(signedTransaction);
            (0, utils_1.logInfo)('Verified in SANDBOX environment');
        }
        // Verify bundle ID
        if (transaction.bundleId !== BUNDLE_ID) {
            return {
                verified: false,
                error: `Bundle ID mismatch: expected ${BUNDLE_ID}, got ${transaction.bundleId}`,
            };
        }
        // Verify product ID
        if (transaction.productId !== expectedProductId) {
            return {
                verified: false,
                error: `Product ID mismatch: expected ${expectedProductId}, got ${transaction.productId}`,
            };
        }
        (0, utils_1.logInfo)(`App Store purchase verified: productId=${transaction.productId}, transactionId=${transaction.transactionId}`);
        return {
            verified: true,
            transactionId: String(transaction.transactionId),
        };
    }
    catch (error) {
        (0, utils_1.logError)('App Store verification error:', (error === null || error === void 0 ? void 0 : error.message) || error);
        return { verified: false, error: (error === null || error === void 0 ? void 0 : error.message) || 'App Store verification failed' };
    }
}
//# sourceMappingURL=purchase_verification.js.map