import '../../generated/app_localizations.dart';

/// How far away another user is, in coarse buckets (security P1-4).
///
/// Other users' positions are only known approximately (`approxLocation`:
/// a ~4.9 km geohash cell centre plus a stable offset of up to 1.5 km), so an
/// exact "1.3 km away" would be both misleading and a trilateration aid.
/// Every distance to ANOTHER person is shown as one of these buckets.
enum DistanceBucket {
  under2Km,
  from2To5Km,
  from5To10Km,
  from10To25Km,
  over25Km
}

/// The bucket for [km], or null when the distance is unknown (null, NaN,
/// infinite or negative).
DistanceBucket? distanceBucketFor(double? km) {
  if (km == null || km.isNaN || km.isInfinite || km < 0) return null;
  if (km < 2) return DistanceBucket.under2Km;
  if (km < 5) return DistanceBucket.from2To5Km;
  if (km < 10) return DistanceBucket.from5To10Km;
  if (km < 25) return DistanceBucket.from10To25Km;
  return DistanceBucket.over25Km;
}

/// Localized label of [bucket].
String distanceBucketText(AppLocalizations l10n, DistanceBucket bucket) {
  switch (bucket) {
    case DistanceBucket.under2Km:
      return l10n.distanceBucketUnder2Km;
    case DistanceBucket.from2To5Km:
      return l10n.distanceBucket2To5Km;
    case DistanceBucket.from5To10Km:
      return l10n.distanceBucket5To10Km;
    case DistanceBucket.from10To25Km:
      return l10n.distanceBucket10To25Km;
    case DistanceBucket.over25Km:
      return l10n.distanceBucketOver25Km;
  }
}

/// Localized bucket label for [km], or '' when unknown. With
/// [zeroIsUnknown] a distance of exactly 0 (the "no location" default of the
/// candidate models) is also treated as unknown.
String distanceLabel(AppLocalizations l10n, double? km,
    {bool zeroIsUnknown = true}) {
  if (zeroIsUnknown && km == 0) return '';
  final bucket = distanceBucketFor(km);
  return bucket == null ? '' : distanceBucketText(l10n, bucket);
}
