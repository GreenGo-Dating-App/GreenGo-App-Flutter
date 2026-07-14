# GreenGo Admin Panel — Actualization Plan

> **Goal:** Bring the React admin panel up to parity with everything the GreenGo app now does — a management surface per major collection, with first-class support for **Events (see + ban)**, **Businesses (see + verify + ban)**, **Statistics**, **Moderation (reports, ban/suspend users, remove content)**, **Coins economy**, plus Groups/Communities, a content-moderation queue, feature flags, and an audit log.
>
> **Status:** Planning / not started
> **Date:** 2026-07-13
> **App repo (backend + source):** `Desktop/Projects/GreenGo/GreenGo-App-Flutter` — Flutter app + `functions/` (TypeScript Cloud Functions) + `firestore.rules` + `firestore.indexes.json`. Firebase project **`greengo-chat`**.
> **Admin panel repo:** `github.com/GreenGo-Dating-App/greengo-admin-panel` (private, React/Vite). Deployed via app `firebase.json` hosting target **`admin`** → `../greengo-admin-panel/dist`.
> **Admin URL:** https://admin.greengochat.com

---

## 1. Current State of the Admin Panel

### 1.1 Stack (from `greengo-admin-panel/package.json`)

| Layer | Choice |
|---|---|
| Framework | **React 19.2** + **Vite 5.4** + **TypeScript 5.9** (`type: module`) |
| UI library | **MUI 7.3** (`@mui/material`, `@mui/icons-material`) + **`@mui/x-data-grid` 8** + `@mui/x-date-pickers` |
| Server state | **@tanstack/react-query 5** (aggressive cache: `staleTime` 10 min, `gcTime` 30 min, no refetch on focus/mount — see `src/App.tsx`) |
| Client state | **Zustand 5** (`src/store/authStore.ts`) |
| Routing | **react-router-dom 6.30** (`BrowserRouter`, `ProtectedRoute` in `src/App.tsx`) |
| Charts | **Recharts 3** |
| Maps | **react-leaflet 5** + `leaflet` (geo heatmaps) |
| PDF | `@react-pdf/renderer`, `jspdf`, `html2canvas` (invoice/report export) |
| Forms | `react-hook-form` + `zod` |
| Firebase | **firebase 12.6** (client Web SDK). `firebase-admin` present only as a devDependency for local scripts. |
| Theme | Dark luxury **gold/black** (`#D4AF37` gold on `#0A0A0A`), defined inline in `src/App.tsx`. |

### 1.2 How it talks to Firebase

The panel uses the **client Web SDK directly** (`src/config/firebase.ts` → `getAuth / getFirestore / getFunctions / getStorage`; config from `VITE_FIREBASE_*` env vars). Data access is **hybrid**:

- **Direct Firestore reads/writes** for most screens — e.g. `src/services/userService.ts` (queries `profiles`), `moderationService.ts` (`moderation_queue`, `user_reports`), `coinService.ts` (`coinBalances`, `coinTransactions`), `dashboardService.ts` (uses `getCountFromServer` + 5-min in-memory cache to minimize reads), `databaseService.ts` (read-only Firestore browser over a hard-coded `KNOWN_COLLECTIONS` list).
- **Callable Cloud Functions** (`httpsCallable`) for privileged ops — e.g. 2FA (`send2FACode` / `verify2FACode`) and some user-management actions.

> These direct writes only succeed because `firestore.rules` grants `isAdminPanelUser()` broad access via the **catch-all** `match /{document=**}` (read if signed-in, write if admin-panel user). This is powerful but bypasses server-side validation and audit — see §3.

### 1.3 Auth & role-gating

- Sign-in flow (`src/contexts/AuthContext.tsx`, `src/services/authService.ts`): Firebase **email/password** → look up **`admin_users/{uid}`** doc → require `isActive !== false` → **mandatory email 2FA** (`send2FACode` then `verify2FACode`, implemented in `functions/src/admin/adminPanelFunctions.ts`). Full re-authentication (incl. 2FA) is forced on **every page reload** for security.
- `admin_users/{uid}` carries `role` + a **`permissions[]`** array. The nav (`src/components/layout/MainLayout.tsx`) gates each item by a `permission` string (e.g. `viewReports`, `adjustCoins`, `manageAdmins`, `systemSettings`) and optionally a `featureFlag`.

