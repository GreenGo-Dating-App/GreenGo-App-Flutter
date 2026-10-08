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
  /** Subscription identity (used to match later renewal/expiry notifications to this user). */
  originalTransactionId?: string;
  /** Store-authoritative expiry for auto-renewable subscriptions, epoch ms. */
  expiresDateMs?: number;
  /**
   * Genuine purchase, but its subscription period is over (expiry <= now, or
   * Play state EXPIRED / ON_HOLD / PAUSED). Callers must NOT grant on it.
   */
  expired?: boolean;
  /** Genuine purchase that the store refunded / revoked. Callers must NOT grant on it. */
  revoked?: boolean;
  /** Store product id the token/transaction belongs to (Play: lineItems[].productId). */
  productId?: string;
  /**
   * Store environment the purchase was made in. Apple: 'PRODUCTION' | 'SANDBOX'
   * (TestFlight / App Review / sandbox testers). Play: 'SANDBOX' when the
   * license-tester flag (purchaseType 0) is set, else 'PRODUCTION'.
   */
  environment?: 'PRODUCTION' | 'SANDBOX';
  /** Play products.get purchaseType: 0 = Test (license tester), 1 = Promo, 2 = Rewarded; undefined = normal. */
  purchaseType?: number;
  /** Play obfuscatedExternalAccountId (the app sets it to the buyer's uid via applicationUserName). */
  obfuscatedAccountId?: string;
  /** Apple appAccountToken (UUID) when the app set one. */
  appAccountToken?: string;
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
      const purchaseType =
        typeof result.data.purchaseType === 'number' ? result.data.purchaseType : undefined;
      logInfo(
        `Google Play purchase verified: productId=${productId}` +
        `${purchaseType !== undefined ? ` purchaseType=${purchaseType}` : ''}`,
      );
      return {
        verified: true,
        transactionId: result.data.orderId || undefined,
        purchaseType,
        // purchaseType 0 = bought with a license-tester account (no money moved).
        environment: purchaseType === 0 ? 'SANDBOX' : 'PRODUCTION',
        obfuscatedAccountId: result.data.obfuscatedExternalAccountId || undefined,
      };
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
      // H4: FAIL CLOSED — an unreachable/misconfigured store API must NOT grant
      // entitlement (was `verified: true`, which handed out free coins/tiers).
      return { verified: false, apiUnavailable: true };
    }

    logError('Google Play verification error:', msg);
    return { verified: false, error: msg };
  }
}

/**
 * Verify a Google Play auto-renewable SUBSCRIPTION by its purchase token, using
 * the Subscriptions v2 API (the products API used by [verifyGooglePlayPurchase]
 * is for one-time products and fails for subscriptions). Returns the store
 * expiry so the caller can set entitlement without client-side stacking.
 */
