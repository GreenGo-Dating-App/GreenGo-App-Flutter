# Event Ticketing & Payments — Strategy & Compliance Plan

**Status:** 🟢 To actualize — decision pending (entity route)
**Last updated:** 2026-07-13
**Owner:** Renato (GreenGo)

> **Goal (stated by owner):** Sell tickets to **private, in‑person events** inside GreenGo. Charge a
> **platform fee of USD 2.99 per ticket** (USD‑pegged), never below a **USD 2.00 floor**, and be **taxed
> only on that fee** — never on the ticket price that flows through to the event organizer.
> App is used **worldwide**; **organizers are mostly in the USA**; owner is a **Brazilian resident**.

---

## 0. TL;DR — the one thing that decides everything

The whole "taxed only on my \$2.99" outcome depends on **not being the merchant of record** on the
ticket. The organizer must be the seller; GreenGo is only a **platform that takes a fee**. That is a
standard marketplace pattern (Eventbrite, Airbnb) and is implemented with **Stripe Connect
destination charges + `application_fee_amount`**.

**But three of the owner's constraints form an over‑constrained triangle:**

```
      "Company is in Brazil (or I'm a private individual)"
                     ▲
                     │   ← pick at most two cleanly
                     │
"Organizers in the USA" ───────── "Taxed only on my $2.99 fee"
```

- A **Brazilian PSP** (Stripe BR / Pagar.me / Iugu / Asaas) is **domestic** — it **cannot pay out US
  organizers**. So a lone Brazilian entity **cannot** run the auto‑split model for US sellers.
