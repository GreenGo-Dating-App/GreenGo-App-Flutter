import '../../../core/utils/display_image.dart';
import '../../events/domain/entities/external_event.dart';
import '../../user_experiences/domain/entities/user_experience.dart';

/// One card of Explore "Top experiences": a member-hosted experience
/// ([community], optionally [featured]) or a partner (Viator) one ([partner]).
class TopExperienceItem {
  const TopExperienceItem.community(UserExperience this.community,
      {this.featured = false})
      : partner = null;
  const TopExperienceItem.partner(ExternalEvent this.partner)
      : community = null,
        featured = false;

  final UserExperience? community;
  final ExternalEvent? partner;

  /// Promoted (tier 1): `isFeatured && featuredUntil > now` when built.
  final bool featured;

  /// Stable de-duplication / cache key: `u:<id>` member, `x:<id>` partner.
  String get key =>
      community != null ? 'u:${community!.id}' : 'x:${partner!.id}';
}

/// How many cards "Top experiences" shows.
const int kTopExperiencesLimit = 20;

/// Bayesian prior for [weightedRating]: an experience is assumed to hold
/// [kRatingPriorWeight] virtual reviews of [kRatingPriorMean] stars.
const double kRatingPriorMean = 3.5;
const int kRatingPriorWeight = 5;

/// With a known location, community experiences within this many km are
/// ranked before farther (or unlocated) ones.
const double kTopExperiencesNearKm = 50;

/// Weighted (Bayesian) average rating:
///
///   W = (C·m + R·v) / (C + v)
///
/// R = the experience's average rating, v = its rating count, m =
/// [kRatingPriorMean] (3.5★), C = [kRatingPriorWeight] (5). Few reviews stay
/// close to the prior; many reviews converge on the real average — so one
/// 5★ review (W = 3.75) never beats forty 4.5★ reviews (W ≈ 4.39). Unrated
/// experiences score exactly m.
double weightedRating(UserExperience e) {
  final v = e.ratingCount < 0 ? 0 : e.ratingCount;
  final r = e.averageRating;
  return (kRatingPriorWeight * kRatingPriorMean + r * v) /
      (kRatingPriorWeight + v);
}

/// Builds Explore "Top experiences" — up to [limit] cards, de-duplicated,
/// filled strictly in this order:
///
/// Only items with a picture are ever returned ([experienceHasPicture],
/// [externalEventHasPicture]).
///
///  1. FEATURED published member experiences (`isFeatured && featuredUntil >
///     now`, from either list — an expired promotion falls back to tier 2):
///     nearest first when [distanceKm] is given, else latest `featuredUntil`
///     first, ties by [weightedRating];
///  2. other PUBLISHED member experiences by [weightedRating] (desc; ties: more
///     ratings, then id). With [distanceKm], those within [nearKm] come first;
///  3. PARTNER experiences (with an image) in the given order (the caller's
///     pager is nearest-first), filling the remaining slots.
///
/// Pure: no I/O, no clock unless [now] is omitted. Exclusions (blocked users,
/// banned hosts) are the caller's job — pass only what may be shown.
List<TopExperienceItem> buildTopExperiences(
  List<UserExperience> featured,
  List<UserExperience> community,
  List<ExternalEvent> partner, {
  int limit = kTopExperiencesLimit,
  DateTime? now,
  double? Function(UserExperience e)? distanceKm,
  double nearKm = kTopExperiencesNearKm,
}) {
  if (limit <= 0) return const <TopExperienceItem>[];
  final at = now ?? DateTime.now();
  final out = <TopExperienceItem>[];
  final seen = <String>{};

  // Unique published member experiences across both lists (first wins).
  final pool = <String, UserExperience>{};
  for (final e in [...featured, ...community]) {
    // Pictures only (see experienceHasPicture).
    if (e.id.isEmpty || !e.isPublished || !experienceHasPicture(e)) continue;
    pool.putIfAbsent(e.id, () => e);
  }

  int byRating(UserExperience a, UserExperience b) {
    final w = weightedRating(b).compareTo(weightedRating(a));
    if (w != 0) return w;
    final c = b.ratingCount.compareTo(a.ratingCount);
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  // 1 — featured.
  final promoted =
      pool.values.where((e) => e.isCurrentlyFeaturedAt(at)).toList();
  if (distanceKm != null) {
    promoted.sort((a, b) {
      final da = distanceKm(a) ?? double.infinity;
      final db = distanceKm(b) ?? double.infinity;
      final d = da.compareTo(db);
      return d != 0 ? d : byRating(a, b);
    });
  } else {
    promoted.sort((a, b) {
      final u = b.featuredUntil!.compareTo(a.featuredUntil!);
      return u != 0 ? u : byRating(a, b);
    });
  }
  for (final e in promoted) {
    if (out.length >= limit) return out;
    if (seen.add('u:${e.id}')) {
      out.add(TopExperienceItem.community(e, featured: true));
    }
  }

  // 2 — the rest of the member experiences, best rated (nearby first).
  final rest = pool.values.where((e) => !seen.contains('u:${e.id}')).toList();
  bool near(UserExperience e) {
    if (distanceKm == null) return true; // no location → one tier
    final d = distanceKm(e);
    return d != null && d <= nearKm;
  }

  rest.sort((a, b) {
    final na = near(a), nb = near(b);
    if (na != nb) return na ? -1 : 1;
    return byRating(a, b);
  });
  for (final e in rest) {
    if (out.length >= limit) return out;
    if (seen.add('u:${e.id}')) out.add(TopExperienceItem.community(e));
  }

  // 3 — partner experiences fill what is left.
  for (final p in partner) {
    if (out.length >= limit) break;
    if (p.id.isEmpty || !externalEventHasPicture(p)) continue;
    if (seen.add('x:${p.id}')) out.add(TopExperienceItem.partner(p));
  }
  return out;
}
