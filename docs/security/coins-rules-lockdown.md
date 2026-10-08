# Coins rules lockdown (P1-1, coins part)

Status: **recommendation only. Not applied in `security/p1-coins`.** The coordinator applies it
after the app build with server-side spending is installed (`app_config/version.minVersion`
raised past that build). Old builds still write `coinBalances` / `coinGifts` /
`coinTransactions` directly, and enabling this early breaks spending and gifting for them.

## What the new build writes

| Collection | New app (this branch) | Server (Admin SDK, bypasses rules) |
|---|---|---|
| `coinBalances/{uid}` | **nothing** for spending or gifting. Remaining client writes: `getBalance()` creates an EMPTY doc when none exists; reward credits through `updateBalance` (daily free coins, missions, streak, level, challenge, `claimReward`, referral, monthly allowance). Note that the CURRENT rule already refuses any client update that raises `totalCoins`, so those credits already fail in production today (see "Follow-ups"). | `spendCoins`, `sendGift`, `acceptGift`, `giftCoins`, `declineGift`, purchase verification, grants, clawbacks |
| `coinTransactions/{id}` | the reward credits above (same caveat) | all debits, gift entries, purchases, refunds, clawbacks |
| `coinGifts/{id}` | **nothing** (the Shop send history doc and pending gifts are now created by `giftCoins` / `sendGift`; accept goes through `acceptGift`) | `sendGift`, `giftCoins`, `acceptGift`, `declineGift` |
| `profiles/{uid}` `isBoosted`, `boostExpiry`, `isIncognito`, `incognitoExpiry`, `businessPromotedUntil`, `travelerPaidUntil` | boost / incognito / business promotion: **no longer written by the client**. The client still writes `isIncognito: false` on disable and `isTraveler` / `travelerLocation` / `travelerExpiry` after the paid destination pick. | `spendCoins` |
| `events/{id}` `isFeatured`, `featuredUntil` | still re-written by the full-doc `updateEvent` (`UpdateEvent` bloc event), but with the **server's** value | `spendCoins` (`event_boost`, `event_featured`) |
| `gift_escrow`, `coin_spend_requests`, `gift_velocity`, `gift_refunds` | never | yes. Already covered by the final `match /{document=**}` deny. **No rule needed.** |

## Wave 1: after minVersion is at or past the server-spend build

### `coinBalances/{userId}`

Replace the `create` / `update` rules (and drop the old "PENDING LOCKDOWN" comment block) with:

```
match /coinBalances/{userId} {
  allow read: if isOwner(userId);          // was: any signed-in user (balances are private)
  // Only the empty placeholder getBalance() creates. Every coin comes from the server.
  allow create: if isOwner(userId)
    && request.resource.data.keys().hasOnly(['userId', 'totalCoins', 'earnedCoins',
         'purchasedCoins', 'giftedCoins', 'spentCoins', 'lastUpdated', 'coinBatches'])
    && request.resource.data.userId == userId
    && request.resource.data.totalCoins == 0
    && request.resource.data.earnedCoins == 0
    && request.resource.data.purchasedCoins == 0
    && request.resource.data.giftedCoins == 0
    && request.resource.data.spentCoins == 0
    && request.resource.data.coinBatches.size() == 0;
  allow update, delete: if false;
}
```

Check before tightening `read`. `coin_remote_datasource.searchUsersByCoins` / `getCoinStatistics`
(the in-app admin screen) read other users' balances. If that screen is still used,
keep `allow read: if isSignedIn()` for this wave and move it behind an admin callable later.
The welcome-grant exception is no longer needed: `applySignupGrants` grants the welcome coins
server-side, and the client grant was removed from `onboarding_bloc` earlier.

### `coinTransactions/{transactionId}`

```
match /coinTransactions/{transactionId} {
  allow read: if isSignedIn() && resource.data.userId == request.auth.uid;
  allow create, update, delete: if false;
}
```

`read` narrowing is safe. Every app query filters `where('userId', isEqualTo: uid)`, and
the server's `declineGift` / `acceptGift` proof queries run on the Admin SDK.

### `coinGifts/{giftId}`

