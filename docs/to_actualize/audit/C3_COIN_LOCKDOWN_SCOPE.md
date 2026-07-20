# C3 — Coin Economy Server-Lockdown Scope (giftCoins + rule tightening)

Status: **blatant hole FIXED** (commit 133c8a8). Full server-lockdown = **scoped here, NOT yet implemented** — it is a real multi-step refactor with a data-model prerequisite that needs on-device testing. Do **not** rush it into the MVP.

## What is already fixed
Legacy `ShopScreen` no longer mints coins client-side; `limit_reached_dialog` routes to the verified `CoinShopScreen`. The ordinary-user "two-tap free coins" exploit is closed. See `REMEDIATION_PLAN.md §0.3`.

## The remaining hole
`firestore.rules` still allows `isOwner(userId)` to write `coinBalances`/`videoCoinBalances`/`coinTransactions`. A technical attacker with a custom Firestore client (not the app UI) can still mint directly. Closing this requires moving **every credit path** to server callables, then tightening the rule to spend-only/server-only.

## ⚠️ Blocking prerequisite discovered — camelCase vs snake_case split
The coin backend writes to **two different collections**:

| Writer | Collection | Client reads it? |
|---|---|---|
| Client datasource (`coin_remote_datasource.dart`), `shop_screen`, gifts | `coinBalances` / `coinTransactions` (camelCase) | ✅ YES |
| `shared/grants.ts` `grantCoins()` | `coinBalances` / `coinTransactions` (camelCase) | ✅ YES |
| `subscription/index.ts` `verifyPurchase` (membership + welcome coins, via grantCoins) | `coinBalances` (camelCase) | ✅ YES |
| `coins/index.ts` — `verifyGooglePlayCoinPurchase`, `verifyAppStoreCoinPurchase`, `claimReward`, `grantMonthlyAllowances`, `processExpiredCoins` | `coin_balances` / `coin_transactions` (**snake_case**) | ❌ NO — phantom collection |

**Implication:** the coins/index.ts callables (reward claim, monthly allowance, coin-bundle purchase verify, expiry) operate on a collection the app never reads. They are either dead code or silently broken. They therefore **cannot be reused** for the lockdown until reconciled to camelCase.

**Action item (do FIRST, independently, and verify on device):** decide `coinBalances` (camelCase) is canonical, then either (a) rewrite the five coins/index.ts functions to read/write camelCase, or (b) delete the ones that are dead (confirm the client path already covers reward/allowance/bundle-purchase). Verify a real coin-bundle purchase and a reward claim actually change the in-app balance BEFORE touching rules.

## Sequenced lockdown plan (after the prerequisite)
1. **Canonical camelCase server credit callables** (Admin SDK bypasses rules):
   - Purchase (bundle): confirm which callable the client actually invokes — `CoinShopScreen` calls `verifyPurchase` (subscription). Ensure coin *bundles* (not just membership) credit camelCase `coinBalances`.
   - Reward: `claimReward` → rewrite to camelCase (currently snake).
   - Monthly allowance: `grantMonthlyAllowances` → camelCase (currently snake).
   - **Gift: NEW `giftCoins` callable** — atomic transaction mirroring the client `sendGift`/`acceptGift`/`declineGift` (debit sender, create pending `coinGifts` doc; accept → credit receiver + status; decline → refund sender). Model shape is in `coin_remote_datasource.dart` (`_debitInTransaction`/`_creditInTransaction`, `CoinGiftModel`). Keep the chat-notification side-effect (`_createGiftChatNotification`) either in the callable or a Firestore trigger on `coinGifts`.
   - Video coins: NEW callable for `addVideoCoins` (credit `videoCoinBalances`); `useVideoCoins` (decrement) can stay client under a spend-only rule.
2. **Rewire client** (`coin_remote_datasource.dart`) so every *credit* path calls a callable instead of a direct transaction. *Spends* (decrements) may stay client if the rule is spend-only.
3. **Tighten `firestore.rules`:**
   - Interim/spend-only: `allow update: if isOwner(userId) && request.resource.data.totalCoins <= resource.data.totalCoins` (blocks all increases; gifts-received/rewards must already be callable-only or they break).
   - Full: `allow write: if false` on `coinBalances`/`videoCoinBalances`/`coinTransactions`/`coinGifts` — all mutations server-only.
4. **Device test EVERY flow** before/after: buy bundle, spend on a feature, send gift, accept gift, decline gift, claim reward, monthly allowance, video-coin buy + use. No emulator-only sign-off — the camel/snake split will only surface with a real balance read.

## Recommendation for the MVP
Ship with the blatant hole fixed (done). Treat the rule lockdown + camel/snake reconciliation as the **first post-launch hardening sprint**, with device testing — not a rushed pre-MVP change. The residual risk (raw-SDK mint by a technical attacker) is real but not an ordinary-user path, and App Check (also on the audit backlog) raises that bar further in the meantime.
