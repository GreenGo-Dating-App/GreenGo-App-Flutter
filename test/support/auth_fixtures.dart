import 'package:greengo_chat/core/services/access_control_service.dart';
import 'package:greengo_chat/features/authentication/domain/entities/user.dart';
import 'package:greengo_chat/features/authentication/domain/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

/// Auth & Session test fixtures — owned by the auth/onboarding test suite.
/// (Kept separate from test/support/mock_data.dart, which other agents share.)
/// See docs/testing/GREENGO_MASTER_TEST_PLAN.md — A. Authentication & Session.

/// A fixed, non-flaky clock for anything that would otherwise call
/// DateTime.now() inside a fixture.
final DateTime kFixedNow = DateTime(2026, 7, 15, 12);

/// Builds a deterministic domain [User] for auth tests.
User buildTestUser({
  String id = 'test_uid_1',
  String email = 'ava@greengo.app',
  String? displayName = 'Ava Reyes',
  String? photoUrl,
  bool emailVerified = true,
  DateTime? createdAt,
  DateTime? lastLoginAt,
}) {
  return User(
    id: id,
    email: email,
    displayName: displayName,
    photoUrl: photoUrl,
    emailVerified: emailVerified,
    createdAt: createdAt ?? kFixedNow,
    lastLoginAt: lastLoginAt,
  );
}

/// Mocktail double for the auth repository injected into [AuthBloc].
class MockAuthRepository extends Mock implements AuthRepository {}

/// Mocktail double for the access-control service. Using a Mock (rather than
/// the real class) avoids the real constructor, which touches
/// FirebaseFirestore.instance / FirebaseAuth.instance.
class MockAccessControlService extends Mock implements AccessControlService {}
