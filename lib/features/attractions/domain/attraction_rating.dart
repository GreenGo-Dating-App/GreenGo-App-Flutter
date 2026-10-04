/// GreenGo users' rating of a catalogue attraction, read from the
/// server-owned aggregate on `attraction_stats/{attractionId}`
/// (ratingSum / ratingCount / ratingAvg — maintained by the
/// `onAttractionRatingWritten` Cloud Function; no client writes them).
class AttractionRatingSummary {
  const AttractionRatingSummary({required this.sum, required this.count});

  /// Sum of every user's stars.
  final int sum;

  /// Number of users who rated. `<= 0` means "no ratings".
  final int count;

  static const AttractionRatingSummary empty =
      AttractionRatingSummary(sum: 0, count: 0);

  bool get hasRatings => count > 0 && sum >= count && sum <= 5 * count;

  /// Average stars (1..5), or 0 when there are no (consistent) ratings.
  double get average => hasRatings ? sum / count : 0;

  /// From an `attraction_stats` document (missing fields = no ratings).
  factory AttractionRatingSummary.fromStats(Map<String, dynamic>? m) {
    if (m == null) return empty;
    final sum = (m['ratingSum'] as num?)?.toInt() ?? 0;
    final count = (m['ratingCount'] as num?)?.toInt() ?? 0;
    return AttractionRatingSummary(sum: sum, count: count);
  }

  /// The summary after the current user changes their own rating from
  /// [oldStars] to [newStars] (null = no rating). Used for the optimistic
  /// update before the server aggregate catches up.
  AttractionRatingSummary withUserChange(int? oldStars, int? newStars) {
    final s = sum - (oldStars ?? 0) + (newStars ?? 0);
    final c = count - (oldStars != null ? 1 : 0) + (newStars != null ? 1 : 0);
    return AttractionRatingSummary(sum: s, count: c);
  }

  /// Compact persisted form: [sum, count].
  List<int> toJson() => [sum, count];

  static AttractionRatingSummary? fromJson(Object? v) {
    if (v is List && v.length == 2 && v[0] is num && v[1] is num) {
      return AttractionRatingSummary(
          sum: (v[0] as num).toInt(), count: (v[1] as num).toInt());
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is AttractionRatingSummary &&
      other.sum == sum &&
      other.count == count;

  @override
  int get hashCode => Object.hash(sum, count);

  @override
  String toString() => 'AttractionRatingSummary($sum/$count)';
}

/// What a card shows on its rating line.
class AttractionRatingDisplay {
  const AttractionRatingDisplay._(this.value, this.count);

  /// Stars, 1 decimal when rendered.
  final double value;

  /// Number of GreenGo ratings; null for the Google rating fallback.
  final int? count;

  bool get isGreenGo => count != null;

  /// "4.6" — always one decimal.
  String get valueLabel => value.toStringAsFixed(1);

  /// The display rule: GreenGo users' rating when anyone rated, else the
  /// Google rating when the catalogue has one, else nothing (null).
  static AttractionRatingDisplay? of(
      AttractionRatingSummary? greengo, double? googleRating) {
    if (greengo != null && greengo.hasRatings) {
      return AttractionRatingDisplay._(greengo.average, greengo.count);
    }
    if (googleRating != null && googleRating > 0) {
      return AttractionRatingDisplay._(googleRating, null);
    }
    return null;
  }
}