### 1.4 Existing pages (28) — `src/pages/`

`Dashboard, Users, Moderation, Analytics, VipMembers, Subscriptions, Coins, Payments, Invoices, Shop, Coupons, Gamification, LanguageLearning, SupportChats, AISettings, Notifications, EmailSettings, EmailTemplates, EmailAnalytics, Database, SystemHealth, FeatureFlags, VersionManagement, LegalDocuments, EnvironmentManagement, CountdownDates, AdminRoles, AuditLog`.

Nav groups (MainLayout): **Dashboard · Users · Finance · Content · Communication · System · Administration**.

### 1.5 Gaps — what the app does that the panel canNOT manage

| App feature (collection) | Admin surface today | Gap |
|---|---|---|
| **Events** (`events`) | none | **No Events page. No way to see/filter/ban user- or business-created events.** |
| **External events** (`external_events`, `external_events_index`, `external_country_stats`) | none | **No way to view or hide ingested Tiqets/Viator/Geoapify/Ticketmaster events.** |
| **Businesses** (`profiles` where `isBusiness`, `business_verification_requests`, `business_followers`, `business_leads`, `business_ratings`) | verification is done **in-app** by `isProfileAdmin()` users only | **No business directory, no admin verify/reject/ban, no ratings/leads view.** |
| **Groups / Culture Circles** (`groups`) | none | **No group listing/moderation.** |
| **Communities** (`communities`) | none | **No community listing/moderation.** |
| Coins economy | Coins/Shop/Coupons pages exist | Faucet/promotions/manual-adjust audit incomplete; ledger uses direct writes. |
| Moderation | Moderation page exists (`user_reports`, `moderation_queue`) | Wired for **dating-era** reports; no event/business/community content actions. |
| Dashboard stats | present but **legacy** | Metrics count `matches`, `messages`, `subscriptions` — not events/businesses/coins economy/DAU-MAU for the current product. |

> The panel and several backend admin functions still carry **dating-app vocabulary** (matches, matchmakers, swipes). GreenGo is now a cross-cultural discovery/networking app; the actualization also re-frames metrics and copy.

---

## 2. Data Model the Admin Must Expose (from the app repo)

Enumerated from `firestore.rules` + `functions/src/`:

| Domain | Collection(s) | Key fields | Rule gate (client) |
|---|---|---|---|
| Users | `users/{uid}` | `role, accountStatus, banned, bannedUntil, suspendedUntil, lastActiveAt, createdAt` | read: signed-in; update: owner or `isAdminPanelUser()` |
| Profiles | `profiles/{uid}` | `displayName, isAdmin, isBanned, isBusiness, businessVerified, followerCount, ratingSum, ratingCount, location` | update: owner (not `isBanned`), `isAdminPanelUser()`, `isProfileAdmin()` |
| Events | `events/{id}` (+ `attendees`, `likes`, `messages` subcols) | `organizerId, visibility, attendeeCount, tierGoingCounts, viewCount` | **write: organizer only** (admin catch-all does **not** apply — specific match wins) |
| External events | `external_events`, `external_events_index`, `external_country_stats`, `city_coordinates` | provider payload, geohash, category | **write: false** (CF-only) |
| Businesses | `profiles` (`isBusiness`), `business_verification_requests/{uid}`, `business_followers/*`, `business_leads/*`, `business_ratings/*` | `status(pending/approved/rejected)`, ratings, leads | verify: `isProfileAdmin()` |
| Groups | `groups/{id}` (+ `messages`, `members`), `user_group_inbox`, `user_group_tags` | `participants, roles` | read/write: members only |
| Communities | `communities/{id}/**` | membership, posts, messages | read/write: any signed-in |
| Coins | `coinBalances/{uid}`, `coinTransactions`, `coinGifts`, `coinOrders`, `coinPromotions`, `claimedRewards`, `referrals`, `referral_codes` | `totalCoins`, ledger entries, gifts | reads: signed-in; integrity guards on writes |
| Moderation | `reports`, `message_reports`, `user_reports`, `moderation_queue`, `game_reported_words`, `blocked_users` | `status, priority, reportedUserId, action` | **`isAdmin()`** (users.role=='admin') — see mismatch below |
| Subscriptions / IAP | `subscriptions`, `memberships`, `membership_purchases` | `tier, status` | read: signed-in; write: CF-only |
| Config | `featureFlags`, `appConfig`, `app_config`, `tierConfigs`, `legalDocuments` | flags/config | write: `isAdminPanelUser()` (only `app_config`) |
| Audit | `admin_actions`, `admin_audit_index`, `admin_audit_logs_YYYY_MM` | actor, action, target | `isAdminPanelUser()` create-only |

