# GreenGo — Dev Plan: Storefront dualism, community controls, membership, tours

Grounded in a full code map (Aug 2026). Each phase is independently shippable
(build + install + verify on the Pixel 9). Rules/indexes/functions are the
deploy-gated tail. i18n: every new UI string → `lib/l10n/app_en.arb` + 6 locales
+ `flutter gen-l10n`.

---

## PHASE 0 — Quick wins (one build)

1. **Remove the "Discover" page title.**
   `explore/presentation/screens/network_discovery_screen.dart:726-734` — in the
   non-searching branch replace `Text(...)` with `const SizedBox.shrink()` (keep
   the search `TextField` branch and all `actions:` icons).
2. **Discover person image size = Explore.**
   Same file, grid delegate `:900` — change `childAspectRatio: 1` → `5/7`
   (≈0.714) to match Explore's 150×210 portrait cards
   (`explore_screen.dart:1994/1997`).
3. **"Become a business" card after "Progress & Grow".**
   `profile/presentation/screens/edit_profile_screen.dart` — cut the business
   `Container` block `:269-288` and paste it immediately after the
   Progress & Growth `SettingsAccordion` (after `:525`).

---

## PHASE 1 — Community controls

State from map: `cityTip` already exists end-to-end; announcements already
owner/admin-gated; promote/demote + moderation sheet already exist (binary
admin/member only); `deleteCommunity` exists in datasource/repo but has **no
bloc event, no UI, no password**.

1. **Restrict Tips posting to admins / designated writers.**
   - UI: `community_detail_screen.dart:470` — change `if (_isMember)` on the
     add-tip bar to a permission check (`_isModerator || member.canWriteTips`).
   - Rules: `firestore.rules:988-993` — add a clause so `languageTip`/
     `culturalFact`/`cityTip` creation requires `isCommunityMod()` OR the new
     per-member permission flag. Mirror into `devops/scripts/firebase/firestore.rules`.
2. **City tip** — model already done; just ensure it's offered to permitted
   writers (relax the `localGuides && _isLocalGuide` gate at `_addTip:530-534`
   for admins/designated writers).
3. **Granular nomination (moderator / tip-writer / announcement-writer).**
   - Member entity `community_member.dart` — add `canWriteTips`,
     `canWriteAnnouncements` bool fields (+ model serialization).
   - Extend `MemberModerationAction` (`communities_event.dart:173-180`) with
     `grantTips/revokeTips/grantAnnouncements/revokeAnnouncements`; wire the
     moderation sheet (`member_moderation_sheet.dart:74-89`), bloc
     `_onModerateMember` (`communities_bloc.dart:412-453`), and datasource
     `updateMemberModeration` (`:611`).
   - Rules `:974` (members update by mod) already covers writing these flags;
     announcements rule `:990-993` extends to `canWriteAnnouncements`.
   - "Moderator" = the existing `promoteToAdmin`; keep it.
4. **Delete community (owner-password-gated).**
   - Add `DeleteCommunity` event + `on<DeleteCommunity>` handler
     (`communities_event.dart`, `communities_bloc.dart`) → existing
     `repository.deleteCommunity` (`communities_remote_datasource.dart:266`).
   - UI: owner-only item in the app-bar popup
     (`community_detail_screen.dart:357-408`), gated `if (_isOwner)`.
   - Password gate: reuse the **account-password re-auth** pattern from account
     deletion (`edit_profile_screen.dart` reauth block) — `EmailAuthProvider
     .credential` + `reauthenticateWithCredential`, with the social-login guard
     and no `.trim()`. (Rules can't verify a password; re-auth is the real gate.
     Alternative: move deletion to a Cloud Function. Recommend re-auth client-side.)

---

## PHASE 2 — Featured community events

Current (`explore_screen.dart` `_loadLuxuryEvents`): boosted
(`event.isCurrentlyFeatured`) → live-of-day → nearest normal, capped 3, 50km.
Change to the requested order and guarantees:
- **Tier 1** boosted community events (`isCurrentlyFeatured`).
- **Tier 2** RANDOM community events (shuffle nearest non-featured) — was "live".
- **Tier 3** live events as the final fallback.
- **Mandatory:** every card `startDate >= startOfToday` (today/future only);
  always pad to **exactly 3** cards (`_luxuryEventsSection:1789-1862` already
  renders 3 skeletons — keep the carousel at 3).
- Selection lives ~`:660-826`; add the today/future filter and reorder tiers.

---

## PHASE 3 — Membership revamp

Two un-unified tier systems + an unused `TierEntitlements.perksFor()`. Real
per-tier limits live in `core/services/tier_entitlements.dart` (free/silver/gold/
platinum; `null`=∞): maxEvents 1/3/5/∞, maxGroups 1/∞/∞/∞, maxDailyConnects
10/50/200/∞, boosts 0/1/4/30, monthlyCoins 100/500/1500/5000, canBecomeBusiness
& analytics = Platinum-only.