export async function verifyGooglePlaySubscription(
  token: string,
): Promise<VerificationResult> {
  try {
    const publisher = await getAndroidPublisher();
    const res: any = await publisher.purchases.subscriptionsv2.get({
      packageName: PACKAGE_NAME,
      token,
    });

    const state: string = res.data?.subscriptionState || '';
    const lineItems: any[] = res.data?.lineItems || [];
    let latestMs: number | undefined;
    let productId: string | undefined;
    for (const li of lineItems) {
      if (li.expiryTime) {
        const ms = new Date(li.expiryTime).getTime();
        if (!latestMs || ms > latestMs) {
          latestMs = ms;
          productId = li.productId || productId;
        }
      } else if (!productId && li.productId) {
        productId = li.productId;
      }
    }

    // Not paid yet → not a purchase to act on (the client should wait).
    if (state === 'SUBSCRIPTION_STATE_PENDING') {
      return { verified: false, error: `Subscription state: ${state}` };
    }

    // A genuine Play subscription whose access is over. Reported as verified
    // + expired so the caller can acknowledge it without granting anything
    // (restorePurchases() replays lapsed subscriptions).
    const lapsedState =
      state === 'SUBSCRIPTION_STATE_EXPIRED' ||
      state === 'SUBSCRIPTION_STATE_ON_HOLD' ||
      state === 'SUBSCRIPTION_STATE_PAUSED' ||
      state === 'SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED';
    const expiryPassed = latestMs === undefined || latestMs <= Date.now();
    // ACTIVE / IN_GRACE_PERIOD / CANCELED (auto-renew off) keep access only
    // until the line item's expiryTime.
    const expired = lapsedState || expiryPassed;

    logInfo(`Google Play subscription verified: state=${state} expired=${expired}`);
    return {
      verified: true,
      expired,
      expiresDateMs: latestMs,
      originalTransactionId: token,
      productId,
    };
  } catch (error: any) {
    const msg = error?.message || String(error);
    const isApiError =
      msg.includes('403') || msg.includes('401') || msg.includes('not enabled') ||
      msg.includes('PERMISSION_DENIED') || msg.includes('accessNotConfigured') ||
      msg.includes('has not been used');
    if (isApiError) {
      logError(
        'Google Play subscriptions API not configured — subscription accepted ' +
        'without server verification. Link the API in Play Console to enable it.',
        msg,
      );
      // H4: FAIL CLOSED — an unreachable/misconfigured store API must NOT grant
      // entitlement (was `verified: true`, which handed out free coins/tiers).
      return { verified: false, apiUnavailable: true };
    }
    // HTTP 410: Play no longer keeps this token (subscription expired long
    // ago). Nothing to grant; report expired so restore stops retrying it.
    const status = error?.code ?? error?.response?.status;
    if (status === 410 || msg.includes('410') || msg.includes('no longer available')) {
      logInfo('Google Play subscription token gone (410) — treating as expired');
      return { verified: true, expired: true, originalTransactionId: token };
    }
    logError('Google Play subscription verification error:', msg);
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
    let environment: 'PRODUCTION' | 'SANDBOX' = 'PRODUCTION';

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
      environment = 'SANDBOX';
      logInfo('Verified in SANDBOX environment');
    }
    // The signed payload carries its own environment; trust it over the
    // verifier that happened to accept it.
    if (typeof transaction?.environment === 'string') {
      environment = /sandbox|xcode/i.test(transaction.environment) ? 'SANDBOX' : 'PRODUCTION';
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

    // Refunded / revoked by Apple (revocationDate set) or a subscription
    // transaction whose period is over. Still a genuine transaction, so it is
    // reported verified — callers that grant time-bound entitlements
    // (memberships) must check `revoked` / `expired` and grant nothing.
    const revoked = transaction.revocationDate !== undefined && transaction.revocationDate !== null;
    const expiresDateMs =
      typeof transaction.expiresDate === 'number' ? transaction.expiresDate : undefined;
    const expired = expiresDateMs !== undefined && expiresDateMs <= Date.now();

    logInfo(
      `App Store purchase verified: productId=${transaction.productId}, transactionId=${transaction.transactionId}` +
      `${revoked ? ' (REVOKED)' : ''}${expired ? ' (EXPIRED)' : ''}`,
    );

    return {
      verified: true,
      revoked,
      expired,
      productId: String(transaction.productId),
      transactionId: String(transaction.transactionId),
      originalTransactionId: transaction.originalTransactionId
        ? String(transaction.originalTransactionId)
        : undefined,
      // For auto-renewable subscriptions StoreKit includes expiresDate (epoch ms).
      expiresDateMs,
      environment,
      appAccountToken: transaction.appAccountToken ? String(transaction.appAccountToken) : undefined,
    };
  } catch (error: any) {
    logError('App Store verification error:', error?.message || error);
    return { verified: false, error: error?.message || 'App Store verification failed' };
  }
}

// ========== SUBSCRIPTION NOTIFICATIONS SUPPORT ==========