### 2.1 Two admin-identity systems (must reconcile)

`firestore.rules` defines **three** distinct admin predicates:

```
isAdmin()          → get(users/{uid}).data.role == 'admin'        // dating-era
isAdminPanelUser() → exists(admin_users/{uid})                    // the React panel
isProfileAdmin()   → get(profiles/{uid}).data.isAdmin == true     // in-app admin tools
```

**Consequence:** the panel authenticates against `admin_users`, but `reports`, `message_reports`, `user_reports`, and `analytics` are gated by **`isAdmin()`** (the `users` role), and **business verification** is gated by **`isProfileAdmin()`**. A panel admin who is not *also* `users.role=='admin'` and `profiles.isAdmin==true` **cannot read reports or approve businesses via the client SDK today.** This must be fixed (unify on `isAdminPanelUser()` for admin reads, or route these through callables — recommended).

---

## 3. Architecture & Security

### 3.1 Authentication (keep + harden)

Keep the existing model: Firebase email/password → `admin_users/{uid}` membership → mandatory email 2FA → forced re-auth on reload. **Add custom claims.**

- Set a Firebase Auth **custom claim** `admin: true` (+ `adminRole`, `adminPermissions`) on admin accounts, written by a CF when an `admin_users` doc is created/updated. Claims let both `firestore.rules` and callables verify admin status **without an extra `get()`** per request (cheaper, atomic, revocable).
- Update `firestore.rules` `isAdminPanelUser()` to also honor the claim: `request.auth.token.admin == true`. Fall back to the `exists()` check during migration.

### 3.2 Privileged writes → callable Cloud Functions (recommended default)

**Rule: any state-changing admin action goes through a callable Cloud Function using the Admin SDK, not a direct client write.** Reasons:

1. **`external_events` and `events` cannot be admin-written from the client at all** (rules block it) — a CF with the Admin SDK is the *only* way to ban/hide them.
2. Server-side validation, idempotency, fan-out (e.g. notify attendees on event removal), and **mandatory audit-log entries** (`admin_actions`) can't be enforced from the client.
3. Every callable already funnels through `verifyAdminAuth(request.auth)` (`functions/src/shared/utils.ts`) — a single choke point for authorization.

**Direct Firestore reads stay** for list/detail views (cheap, cache-friendly via React Query), *provided* rules grant admin read. Only **writes** must be callables.

### 3.3 New backend needed (summary — detail in §5)

- New callables: `banEvent`, `unbanEvent`, `hideExternalEvent`, `verifyBusiness`, `rejectBusiness`, `banBusiness`, `moderateCommunity`, `moderateGroup`, `adjustCoinBalance`, `getPlatformStats` (events/businesses/coins/DAU-MAU).
- `firestore.rules`: add explicit **admin read** to `events`, `external_events`, `communities`, `groups`, `business_*`, and **admin update** to `events` (or keep client-blocked and do all mutations via callables — preferred). Unify report/business reads on `isAdminPanelUser()` (or claim).
- New composite indexes for admin filters (status, banned, createdAt) — see §5.3.

---

## 4. Feature Modules

