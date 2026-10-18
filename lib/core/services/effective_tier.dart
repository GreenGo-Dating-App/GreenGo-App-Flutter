import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/membership/domain/entities/membership.dart';

/// THE single place that decides which membership tier a user is ENTITLED to
/// right now.
///
/// Source of truth is `profiles/{uid}`:
///   • `membershipTier`  — 'PLATINUM' | 'GOLD' | 'SILVER' | 'BASIC' | 'FREE' | 'TEST'
///   • `membershipEndDate` — when the paid tier stops
///   • `hasBaseMembership` + `baseMembershipEndDate` — the SEPARATE Base plan
///
/// The stored `membershipTier` string is NOT trusted on its own: the server
/// downgrade job runs on a schedule, so between the end date and that job the
/// document still says e.g. 'PLATINUM'. Every gate, limit and tier badge must
/// go through [effectiveTier] / [effectiveTierFromDoc] / `Profile.effectiveTier`.
///
/// Mirrors on `users/{uid}` (`subscriptionTier`, lowercase `membershipTier`,
/// `subscriptionExpiryDate`, …) and `memberships/*` drift and are never used
/// for gating.
///
/// Rules:
///   • TEST stays TEST (internal testers).
///   • Admins keep their stored tier (the admin seed has no end date).
///   • SILVER / GOLD / PLATINUM are only active while `endDate` is after
///     `now`. A missing end date means NOT active — no server writer grants a
///     paid tier without an end date.
///   • 'BASIC' / 'BASE' / 'FREE' / unknown → FREE (Base is tracked by
///     [isBaseMembershipActive], not by the tier).
MembershipTier effectiveTier({
  String? rawTier,
  DateTime? endDate,
  bool isAdmin = false,
  DateTime? now,
}) =>
    effectiveTierOf(
      MembershipTier.fromString(rawTier),
      endDate,
      isAdmin: isAdmin,
      now: now,
    );

/// [effectiveTier] for an already-parsed stored tier.
MembershipTier effectiveTierOf(
  MembershipTier stored,
  DateTime? endDate, {
  bool isAdmin = false,
  DateTime? now,
}) {
  if (stored == MembershipTier.test) return MembershipTier.test;
  if (isAdmin) return stored;
  if (stored == MembershipTier.free) return MembershipTier.free;
  if (endDate == null) return MembershipTier.free;
  return endDate.isAfter(now ?? DateTime.now()) ? stored : MembershipTier.free;
}

/// Whether the user currently holds ANY membership that lets them interact:
/// an active paid tier, an active Base membership, or TEST.
///
/// Same semantics as `Profile.isBaseMembershipActive`.
bool isBaseMembershipActive({
  required MembershipTier effective,
  bool hasBaseMembership = false,
  DateTime? baseMembershipEndDate,
  DateTime? now,
}) {
  if (effective != MembershipTier.free) return true; // active paid / TEST
  return hasBaseMembership &&
      baseMembershipEndDate != null &&
      baseMembershipEndDate.isAfter(now ?? DateTime.now());
}

/// Apple 3.1.2(b) (and owner rule, all platforms): Silver / Gold / Platinum
/// already include everything Base gives, so while one of them is ACTIVE
/// ([effective] from [effectiveTier]) Base is shown as "Included in your plan"
/// and is never offered for sale on top of it.
bool baseIncludedInPaidTier(MembershipTier effective) =>
    effective == MembershipTier.silver ||
    effective == MembershipTier.gold ||
    effective == MembershipTier.platinum;

/// Converts a Firestore value (Timestamp / DateTime / millis / ISO string) to
/// a [DateTime]; null when absent or unparseable.
DateTime? tierDateFromValue(Object? v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// [effectiveTier] computed straight from a raw `profiles/{uid}` document.
/// A null / empty document resolves to FREE.
MembershipTier effectiveTierFromDoc(Map<String, dynamic>? data,
    {DateTime? now}) {
  if (data == null) return MembershipTier.free;
  return effectiveTier(
    rawTier: data['membershipTier'] as String?,
    endDate: tierDateFromValue(data['membershipEndDate']),
    isAdmin: data['isAdmin'] == true,
    now: now,
  );
}

/// [isBaseMembershipActive] computed straight from a raw `profiles/{uid}`
/// document.
bool isBaseMembershipActiveFromDoc(Map<String, dynamic>? data,
    {DateTime? now}) {
  if (data == null) return false;
  return isBaseMembershipActive(
    effective: effectiveTierFromDoc(data, now: now),
    hasBaseMembership: data['hasBaseMembership'] == true,
    baseMembershipEndDate: tierDateFromValue(data['baseMembershipEndDate']),
    now: now,
  );
}

/// Server refusal code for a participation attempt without Base (callables
/// `createTicketCheckout` / `createBooking`, functions/src/shared/participation.ts).
const String kBaseMembershipRequiredCode = 'base_membership_required';

/// Owner rule (2026-10-11): joining events (going / waitlist / tickets) and
/// booking experiences needs the Base membership; an active paid tier or TEST
/// counts too. THE same predicate as 1:1 chat ([isBaseMembershipActive]),
/// mirrored by `canParticipate()` in the Firestore rules and `hasBaseAccess()`
/// on the server. For a [Profile] use `BaseMembershipGate.canParticipate`.
bool canParticipateFromDoc(Map<String, dynamic>? data, {DateTime? now}) =>
    isBaseMembershipActiveFromDoc(data, now: now);

/// The next instant (strictly after [now]) at which the effective tier or the
/// Base membership of this user changes on its own — i.e. the soonest future
/// `membershipEndDate` / `baseMembershipEndDate` that is still in force.
/// null when nothing is scheduled to lapse.
DateTime? nextEntitlementChange({
  required MembershipTier stored,
  DateTime? endDate,
  bool isAdmin = false,
  bool hasBaseMembership = false,
  DateTime? baseMembershipEndDate,
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  DateTime? next;
  if (stored != MembershipTier.test &&
      stored != MembershipTier.free &&
      !isAdmin &&
      endDate != null &&
      endDate.isAfter(n)) {
    next = endDate;
  }
  if (hasBaseMembership &&
      baseMembershipEndDate != null &&
      baseMembershipEndDate.isAfter(n) &&
      (next == null || baseMembershipEndDate.isBefore(next))) {
    next = baseMembershipEndDate;
  }
  return next;
}
