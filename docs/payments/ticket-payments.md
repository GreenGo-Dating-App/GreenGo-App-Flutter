# Paid tickets for events and experiences

Branch `feat/ticket-payments` · 2026-10-08 · nothing deployed.

GreenGo sells tickets for paid events and paid experiences **without touching
the money**: every payment goes straight to the organizer, and GreenGo takes
**no fee** (no `application_fee_amount`, no `marketplace_fee`). The QR ticket
exists **only after the payment is confirmed**, in both modes.

| Mode | How the buyer pays | Who confirms | Seat hold |
|---|---|---|---|
| **Link** (default, zero setup) | One of the organizer's Profile > Payment methods (Pix key, PicPay, PayPal, Venmo, Cash App, Revolut, Wise, Monzo, Ko-fi) or cash / bank transfer, with a `GG-XXXXXX` reference code | The **organizer**, in "Payments to confirm" (one tap or batch). GreenGo does not verify these payments. | 24 h to pay, then 48 h for the organizer; reminders every 12 h |
| **Instant** (upgrade) | Stripe (cards, Apple Pay, Google Pay; Pix for BRL on Brazilian accounts) or Mercado Pago (Pix, cards, MP balance; no boleto/ATM), inside the app | The **provider webhook**, automatically | 30 min (+90 s margin, Stripe minimum) |

Stripe and Mercado Pago are **always** the connected mode. A pasted
`buy.stripe.com` or `mpago.la` link from the profile is never offered as a
manual method (listings that used one show "Connect Mercado Pago / Stripe").
Profile > Payment methods itself is unchanged (person-to-person use).

## Owner defaults (easy to change)

| Default | Where |
|---|---|
| Anyone who finishes Stripe / MP onboarding may sell instant tickets (the provider does KYC). Paid experiences still need the existing approved host ID document. | `ticket_payments/config.ts` `SELLER_GATE`; `experience_bookings/service.ts` |
| Instant hold 30 min; link hold 24 h; organizer confirmation window 48 h; reminder after 6 h then every 12 h | `config.ts` `HOLD_MINUTES`, `LINK_HOLD_HOURS`, `CONFIRM_WINDOW_HOURS`, `REMIND_*` |
| Max tickets per person 4 (listing `maxTicketsPerUser`; `null`/`0` = no limit; 1..100) | `config.ts` `DEFAULT_MAX_TICKETS_PER_USER`, app `kDefaultMaxTicketsPerUser` |
| "Instant recommended" from 30 places (or unlimited) | app `kLargeAudienceThreshold`, overridable with Firestore `app_config/ticket_payments.largeAudienceThreshold` |
| "Tired of confirming?" hint from 10 waiting payments | app `kPendingConfirmationsHint` |
| Refunds are done by the organizer in their Stripe / MP dashboard; the `charge.refunded` / `charge.dispute.created` / MP `refunded` / `charged_back` / `in_mediation` webhooks mark the order and **every ticket** refunded/disputed, free the seats and the per-person allowance, and the door refuses the QR | `webhooks.ts`, `orders.ts markOrderReversed` |
| Late payment after the hold expired: accepted, tickets issued, order flagged `lateOverCapacity` if the event was full (organizer refunds if needed) | `orders.ts markOrderPaid` |

## Architecture

```
Buyer app ── createTicketCheckout ──► transaction: price/currency/title from the listing doc,
                                         capacity + per-type stock + per-person limit,
                                         seat/allowance holds, ticket_orders/{id}
           ├─ instant: Stripe Checkout Session (direct charge, stripeAccount=organizer)
           │           or MP preference (organizer token) ──► in-app browser / same tab (web)
           │           ◄── stripeConnectWebhook / mercadoPagoWebhook (signed, MP re-fetched)
           └─ link:    GG- code + method snapshot ──► "I've paid" (+ receipt) ──► organizer
                       confirmTicketPayment / rejectTicketPayment
                                     │
                                     ▼
              markOrderPaid (transaction, idempotent): tickets/{orderId}_{n} with signed
              QR greengo:tk:{ticketId}:{hmac}, attendee 'going' / booking payment 'paid',
              push "Your ticket is ready"
Door ── checkInTicket / checkInEventAttendee ──► HMAC + tickets/{id}.status == 'valid',
                                                  single use per ticket, scanner rights, time window
```

Checkout payloads are built server-side only (`checkoutPayload.ts`): line
items per ticket type (name, perks + date/time in the host's zone + place,
cover image, minor-unit amount, quantity), buyer e-mail, locale,
`client_reference_id` / `external_reference` = order id, metadata, statement
descriptor (ASCII, 22 chars), expiry = hold end. Organizers never create
products or prices in their dashboards; listing edits apply to the next
checkout; existing orders/tickets keep their stored price.