Each new page lives under `src/pages/`, with a matching `src/services/*Service.ts`, a route in `src/App.tsx`, and a nav entry in `MainLayout.tsx` (with a `permission` gate). New nav group: **"Marketplace"** (Events, External Events, Businesses, Communities, Groups) alongside existing groups.

### 4.1 Dashboard / Statistics — *rebuild*
- **Purpose:** single at-a-glance operational view for the *current* product.
- **Data source:** new callable **`getPlatformStats`** (aggregates), plus `getCountFromServer` for cheap totals. Reuse existing `analytics/*` callables (`getRevenueDashboard`, `getMRRTrends`, `getUserMetrics`, `getEngagementMetrics`, `predictChurn`).
- **Key widgets:** Users (total, new, **DAU/MAU**, active-rate), Events (total, upcoming, external vs user-created, banned), Businesses (total, verified, pending verification), **Coins economy** (coins in circulation, minted/faucet, spent, gifted, top sinks), Revenue (MRR, IAP, coin purchases, Stripe), **Moderation queue depth** (open reports by type/priority).
- **Acceptance:** loads < 2 s from cache; every tile links to its module filtered to that slice; no `matches`/`swipes` vocabulary remains.

### 4.2 Events (+ ban) — *new*
- **Purpose:** browse/inspect/moderate **user- and business-created** events.
- **Data source:** direct read of `events` (admin read rule) with server-side filters; detail pulls `attendees`, `likes`, `messages` subcollections. Actions via callables.
- **Key actions:** list + filter (city/country, category, visibility, organizer type, date range, `banned`); detail (organizer, RSVP counts, chat preview); **`banEvent`** (soft: set `banned:true`, `bannedReason`, hide from discovery, optional notify organizer+attendees) / **`unbanEvent`**; hard **`deleteEvent`** (cascades attendees/messages) for illegal content.
- **Acceptance:** a banned event disappears from app discovery within one read cycle; action is written to `admin_actions`; organizer optionally notified.

### 4.3 External Events (+ hide) — *new*
- **Purpose:** oversight of ingested Tiqets/Viator/Geoapify/Ticketmaster events (`functions/src/external_events/*`).
- **Data source:** read `external_events` (+ `external_events_index`, `external_country_stats`). `external_events` is **write:false**, so all mutations are callables.
- **Key actions:** list/filter by provider, country, category, ingest date; **`hideExternalEvent`** (adds to a `hidden`/blocklist consumed by ingesters & queries) so bad third-party data can be suppressed without waiting for the next ingest; view ingester health/last-run.
- **Acceptance:** hidden external event no longer surfaces in the app Events tab; blocklist survives re-ingest.

### 4.4 Businesses (+ verify / ban) — *new*
- **Purpose:** business directory + verification workflow + enforcement.
- **Data source:** `profiles` where `isBusiness==true`; `business_verification_requests` (pending queue); `business_ratings`, `business_leads`, `business_followers` for detail. Actions via callables.
- **Key actions:** directory (search, filter verified/pending/banned, sort by followers/rating); detail (ratings, leads, follower count, submitted docs); **`verifyBusiness`** (sets `profiles.businessVerified`, resolves request) / **`rejectBusiness`** (reason) / **`banBusiness`** (sets `profiles.isBanned`, hides listings & their events).
- **Acceptance:** moves the today's **in-app-only** `isProfileAdmin()` verification into the panel; badge appears in-app on approve; banned business + its events drop from discovery; audit-logged.

### 4.5 Users & Moderation — *extend existing*
- **Purpose:** user directory + reports triage + enforcement.
- **Data source:** `profiles`/`users` (existing `userService`); reports from `reports` / `user_reports` / `message_reports` / `moderation_queue`. Actions via existing admin callables.
- **Key actions (reuse):** `searchUsers`, `getUserDetails`, `banUser`/`unbanUser`, `suspendUser`/`reactivateUser`, `deleteUserAccount`, `getModerationQueue`, `processReport`/`bulkProcessReports`, `assignModerator` (all in `functions/src/admin/*`). `adminSetUserDisabled`, `adminChangeUserPassword`, `adminDeleteUser` in `adminPanelFunctions.ts`.
- **Fixes:** wire report reads through a callable (or unify rules) so the panel actually sees them; extend `processReport` targets to cover **event/business/community/message** content, not just user profiles.
- **Acceptance:** a report can be actioned end-to-end (warn/suspend/ban/remove content) with one click; queue depth matches the Dashboard tile.