1. **"Start your free trial" copy** — `core/widgets/base_membership_dialog.dart`
   bullets `:661-665` + ARB `membershipTrialFeature1-3` / `membershipTrialSubtitle`
   (`app_en.arb:5180-5187` + 6 locales):
   - Drop "Unlimited Swipes & Connections".
   - Emphasize: create unlimited **communities, events & groups**; **no ads**;
     bonus coins; full access.
   - Embed a **coupon field**: reuse `CouponCodeWidget`
     (`membership/presentation/widgets/coupon_code_widget.dart`) or the
     register-style inline `validateCoupon` field.
2. **Tier feature lists = real entitlements.** Replace the dating-style
   `SubscriptionTier.features` map (`subscription/domain/entities/subscription.dart:154-229`)
   and the rendered rows (`coin_shop_screen.dart:1563-1578`,
   `subscription_selection_screen.dart:578-586`) with entitlement-driven bullets
   (events/groups/communities creation, daily connects, boosts, monthly coins,
   business account for VIP, no ads, priority support). Prefer wiring
   `TierEntitlements.perksFor()` (`:389-440`) into these UIs; add the missing
   `tierPerk*` l10n strings.
3. **Base membership full feature list** — add a base column/section sourced from
   `TierEntitlements` free-tier values.

---

## PHASE 4 — Business / Storefront dualism (largest; sub-phased)

Today: business = `profiles/{uid}.isBusiness` (one-time, irreversible,
Platinum-gated). No `businessProfiles` collection, no separate chat identity.
Target: a separate, **freely toggleable, Platinum-gated** storefront identity.

**4a — Data model + toggle**
- New `businessProfiles/{uid}` doc (one storefront per Platinum user; id = uid to
  avoid re-keying `business_followers`/`business_ratings`/`business_leads`/
  `business_verification_requests`, all already keyed by businessId==uid). Move
  storefront fields off `profiles`: storeName, businessLegalName, category, logo
  (avatar), coverImageUrl, galleryImages, storefrontBio, storefrontLinks,
  openingHours, businessWhatsapp, businessVerified, + denorm followerCount/
  ratingSum/ratingCount. Add `isActive` (the free toggle) + `ownerUserId`.
- Entity/model `BusinessProfile` (new) + datasource/repo.
- Replace the one-time flow (`business_account_screen.dart:231-317`) with a
  **switch**: Platinum → toggle `businessProfiles/{uid}.isActive`; non-Platinum →
  the shop Membership-tab upsell (already wired). `isActive=false` hides the
  storefront everywhere and blocks business chat.

**4b — Storefront-only view + discovery**
- `business_storefront_screen.dart` reads the `BusinessProfile` doc; shows
  store name/logo/cover/category/hours/gallery — **not** the person behind it.
- `storefront_editor_screen.dart` writes to `businessProfiles/{uid}`.
- **Explore "Storefronts near you"** (with images): new query over
  `businessProfiles where isActive == true` (+ geo/city), replacing/augmenting the
  current `profiles.where(isBusiness)` surfaces (`explore_screen.dart:886/1036`).
  Rename section title → "Storefronts near you".

**4c — Exchanges "Business" tab + chat identity + group/community exclusion**
- **Business tab**: `chat/presentation/screens/conversations_screen.dart` — add a
  3rd tab (Messages / Groups / **Business**) shown only when the user's storefront
  `isActive`. Route business-directed conversations there.
- **Separate chat identity**: `chat_remote_datasource.dart getOrCreateSearchConversation`
  keys on userId pairs. Add a business-tagged conversation (e.g.
  `conversationType: 'business'` + `businessId`) created by
  `business_contact_button.dart` → shows under the owner's Business tab, and as
  the storefront to the customer. Personal Messages stay separate.
- **Group/community exclusion (search allowed, add/join blocked)**: storefront
  identity remains searchable (people/business/universal search untouched), but
  the storefront cannot be *added/joined*:
  - Groups: guard add-participant (`create_group_screen` / add-member paths) to
    reject business identities.
  - Communities: guard join/add (`joinCommunity` call sites + join_requests) so a
    storefront identity can't become a member.

**4d — Profile display + rules/indexes**
- Profile detail: name + verification badge + age **prominent**, business flag
  **below** (adjust `discovery/.../profile_detail_screen.dart` header order).
- Rules: `businessProfiles/{uid}` — public read, owner-only write; keep the
  existing B2B collections (already uid-keyed). Add geo/city index for the
  storefronts query.

---

## PHASE 5 — Per-page first-time guided tours

Infra already exists: `showcaseview` + `app_tour/.../tour_controller.dart`
(`maybeStartMiniTour({tourId, userId, keys})`, per-user first-open tracking in
SharedPreferences). For each main page add: a unique `tourId`, `GlobalKey`s, a
`ShowCaseWidget` host, `TourShowcase`-wrapped targets, and a post-frame
`maybeStartMiniTour(...)`. Register new tourIds in `resetAllTours`
(`tour_controller.dart:153-159`). Pages: Explore, Discover, Exchanges,
Communities, Events, Profile, Shop, Notifications.

---

## Suggested sequencing
Phase 0 (fast) → Phase 2 (Featured events) → Phase 1 (Community controls) →
Phase 3 (Membership copy + lists) → **Phase 4 (Storefront dualism, 4a→4d)** →
Phase 5 (Tours). Phase 4 is the centerpiece and unblocks the most requests; its
sub-phases each build/verify independently.