### Currency rules

* Prices are stored and charged as integer **minor units** + ISO code
  (zero-decimal aware: JPY, KRW, CLP…). Events keep `price` (major) +
  `currency` symbol and gain `currencyCode`.
* Mercado Pago charges only in the connected account's **site currency**
  (`MLB→BRL, MLA→ARS, MLM→MXN, MLC→CLP, MCO→COP, MPE→PEN, MLU→UYU`, read from
  `/users/me` on connect). The editor blocks MP for other currencies; the
  server re-checks (`currency_not_supported`).
* Minimums: Stripe per-currency table (0.50 USD/EUR/BRL, 0.30 GBP, 50 JPY…),
  MP 1.00 local (`amount_below_minimum`). Link mode: any currency, no minimum.

### Experiences

* The guest books a date (request to book, host accepts) as before; the
  booking now carries `payment.mode 'online'` + provider. After the host
  accepts, the guest taps **Pay now** (same order flow). Seats are held by the
  booking.
* `pricingMode`: `per_person` (default; one ticket per person) or `per_group`
  (`groupPrice` in minor units for a party of `minGroupSize..maxGroupSize`,
  one group ticket with `partySize`; the slot counts groups).
* Date-based price: `dayOverrides[date].priceOverride` > `weekendPrice` on
  `weekendDays` (default Sat+Sun) > base, resolved in the host's time zone at
  booking time and stored on the booking/order/ticket (`priceRule`).
* Recurring availability ("Manage times"): `availabilityRules` (window,
  duration, break, start-every, weekdays, date range, places per time, time
  zone) + `availabilityOverrides` (per-day closed / hours / explicit times /
  special price, removed and added single times), computed on the fly —
  nothing is pre-materialised. Buyers book with `createBooking({slotId:
  'recurring', startAt})`; seats live in `experience_slot_counters`
  (created lazily, per_group counts groups). `getExperienceAvailability`
  returns <= 62 days with seats left and the price of each date.
  Legacy dated slots keep working for listings without a schedule.
* Host removes / closes booked times: the save first answers
  `needsConfirm` with the count; after confirmation every booking at those
  times is cancelled by the host (100 % refund owed, no host penalty), the
  guest gets a push, and the money goes back: instant mode through the
  provider API ON THE ORGANIZER'S ACCOUNT (Stripe `refunds.create` with
  `stripeAccount`, MP `POST /v1/payments/{id}/refunds` with the organizer
  token; idempotency key `gg_refund_{orderId}`), recorded as
  `ticket_orders.refund {status: requested | refund_required | refund_owed}`;
  manual mode -> `refund_owed` + an organizer reminder. The provider refund
  webhook then invalidates the tickets as for any refund.

### Events

* `ticketProvider` = `link | stripe | mercadopago`, `ticketLinkMethod`,
  `ticketPaymentInstructions`, `currencyCode`, `maxTicketsPerUser`.
* Optional ticket types `events/{id}/ticket_types/{typeId}` (name, perks,
  price in minor units, stock, sales window, per-person limit, hidden,
  active, sortOrder; `sold`/`held` server-only). Without types the event price
  is the single "general" ticket. Free types are issued without payment.
* Paid events count **seats** in `attendeeCount` (server-maintained). One
  attendee doc per buyer (`ticketCount`, `guestCount = ticketCount-1`,
  `ticketId`), one QR per seat.

## Data model (all writes server-only unless noted)

| Collection | Who reads | Notes |
|---|---|---|
| `payment_accounts/{uid}` | owner | `stripe {accountId, chargesEnabled, detailsSubmitted, country, status}`, `mercadoPago {userId, siteId, currency, liveMode, status}` |
| `payment_accounts_private/{uid}` | nobody | MP access/refresh tokens sealed with AES-256-GCM (key: `TICKET_TOKEN_ENCRYPTION_KEY`, else HKDF of the ticket key) |
| `ticket_orders/{orderId}` | buyer, organizer | status `creating·pending·pending_payment·awaiting_confirmation·paid·expired·cancelled·failed·rejected·refunded·disputed`, amounts, items, code, payment snapshot, receiptPath, ticketIds |
| `tickets/{orderId}_{n}` | buyer only | signed `qrPayload`, status `valid·refunded·disputed`, type, partySize, checkedInAt |
| `ticket_holdings/{kind}_{listingId}_{uid}` | that buyer | `{held, owned, types{}}` per-person limit counter |
| `ticket_inventory/event_{id}`, `ticket_codes/{code}`, `payment_events/{key}`, `experience_slot_counters/{id}` | nobody | holds, code uniqueness, webhook idempotency, slot counters |
| `events/{id}/ticket_types/{typeId}` | signed-in | organizer/co-owners write everything except `sold`/`held` |
| Storage `ticket_receipts/{orderId}/…` | buyer, organizer, staff | buyer uploads one image ≤ 5 MB while the order is open; moderated as a private image |