### 4.6 Coins Economy — *extend existing*
- **Purpose:** inspect and correct the coin ledger; monitor the faucet.
- **Data source:** `coinBalances`, `coinTransactions`, `coinGifts`, `coinOrders`, `coinPromotions`, `claimedRewards`, `referrals`. Existing `functions/src/coins/coinManager.ts`.
- **Key actions:** per-user balance + full transaction history; **`adjustCoinBalance`** (new callable — grant/deduct with reason, writes a ledger entry + `admin_actions`, never a raw client write); view/create promotions & faucet config; gift/refund audit; referral fraud view.
- **Acceptance:** manual adjustments are atomic (transaction), produce a `coinTransactions` entry, and are audited; economy totals reconcile with the Dashboard tile.

### 4.7 Groups / Communities — *new*
- **Purpose:** moderation of `groups` (Culture Circles) and `communities`.
- **Data source:** read via callable (`groups` is members-only; needs Admin SDK) or an admin read rule; `communities` is signed-in-readable already.
- **Key actions:** list/search; detail (members, recent messages/posts); **`moderateGroup` / `moderateCommunity`** (hide, archive, remove message/post, remove member, ban owner); tie into reports.
- **Acceptance:** a flagged community/group can be hidden or purged; action audited; members optionally notified.

### 4.8 Content Moderation Queue — *new unified surface*
- **Purpose:** one inbox for **all** UGC report types (users, messages, events, businesses, communities, group messages, reported game words).
- **Data source:** `reports`, `user_reports`, `message_reports`, `game_reported_words`, plus new event/business/community report writes; served by an extended `getModerationQueue`.
- **Key actions:** unified triage with priority, assignment (`assignModerator`), bulk actions, per-type "remove content" that calls the right ban/hide callable.
- **Acceptance:** every reportable surface in the app lands here; SLA/queue-age visible; supports the app's UGC-safety obligations (Apple/Play).

### 4.9 Settings / Feature Flags — *extend existing*
- **Purpose:** runtime control without a release.
- **Data source:** `featureFlags`, `appConfig`/`app_config` (`app_config` is `isAdminPanelUser()`-writable), `tierConfigs`, `legalDocuments`, `CountdownDates`.
- **Key actions:** toggle flags (gamification, languageLearning, events, communities…); edit tier limits, legal docs, countdowns.
- **Acceptance:** a flag flip reflects in-app on next config read; changes audited.

### 4.10 Audit Log — *extend existing*
- **Purpose:** immutable record of every admin action.
- **Data source:** `admin_actions`, `admin_audit_index`, monthly `admin_audit_logs_YYYY_MM`.
- **Key actions:** filter by actor/type/target/date; drill into a single action; export CSV/PDF.
- **Acceptance:** **every** callable in §5 writes here; entries are create-only (rules already enforce `update,delete: false`).

---

## 5. Backend Work Needed

### 5.1 New / updated Cloud Functions (`functions/src/`)

