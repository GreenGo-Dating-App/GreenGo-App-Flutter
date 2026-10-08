/**
 * Ticket payments (paid events + paid experiences) — configuration.
 *
 * Money goes STRAIGHT to the organizer's own Stripe (Connect Standard, direct
 * charge) or Mercado Pago (OAuth marketplace) account. GreenGo takes NO fee:
 * no application_fee_amount, no marketplace_fee.
 *
 * Every value comes from the environment (functions/.env, gitignored, or a
 * Secret Manager secret bound to the function). Nothing is required at deploy
 * time: a missing value makes the matching callable answer
 * `failed-precondition` / `payments_not_configured`, and the app hides the
 * paid option. Values (see docs/payments/ticket-payments.md):
 *
 *   STRIPE_SECRET_KEY               platform key (already a Secret Manager secret
 *                                   used by the web repo's coin checkout)
 *   STRIPE_CONNECT_WEBHOOK_SECRET   whsec_ of the NEW Connect endpoint
 *                                   (comma-separated for rotation)
 *   MP_CLIENT_ID / MP_CLIENT_SECRET Mercado Pago marketplace application
 *   MP_WEBHOOK_SECRET               MP "assinatura secreta" for webhooks
 *   MP_REDIRECT_URI                 optional; defaults to the mpOAuthCallback URL
 *   TICKET_QR_SIGNING_KEY           optional, >= 32 chars; signs ticket QR tokens,
 *                                   the MP OAuth state and (HKDF) seals MP tokens.
 *                                   Absent -> generated once in server_secrets/ticket_payments
 *   TICKET_TOKEN_ENCRYPTION_KEY     optional dedicated key for MP tokens
 *   TICKET_RETURN_BASE_URL          optional; defaults to the
 *                                   ticketCheckoutReturn function URL
 *
 * Owner defaults (easy to change here):
 */

/** Seat hold while a checkout is pending (Stripe Checkout needs >= 30 min). */
export const HOLD_MINUTES = 30;
/** Stripe refuses expires_at < 30 min after creation: keep a safety margin. */
export const STRIPE_EXPIRY_MARGIN_SECONDS = 90;
/** Any user who completes Stripe / MP onboarding may sell (the provider does KYC). */
export const SELLER_GATE: 'provider_onboarding' = 'provider_onboarding';
/** Max tickets per order (events also cap at 1 + guestsAllowedPerAttendee). */
export const MAX_QUANTITY = 100;
/** Per-user ticket limit when a listing does not set maxTicketsPerUser (null/0 there = no limit). */
export const DEFAULT_MAX_TICKETS_PER_USER = 4;
/** Refresh MP tokens this long before they expire. */
export const MP_REFRESH_BEFORE_MS = 10 * 24 * 60 * 60 * 1000;

/**
 * Mode B "instant": connected Stripe / Mercado Pago (webhook confirms).
 * Mode A "link" (default, zero setup): one of the organizer's own payment
 * methods; the buyer says "I've paid" and the ORGANIZER confirms. GreenGo does
 * not verify link payments.
 */
export const PROVIDERS = ['stripe', 'mercadopago'] as const;
export type Provider = typeof PROVIDERS[number];
export function isProvider(v: unknown): v is Provider {
  return typeof v === 'string' && (PROVIDERS as readonly string[]).includes(v);
}
export type TicketProvider = Provider | 'link';
export function isTicketProvider(v: unknown): v is TicketProvider {
  return v === 'link' || isProvider(v);
}

/** Link mode: seat held this long for payment + "I've paid". */
export const LINK_HOLD_HOURS = 24;
/** Link mode: after "I've paid", the organizer has this long to confirm, then the seat is released. */
export const CONFIRM_WINDOW_HOURS = 48;
/** Link mode: first organizer reminder after this long, then every REMIND_EVERY_HOURS. */
export const REMIND_AFTER_HOURS = 6;
export const REMIND_EVERY_HOURS = 12;
/** Receipt image cap (also in storage.rules). */
export const RECEIPT_MAX_MB = 5;

/**
 * Link-mode methods. The first 9 are Profile > Payment methods keys
 * (profiles/{uid}.paymentLinks); 'cash' and 'bankTransfer' are listing-only
 * (instructions in ticketPaymentInstructions) and ALSO need the organizer's
 * confirmation before any QR exists (no pay-at-the-door QR).
 */
// Pasted Stripe / Mercado Pago links are NOT manual options: those two
// providers are always the connected (instant) mode.
export const PROFILE_LINK_METHODS = ['pix', 'picPay', 'paypal', 'venmo', 'cashApp',
  'revolut', 'wise', 'monzo', 'kofi'] as const;
export const LISTING_ONLY_METHODS = ['cash', 'bankTransfer'] as const;
export function isLinkMethod(v: unknown): v is string {
  return typeof v === 'string'
    && ((PROFILE_LINK_METHODS as readonly string[]).includes(v) || (LISTING_ONLY_METHODS as readonly string[]).includes(v));
}

export const COL = {
  accounts: 'payment_accounts',
  accountsPrivate: 'payment_accounts_private',
  orders: 'ticket_orders',
  tickets: 'tickets',
  inventory: 'ticket_inventory',
  codes: 'ticket_codes',
  holdings: 'ticket_holdings',
  events: 'payment_events',
} as const;

const env = (k: string): string => (process.env[k] || '').trim();

export function projectId(): string {
  return env('GCLOUD_PROJECT') || env('GCP_PROJECT') || 'greengo-chat';
}

export function functionsBaseUrl(): string {
  return `https://us-central1-${projectId()}.cloudfunctions.net`;
}

export function stripeSecretKey(): string { return env('STRIPE_SECRET_KEY'); }
export function stripeConnectWebhookSecrets(): string[] {
  return env('STRIPE_CONNECT_WEBHOOK_SECRET').split(',').map((s) => s.trim()).filter(Boolean);
}
export function mpClientId(): string { return env('MP_CLIENT_ID'); }
export function mpClientSecret(): string { return env('MP_CLIENT_SECRET'); }
export function mpWebhookSecret(): string { return env('MP_WEBHOOK_SECRET'); }
export function mpRedirectUri(): string {
  return env('MP_REDIRECT_URI') || `${functionsBaseUrl()}/mpOAuthCallback`;
}
export function mpUseSandbox(): boolean { return env('MP_USE_SANDBOX') === 'true'; }
export function qrSigningKey(): string { return env('TICKET_QR_SIGNING_KEY'); }
export function tokenEncryptionKey(): string { return env('TICKET_TOKEN_ENCRYPTION_KEY'); }
export function returnBaseUrl(): string {
  return env('TICKET_RETURN_BASE_URL') || `${functionsBaseUrl()}/ticketCheckoutReturn`;
}
export function mpWebhookUrl(): string {
  return env('MP_WEBHOOK_URL') || `${functionsBaseUrl()}/mercadoPagoWebhook`;
}

/** Instant mode needs the provider keys; the QR key self-provisions (see keys.ts). */
export function stripeConfigured(): boolean {
  return /^(sk|rk)_/.test(stripeSecretKey());
}
export function stripeWebhookConfigured(): boolean { return stripeConnectWebhookSecrets().length > 0; }
export function mercadoPagoConfigured(): boolean {
  return mpClientId().length > 0 && mpClientSecret().length > 0;
}
export function providerConfigured(p: Provider): boolean {
  return p === 'stripe' ? stripeConfigured() : mercadoPagoConfigured();
}