```
match /coinGifts/{giftId} {
  allow read: if isSignedIn()
    && (resource.data.senderId == request.auth.uid
        || resource.data.receiverId == request.auth.uid);
  allow create, update, delete: if false;
}
```

This also closes the "re-pend a settled gift" trick that today's rules allow
(`status` back to `pending`). The server already refuses double settlement through the
`gift_escrow` status and the `gift_refunds/{debitId}` claim, so this is defence in depth.

## Wave 2: server-owned effect fields (same wave or the next one)

Add these to the `profiles/{uid}` owner-update guard, in the same style as the
existing `membershipTier` checks:

```
// Boost / incognito / business promotion are paid through spendCoins only.
&& request.resource.data.get('isBoosted', false) == resource.data.get('isBoosted', false)
&& request.resource.data.get('boostExpiry', null) == resource.data.get('boostExpiry', null)
&& request.resource.data.get('businessPromotedUntil', null)
     == resource.data.get('businessPromotedUntil', null)
&& request.resource.data.get('travelerPaidUntil', null)
     == resource.data.get('travelerPaidUntil', null)
// Incognito may be switched OFF by the user, never on.
&& (request.resource.data.get('isIncognito', false) == resource.data.get('isIncognito', false)
    || request.resource.data.get('isIncognito', false) == false)
&& (request.resource.data.get('incognitoExpiry', null) == resource.data.get('incognitoExpiry', null)
    || request.resource.data.get('isIncognito', false) == false)
// Traveler ON requires a paid pass (or a tier that gets it free).
&& (request.resource.data.get('isTraveler', false) == false
    || resource.data.get('isTraveler', false) == true
    || request.resource.data.get('travelerPaidUntil', resource.data.get('travelerPaidUntil', null)) > request.time
    || resource.data.get('membershipTier', 'FREE') in ['PLATINUM', 'platinum', 'TEST', 'test'])
```

Things to check first:
- Find any other writer of `isBoosted` / `boostExpiry` (expiry self-heal jobs, admin
  tools). Run `grep -rn "isBoosted\|boostExpiry" lib/ functions/src` in BOTH app repos.
  Allow the client to write `isBoosted: false` if an expiry self-heal does that.
- Platinum traveler is free in `edit_profile_screen` (no `spendCoins` call). Verify which tier
  strings `profiles.membershipTier` actually holds before you rely on the list above.

Events (`events/{eventId}` owner update): add
```
&& request.resource.data.get('isFeatured', false) == resource.data.get('isFeatured', false)
&& request.resource.data.get('featuredUntil', null) == resource.data.get('featuredUntil', null)
```
This is safe for the new build because it re-writes the server's values unchanged.
One gap: `EventModel.toFirestore` serialises `featuredUntil` from a `DateTime` (millisecond
precision) and the server writes a millisecond `Timestamp`, so the values compare equal.
Confirm this with a rules test before you deploy.

## Tests to add with the lockdown (`tool/rules_security_test.cjs`)

- An owner cannot raise `totalCoins`, cannot write `coinBatches`, cannot create a non-empty balance.
- An owner cannot create `coinTransactions` (including a `coinPurchase` entry) or `coinGifts`.
- An owner cannot set `isBoosted: true` / `isIncognito: true` / `businessPromotedUntil`.
- An owner CAN create the empty balance placeholder and CAN set `isIncognito: false`.
- An owner CAN update an event with unchanged `isFeatured` / `featuredUntil`.

## Follow-ups (outside this branch)

- **Client reward credits** (`updateBalance` credits: daily free coins, missions, streak, level,
  challenge, `claimReward`, referral, monthly allowance) cannot survive Wave 1, and the
  current "never rises" rule already refuses them. They need a server `claimCoinReward`
  callable with per-reward idempotency (or they should be removed) before the lockdown.
- `adminAdjustCoins` in the app's admin screen writes balances client-side. Route it through
  the existing admin callable (`functions/src/admin/userManagement.ts`).
- Web repo (`greengo-app-flutter-web`) has the same client debit call sites. It needs this
  branch's `lib/` changes before the web build goes past minVersion.