| Callable | Module | Behaviour |
|---|---|---|
| `banEvent` / `unbanEvent` | `admin/eventModeration.ts` (new) | Set `events/{id}.banned`, reason, actor; remove from discovery; optional notify; audit. |
| `deleteEvent` | same | Hard delete + cascade `attendees`/`messages`/`likes`. |
| `hideExternalEvent` / `unhideExternalEvent` | `external_events/moderation.ts` (new) | Maintain a blocklist consumed by ingesters (`ingest.ts`, `build_index.ts`) and read queries. |
| `verifyBusiness` / `rejectBusiness` / `banBusiness` | `admin/businessModeration.ts` (new) | Set `profiles.businessVerified` / `isBanned`; resolve `business_verification_requests`; cascade-hide the business's events; audit. |
| `moderateGroup` / `moderateCommunity` | `admin/communityModeration.ts` (new) | Hide/archive/remove content/member; audit. |
| `adjustCoinBalance` | extend `coins/coinManager.ts` | Transactional grant/deduct + `coinTransactions` ledger entry + audit. |
| `getPlatformStats` | `admin/adminDashboard.ts` (extend) | Aggregate current-product metrics (events, businesses, coins economy, DAU/MAU) from sharded counters — see §6. |
| `setAdminClaims` (trigger) | `admin/roleManagement.ts` (extend) | On `admin_users` write, set/clear Auth custom claims. |
| Report reads | extend `admin/moderationQueue.ts` | Serve reports/queue to the panel via callable so client rule-mismatch is moot; extend targets to event/business/community. |

> **Reusable today** (already deployed via `functions/src/index.ts`): `banUser`, `unbanUser`, `suspendUser`, `reactivateUser`, `deleteUserAccount`, `getModerationQueue`, `processReport`, `bulkProcessReports`, `assignModerator`, `getDashboardStats`, `getUserGrowth`, `getRevenueStats`, `assignRole`/`revokeRole`, plus `safety/contentModeration`, `safety/reportingSystem`, and the `analytics/*` suite. **No event/business/external-event/community moderation callable exists yet — that is the core new backend work.**

### 5.2 `firestore.rules` / claims changes
- Add `request.auth.token.admin == true` to `isAdminPanelUser()`.
- Grant **admin read** on `events`, `external_events*`, `communities`, `groups`, `business_*` for the panel (or serve via callables — pick per collection; callables preferred for `groups`/`events` writes since specific matches block the catch-all).
- **Do not** open client admin *writes* to `events`/`external_events`; keep them CF-only.
- Unify `reports` / `message_reports` / `user_reports` / `analytics` reads on `isAdminPanelUser()` (or the claim) so the panel stops depending on the legacy `users.role=='admin'` path.

### 5.3 `firestore.indexes.json` — new composite indexes
- `events`: `(banned ASC, startAt DESC)`, `(country ASC, startAt DESC)`, `(organizerType ASC, createdAt DESC)`.
- `external_events`: `(provider ASC, ingestedAt DESC)`, `(hidden ASC, country ASC)`.
- `profiles`: `(isBusiness ASC, businessVerified ASC)`, `(isBusiness ASC, followerCount DESC)`.
- `business_verification_requests`: `(status ASC, createdAt ASC)`.
- `coinTransactions`: `(userId ASC, createdAt DESC)` (if not present).
- reports/queue: `(status ASC, priority DESC, createdAt ASC)`.

---

## 6. Statistics / Analytics Approach

- **Cheap totals:** `getCountFromServer()` (already used in `dashboardService.ts` and `admin/*`), cached 5 min in React Query + in-memory.
- **Live aggregates at scale:** GreenGo already denormalizes via **`FieldValue.increment` sharded counters** — e.g. `events/country_aggregate.ts` (`onEventWriteUpdateCountryStats` → `external_country_stats`), event `attendeeCount`/`tierGoingCounts`, profile `followerCount`/`ratingSum`/`ratingCount`. `getPlatformStats` should **read these pre-computed counters**, not scan collections, to stay O(1) as the app scales to millions.
- **Coins economy:** sum from a maintained `coinPromotions`/faucet counter + periodic rollup rather than scanning `coinTransactions`.
- **Revenue / cohort / churn / segmentation:** reuse the existing `functions/src/analytics/*` callables (`getRevenueDashboard`, `getMRRTrends`, `getCohortAnalysis`, `getRetentionRates`, `predictChurn`, `getUserMetrics`, `getEngagementMetrics`, user-segmentation).
- **BigQuery:** `functions/src/analytics/bigQuerySetup.ts` exists — if the Firestore→BigQuery export is enabled, heavy historical dashboards (DAU/MAU trends, funnels) should query BigQuery, not Firestore, to avoid read-cost blowups. Confirm export status (open question).

---

## 7. Phased Rollout