export interface AppStoreNotificationInfo {
  notificationType: string;
  subtype?: string;
  productId?: string;
  originalTransactionId?: string;
  /** Subscription expiry from the signed transaction, epoch ms. */
  expiresDateMs?: number;
  /** The transaction's own id (for consumables == originalTransactionId). */
  transactionId?: string;
  /** 'Consumable' | 'Non-Consumable' | 'Auto-Renewable Subscription' | 'Non-Renewing Subscription'. */
  productType?: string;
  /** 'PRODUCTION' | 'SANDBOX' (from the signed notification data). */
  environment?: 'PRODUCTION' | 'SANDBOX';
  /** Set when Apple refunded / revoked the transaction, epoch ms. */
  revocationDateMs?: number;
  /** Apple revocationReason: 0 = other, 1 = app issue. */
  revocationReason?: number;
  /** Unique id of this notification (Apple retries reuse it). */
  notificationUUID?: string;
  /** CONSUMPTION_REQUEST only: why the customer asked for the refund. */
  consumptionRequestReason?: string;
}

/**
 * Verify + decode an App Store Server Notification V2 `signedPayload` and the
 * transaction it carries. Tries Production then Sandbox (TestFlight/sandbox).
 * Reuses the same Apple root certs / library as purchase verification.
 */
export async function decodeAppStoreNotification(
  signedPayload: string,
  appAppleId: number,
): Promise<AppStoreNotificationInfo> {
  const { SignedDataVerifier, Environment } = await import('@apple/app-store-server-library');
  const rootCerts = await getAppleRootCerts();

  const tryEnv = async (env: any): Promise<AppStoreNotificationInfo> => {
    const verifier = new SignedDataVerifier(rootCerts, true, env, BUNDLE_ID, appAppleId);
    const payload: any = await verifier.verifyAndDecodeNotification(signedPayload);
    let tx: any;
    const signedTx = payload?.data?.signedTransactionInfo;
    if (signedTx) {
      tx = await verifier.verifyAndDecodeTransaction(signedTx);
    }
    return {
      notificationType: String(payload?.notificationType ?? ''),
      subtype: payload?.subtype ? String(payload.subtype) : undefined,
      productId: tx?.productId ? String(tx.productId) : undefined,
      originalTransactionId: tx?.originalTransactionId
        ? String(tx.originalTransactionId)
        : undefined,
      expiresDateMs: typeof tx?.expiresDate === 'number' ? tx.expiresDate : undefined,
      transactionId: tx?.transactionId ? String(tx.transactionId) : undefined,
      productType: tx?.type ? String(tx.type) : undefined,
      environment: /sandbox|xcode/i.test(String(payload?.data?.environment ?? tx?.environment ?? ''))
        ? 'SANDBOX'
        : 'PRODUCTION',
      revocationDateMs: typeof tx?.revocationDate === 'number' ? tx.revocationDate : undefined,
      revocationReason: typeof tx?.revocationReason === 'number' ? tx.revocationReason : undefined,
      notificationUUID: payload?.notificationUUID ? String(payload.notificationUUID) : undefined,
      consumptionRequestReason: payload?.data?.consumptionRequestReason
        ? String(payload.data.consumptionRequestReason)
        : undefined,
    };
  };

  try {
    return await tryEnv(Environment.PRODUCTION);
  } catch {
    return await tryEnv(Environment.SANDBOX);
  }
}

/**
 * Look up the current expiry of a Google Play subscription by its purchase
 * token (used to extend entitlement on a renewal RTDN). Returns the latest
 * line-item expiry. Falls back gracefully if the API isn't configured.
 */
