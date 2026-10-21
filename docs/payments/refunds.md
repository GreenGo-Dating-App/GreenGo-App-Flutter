# Seller-cancelled refunds, manual refund proofs, deletion blockers

Branch `fix/refunds-deletion-gaps` · 2026-10-21 · owner approved · nothing deployed.

## 1. What triggers an automatic refund

| Seller action | Refund | Reason stored |
|---|---|---|
| Organiser sets a paid event to `cancelled` (app "Cancel event", business "Cancel", series cancel, any client write) | every PAID order of the event, in full | `event_cancelled` |
| A paid event is hard-deleted anyway (console / admin / old app before the rules) | same (backstop) | `event_deleted` |
| Host cancels a booking (`cancelBooking` by the host) | that booking's order, in full | `host_cancelled` |
| Host cancels a whole slot (`cancelExperienceSlot`) | every paid booking on it | `slot_cancelled` |
| Host removes / closes booked times (`updateExperienceAvailability` confirm) | every paid booking at those times | `host_removed_time` |
| Host deletes an experience with future bookings | every paid future booking | `experience_deleted` |
| A payment lands after the listing was cancelled | that order | `late_payment_cancelled_listing` |

Guest-initiated booking cancellations are unchanged: `refundDue` from the
cancellation policy, paid by the host (Terms 12.5 c). An event that already
ended (endDate passed, or `completed`) never triggers refunds when it is
cancelled or deleted later.

## 2. Money flow (Terms 11.6 f / 12.2 / 12.5 c)

