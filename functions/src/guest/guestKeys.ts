/**
 * Keys of the guest flow, derived (HKDF) from the ticket signing key
 * (ticket_payments/keys.ts: TICKET_QR_SIGNING_KEY or the self-provisioned
 * server_secrets/ticket_payments key), so there is nothing new to configure:
 *   - identity: guest key of an e-mail (shared/guestIdentity.ts guestKeyFor)
 *   - signing:  form tokens, payment-return and "pay now" capabilities
 * Separate derivations, so one can never stand in for the other.
 */
import * as crypto from 'crypto';
import { ticketKey } from '../ticket_payments/keys';

function derive(master: string, info: string): string {
  return Buffer.from(crypto.hkdfSync('sha256', master, 'greengo-guest', info, 32)).toString('hex');
}

let identity: string | null = null;
let signing: string | null = null;

export async function guestIdentitySecret(): Promise<string> {
  return (identity ??= derive(await ticketKey(), 'guest-identity-v1'));
}

export async function guestSigningKey(): Promise<string> {
  return (signing ??= derive(await ticketKey(), 'guest-signing-v1'));
}

/** Test hook. */
export function resetGuestKeys(): void {
  identity = null;
  signing = null;
}