export async function getGooglePlaySubscriptionExpiry(
  token: string,
): Promise<{
  expiresDateMs?: number;
  productId?: string;
  /** Play orderId of the latest (current) period: GPA.x or GPA.x..N for renewals. */
  latestOrderId?: string;
  apiUnavailable?: boolean;
  error?: string;
}> {
  try {
    const publisher = await getAndroidPublisher();
    const res: any = await publisher.purchases.subscriptionsv2.get({
      packageName: PACKAGE_NAME,
      token,
    });
    const lineItems: any[] = res.data?.lineItems || [];
    let latestMs: number | undefined;
    let productId: string | undefined;
    for (const li of lineItems) {
      if (li.expiryTime) {
        const ms = new Date(li.expiryTime).getTime();
        if (!latestMs || ms > latestMs) {
          latestMs = ms;
          productId = li.productId || undefined;
        }
      }
    }
    return {
      expiresDateMs: latestMs,
      productId,
      latestOrderId: res.data?.latestOrderId ? String(res.data.latestOrderId) : undefined,
    };
  } catch (error: any) {
    const msg = error?.message || String(error);
    const isApiError =
      msg.includes('403') || msg.includes('401') || msg.includes('not enabled') ||
      msg.includes('PERMISSION_DENIED') || msg.includes('accessNotConfigured');
    if (isApiError) {
      logError('Google Play subscriptions API not configured for RTDN handling:', msg);
      return { apiUnavailable: true };
    }
    logError('Google Play subscription lookup error:', msg);
    return { error: msg };
  }
}

// ========== GOOGLE PLAY VOIDED PURCHASES (refund / chargeback backstop) ==========

export interface VoidedPurchase {
  purchaseToken: string;
  orderId?: string;
  voidedTimeMillis?: number;
  /** 0 = user, 1 = developer, 2 = Google. */
  voidedSource?: number;
  /** 0 other, 1 remorse, 2 not_received, 3 defective, 4 accidental, 5 fraud, 6 friendly_fraud, 7 chargeback. */
  voidedReason?: number;
  /** 1 = full refund, 2 = quantity-based partial refund. */
  refundType?: number;
}

/**
 * One page of the Android Publisher Voided Purchases API
 * (purchases.voidedpurchases.list), consumables AND subscriptions (type=1).
 * Play only keeps the last 30 days, so an older `startTimeMs` is clamped.
 * Quota: 6000 queries/day, 30 per 30 s; one daily run is far below it.
 */
export async function listGooglePlayVoidedPurchases(
  startTimeMs: number,
  pageToken?: string,
): Promise<{ items: VoidedPurchase[]; nextPageToken?: string; apiUnavailable?: boolean; error?: string }> {
  try {
    const publisher = await getAndroidPublisher();
    const minStart = Date.now() - 30 * 24 * 3600 * 1000 + 60 * 1000;
    const res: any = await publisher.purchases.voidedpurchases.list({
      packageName: PACKAGE_NAME,
      startTime: String(Math.max(startTimeMs, minStart)),
      maxResults: 1000,
      type: 1,
      ...(pageToken ? { token: pageToken } : {}),
    });
    const items: VoidedPurchase[] = (res.data?.voidedPurchases || [])
      .filter((v: any) => v?.purchaseToken)
      .map((v: any) => ({
        purchaseToken: String(v.purchaseToken),
        orderId: v.orderId ? String(v.orderId) : undefined,
        voidedTimeMillis: v.voidedTimeMillis ? Number(v.voidedTimeMillis) : undefined,
        voidedSource: typeof v.voidedSource === 'number' ? v.voidedSource : undefined,
        voidedReason: typeof v.voidedReason === 'number' ? v.voidedReason : undefined,
        refundType: typeof v.refundType === 'number' ? v.refundType : undefined,
      }));
    return { items, nextPageToken: res.data?.tokenPagination?.nextPageToken || undefined };
  } catch (error: any) {
    const msg = error?.message || String(error);
    const isApiError =
      msg.includes('403') || msg.includes('401') || msg.includes('not enabled') ||
      msg.includes('PERMISSION_DENIED') || msg.includes('accessNotConfigured');
    logError('Google Play voided purchases lookup error:', msg);
    return isApiError ? { items: [], apiUnavailable: true } : { items: [], error: msg };
  }
}
