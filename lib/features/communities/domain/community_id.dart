import 'dart:math' as math;

const String _kIdAlphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

/// A new community document id, generated ON THE CLIENT once per create form.
///
/// Same shape as a Firestore auto-id (20 chars, 62-symbol alphabet, secure
/// RNG). Because the create form keeps this id for its whole lifetime, a
/// second tap on "Create" (or a retry after a slow network) writes the SAME
/// `communities/{id}` doc instead of adding a duplicate community.
String newCommunityId([math.Random? random]) {
  final rng = random ?? math.Random.secure();
  return String.fromCharCodes(
    List.generate(
      20,
      (_) => _kIdAlphabet.codeUnitAt(rng.nextInt(_kIdAlphabet.length)),
    ),
  );
}