| Phase | Scope | Acceptance |
|---|---|---|
| **P0 — Auth & Dashboard foundation** | Custom-admin claims + `setAdminClaims` trigger; unify rules on `isAdminPanelUser()`/claim; rebuild Dashboard on `getPlatformStats` (events/businesses/coins/DAU-MAU); remove dating vocabulary. | Panel admin can log in with 2FA; dashboard shows current-product metrics from sharded counters; no client rule-mismatch on reports. |
| **P1 — Events + Businesses + Ban** | Events page (+ `banEvent`/`unbanEvent`/`deleteEvent`); External Events page (+ `hideExternalEvent`); Businesses page (+ `verifyBusiness`/`rejectBusiness`/`banBusiness`); indexes. | Admin can find and **ban** any user/business/external event; can **verify/ban** businesses; app discovery reflects it; all audited. |
| **P2 — Moderation & Users** | Unified moderation queue across all UGC types; extend `processReport` targets; wire report reads via callable; user enforcement actions. | Any report actionable end-to-end; queue depth matches dashboard. |
| **P3 — Coins & Stats depth** | `adjustCoinBalance`; economy dashboards; promotions/faucet mgmt; revenue/cohort/churn wired. | Manual coin adjustments atomic + audited; economy reconciles. |
| **P4 — Groups/Communities, Flags, Audit polish** | Group/Community moderation pages; feature-flag/tier/legal config; audit-log export. | Flagged group/community removable; flag flips live; every action in audit log. |

---

## 8. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| **Read-cost blowup** (naive `collection().get()` for stats) | Use sharded counters + `getCountFromServer` + BigQuery for history; React Query cache (already configured). |
| **Client-side privileged writes** bypass validation/audit | All mutations via callables through `verifyAdminAuth`; keep `events`/`external_events` client-writes blocked. |
| **Three-headed admin identity** (`admin_users` vs `users.role` vs `profiles.isAdmin`) | Migrate to a single **custom claim** as source of truth; keep `exists()` fallback during migration; backfill claims for existing admins. |
| **Banning cascades** (ban business → its events; delete event → attendees/messages) | Implement cascades server-side in callables with batched writes; idempotent. |
| **Dating-era code/vocabulary** misleads operators | Re-frame metrics/copy in P0; leave legacy callables in place but stop surfacing `matches`/`swipes`. |
| **2FA re-auth on every reload** hurts operator UX during heavy moderation | Keep for security; consider a short-lived server-set session claim to reduce friction (decision for user). |
| **Deploy coupling** (admin `dist` lives outside its repo, referenced by app `firebase.json`) | Document the build → `../greengo-admin-panel/dist` → `firebase deploy --only hosting:admin` flow; keep repos in sync. |

---

## 9. Open Questions / Decisions for the User

1. **Admin identity:** consolidate on Firebase **custom claims** (recommended) and deprecate the `users.role=='admin'` + `profiles.isAdmin` paths? Who backfills claims for current admins?
2. **Business verification ownership:** move verification fully into the panel (`admin_users`), or keep the in-app `isProfileAdmin()` reviewer flow as well?
3. **Event ban semantics:** soft-ban (`banned:true`, reversible, keeps data) vs hard-delete — default to soft, hard only for illegal content? Notify organizer/attendees on ban?
4. **External events blocklist:** confirm ingesters (`external_events/ingest.ts`, `build_index.ts`) should consult a `hidden` blocklist so suppression survives re-ingest.
5. **BigQuery:** is the Firestore→BigQuery export live (`analytics/bigQuerySetup.ts`)? If yes, point historical dashboards there.
6. **Coins:** should `adjustCoinBalance` require a second-admin approval for amounts over a threshold?
7. **Scope of "much more":** priority order for Groups vs Communities vs deeper analytics in P4?
8. **Secrets:** admin `.env` uses `VITE_FIREBASE_*` (currently placeholders in `src/config/firebase.ts`). Keys live in `E:\Projects\GreenGo\credentials\greengo-credentials.txt` — confirm the panel's `.env` is populated there and never committed.
