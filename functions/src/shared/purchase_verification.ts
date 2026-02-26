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

import { google } from 'googleapis';
import axios from 'axios';
import { logInfo, logError } from './utils';

const PACKAGE_NAME = 'com.greengochat.greengochatapp';
const BUNDLE_ID = 'com.greengochat.greengochatapp';

export interface VerificationResult {
  verified: boolean;
  transactionId?: string;
  error?: string;
  /** True when the store API is unreachable / not configured (not an invalid purchase) */
  apiUnavailable?: boolean;
}

// ========== GOOGLE PLAY VERIFICATION ==========

let androidPublisherClient: ReturnType<typeof google.androidpublisher> | null = null;

async function getAndroidPublisher() {
  if (androidPublisherClient) return androidPublisherClient;

  const auth = new google.auth.GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });

  androidPublisherClient = google.androidpublisher({ version: 'v3', auth });
  return androidPublisherClient;
}

/**
 * Verify a Google Play managed product (consumable) purchase.
 *
 * @param productId  The product ID (e.g. "greengo_coins_100")
 * @param token      The purchase token from PurchaseDetails.verificationData.serverVerificationData
 */
export async function verifyGooglePlayPurchase(
  productId: string,
  token: string,
): Promise<VerificationResult> {
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
      logInfo(`Google Play purchase verified: productId=${productId}`);
      return { verified: true, transactionId: result.data.orderId || undefined };
    }

    logInfo(`Google Play purchase state=${purchaseState} for productId=${productId}`);
    return { verified: false, error: `Purchase state: ${purchaseState}` };
  } catch (error: any) {
    const msg = error?.message || String(error);

    // Distinguish API-not-configured errors from actual invalid purchases.
    // Common causes: project not linked, service account lacks permissions,
    // androidpublisher API not enabled.
    const isApiError =
      msg.includes('forbidden') ||
      msg.includes('Forbidden') ||
      msg.includes('403') ||
      msg.includes('401') ||
      msg.includes('not enabled') ||
      msg.includes('has not been used') ||
      msg.includes('PERMISSION_DENIED') ||
      msg.includes('accessNotConfigured');

    if (isApiError) {
      logError(
        'Google Play API not configured — purchase accepted without server verification. ' +
        'Set up API Access in Google Play Console to enable verification.',
        msg,
      );
      return { verified: true, apiUnavailable: true };
    }

    logError('Google Play verification error:', msg);
    return { verified: false, error: msg };
  }
}

// ========== APP STORE (iOS) VERIFICATION ==========

let cachedAppleRootCerts: Buffer[] | null = null;

/**
 * Fetch and cache Apple root CA certificates for JWS verification.
 */
async function getAppleRootCerts(): Promise<Buffer[]> {
  if (cachedAppleRootCerts) return cachedAppleRootCerts;

  const certUrls = [
    'https://www.apple.com/certificateauthority/AppleRootCA-G3.cer',
    'https://www.apple.com/appleca/AppleIncRootCertificate.cer',
  ];

  const certs: Buffer[] = [];
  for (const url of certUrls) {
    try {
      const response = await axios.get(url, {
        responseType: 'arraybuffer',
        timeout: 10000,
      });
      certs.push(Buffer.from(response.data));
    } catch (err: any) {
      logError(`Failed to fetch Apple cert from ${url}:`, err?.message);
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
export async function verifyAppStorePurchase(
  signedTransaction: string,
  expectedProductId: string,
  appAppleId: number,
): Promise<VerificationResult> {
  if (!appAppleId || appAppleId === 0) {
    logError('APPLE_APP_ID not configured — set it in functions/.env');
    return { verified: false, error: 'APPLE_APP_ID not configured' };
  }

  try {
    const { SignedDataVerifier, Environment } = await import(
      '@apple/app-store-server-library'
    );

    const rootCerts = await getAppleRootCerts();
    let transaction: any;

    // Try production first, fall back to sandbox for TestFlight / sandbox testers
    try {
      const verifier = new SignedDataVerifier(
        rootCerts,
        true,
        Environment.PRODUCTION,
        BUNDLE_ID,
        appAppleId,
      );
      transaction = await verifier.verifyAndDecodeTransaction(signedTransaction);
    } catch {
      logInfo('Production verification failed, trying Sandbox...');
      const sandboxVerifier = new SignedDataVerifier(
        rootCerts,
        true,
        Environment.SANDBOX,
        BUNDLE_ID,
        appAppleId,
      );
      transaction = await sandboxVerifier.verifyAndDecodeTransaction(signedTransaction);
      logInfo('Verified in SANDBOX environment');
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

    logInfo(
      `App Store purchase verified: productId=${transaction.productId}, transactionId=${transaction.transactionId}`,
    );

    return {
      verified: true,
      transactionId: String(transaction.transactionId),
    };
  } catch (error: any) {
    logError('App Store verification error:', error?.message || error);
    return { verified: false, error: error?.message || 'App Store verification failed' };
  }
}