## Rules / indexes changed

* `firestore.rules`: paid events — no self `going`/`waitlist`, no waitlist
  promotion, no client `attendeeCount`/`tierGoingCounts`, ticket fields
  server-only, party size frozen; `validTicketing`; `ticket_types`;
  `payment_accounts*`, `ticket_orders`, `tickets`, `ticket_holdings`;
  experiences accept `paymentMethods ['online']` + `paymentProvider` /
  `paymentLinkMethod` / `paymentInstructions` / `pricingMode` / `groupPrice` /
  `maxTicketsPerUser`; `availabilityRules/Overrides` server-owned;
  `booking_consents.method` may be `online`. Free events unchanged.
* `firestore.rules` (cont.): `ticket_holdings` readable by its buyer;
  `weekendPrice` / `weekendDays` on experiences.
* `storage.rules`: `ticket_receipts/{orderId}/{file}`.
* `firestore.indexes.json`: `bookings` (experienceId, slotStart),
  `ticket_orders` (buyerId, listingId, status),
  (status, expiresAt), (status, remindAt), (organizerId, status, sentAt),
  (buyerId, createdAt desc); `tickets` (buyerId, issuedAt desc);
  `experience_slot_counters` (experienceId, startMs).

## Deploy list (BY NAME, after the app update)

```
firebase deploy --only firestore:indexes            # wait until built
firebase deploy --only \
functions:getTicketPaymentsConfig,functions:startStripeOnboarding,functions:startMercadoPagoOnboarding,\
functions:refreshPaymentAccount,functions:createTicketCheckout,functions:syncTicketOrder,functions:cancelTicketOrder,\
functions:markTicketPaymentSent,functions:confirmTicketPayment,functions:rejectTicketPayment,\
functions:stripeConnectWebhook,functions:mercadoPagoWebhook,functions:mpOAuthCallback,functions:ticketCheckoutReturn,\
functions:expireTicketOrders,functions:remindTicketConfirmations,functions:refreshMercadoPagoTokens,\
functions:checkInTicket,functions:getEventTicketCode,functions:checkInEventAttendee,\
functions:getExperienceAvailability,functions:updateExperienceAvailability,\
functions:createBooking,functions:respondToBookingRequest,functions:cancelBooking,functions:cancelExperienceSlot,\
functions:getBookingCheckInCode,functions:checkInBooking,functions:markBookingNoShow,functions:markBookingPaid,\
functions:confirmCashReceived,functions:openBookingDispute,functions:resolveBookingDispute,functions:getSlotAvailability,\
functions:createUserExperience,functions:publishUserExperience,functions:spendCoins,functions:moderateUploadedImage
firebase deploy --only firestore:rules,storage      # after the new app is out (rules close the bypasses)
```

Deploy with `FUNCTIONS_DISCOVERY_TIMEOUT=180` as usual; everything runs at
512MiB. `STRIPE_SECRET_KEY` is bound as the existing Secret Manager secret.

**Compatibility.** Old app versions cannot buy paid tickets (they still try
coins, now refused with `event_paid_with_tickets`); free events are unchanged.
Legacy coin-priced events (price > 0, no provider) are not on sale until the
organizer picks a sale mode; their existing attendees keep their signed
`greengo:ev:` codes, but unsigned legacy JSON tickets are refused on every
paid event. Link-mode experience bookings now show the QR only after the
host's "received". Existing cash bookings keep the pay-at-the-door QR; new
listings cannot pick cash at the door.

## Webhook / redirect URLs to register

| What | URL |
|---|---|
| Stripe **Connect** webhook | `https://us-central1-greengo-chat.cloudfunctions.net/stripeConnectWebhook` |
| Mercado Pago webhook | `https://us-central1-greengo-chat.cloudfunctions.net/mercadoPagoWebhook` (also sent per preference as `notification_url`) |
| Mercado Pago OAuth redirect URI | `https://us-central1-greengo-chat.cloudfunctions.net/mpOAuthCallback` |
| Checkout / onboarding return page | `https://us-central1-greengo-chat.cloudfunctions.net/ticketCheckoutReturn` (web → `greengo-chat.web.app/?link=/t/{orderId}`; app → `greengo://t/{orderId}`) |

## Owner setup

### Stripe (dashboard, platform account)
1. **Connect → Get started**: platform/marketplace, **Standard accounts**,
   fill the platform profile (name GreenGo, website, support e-mail, logo,
   brand color), set "Onboarding: Account Links".