* Stripe (direct charge on the seller's connected account): `refunds.create`
  ON THE CONNECTED ACCOUNT (`stripeAccount`), no `amount` (= the whole
  charge), `refund_application_fee: true`, idempotency key
  `gg_refund_{orderId}`. The buyer gets 100 % of what they paid; the refund
  is debited from the seller's Stripe balance; GreenGo's application fee goes
  back to the seller. Stripe keeps its own processing fee (Stripe's terms).
* Mercado Pago: `POST /v1/payments/{id}/refunds` with the SELLER's OAuth
  token, `X-Idempotency-Key: gg_refund_{orderId}`; a full refund returns the
  marketplace fee with the payment.
* Legacy `link` orders (paid outside GreenGo): `refund_owed`, the seller must
  pay back; buyer and seller are told.
* Open (unpaid) orders of the listing: closed `cancelled`, holds released,
  Stripe session expired. Nothing to refund.
* GreenGo never refunds from its own funds.

## 3. Engine (functions/src/ticket_payments/refunds.ts)

Outbox `ticket_refunds/{orderId}` (server-only, default deny in both rule
files): ONE doc per order, created with `create()` = never a second refund,
whatever re-triggers. Status:

```
pending -> processing -> refunded | refund_owed | not_needed
                       -> retry (backoff 2 min x4 ... max 6 h) -> ...
                       -> refund_failed  (permanent error, or 6 attempts)
refund_failed -> manual_refund_pending_review -> refunded_manually | refund_failed
```

The order mirrors it in `ticket_orders.refund { status, reason, at,
providerRefundId?, error? }` (`requested` = provider accepted). On success the
order goes to `refunded` at once through `markOrderReversed` (every ticket
invalid at the door, seats / price-phase counters / per-person allowance /
attendee released, `paidOrderCount` decremented); the provider's refund
webhook later is a no-op.

Permanent errors (no blind retries): Stripe `account_invalid`,
`balance_insufficient`, `insufficient_funds`, disputes, permission /
authentication / invalid-request errors, missing payment reference; MP 4xx
(except 429), `mp_not_connected`. `charge_already_refunded` = refunded.

`refund_failed`: `admin_alerts/ticket_refund_failed_{orderId}` (type
`ticket_refund_failed`, ids only), buyer push + e-mail ("GreenGo support will
contact you", guests by e-mail), seller push ("refund manually and upload the
proof").

Notifications: buyer push `ticket_refund_started` + e-mail (members; guests
get the existing "refunded" guest e-mail from the order trigger); organiser
ONE summary push per cancelled event (`ticket_refund_batches/event_{id}`) when
every row is done.

Events: `events.paidOrderCount` (server-only) = paid orders not refunded;
`events.ticketRefundsAt` (server-only) = refunds started -> the event stays
`cancelled`. Rules: organiser delete only when `paidOrderCount == 0`; the app
turns Delete into Cancel event when > 0 (`EventsRemoteDataSource.deleteEvent`
re-checks the server value before deleting anything).
`functions/scripts/backfill-paid-order-count.ts` sets the counter for events
that sold before the deploy (dry run by default).

## 4. Manual refund proof (seller) and admin review

1. The seller refunds the buyer from their own Stripe / MP dashboard.
2. App (Delete account sheet, "Upload refund proof", or any future screen):
   upload to Storage `refund_proofs/{orderId}/{timestamp}.{ext}`.
   storage.rules: create only by the order's organiser, only while
   `ticket_orders/{orderId}.refund.status == 'refund_failed'`, image
   (jpeg/png/webp/heic) or PDF, <= 10 MB, each object written once, never
   client-deleted; read by that seller and staff (`isStaff()`).
3. Callable `submitManualRefundProof({ orderId, proofPath, note? })` (seller):
   `refund_failed -> manual_refund_pending_review`, `proof { path, note,
   uploadedBy, uploadedAt }`; the admin alert gets `status:
   'proof_submitted', proofPath`.

### Admin contract (for the admin panel session)

* Queue: `admin_alerts` where `type == 'ticket_refund_failed'` (`status`
  `open` -> `proof_submitted` -> `resolved` | back to `open`). Fields:
  orderId, kind, listingId, bookingId, organizerId, buyerId, isGuest,
  provider, amount (minor units), currency, reason, error, attempts,
  proofPath, proofSubmittedAt, reviewedBy, reviewedAt.
* Detail: `ticket_refunds/{orderId}` (admin SDK / callable only) and
  `ticket_orders/{orderId}`; the proof file via Storage (staff can read).
* Decision: callable **`adminReviewManualRefund`** `{ orderId: string,
  approve: boolean, reason?: string }` (reason REQUIRED to reject, <= 500
  chars). superAdmin only (`requireAdmin(SUPER_ADMIN_ONLY)`, fresh admin 2FA
  when `app_config/security_flags.requireAdmin2fa` is on). Returns `{ orderId,
  status: 'refunded_manually' | 'refund_failed' }`. Errors (`details.code`):
  `invalid_order_id`, `invalid_decision`, `reason_required`,
  `refund_not_found`, `not_pending_review`.
  * approve -> `refunded_manually`: the order becomes `refunded` (tickets
    invalid, counters released), seller push `ticket_manual_refund_approved`,
    buyer push (members), alert `resolved`.
  * reject -> back to `refund_failed` with `review.reason`, seller push
    `ticket_manual_refund_rejected` with the reason; the seller can upload a
    new proof.

## 5. Account deletion blockers

`functions/src/auth/deletionBlockers.ts`. Deletion is refused (code
`deletion_blocked_paid_orders`, `blockers` list) while the user, as SELLER,
has:
* paid orders (`ticket_orders` organizerId ==, status == 'paid', startsAt >=
  now - 2 days) of an event that has not ended / an experience booking that is
  not completed and not over, or
* any refund row that is not settled (`pending`, `processing`, `retry`,
  `refund_failed`, `manual_refund_pending_review`), whatever the date.

Entry points: `deleteMyAccount` (HttpsError `failed-precondition`,
`details.code`), `requestAccountDeletion` signed-in mode (409 JSON),
`confirmAccountDeletion` GET (409 page listing the items instead of the
button) and POST (409, the link is given back), all through
`deleteAccountCompletely`. The e-mail request step only sends the link (it
must not reveal anything about the account). The Auth onDelete trigger cannot
refuse (Auth is already gone: console / admin / old apps).

App: Delete account first calls **`getDeletionBlockers`** `{}` ->
`{ blocked, code, blockers: [{ kind, listingId, title, startsAt, paidOrders,
refundsInProgress, failedRefunds, pendingReview, bookingIds, actionOrders:
[{ orderId, status }] }] }` and shows the sheet (Cancel & refund / Upload
refund proof); the password step opens only when the list is empty.

Indexes (firestore.indexes.json): `ticket_orders (organizerId, status,
startsAt)`, `ticket_refunds (organizerId, status)`.