- A **pessoa física (private individual)** **cannot** be a payment platform at all (PSPs require a
  business; income taxed up to **27.5%** IRPF; can't cleanly issue NFS‑e).

**Resolution:** the payment platform seat must be a **US LLC** (Stripe Atlas, ~US\$500). The owner can
personally stay a private individual *who owns* that LLC, and/or keep a **Brazilian company as the
group parent**. See the route matrix in §3.

---

## 1. The fee model

| Parameter | Value | Notes |
|---|---|---|
| `PLATFORM_FEE_USD` | **2.99** | `application_fee_amount`, USD‑pegged. Charged **on top** of the organizer's base price ("buyer pays fee"). |
| `FLOOR_USD` | **2.00** | Never charge below this. Flat \$2.99 always satisfies it. |
| Currency | Charge in **buyer's local currency** (Stripe presentment) but **peg the fee to USD 2.99** so margin is FX‑stable. |
| Who pays Stripe's processing fee | **The organizer** (connected account) | See lever below. |

### The margin lever (important)
The owner assumed `2.99 − 0.85 Stripe = 2.12` margin. **That is only true if GreenGo pays Stripe's fee.**
In a marketplace split you choose who bears it:

| Who bears Stripe's processing fee | GreenGo net margin | Tax/position |
|---|---|---|
| **Organizer** (the merchant of record) | **full \$2.99** | ✅ strongest — reinforces "organizer is the seller" |
| GreenGo (platform) | ~\$2.12 | weaker; you also eat FX variance |

**Decision:** organizer bears processing (normal — the seller pays the acquirer). GreenGo nets a clean
**\$2.99**, and the \$2.00 floor is always satisfied.

### Formula
```
platformFee = clamp(PLATFORM_FEE_USD, FLOOR_USD, CAP)   // = 2.99, floor 2.00
buyerTotal  = organizerBasePrice + platformFee
// application_fee_amount = platformFee (299 cents)
// processing deducted from the ORGANIZER's portion → GreenGo receives 299 whole
```
Keep `PLATFORM_FEE_USD` / `FLOOR_USD` in **Firebase Remote Config** so they're tunable without a release.

---

## 2. Payment architecture (identical across all viable routes)

- **Organizers onboard as Stripe Connect Express connected accounts** (US KYC, US bank, tax ID). **This
  makes them the merchant of record** — the legal key to fee‑only taxation.
- **Checkout = a single destination charge:**
  - `amount = basePrice + 299`
  - `application_fee_amount = 299`
  - `transfer_data.destination = <organizer_acct>` (or `on_behalf_of`)
  - processing borne by the connected account.
- **Never** use "separate charges & transfers" — the full amount would touch GreenGo's balance first and
  weaken the intermediary position.
- **GreenGo recognized revenue = Σ application fees.** That, and only that, is taxable to the platform.
- **Ticket/QR issued only** on the `checkout.session.completed` / `payment_intent.succeeded` webhook.

### App‑store exemption (a real win)
Tickets to **in‑person / physical events are exempt** from Apple IAP (§3.1.3(e)/3.1.5) and Google Play
Billing. → Use **Stripe directly on web, iOS, and Android**; **no 15–30% store cut**. Listings must
clearly describe **physical, in‑person** events.

---

## 3. Entity route matrix — pick one

| # | Route | Company in BR? | US organizers? | Fee‑only tax? | Cost / effort | Verdict |
|---|---|---|---|---|---|---|
| **A** | **BR parent + US payment subsidiary** (US LLC owned by GreenGo Brasil) | ✅ (group HQ) | ✅ native USD payouts | ✅ | 2 entities, ~US\$500 + BR accounting | **Recommended** — satisfies all three corners |
| **B** | **Single BR entity as software vendor** (organizers use their *own* Stripe; GreenGo bills a fee) | ✅ | ✅ (they run payments) | ✅ (export of services) | 1 entity; **manual** fee collection | Viable if you refuse a 2nd entity; product changes |
| **C** | **US LLC only** (Stripe Atlas), owner is a private individual owning it | ❌ (US) | ✅ native | ✅ | ~US\$500 + BR offshore reporting | Cleanest global build; company is US, not BR |
| **D** | **Pessoa física / autônomo, software‑vendor** (no entity anywhere) | n/a | ✅ (they run payments) | ⚠️ taxed up to 27.5% | lowest | **Validation only** — see §6 |

**Why a lone Brazilian CNPJ is not on this list for the auto‑split model:** Stripe BR / Pagar.me / Iugu /
Asaas are **domestic** and cannot pay US organizers. Forcing the BR entity to collect the full amount and
wire payouts abroad makes it **merchant of record on the entire sum** (taxed on everything) **+ IOF on
money in and out** + a câmbio contract per transaction — the opposite of the goal.

### Recommended path
- **If GreenGo must remain a Brazilian company → Route A** (BR parent owns a thin US payment LLC).
- **If global‑first and entity location doesn't matter → Route C** (US LLC via Atlas).
- **To validate cheaply before incorporating → Route D**, then graduate to A or C once proven.

---

## 4. Route A — BR parent + US payment subsidiary (recommended)

```
GreenGo Brasil (CNPJ)  ← HQ, owns the IP, owns ↓
        └── GreenGo US LLC (Delaware, via Stripe Atlas)  ← payment arm only
                • Stripe Connect (US) → pays US organizers in USD
                • collects the $2.99 application fees
        ▲
        │  US LLC pays the BR parent for software/dev/IP (invoice)
        │  → "export of services" from Brazil (ISS‑exempt, PIS/COFINS zero‑rated)
```

- **US LLC revenue** = the \$2.99 fees only.
- **BR parent revenue** = what it invoices the US LLC for software/IP → taxed in Brazil on
  **Simples/Lucro Presumido**; **export of services is ISS‑exempt and PIS/COFINS zero‑rated** (tax‑favored).
- **"Company is in Brazil" stays true** at the group level; payment *execution* is US.

---

## 5. Route C — US LLC only (global‑first)

- **Stripe Atlas** (~US\$500) → Delaware LLC + EIN + US bank (Mercury/Column) + Stripe pre‑linked. Choose
  **LLC** unless raising VC (then C‑Corp).
- Single‑member LLC owned by a non‑US person = **disregarded entity**, but **Form 5472 + pro forma 1120 is
  mandatory** (see §7).
- Same Connect architecture as §2. Best fit for "used all around the world."

---

## 6. Route D — Pessoa física / autônomo (validation only)

The **only** model a private individual can legally run: **software vendor**, not payment platform.

- Organizers process payments with **their own** US Stripe/PayPal (they hold all ticket money).
- Owner, as a Brazilian **autônomo**, invoices a **software/service fee** and receives it personally.
- **No Stripe Connect / no auto‑split** — fees collected **manually** (monthly reconciliation).

**Costs & risks (why this caps out fast):**

| | Pessoa física (autônomo) | Company (A / C) |
|---|---|---|
| Tax on fee | **Carnê‑Leão / IRPF up to 27.5%** | ~6% (BR Simples) / LLC handling |
| Fee collection | **Manual**, collection risk | Auto‑split at checkout |
| Liability | **Unlimited, personal** (refunds/chargebacks hit personal assets) | Limited to the entity |
| NFS‑e | Awkward (RPA/autônomo) | Clean |
| Receita risk | **High** — habitual profit‑driven activity can be reclassified as a de facto business | None |

**Use for the first ~20–50 events to prove demand, then incorporate.** Do **not** build the real business
on this foundation.

---

## 7. Compliance checklists

### Brazil
- **Nature of revenue:** intermediation/software **service** → issue **NFS‑e** for the fee only (automate
  via NFE.io / eNotas / PSP integration).
- **ISS** (municipal) 2–5% on the fee; **export of services is ISS‑exempt** (Route A/B/C outbound invoices).
- **Regime:** start on **Simples Nacional** (likely Anexo III, ~6% effective); revisit at scale.
- **FX/IOF:** only a problem if a BR entity receives foreign ticket revenue directly (avoided by Routes A/C).
- **PIX:** support it for any BR‑domestic volume.
- **LGPD:** ticket + payer data adds a processing purpose → update privacy policy + records.
- **Owner's offshore holding (Routes A/C):** **Lei 14.754/2023** — declare the foreign entity; offshore
  profits taxed (~15%/yr) + reported in IRPF.

### United States (Routes A / C)
- **Stripe Tax ON** → auto‑collects US **state marketplace‑facilitator sales tax** on tickets where due.
  Pass‑through; never touches GreenGo's fee income.
- **Form 5472 + pro forma 1120** for the foreign‑owned single‑member LLC — **mandatory every year even at
  \$0 US tax**; **US\$25,000 penalty** if missed (~US\$300–600/yr via a US CPA).
- **ECI question:** whether platform income is US‑taxable (effectively‑connected income) depends on where
  the work is performed (owner in Brazil, no US office/staff → often argued *not* ECI). **A US CPA must
  confirm before scaling.**
- Stripe issues **1099‑K to organizers** (their income, their filing).

### Worldwide
- **Marketplace facilitator / VAT / sales tax:** EU, UK, many US states, increasingly elsewhere may require
  the *platform* to **collect & remit** tax on the buyer's behalf. Pass‑through → doesn't change the
  "fee‑only" outcome, but must be collected. → **Stripe Tax** automates.

---

## 8. GreenGo implementation (Firebase / Firestore / Cloud Functions)

### Firestore
```
organizers/{uid}   → { stripeAccountId, chargesEnabled, payoutsEnabled, country:"US", taxId }
events/{eventId}   → { organizerUid, basePriceCents, currency:"usd", title, ... }
ticketOrders/{id}  → { eventId, buyerUid, status, paymentIntentId, feeCents:299, createdAt }
```

### Cloud Function — create checkout
```js
exports.createTicketCheckout = onCall(async (req) => {
  const { eventId } = req.data;
  const ev  = (await db.doc(`events/${eventId}`).get()).data();
  const org = (await db.doc(`organizers/${ev.organizerUid}`).get()).data();
  if (!org.chargesEnabled) throw new HttpsError("failed-precondition", "Organizer not ready");

  const FEE = 299; // $2.99, USD-pegged
  const session = await stripe.checkout.sessions.create({
    mode: "payment",
    line_items: [{
      price_data: {
        currency: ev.currency,
        unit_amount: ev.basePriceCents + FEE,
        product_data: { name: ev.title },
      },
      quantity: 1,
    }],
    payment_intent_data: {
      application_fee_amount: FEE,
      transfer_data: { destination: org.stripeAccountId },
      // connected account bears Stripe processing → GreenGo's $2.99 stays whole
    },
    automatic_tax: { enabled: true },   // Stripe Tax → US state sales tax + worldwide VAT
    success_url: "...", cancel_url: "...",
  });
  return { url: session.url };
});
```

### Webhook
- On `checkout.session.completed` / `payment_intent.succeeded` → write `ticketOrders/{id}.status="paid"`
  and **issue the ticket/QR**. Idempotent by `paymentIntentId`.

### Still to build (once the Stripe/entity is live)
- **Organizer onboarding**: Express `account_links` flow + Firestore state machine for
  `chargesEnabled` / `payoutsEnabled`.
- **Refunds / chargebacks**: decide fee handling on cancellation (refund the \$2.99 or keep it).
- **Reconciliation**: record each fee for NFS‑e automation.

---

## 9. Decisions still open (owner)

1. **Route:** **A** (BR parent + US payment LLC — recommended if company must stay Brazilian) vs **C**
   (US LLC only — global‑first) vs **D** (autônomo, validation only).
2. **Currencies:** charge everyone in USD, or localize display per region (fee stays USD‑pegged).
3. **Refund policy** on the \$2.99 fee.

## 10. Professionals to engage before real money moves
- **US CPA:** "Single‑member Delaware LLC, non‑resident (Brazil) owner, marketplace facilitation fees from
  US organizers, all work performed from Brazil — do I have US ECI/federal tax, and will you file my annual
  5472 + 1120?"
- **BR contador:** "US LLC owned by me/my BR company — how do I declare it and pay under Lei 14.754/2023,
  and how do distributions/invoices hit Brazilian tax?"

---

### ✅ Locked in
- Fee = **\$2.99**, USD‑pegged, **\$2.00 floor**; **organizer bears Stripe fee → clean \$2.99 margin**.
- Organizer = **merchant of record** via Connect split → **GreenGo taxed only on its fee**.
- **Stripe direct** on web/iOS/Android (in‑person‑event store exemption); **Stripe Tax** for worldwide tax.
- Payment architecture (§2, §8) is portable across Routes A/C.

### ⏳ Not done / remaining
- Owner to **pick the entity route** (§9.1).
- **Incorporate** (US LLC via Atlas for A/C) → yields EIN + Stripe + US bank.
- **US CPA + BR contador** sign‑off (§10).
- Build **organizer onboarding + refunds + reconciliation** (§8) once the account exists.