2. **Developers → Webhooks → Add endpoint**: URL above, **"Listen to events on
   Connected accounts"**, events `checkout.session.completed`,
   `checkout.session.async_payment_succeeded`,
   `checkout.session.async_payment_failed`, `checkout.session.expired`,
   `charge.refunded`, `charge.dispute.created`, `account.updated`. This is a
   **new** endpoint: do NOT reuse the coin `stripeWebhook` endpoint (and fix
   its known duplicate separately).
3. Copy the signing secret into `STRIPE_CONNECT_WEBHOOK_SECRET`.
4. Pix on Stripe works only for Brazilian connected accounts that activated
   Pix; otherwise checkout falls back to cards + wallets automatically.

### Mercado Pago (developers portal)
1. **Your integrations → Create application**: product "Checkout Pro",
   model **Marketplace**, enable **OAuth**; add the redirect URI above.
2. **Webhooks**: production URL above, event **Payments**; copy the
   **secret signature** into `MP_WEBHOOK_SECRET`.
3. Copy **Client ID / Client secret** into `MP_CLIENT_ID` / `MP_CLIENT_SECRET`.
4. Test with MP **test users** (one seller, one buyer); set
   `MP_USE_SANDBOX=true` while testing (uses `sandbox_init_point`).
5. MP may require approval of the marketplace app before production OAuth.

### `functions/.env` keys (never commit)

```
STRIPE_CONNECT_WEBHOOK_SECRET=whsec_...          # Stripe Connect endpoint
MP_CLIENT_ID=...
MP_CLIENT_SECRET=...
MP_WEBHOOK_SECRET=...
TICKET_QR_SIGNING_KEY=<64 random hex>            # optional; else auto-generated in server_secrets/ticket_payments
TICKET_TOKEN_ENCRYPTION_KEY=<64 random hex>      # optional; seals MP tokens
# optional: MP_REDIRECT_URI, MP_WEBHOOK_URL, TICKET_RETURN_BASE_URL, MP_USE_SANDBOX
```
`STRIPE_SECRET_KEY` stays in Secret Manager (already set for web coins).
With nothing configured, link mode works; instant options show "Not available yet".

## Store policy

In-person event and experience tickets are **exempt from IAP**: Apple App Store
Review Guideline 3.1.3(e) (goods/services consumed outside the app must use
other payment methods) and Google Play's Payments policy (physical services,
event tickets). **Online/virtual events are NOT exempt** (3.1.3(d) real-time
digital services need IAP): keep paid listings in-person only; there is no
"online" flag yet. Stripe for tickets is a separate code path from the
web-only coin/membership Stripe code. Coin-priced event joins are retired.

## App

* Profile > Edit profile > **Account settings**: "Payment methods" (unchanged
  person-to-person links) and **"Get paid"** (connect Stripe / Mercado Pago,
  Payments to confirm). The old entries in the profile section were removed.
* Create / edit **wizards** for events (Basics / When & where / Tickets /
  Payment / Review) and experiences (Basics / Location / Format & price /
  Availability / Payment / Review): validation-gated Next, payment step
  skipped for free listings, local draft + resume, edit overview with "Edit"
  per section, review checklist; phone = one step per screen, web/wide =
  side stepper.
* Experiences: **Manage times** (from "Dates & availability"), buyer calendar
  with only bookable days, weekend price + weekend days in the editor,
  special price per day in the day editor.
* Ticket types: drag-to-reorder, sales summary (sold / reserved / left /
  revenue per type).

## Tests (last run 2026-10-08)

| Suite | Result |
|---|---|
| Security emulator (`jest.security.config.js`) | 323 / 323 pass (baseline 285; 38 in `ticket-payments.emulator.test.ts`) |
| Functions unit | 530 pass, 100 fail = the same pre-existing failures as `main` (11 legacy suites) |
| Flutter `flutter test` | 1615 pass (baseline 1586) |
| `flutter analyze` | 163 issues, 0 errors (baseline 163) |

New coverage: server price / payload from the listing, Stripe + MP
payloads, capacity + holds + expiry, webhook signatures, idempotent paid,
QR only after paid, refunds / disputes, MP re-fetch + currency + minimums,
link mode end to end, receipt storage access, paid-event rules, free events
unchanged, per-person limits incl. concurrency, single-use QR per ticket,
ticket types, per-group pricing, recurring availability (generation, DST,
overrides precedence, bookings against generated times, last-seat race,
host removal -> cancel + Stripe / MP refund / refund_owed), date-based
prices, the Manage times / recurring picker / wizard widgets.

## Not done yet

* Provider-side refunds started by the organizer from inside GreenGo for
  other reasons than removed times (the owner chose dashboard refunds).
* A grace window before start for the experience door is the existing
  check-in window (3 h early); it is not separately configurable per listing.
