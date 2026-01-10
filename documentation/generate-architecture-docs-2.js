const fs = require('fs');
const path = require('path');

// Remaining Architecture Pages (13, 15-20)
const architecturePages = [
    {
        file: '13-repository-pattern.html',
        title: 'Repository Pattern',
        content: `
            <h2>Repository Pattern Architecture</h2>
            <p>The Repository Pattern provides an abstraction layer between the domain and data mapping layers, acting as an in-memory collection of domain objects. In GreenGo, repositories handle all data operations while hiding the complexity of data sources.</p>

            <div class="info-box">
                <strong>Purpose:</strong> Decouple business logic from data access logic, enabling testability and flexibility in data source changes.
            </div>

            <h2>Repository Architecture Diagram</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                        REPOSITORY PATTERN FLOW                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   USE CASE      │     │   REPOSITORY    │     │  DATA SOURCE    │
│   (Domain)      │────▶│   (Interface)   │────▶│  (Implementation)│
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
            ┌───────▼───────┐     ┌───────▼───────┐
            │   REMOTE      │     │    LOCAL      │
            │   (Firebase)  │     │   (Hive/SQL)  │
            └───────────────┘     └───────────────┘
            </code></pre>

            <h2>Detailed Repository Structure</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                    REPOSITORY IMPLEMENTATION LAYERS                      │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│  DOMAIN LAYER (lib/features/*/domain/repositories/)                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  abstract class UserRepository {                                 │   │
│  │    Future<Either<Failure, User>> getUser(String id);            │   │
│  │    Future<Either<Failure, void>> updateUser(User user);         │   │
│  │    Future<Either<Failure, List<User>>> searchUsers(Query q);    │   │
│  │    Stream<Either<Failure, User>> watchUser(String id);          │   │
│  │  }                                                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ implements
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  DATA LAYER (lib/features/*/data/repositories/)                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  class UserRepositoryImpl implements UserRepository {            │   │
│  │    final UserRemoteDataSource remoteDataSource;                  │   │
│  │    final UserLocalDataSource localDataSource;                    │   │
│  │    final NetworkInfo networkInfo;                                │   │
│  │                                                                   │   │
│  │    @override                                                      │   │
│  │    Future<Either<Failure, User>> getUser(String id) async {      │   │
│  │      if (await networkInfo.isConnected) {                        │   │
│  │        try {                                                      │   │
│  │          final user = await remoteDataSource.getUser(id);        │   │
│  │          await localDataSource.cacheUser(user);                  │   │
│  │          return Right(user.toEntity());                          │   │
│  │        } on ServerException catch (e) {                          │   │
│  │          return Left(ServerFailure(e.message));                  │   │
│  │        }                                                          │   │
│  │      } else {                                                     │   │
│  │        try {                                                      │   │
│  │          final user = await localDataSource.getCachedUser(id);   │   │
│  │          return Right(user.toEntity());                          │   │
│  │        } on CacheException {                                      │   │
│  │          return Left(CacheFailure());                            │   │
│  │        }                                                          │   │
│  │      }                                                            │   │
│  │    }                                                              │   │
│  │  }                                                                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
            </code></pre>

            <h2>Data Source Architecture</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                        DATA SOURCE HIERARCHY                             │
└─────────────────────────────────────────────────────────────────────────┘

                    ┌─────────────────────┐
                    │   DataSource        │
                    │   (Abstract)        │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
     ┌────────▼────────┐ ┌─────▼─────┐ ┌───────▼───────┐
     │ RemoteDataSource│ │LocalSource│ │ CacheSource   │
     │ (Firebase/API)  │ │ (SQLite)  │ │ (Hive/Memory) │
     └────────┬────────┘ └─────┬─────┘ └───────┬───────┘
              │                │               │
     ┌────────▼────────┐ ┌─────▼─────┐ ┌───────▼───────┐
     │• Firestore      │ │• User DB  │ │• Profile Cache│
     │• Cloud Storage  │ │• Chat DB  │ │• Match Cache  │
     │• Cloud Functions│ │• Settings │ │• Search Cache │
     └─────────────────┘ └───────────┘ └───────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│  REMOTE DATA SOURCE IMPLEMENTATION                                      │
│  File: lib/features/auth/data/datasources/auth_remote_datasource.dart   │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  abstract class AuthRemoteDataSource {                           │   │
│  │    Future<UserModel> signInWithEmail(String email, String pass); │   │
│  │    Future<UserModel> signUpWithEmail(String email, String pass); │   │
│  │    Future<void> signOut();                                       │   │
│  │    Future<UserModel> getCurrentUser();                           │   │
│  │    Stream<UserModel?> get authStateChanges;                      │   │
│  │  }                                                               │   │
│  │                                                                   │   │
│  │  class AuthRemoteDataSourceImpl implements AuthRemoteDataSource { │   │
│  │    final FirebaseAuth _auth;                                      │   │
│  │    final FirebaseFirestore _firestore;                            │   │
│  │                                                                   │   │
│  │    @override                                                      │   │
│  │    Future<UserModel> signInWithEmail(                             │   │
│  │      String email, String password                                │   │
│  │    ) async {                                                      │   │
│  │      final credential = await _auth.signInWithEmailAndPassword(   │   │
│  │        email: email, password: password                           │   │
│  │      );                                                           │   │
│  │      final doc = await _firestore                                 │   │
│  │        .collection('users')                                       │   │
│  │        .doc(credential.user!.uid)                                 │   │
│  │        .get();                                                    │   │
│  │      return UserModel.fromFirestore(doc);                         │   │
│  │    }                                                              │   │
│  │  }                                                                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
            </code></pre>

            <h2>Repository Data Flow Sequence</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│              REPOSITORY GET USER DATA FLOW SEQUENCE                      │
└─────────────────────────────────────────────────────────────────────────┘

 BLoC          UseCase       Repository      Remote         Local       Network
  │               │              │             │              │            │
  │ GetUser(id)   │              │             │              │            │
  │──────────────▶│              │             │              │            │
  │               │ call(id)     │             │              │            │
  │               │─────────────▶│             │              │            │
  │               │              │ isConnected │              │            │
  │               │              │─────────────┼──────────────┼───────────▶│
  │               │              │             │              │    true    │
  │               │              │◀────────────┼──────────────┼────────────│
  │               │              │             │              │            │
  │               │              │ getUser(id) │              │            │
  │               │              │────────────▶│              │            │
  │               │              │             │ Firestore    │            │
  │               │              │             │ Query        │            │
  │               │              │  UserModel  │              │            │
  │               │              │◀────────────│              │            │
  │               │              │             │              │            │
  │               │              │ cacheUser() │              │            │
  │               │              │─────────────┼─────────────▶│            │
  │               │              │             │     saved    │            │
  │               │              │◀────────────┼──────────────│            │
  │               │              │             │              │            │
  │               │ Right(User)  │             │              │            │
  │               │◀─────────────│             │              │            │
  │ Right(User)   │              │             │              │            │
  │◀──────────────│              │             │              │            │
  │               │              │             │              │            │
            </code></pre>

            <h2>Complete Repository Examples</h2>
            <h3>User Repository</h3>
            <p><strong>File:</strong> <code>lib/features/profile/domain/repositories/user_repository.dart</code></p>
            <pre><code class="language-dart">
abstract class UserRepository {
  /// Get user by ID
  Future<Either<Failure, UserEntity>> getUser(String userId);

  /// Get current authenticated user
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Update user profile
  Future<Either<Failure, void>> updateProfile(UserEntity user);

  /// Upload profile photo
  Future<Either<Failure, String>> uploadPhoto(File photo, int index);

  /// Delete profile photo
  Future<Either<Failure, void>> deletePhoto(String photoUrl);

  /// Update user location
  Future<Either<Failure, void>> updateLocation(GeoPoint location);

  /// Watch user changes in real-time
  Stream<Either<Failure, UserEntity>> watchUser(String userId);

  /// Search users with filters
  Future<Either<Failure, List<UserEntity>>> searchUsers(SearchFilters filters);

  /// Block a user
  Future<Either<Failure, void>> blockUser(String userId);

  /// Report a user
  Future<Either<Failure, void>> reportUser(String userId, String reason);
}
            </code></pre>

            <h3>Match Repository</h3>
            <p><strong>File:</strong> <code>lib/features/matching/domain/repositories/match_repository.dart</code></p>
            <pre><code class="language-dart">
abstract class MatchRepository {
  /// Get potential matches for user
  Future<Either<Failure, List<MatchCandidate>>> getPotentialMatches({
    required String userId,
    required int limit,
    required MatchFilters filters,
  });

  /// Record swipe action
  Future<Either<Failure, SwipeResult>> recordSwipe({
    required String swiperId,
    required String swipedId,
    required SwipeType type,
  });

  /// Get all matches for user
  Future<Either<Failure, List<Match>>> getMatches(String userId);

  /// Watch matches in real-time
  Stream<Either<Failure, List<Match>>> watchMatches(String userId);

  /// Unmatch with user
  Future<Either<Failure, void>> unmatch(String matchId);

  /// Get match compatibility score
  Future<Either<Failure, double>> getCompatibilityScore(
    String userId1,
    String userId2
  );
}
            </code></pre>

            <h2>Repository Registration</h2>
            <p><strong>File:</strong> <code>lib/core/di/injection_container.dart</code></p>
            <pre><code class="language-dart">
// Repository registrations
void _initRepositories() {
  // Auth Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // User Repository
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      cacheManager: sl(),
    ),
  );

  // Match Repository
  sl.registerLazySingleton<MatchRepository>(
    () => MatchRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      mlService: sl(),
    ),
  );

  // Chat Repository
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      encryptionService: sl(),
    ),
  );
}
            </code></pre>

            <h2>Offline-First Repository Strategy</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                    OFFLINE-FIRST DATA STRATEGY                           │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   REQUEST       │     │   CHECK         │     │   FETCH         │
│   RECEIVED      │────▶│   NETWORK       │────▶│   DATA          │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │                        │
                    ┌──────────┴──────────┐    ┌────────┴────────┐
                    │                     │    │                 │
            ┌───────▼───────┐     ┌───────▼────▼──┐     ┌────────▼───────┐
            │   ONLINE      │     │   OFFLINE     │     │   CACHE        │
            │               │     │               │     │   UPDATE       │
            └───────┬───────┘     └───────┬───────┘     └────────────────┘
                    │                     │
            ┌───────▼───────┐     ┌───────▼───────┐
            │ Remote First  │     │ Cache First   │
            │ Then Cache    │     │ Queue Sync    │
            └───────────────┘     └───────────────┘

Strategy Implementation:
┌─────────────────────────────────────────────────────────────────┐
│ 1. CACHE FIRST (Read Operations)                                │
│    - Check local cache for data                                 │
│    - Return cached data immediately                             │
│    - Fetch fresh data in background                             │
│    - Update cache and notify listeners                          │
├─────────────────────────────────────────────────────────────────┤
│ 2. NETWORK FIRST (Write Operations)                             │
│    - Attempt remote write first                                 │
│    - On success: update local cache                             │
│    - On failure: queue for retry, update local optimistically   │
├─────────────────────────────────────────────────────────────────┤
│ 3. SYNC QUEUE (Offline Changes)                                 │
│    - Store pending operations in queue                          │
│    - Retry on connectivity restored                             │
│    - Handle conflicts with server data                          │
└─────────────────────────────────────────────────────────────────┘
            </code></pre>

            <h2>Best Practices</h2>
            <table>
                <thead>
                    <tr><th>Practice</th><th>Description</th><th>Implementation</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Single Responsibility</strong></td>
                        <td>Each repository handles one aggregate root</td>
                        <td>UserRepository, MatchRepository, ChatRepository</td>
                    </tr>
                    <tr>
                        <td><strong>Dependency Inversion</strong></td>
                        <td>Domain depends on abstractions, not implementations</td>
                        <td>Use Cases reference abstract repository interfaces</td>
                    </tr>
                    <tr>
                        <td><strong>Error Translation</strong></td>
                        <td>Convert exceptions to domain failures</td>
                        <td>ServerException → ServerFailure</td>
                    </tr>
                    <tr>
                        <td><strong>Data Mapping</strong></td>
                        <td>Convert between models and entities</td>
                        <td>UserModel.toEntity(), Entity.toModel()</td>
                    </tr>
                    <tr>
                        <td><strong>Caching Strategy</strong></td>
                        <td>Implement appropriate caching per repository</td>
                        <td>Profile: long cache, Matches: short cache</td>
                    </tr>
                </tbody>
            </table>
        `
    },
    {
        file: '15-error-handling.html',
        title: 'Error Handling',
        content: `
            <h2>Error Handling Architecture</h2>
            <p>GreenGo implements a comprehensive error handling system using the Either type from the dartz package. This functional approach ensures type-safe error handling throughout the application.</p>

            <div class="info-box">
                <strong>Core Principle:</strong> Errors are values, not exceptions. Use Either&lt;Failure, Success&gt; to represent operations that can fail.
            </div>

            <h2>Error Handling Flow Diagram</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                      ERROR HANDLING ARCHITECTURE                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                               │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  BLoC handles Either result:                                     │   │
│  │  result.fold(                                                    │   │
│  │    (failure) => emit(ErrorState(failure.message)),               │   │
│  │    (success) => emit(SuccessState(success)),                     │   │
│  │  );                                                              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    ▲
                                    │ Either<Failure, T>
                                    │
┌─────────────────────────────────────────────────────────────────────────┐
│                           DOMAIN LAYER                                   │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  UseCase returns Either<Failure, T>                              │   │
│  │  - Validates input                                               │   │
│  │  - Calls repository                                              │   │
│  │  - Returns typed result                                          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    ▲
                                    │ Either<Failure, T>
                                    │
┌─────────────────────────────────────────────────────────────────────────┐
│                            DATA LAYER                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Repository catches exceptions and converts to Failures:         │   │
│  │  try {                                                           │   │
│  │    final result = await dataSource.fetch();                      │   │
│  │    return Right(result);                                         │   │
│  │  } on ServerException catch (e) {                                │   │
│  │    return Left(ServerFailure(e.message));                        │   │
│  │  } on CacheException catch (e) {                                 │   │
│  │    return Left(CacheFailure(e.message));                         │   │
│  │  }                                                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
            </code></pre>

            <h2>Failure Hierarchy</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                        FAILURE CLASS HIERARCHY                           │
└─────────────────────────────────────────────────────────────────────────┘

                        ┌─────────────────┐
                        │    Failure      │
                        │   (Abstract)    │
                        └────────┬────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
┌───────▼───────┐       ┌────────▼────────┐      ┌────────▼────────┐
│ ServerFailure │       │  CacheFailure   │      │ NetworkFailure  │
├───────────────┤       ├─────────────────┤      ├─────────────────┤
│• message      │       │• message        │      │• message        │
│• statusCode   │       │• key            │      │• isTimeout      │
│• errorCode    │       │                 │      │                 │
└───────────────┘       └─────────────────┘      └─────────────────┘
        │
        ├─────────────────────────┬─────────────────────────┐
        │                         │                         │
┌───────▼───────┐        ┌────────▼────────┐       ┌────────▼────────┐
│ AuthFailure   │        │ ValidationFail  │       │ PermissionFail  │
├───────────────┤        ├─────────────────┤       ├─────────────────┤
│• invalidCreds │        │• field          │       │• requiredPerm   │
│• tokenExpired │        │• constraint     │       │• currentPerm    │
│• userNotFound │        │• value          │       │                 │
└───────────────┘        └─────────────────┘       └─────────────────┘

File: lib/core/error/failures.dart
            </code></pre>

            <h2>Complete Failure Implementation</h2>
            <p><strong>File:</strong> <code>lib/core/error/failures.dart</code></p>
            <pre><code class="language-dart">
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

// Server/Network Failures
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required String message,
    String? code,
    this.statusCode,
  }) : super(message: message, code: code);

  factory ServerFailure.fromException(ServerException e) {
    return ServerFailure(
      message: e.message,
      code: e.code,
      statusCode: e.statusCode,
    );
  }
}

class NetworkFailure extends Failure {
  final bool isTimeout;

  const NetworkFailure({
    required String message,
    this.isTimeout = false,
  }) : super(message: message, code: 'NETWORK_ERROR');
}

// Cache Failures
class CacheFailure extends Failure {
  const CacheFailure({String message = 'Cache error occurred'})
      : super(message: message, code: 'CACHE_ERROR');
}

// Auth Failures
class AuthFailure extends Failure {
  final AuthFailureType type;

  const AuthFailure({
    required String message,
    required this.type,
  }) : super(message: message, code: type.code);
}

enum AuthFailureType {
  invalidCredentials('INVALID_CREDENTIALS'),
  userNotFound('USER_NOT_FOUND'),
  emailInUse('EMAIL_IN_USE'),
  weakPassword('WEAK_PASSWORD'),
  tokenExpired('TOKEN_EXPIRED'),
  accountDisabled('ACCOUNT_DISABLED'),
  tooManyRequests('TOO_MANY_REQUESTS');

  final String code;
  const AuthFailureType(this.code);
}

// Validation Failures
class ValidationFailure extends Failure {
  final String field;
  final dynamic value;

  const ValidationFailure({
    required String message,
    required this.field,
    this.value,
  }) : super(message: message, code: 'VALIDATION_ERROR');
}

// Permission Failures
class PermissionFailure extends Failure {
  final String requiredPermission;

  const PermissionFailure({
    required String message,
    required this.requiredPermission,
  }) : super(message: message, code: 'PERMISSION_DENIED');
}

// Feature-specific Failures
class MatchFailure extends Failure {
  const MatchFailure({required String message})
      : super(message: message, code: 'MATCH_ERROR');
}

class ChatFailure extends Failure {
  const ChatFailure({required String message})
      : super(message: message, code: 'CHAT_ERROR');
}

class PaymentFailure extends Failure {
  final String? transactionId;

  const PaymentFailure({
    required String message,
    this.transactionId,
  }) : super(message: message, code: 'PAYMENT_ERROR');
}
            </code></pre>

            <h2>Exception Classes</h2>
            <p><strong>File:</strong> <code>lib/core/error/exceptions.dart</code></p>
            <pre><code class="language-dart">
// Base Exception
class AppException implements Exception {
  final String message;
  final String? code;

  AppException({required this.message, this.code});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

// Server Exception
class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required String message,
    String? code,
    this.statusCode,
  }) : super(message: message, code: code);

  factory ServerException.fromFirebaseException(FirebaseException e) {
    return ServerException(
      message: _mapFirebaseError(e.code),
      code: e.code,
    );
  }

  static String _mapFirebaseError(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action';
      case 'not-found':
        return 'The requested resource was not found';
      case 'already-exists':
        return 'This resource already exists';
      case 'resource-exhausted':
        return 'Quota exceeded. Please try again later';
      case 'unauthenticated':
        return 'Authentication required';
      case 'unavailable':
        return 'Service temporarily unavailable';
      default:
        return 'An unexpected error occurred';
    }
  }
}

// Cache Exception
class CacheException extends AppException {
  CacheException({String message = 'Cache error'})
      : super(message: message, code: 'CACHE_ERROR');
}

// Network Exception
class NetworkException extends AppException {
  final bool isTimeout;

  NetworkException({
    required String message,
    this.isTimeout = false,
  }) : super(message: message, code: 'NETWORK_ERROR');
}
            </code></pre>

            <h2>Error Handling in BLoC</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                    BLOC ERROR HANDLING PATTERN                           │
└─────────────────────────────────────────────────────────────────────────┘

  Event              BLoC                UseCase           Result
    │                 │                    │                 │
    │ LoginRequested  │                    │                 │
    │────────────────▶│                    │                 │
    │                 │ emit(Loading)      │                 │
    │                 │────────┐           │                 │
    │                 │        │           │                 │
    │                 │◀───────┘           │                 │
    │                 │                    │                 │
    │                 │ call(params)       │                 │
    │                 │───────────────────▶│                 │
    │                 │                    │ Execute         │
    │                 │                    │────────────────▶│
    │                 │                    │                 │
    │                 │                    │ Either<F,S>     │
    │                 │◀───────────────────│◀────────────────│
    │                 │                    │                 │
    │                 │ result.fold(       │                 │
    │                 │   (f) => Error,    │                 │
    │                 │   (s) => Success   │                 │
    │                 │ )                  │                 │
    │                 │────────┐           │                 │
    │                 │        │           │                 │
    │                 │◀───────┘           │                 │
    │ State Change    │                    │                 │
    │◀────────────────│                    │                 │
            </code></pre>

            <h3>BLoC Implementation Example</h3>
            <p><strong>File:</strong> <code>lib/features/auth/presentation/bloc/auth_bloc.dart</code></p>
            <pre><code class="language-dart">
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase signIn;
  final SignUpUseCase signUp;
  final SignOutUseCase signOut;

  AuthBloc({
    required this.signIn,
    required this.signUp,
    required this.signOut,
  }) : super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await signIn(SignInParams(
      email: event.email,
      password: event.password,
    ));

    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is AuthFailure) {
      switch (failure.type) {
        case AuthFailureType.invalidCredentials:
          return 'Invalid email or password';
        case AuthFailureType.userNotFound:
          return 'No account found with this email';
        case AuthFailureType.accountDisabled:
          return 'This account has been disabled';
        case AuthFailureType.tooManyRequests:
          return 'Too many attempts. Please try again later';
        default:
          return failure.message;
      }
    } else if (failure is NetworkFailure) {
      return failure.isTimeout
          ? 'Connection timed out. Please check your internet'
          : 'No internet connection';
    } else if (failure is ServerFailure) {
      return failure.message;
    }
    return 'An unexpected error occurred';
  }
}
            </code></pre>

            <h2>Global Error Handler</h2>
            <p><strong>File:</strong> <code>lib/core/error/error_handler.dart</code></p>
            <pre><code class="language-dart">
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final _errorController = StreamController<AppError>.broadcast();
  Stream<AppError> get errorStream => _errorController.stream;

  void handleError(dynamic error, StackTrace? stackTrace) {
    final appError = _mapToAppError(error, stackTrace);
    _errorController.add(appError);
    _logError(appError);
  }

  AppError _mapToAppError(dynamic error, StackTrace? stackTrace) {
    if (error is Failure) {
      return AppError(
        message: error.message,
        code: error.code,
        type: _getErrorType(error),
        stackTrace: stackTrace,
      );
    } else if (error is Exception) {
      return AppError(
        message: error.toString(),
        type: ErrorType.unknown,
        stackTrace: stackTrace,
      );
    }
    return AppError(
      message: 'An unexpected error occurred',
      type: ErrorType.unknown,
      stackTrace: stackTrace,
    );
  }

  ErrorType _getErrorType(Failure failure) {
    if (failure is NetworkFailure) return ErrorType.network;
    if (failure is AuthFailure) return ErrorType.auth;
    if (failure is ServerFailure) return ErrorType.server;
    if (failure is ValidationFailure) return ErrorType.validation;
    return ErrorType.unknown;
  }

  void _logError(AppError error) {
    // Log to analytics/crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      error.stackTrace,
      reason: error.message,
    );
  }
}

enum ErrorType { network, auth, server, validation, permission, unknown }

class AppError {
  final String message;
  final String? code;
  final ErrorType type;
  final StackTrace? stackTrace;

  AppError({
    required this.message,
    this.code,
    required this.type,
    this.stackTrace,
  });
}
            </code></pre>

            <h2>UI Error Display</h2>
            <p><strong>File:</strong> <code>lib/core/presentation/widgets/error_display.dart</code></p>
            <pre><code class="language-dart">
class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final ErrorType type;

  const ErrorDisplay({
    required this.message,
    this.onRetry,
    this.type = ErrorType.unknown,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIcon(),
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.auth:
        return Icons.lock_outline;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.permission:
        return Icons.block;
      default:
        return Icons.error_outline;
    }
  }
}
            </code></pre>

            <h2>Error Handling Best Practices</h2>
            <table>
                <thead>
                    <tr><th>Practice</th><th>Description</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Use Either Type</strong></td>
                        <td>Always return Either&lt;Failure, T&gt; from repositories and use cases</td>
                    </tr>
                    <tr>
                        <td><strong>Specific Failures</strong></td>
                        <td>Create specific failure types for different error scenarios</td>
                    </tr>
                    <tr>
                        <td><strong>Map at Boundaries</strong></td>
                        <td>Convert exceptions to failures at the data layer boundary</td>
                    </tr>
                    <tr>
                        <td><strong>User-Friendly Messages</strong></td>
                        <td>Map technical errors to user-friendly messages in BLoC</td>
                    </tr>
                    <tr>
                        <td><strong>Log Everything</strong></td>
                        <td>Log errors to crashlytics with full context</td>
                    </tr>
                    <tr>
                        <td><strong>Retry Logic</strong></td>
                        <td>Implement retry for transient failures (network, timeout)</td>
                    </tr>
                </tbody>
            </table>
        `
    },
    {
        file: '16-navigation.html',
        title: 'Navigation & Routing',
        content: `
            <h2>Navigation Architecture</h2>
            <p>GreenGo uses GoRouter for declarative, type-safe routing with deep linking support. The navigation system handles authentication flows, nested navigation, and route guards.</p>

            <div class="info-box">
                <strong>Key Package:</strong> go_router ^12.0.0<br>
                <strong>Navigation Type:</strong> Declarative with Route Guards
            </div>

            <h2>Navigation Architecture Diagram</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                      NAVIGATION ARCHITECTURE                             │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                           APP ROUTER                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      GoRouter Configuration                      │   │
│  │  • Route definitions                                             │   │
│  │  • Redirect logic                                                │   │
│  │  • Error handling                                                │   │
│  │  • Navigation observers                                          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
            ┌───────▼───────┐ ┌─────▼─────┐ ┌───────▼───────┐
            │  Auth Routes  │ │Main Routes│ │ Modal Routes  │
            │  /login       │ │ /home     │ │ /settings     │
            │  /signup      │ │ /discover │ │ /profile/edit │
            │  /onboarding  │ │ /matches  │ │ /subscription │
            │  /verify      │ │ /chat     │ │               │
            └───────────────┘ └─────┬─────┘ └───────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
            ┌───────▼───────┐ ┌─────▼─────┐ ┌───────▼───────┐
            │  Shell Route  │ │Sub-Routes │ │ Deep Links    │
            │  (Bottom Nav) │ │ /chat/:id │ │ greengo://    │
            └───────────────┘ └───────────┘ └───────────────┘
            </code></pre>

            <h2>Route Flow Diagram</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                        NAVIGATION FLOW                                   │
└─────────────────────────────────────────────────────────────────────────┘

    App Start
        │
        ▼
┌───────────────┐    No     ┌───────────────┐    No     ┌───────────────┐
│ Authenticated?│──────────▶│  Has Profile? │──────────▶│   /login      │
└───────┬───────┘           └───────┬───────┘           └───────────────┘
        │ Yes                       │ Yes
        ▼                           ▼
┌───────────────┐           ┌───────────────┐
│ Profile       │    No     │   /home       │
│ Complete?     │──────────▶│   (Main App)  │
└───────┬───────┘           └───────────────┘
        │ No
        ▼
┌───────────────┐
│  /onboarding  │
│  (8 steps)    │
└───────────────┘

Protected Route Access:
┌───────────────┐           ┌───────────────┐           ┌───────────────┐
│ Navigate to   │──────────▶│ Route Guard   │──────────▶│ Auth Check    │
│ /matches      │           │ Check         │           │               │
└───────────────┘           └───────┬───────┘           └───────┬───────┘
                                    │                           │
                           ┌────────┴────────┐         ┌────────┴────────┐
                           │                 │         │                 │
                    ┌──────▼──────┐   ┌──────▼──────┐  │                 │
                    │ Authorized  │   │Unauthorized │  │                 │
                    │ → /matches  │   │ → /login    │  │                 │
                    └─────────────┘   └─────────────┘  │                 │
            </code></pre>

            <h2>Complete Router Configuration</h2>
            <p><strong>File:</strong> <code>lib/core/navigation/app_router.dart</code></p>
            <pre><code class="language-dart">
import 'package:go_router/go_router.dart';

class AppRouter {
  final AuthRepository authRepository;
  final UserRepository userRepository;

  AppRouter({
    required this.authRepository,
    required this.userRepository,
  });

  late final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: authRepository.authStateListenable,
    redirect: _redirect,
    routes: [
      // Splash/Initial Route
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verifyEmail',
        builder: (context, state) => const VerifyEmailScreen(),
      ),

      // Onboarding Route
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
        routes: [
          GoRoute(
            path: 'step/:step',
            name: 'onboardingStep',
            builder: (context, state) {
              final step = int.parse(state.pathParameters['step']!);
              return OnboardingStepScreen(step: step);
            },
          ),
        ],
      ),

      // Main App Shell Route (with bottom navigation)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/discover',
            name: 'discover',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiscoverScreen(),
            ),
          ),
          GoRoute(
            path: '/matches',
            name: 'matches',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MatchesScreen(),
            ),
          ),
          GoRoute(
            path: '/messages',
            name: 'messages',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MessagesScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Chat Route (outside shell for full screen)
      GoRoute(
        path: '/chat/:matchId',
        name: 'chat',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return ChatScreen(matchId: matchId);
        },
      ),

      // Profile View Route
      GoRoute(
        path: '/user/:userId',
        name: 'userProfile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserProfileScreen(userId: userId);
        },
      ),

      // Settings Routes
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'account',
            name: 'accountSettings',
            builder: (context, state) => const AccountSettingsScreen(),
          ),
          GoRoute(
            path: 'notifications',
            name: 'notificationSettings',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: 'privacy',
            name: 'privacySettings',
            builder: (context, state) => const PrivacySettingsScreen(),
          ),
          GoRoute(
            path: 'subscription',
            name: 'subscription',
            builder: (context, state) => const SubscriptionScreen(),
          ),
        ],
      ),

      // Edit Profile
      GoRoute(
        path: '/edit-profile',
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );

  // Redirect Logic
  String? _redirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = authRepository.isAuthenticated;
    final isOnAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup' ||
        state.matchedLocation == '/forgot-password';
    final isOnOnboarding = state.matchedLocation.startsWith('/onboarding');

    // Not authenticated - redirect to login
    if (!isAuthenticated && !isOnAuthRoute && state.matchedLocation != '/') {
      return '/login';
    }

    // Authenticated but on auth route - redirect to home
    if (isAuthenticated && isOnAuthRoute) {
      // Check if onboarding is complete
      final user = authRepository.currentUser;
      if (user != null && !user.isOnboardingComplete) {
        return '/onboarding';
      }
      return '/home';
    }

    // Authenticated but onboarding incomplete
    if (isAuthenticated && !isOnOnboarding) {
      final user = authRepository.currentUser;
      if (user != null && !user.isOnboardingComplete) {
        return '/onboarding';
      }
    }

    return null; // No redirect
  }
}
            </code></pre>

            <h2>Route Names Constants</h2>
            <p><strong>File:</strong> <code>lib/core/navigation/routes.dart</code></p>
            <pre><code class="language-dart">
abstract class Routes {
  // Auth
  static const login = 'login';
  static const signup = 'signup';
  static const forgotPassword = 'forgotPassword';
  static const verifyEmail = 'verifyEmail';

  // Onboarding
  static const onboarding = 'onboarding';
  static const onboardingStep = 'onboardingStep';

  // Main
  static const home = 'home';
  static const discover = 'discover';
  static const matches = 'matches';
  static const messages = 'messages';
  static const profile = 'profile';

  // Features
  static const chat = 'chat';
  static const userProfile = 'userProfile';
  static const editProfile = 'editProfile';

  // Settings
  static const settings = 'settings';
  static const accountSettings = 'accountSettings';
  static const notificationSettings = 'notificationSettings';
  static const privacySettings = 'privacySettings';
  static const subscription = 'subscription';
}
            </code></pre>

            <h2>Navigation Extensions</h2>
            <p><strong>File:</strong> <code>lib/core/navigation/navigation_extensions.dart</code></p>
            <pre><code class="language-dart">
extension NavigationExtensions on BuildContext {
  // Navigate to named route
  void goToRoute(String name, {Map<String, String>? params}) {
    GoRouter.of(this).goNamed(name, pathParameters: params ?? {});
  }

  // Push named route
  void pushRoute(String name, {Map<String, String>? params, Object? extra}) {
    GoRouter.of(this).pushNamed(
      name,
      pathParameters: params ?? {},
      extra: extra,
    );
  }

  // Pop current route
  void popRoute() {
    GoRouter.of(this).pop();
  }

  // Navigate to chat
  void goToChat(String matchId) {
    GoRouter.of(this).pushNamed(Routes.chat, pathParameters: {'matchId': matchId});
  }

  // Navigate to user profile
  void goToUserProfile(String userId) {
    GoRouter.of(this).pushNamed(Routes.userProfile, pathParameters: {'userId': userId});
  }

  // Navigate to settings
  void goToSettings() {
    GoRouter.of(this).pushNamed(Routes.settings);
  }

  // Go back to home
  void goHome() {
    GoRouter.of(this).goNamed(Routes.home);
  }
}
            </code></pre>

            <h2>Deep Linking Configuration</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                        DEEP LINK HANDLING                                │
└─────────────────────────────────────────────────────────────────────────┘

Supported Deep Links:
┌─────────────────────────────────────────────────────────────────────────┐
│ greengo://chat/ABC123        → Opens chat with match ABC123             │
│ greengo://user/XYZ789        → Opens user profile XYZ789                │
│ greengo://matches            → Opens matches screen                     │
│ greengo://discover           → Opens discover screen                    │
│ greengo://settings/subscription → Opens subscription settings           │
│                                                                         │
│ https://greengo.app/invite/CODE → Handles referral codes                │
│ https://greengo.app/verify?token=X → Handles email verification         │
└─────────────────────────────────────────────────────────────────────────┘

Android Configuration (android/app/src/main/AndroidManifest.xml):
&lt;intent-filter android:autoVerify="true"&gt;
    &lt;action android:name="android.intent.action.VIEW" /&gt;
    &lt;category android:name="android.intent.category.DEFAULT" /&gt;
    &lt;category android:name="android.intent.category.BROWSABLE" /&gt;
    &lt;data android:scheme="greengo" /&gt;
    &lt;data android:scheme="https" android:host="greengo.app" /&gt;
&lt;/intent-filter&gt;

iOS Configuration (ios/Runner/Info.plist):
&lt;key&gt;CFBundleURLTypes&lt;/key&gt;
&lt;array&gt;
    &lt;dict&gt;
        &lt;key&gt;CFBundleURLSchemes&lt;/key&gt;
        &lt;array&gt;
            &lt;string&gt;greengo&lt;/string&gt;
        &lt;/array&gt;
    &lt;/dict&gt;
&lt;/array&gt;
            </code></pre>

            <h2>Navigation Best Practices</h2>
            <table>
                <thead>
                    <tr><th>Practice</th><th>Implementation</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Use Named Routes</strong></td>
                        <td>Always use goNamed() instead of go() for maintainability</td>
                    </tr>
                    <tr>
                        <td><strong>Type-Safe Parameters</strong></td>
                        <td>Use pathParameters with defined keys, validate in route builder</td>
                    </tr>
                    <tr>
                        <td><strong>Shell Routes</strong></td>
                        <td>Use ShellRoute for persistent UI elements (bottom nav)</td>
                    </tr>
                    <tr>
                        <td><strong>Route Guards</strong></td>
                        <td>Implement redirect logic for authentication and authorization</td>
                    </tr>
                    <tr>
                        <td><strong>Deep Link Testing</strong></td>
                        <td>Test all deep links on both platforms before release</td>
                    </tr>
                </tbody>
            </table>
        `
    },
    {
        file: '17-api-layer.html',
        title: 'API & Network Layer',
        content: `
            <h2>API Layer Architecture</h2>
            <p>GreenGo's API layer handles all network communication with Firebase services and external APIs. It implements retry logic, request/response interceptors, and comprehensive error handling.</p>

            <h2>Network Architecture Diagram</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                       NETWORK LAYER ARCHITECTURE                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         DATA SOURCES                                     │
└─────────────────────────────────────────────────────────────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│   Firebase    │       │  Cloud        │       │  External     │
│   Services    │       │  Functions    │       │  APIs         │
├───────────────┤       ├───────────────┤       ├───────────────┤
│• Firestore    │       │• HTTPS        │       │• Agora        │
│• Auth         │       │• Callable     │       │• Stripe       │
│• Storage      │       │• Scheduled    │       │• SendGrid     │
│• Messaging    │       │               │       │• Google Maps  │
└───────┬───────┘       └───────┬───────┘       └───────┬───────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │   Network Manager     │
                    │   • Connectivity      │
                    │   • Retry Logic       │
                    │   • Request Queue     │
                    └───────────────────────┘
            </code></pre>

            <h2>Request Flow Sequence</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                     API REQUEST FLOW SEQUENCE                            │
└─────────────────────────────────────────────────────────────────────────┘

 Repository     DataSource    ApiClient     Interceptor    Firebase
     │              │             │              │            │
     │ getData()    │             │              │            │
     │─────────────▶│             │              │            │
     │              │ request()   │              │            │
     │              │────────────▶│              │            │
     │              │             │ onRequest    │            │
     │              │             │─────────────▶│            │
     │              │             │              │ Add Auth   │
     │              │             │              │ Add Headers│
     │              │             │◀─────────────│            │
     │              │             │              │            │
     │              │             │ execute      │            │
     │              │             │─────────────────────────▶│
     │              │             │              │            │
     │              │             │              │   Response │
     │              │             │◀─────────────────────────│
     │              │             │              │            │
     │              │             │ onResponse   │            │
     │              │             │─────────────▶│            │
     │              │             │              │ Transform  │
     │              │             │              │ Log        │
     │              │             │◀─────────────│            │
     │              │  Model      │              │            │
     │              │◀────────────│              │            │
     │  Either      │             │              │            │
     │◀─────────────│             │              │            │
     │              │             │              │            │
            </code></pre>

            <h2>Firebase Service Clients</h2>
            <h3>Firestore Client</h3>
            <p><strong>File:</strong> <code>lib/core/network/firestore_client.dart</code></p>
            <pre><code class="language-dart">
class FirestoreClient {
  final FirebaseFirestore _firestore;
  final NetworkInfo _networkInfo;

  FirestoreClient({
    required FirebaseFirestore firestore,
    required NetworkInfo networkInfo,
  })  : _firestore = firestore,
        _networkInfo = networkInfo;

  // Get document
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    String collection,
    String docId,
  ) async {
    await _checkConnectivity();
    return _firestore.collection(collection).doc(docId).get();
  }

  // Get collection with query
  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(
    String collection, {
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    await _checkConnectivity();

    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = _applyFilter(query, filter);
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply pagination
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.get();
  }

  // Set document
  Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _checkConnectivity();
    return _firestore
        .collection(collection)
        .doc(docId)
        .set(data, SetOptions(merge: merge));
  }

  // Update document
  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _checkConnectivity();
    return _firestore.collection(collection).doc(docId).update(data);
  }

  // Delete document
  Future<void> deleteDocument(String collection, String docId) async {
    await _checkConnectivity();
    return _firestore.collection(collection).doc(docId).delete();
  }

  // Batch write
  Future<void> batchWrite(List<BatchOperation> operations) async {
    await _checkConnectivity();
    final batch = _firestore.batch();

    for (final op in operations) {
      final ref = _firestore.collection(op.collection).doc(op.docId);
      switch (op.type) {
        case BatchOperationType.set:
          batch.set(ref, op.data!, SetOptions(merge: op.merge));
          break;
        case BatchOperationType.update:
          batch.update(ref, op.data!);
          break;
        case BatchOperationType.delete:
          batch.delete(ref);
          break;
      }
    }

    return batch.commit();
  }

  // Stream document
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument(
    String collection,
    String docId,
  ) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  // Stream collection
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
    String collection, {
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    if (filters != null) {
      for (final filter in filters) {
        query = _applyFilter(query, filter);
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  Query<Map<String, dynamic>> _applyFilter(
    Query<Map<String, dynamic>> query,
    QueryFilter filter,
  ) {
    switch (filter.operator) {
      case FilterOperator.equals:
        return query.where(filter.field, isEqualTo: filter.value);
      case FilterOperator.notEquals:
        return query.where(filter.field, isNotEqualTo: filter.value);
      case FilterOperator.lessThan:
        return query.where(filter.field, isLessThan: filter.value);
      case FilterOperator.greaterThan:
        return query.where(filter.field, isGreaterThan: filter.value);
      case FilterOperator.arrayContains:
        return query.where(filter.field, arrayContains: filter.value);
      case FilterOperator.whereIn:
        return query.where(filter.field, whereIn: filter.value as List);
    }
  }

  Future<void> _checkConnectivity() async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException(message: 'No internet connection');
    }
  }
}
            </code></pre>

            <h3>Cloud Functions Client</h3>
            <p><strong>File:</strong> <code>lib/core/network/functions_client.dart</code></p>
            <pre><code class="language-dart">
class FunctionsClient {
  final FirebaseFunctions _functions;
  final NetworkInfo _networkInfo;

  FunctionsClient({
    required FirebaseFunctions functions,
    required NetworkInfo networkInfo,
  })  : _functions = functions,
        _networkInfo = networkInfo;

  Future<T> call<T>(
    String functionName, {
    Map<String, dynamic>? parameters,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException(message: 'No internet connection');
    }

    try {
      final callable = _functions.httpsCallable(
        functionName,
        options: HttpsCallableOptions(timeout: timeout),
      );

      final result = await callable.call(parameters);
      return result.data as T;
    } on FirebaseFunctionsException catch (e) {
      throw ServerException(
        message: e.message ?? 'Function call failed',
        code: e.code,
      );
    }
  }
}

// Usage example
class MatchingService {
  final FunctionsClient _functionsClient;

  Future<List<MatchCandidate>> getPotentialMatches(String userId) async {
    final result = await _functionsClient.call<Map<String, dynamic>>(
      'getPotentialMatches',
      parameters: {'userId': userId, 'limit': 50},
    );

    return (result['matches'] as List)
        .map((m) => MatchCandidate.fromJson(m))
        .toList();
  }

  Future<double> calculateCompatibility(String user1, String user2) async {
    final result = await _functionsClient.call<Map<String, dynamic>>(
      'calculateCompatibility',
      parameters: {'userId1': user1, 'userId2': user2},
    );

    return result['score'] as double;
  }
}
            </code></pre>

            <h2>Network Info Service</h2>
            <p><strong>File:</strong> <code>lib/core/network/network_info.dart</code></p>
            <pre><code class="language-dart">
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get connectivityStream;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;
  final _connectivityController = StreamController<bool>.broadcast();

  NetworkInfoImpl({required Connectivity connectivity})
      : _connectivity = connectivity {
    _connectivity.onConnectivityChanged.listen((result) {
      _connectivityController.add(result != ConnectivityResult.none);
    });
  }

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Stream<bool> get connectivityStream => _connectivityController.stream;
}
            </code></pre>

            <h2>API Endpoints Reference</h2>
            <table>
                <thead>
                    <tr><th>Function</th><th>Type</th><th>Description</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><code>getPotentialMatches</code></td>
                        <td>Callable</td>
                        <td>Get ML-ranked potential matches for user</td>
                    </tr>
                    <tr>
                        <td><code>recordSwipe</code></td>
                        <td>Callable</td>
                        <td>Record like/pass action, check for match</td>
                    </tr>
                    <tr>
                        <td><code>calculateCompatibility</code></td>
                        <td>Callable</td>
                        <td>Calculate compatibility score between users</td>
                    </tr>
                    <tr>
                        <td><code>moderateContent</code></td>
                        <td>Callable</td>
                        <td>AI moderation for photos and text</td>
                    </tr>
                    <tr>
                        <td><code>processPayment</code></td>
                        <td>Callable</td>
                        <td>Handle Stripe payment processing</td>
                    </tr>
                    <tr>
                        <td><code>sendNotification</code></td>
                        <td>Callable</td>
                        <td>Send push notification to user</td>
                    </tr>
                </tbody>
            </table>
        `
    },
    {
        file: '18-caching.html',
        title: 'Caching Strategy',
        content: `
            <h2>Caching Architecture</h2>
            <p>GreenGo implements a multi-layer caching strategy to optimize performance and enable offline functionality. The caching system uses Hive for persistent storage and in-memory caching for frequently accessed data.</p>

            <h2>Caching Layers Diagram</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                        CACHING ARCHITECTURE                              │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                        APPLICATION REQUEST                               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │     L1: MEMORY CACHE          │
                    │     • Instant access          │
                    │     • Session-scoped          │
                    │     • Limited size            │
                    └───────────────┬───────────────┘
                           Miss     │     Hit
                    ┌───────────────▼───────────────┐
                    │     L2: HIVE LOCAL DB         │
                    │     • Persistent storage      │
                    │     • Encrypted data          │
                    │     • TTL-based expiry        │
                    └───────────────┬───────────────┘
                           Miss     │     Hit
                    ┌───────────────▼───────────────┐
                    │     L3: FIREBASE CACHE        │
                    │     • Firestore offline       │
                    │     • Automatic sync          │
                    │     • Conflict resolution     │
                    └───────────────┬───────────────┘
                           Miss     │
                    ┌───────────────▼───────────────┐
                    │     NETWORK REQUEST           │
                    │     • Firebase/API call       │
                    │     • Update all cache layers │
                    └───────────────────────────────┘
            </code></pre>

            <h2>Cache Data Flow</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                      CACHE READ FLOW                                     │
└─────────────────────────────────────────────────────────────────────────┘

  Request       Memory        Hive         Firestore      Network
     │            │             │              │              │
     │ get(key)   │             │              │              │
     │───────────▶│             │              │              │
     │            │ check       │              │              │
     │            │────┐        │              │              │
     │            │    │        │              │              │
     │            │◀───┘        │              │              │
     │            │             │              │              │
     │   HIT?     │             │              │              │
     │◀──Yes──────│             │              │              │
     │            │             │              │              │
     │            │ get(key)    │              │              │
     │            │────────────▶│              │              │
     │            │             │ check        │              │
     │            │             │────┐         │              │
     │            │             │    │         │              │
     │            │             │◀───┘         │              │
     │            │             │              │              │
     │   HIT?     │    data     │              │              │
     │◀──Yes──────│◀────────────│              │              │
     │            │ save        │              │              │
     │            │────┐        │              │              │
     │            │◀───┘        │              │              │
     │            │             │              │              │
     │            │             │ get(key)     │              │
     │            │             │─────────────▶│              │
     │            │             │              │ check        │
     │            │             │              │────┐         │
     │            │             │              │◀───┘         │
     │            │             │              │              │
     │   HIT?     │    data     │     data     │              │
     │◀──Yes──────│◀────────────│◀─────────────│              │
     │            │             │              │              │
     │            │             │              │ fetch        │
     │            │             │              │─────────────▶│
     │            │             │              │     data     │
     │   data     │    save     │    save      │◀─────────────│
     │◀───────────│◀────────────│◀─────────────│              │
     │            │             │              │              │
            </code></pre>

            <h2>Cache Manager Implementation</h2>
            <p><strong>File:</strong> <code>lib/core/cache/cache_manager.dart</code></p>
            <pre><code class="language-dart">
class CacheManager {
  final HiveInterface _hive;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache configuration
  static const defaultTTL = Duration(minutes: 30);
  static const maxMemoryCacheSize = 100;

  CacheManager({required HiveInterface hive}) : _hive = hive;

  // Initialize cache boxes
  Future<void> init() async {
    await _hive.openBox('userCache');
    await _hive.openBox('matchCache');
    await _hive.openBox('chatCache');
    await _hive.openBox('settingsCache');
  }

  // Get from cache with multi-layer lookup
  Future<T?> get<T>(
    String key, {
    String box = 'default',
    Duration? ttl,
  }) async {
    // L1: Check memory cache
    if (_memoryCache.containsKey(key)) {
      if (_isValid(key, ttl ?? defaultTTL)) {
        return _memoryCache[key] as T;
      } else {
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }

    // L2: Check Hive cache
    final hiveBox = _hive.box(box);
    final cached = hiveBox.get(key);

    if (cached != null) {
      final cacheEntry = CacheEntry.fromJson(cached);
      if (cacheEntry.isValid(ttl ?? defaultTTL)) {
        // Promote to memory cache
        _setMemoryCache(key, cacheEntry.data);
        return cacheEntry.data as T;
      } else {
        await hiveBox.delete(key);
      }
    }

    return null;
  }

  // Set cache with multi-layer write
  Future<void> set<T>(
    String key,
    T value, {
    String box = 'default',
    Duration? ttl,
  }) async {
    // L1: Set memory cache
    _setMemoryCache(key, value);

    // L2: Set Hive cache
    final hiveBox = _hive.box(box);
    final entry = CacheEntry(
      data: value,
      timestamp: DateTime.now(),
      ttl: ttl ?? defaultTTL,
    );
    await hiveBox.put(key, entry.toJson());
  }

  // Remove from all cache layers
  Future<void> remove(String key, {String box = 'default'}) async {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    await _hive.box(box).delete(key);
  }

  // Clear specific cache box
  Future<void> clearBox(String box) async {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    await _hive.box(box).clear();
  }

  // Clear all caches
  Future<void> clearAll() async {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    for (final box in ['userCache', 'matchCache', 'chatCache', 'settingsCache']) {
      await _hive.box(box).clear();
    }
  }

  void _setMemoryCache(String key, dynamic value) {
    // Enforce size limit
    if (_memoryCache.length >= maxMemoryCacheSize) {
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _memoryCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }

    _memoryCache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  bool _isValid(String key, Duration ttl) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < ttl;
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  bool isValid(Duration maxAge) {
    return DateTime.now().difference(timestamp) < maxAge;
  }

  Map<String, dynamic> toJson() => {
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'ttl': ttl.inMilliseconds,
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
        data: json['data'],
        timestamp: DateTime.parse(json['timestamp']),
        ttl: Duration(milliseconds: json['ttl']),
      );
}
            </code></pre>

            <h2>Cache Policies by Data Type</h2>
            <table>
                <thead>
                    <tr><th>Data Type</th><th>TTL</th><th>Strategy</th><th>Box</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>User Profile</strong></td>
                        <td>1 hour</td>
                        <td>Cache-first, background refresh</td>
                        <td>userCache</td>
                    </tr>
                    <tr>
                        <td><strong>Match Cards</strong></td>
                        <td>5 minutes</td>
                        <td>Network-first with fallback</td>
                        <td>matchCache</td>
                    </tr>
                    <tr>
                        <td><strong>Chat Messages</strong></td>
                        <td>24 hours</td>
                        <td>Real-time sync with cache</td>
                        <td>chatCache</td>
                    </tr>
                    <tr>
                        <td><strong>User Settings</strong></td>
                        <td>Permanent</td>
                        <td>Local-first, sync on change</td>
                        <td>settingsCache</td>
                    </tr>
                    <tr>
                        <td><strong>Discovery Filters</strong></td>
                        <td>Session</td>
                        <td>Memory only</td>
                        <td>N/A</td>
                    </tr>
                </tbody>
            </table>

            <h2>Offline Sync Queue</h2>
            <p><strong>File:</strong> <code>lib/core/cache/sync_queue.dart</code></p>
            <pre><code class="language-dart">
class SyncQueue {
  final Box _queueBox;
  final NetworkInfo _networkInfo;

  SyncQueue({
    required Box queueBox,
    required NetworkInfo networkInfo,
  })  : _queueBox = queueBox,
        _networkInfo = networkInfo;

  // Add operation to queue
  Future<void> enqueue(SyncOperation operation) async {
    await _queueBox.add(operation.toJson());
  }

  // Process queue when online
  Future<void> processQueue() async {
    if (!await _networkInfo.isConnected) return;

    final operations = _queueBox.values
        .map((e) => SyncOperation.fromJson(e))
        .toList();

    for (int i = 0; i < operations.length; i++) {
      try {
        await _executeOperation(operations[i]);
        await _queueBox.deleteAt(i);
      } catch (e) {
        // Keep in queue for retry
        operations[i].incrementRetry();
        if (operations[i].retryCount > 3) {
          await _queueBox.deleteAt(i);
          // Log failed operation
        }
      }
    }
  }

  Future<void> _executeOperation(SyncOperation op) async {
    // Execute based on operation type
    switch (op.type) {
      case SyncOperationType.createMessage:
        // Send message to server
        break;
      case SyncOperationType.updateProfile:
        // Update profile on server
        break;
      case SyncOperationType.recordSwipe:
        // Record swipe on server
        break;
    }
  }
}
            </code></pre>
        `
    },
    {
        file: '19-real-time.html',
        title: 'Real-time Communication',
        content: `
            <h2>Real-time Architecture</h2>
            <p>GreenGo uses Firebase Firestore and Cloud Messaging for real-time features including chat, match notifications, typing indicators, and presence status.</p>

            <h2>Real-time Data Flow</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                    REAL-TIME DATA ARCHITECTURE                           │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         CLIENT A (Sender)                                │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  MessageBloc → Repository → Firestore                            │   │
│  │      │                          │                                │   │
│  │      │ sendMessage()            │ write to                       │   │
│  │      │                          │ messages/{id}                  │   │
│  │      ▼                          ▼                                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Firestore
                                    │ Replication
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         FIREBASE BACKEND                                 │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  • Document write triggers listener                              │   │
│  │  • Cloud Function sends push notification                        │   │
│  │  • Updates conversation metadata                                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
        ┌───────────────┐  ┌───────────┐  ┌───────────────┐
        │  Snapshot     │  │   FCM     │  │  Metadata     │
        │  Listener     │  │   Push    │  │  Update       │
        └───────┬───────┘  └─────┬─────┘  └───────────────┘
                │                │
                ▼                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         CLIENT B (Receiver)                              │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Stream Listener         Push Handler                            │   │
│  │      │                       │                                   │   │
│  │      │ onData()              │ onMessage()                       │   │
│  │      ▼                       ▼                                   │   │
│  │  MessageBloc.add(NewMessage)  Show Notification                  │   │
│  │      │                                                           │   │
│  │      ▼                                                           │   │
│  │  UI Updates Automatically                                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
            </code></pre>

            <h2>Chat Stream Implementation</h2>
            <p><strong>File:</strong> <code>lib/features/chat/data/datasources/chat_remote_datasource.dart</code></p>
            <pre><code class="language-dart">
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;

  ChatRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<ConversationModel>> watchConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConversationModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    final batch = _firestore.batch();

    // Add message
    final messageRef = _firestore
        .collection('conversations')
        .doc(message.conversationId)
        .collection('messages')
        .doc(message.id);
    batch.set(messageRef, message.toJson());

    // Update conversation metadata
    final conversationRef = _firestore
        .collection('conversations')
        .doc(message.conversationId);
    batch.update(conversationRef, {
      'lastMessage': message.content,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageBy': message.senderId,
    });

    await batch.commit();
  }

  @override
  Stream<TypingStatus> watchTypingStatus(String conversationId, String oderId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('typing')
        .doc(oderId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return TypingStatus.notTyping;
          final data = doc.data()!;
          final timestamp = (data['timestamp'] as Timestamp).toDate();
          final isRecent = DateTime.now().difference(timestamp).inSeconds < 5;
          return isRecent ? TypingStatus.typing : TypingStatus.notTyping;
        });
  }

  @override
  Future<void> setTypingStatus(String conversationId, String oderId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('typing')
        .doc(oderId)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }
}
            </code></pre>

            <h2>Match Notification Stream</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                     MATCH NOTIFICATION FLOW                              │
└─────────────────────────────────────────────────────────────────────────┘

  User A             Cloud Function           Firestore           User B
    │                      │                     │                   │
    │ Like User B          │                     │                   │
    │─────────────────────▶│                     │                   │
    │                      │ Check mutual like   │                   │
    │                      │────────────────────▶│                   │
    │                      │                     │                   │
    │                      │◀────────────────────│                   │
    │                      │                     │                   │
    │                      │ MATCH DETECTED!     │                   │
    │                      │                     │                   │
    │                      │ Create match doc    │                   │
    │                      │────────────────────▶│                   │
    │                      │                     │                   │
    │                      │ Create conversation │                   │
    │                      │────────────────────▶│                   │
    │                      │                     │                   │
    │                      │ Send FCM to both    │                   │
    │◀─────────────────────│─────────────────────┼──────────────────▶│
    │                      │                     │                   │
    │ Match notification   │                     │   Match notif     │
    │ Stream update        │                     │   Stream update   │
    │                      │                     │                   │
            </code></pre>

            <h2>Presence System</h2>
            <p><strong>File:</strong> <code>lib/core/services/presence_service.dart</code></p>
            <pre><code class="language-dart">
class PresenceService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  Timer? _heartbeatTimer;

  PresenceService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  void startPresence() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Set online status
    _updatePresence(uid, true);

    // Start heartbeat
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updatePresence(uid, true),
    );

    // Handle app lifecycle
    AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.paused) {
          _updatePresence(uid, false);
        } else if (state == AppLifecycleState.resumed) {
          _updatePresence(uid, true);
        }
      },
    );
  }

  void stopPresence() {
    _heartbeatTimer?.cancel();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _updatePresence(uid, false);
    }
  }

  Future<void> _updatePresence(String oderId, bool isOnline) async {
    await _firestore.collection('presence').doc(oderId).set({
      'online': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Stream<bool> watchUserPresence(String oderId) {
    return _firestore
        .collection('presence')
        .doc(oderId)
        .snapshots()
        .map((doc) => doc.data()?['online'] ?? false);
  }
}
            </code></pre>

            <h2>Push Notifications</h2>
            <p><strong>File:</strong> <code>lib/core/services/notification_service.dart</code></p>
            <pre><code class="language-dart">
class NotificationService {
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  NotificationService({
    required FirebaseMessaging messaging,
    required FlutterLocalNotificationsPlugin localNotifications,
  })  : _messaging = messaging,
        _localNotifications = localNotifications;

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final token = await _messaging.getToken();
    // Save token to user profile

    // Configure local notifications
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification
    _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_channel',
          'Chat Messages',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    final data = jsonDecode(response.payload ?? '{}');
    // Navigate based on notification type
    switch (data['type']) {
      case 'match':
        // Navigate to matches
        break;
      case 'message':
        // Navigate to chat
        break;
    }
  }
}
            </code></pre>
        `
    },
    {
        file: '20-testing-architecture.html',
        title: 'Testing Architecture',
        content: `
            <h2>Testing Architecture</h2>
            <p>GreenGo follows a comprehensive testing strategy with unit tests, widget tests, and integration tests. The architecture supports easy mocking and test isolation.</p>

            <h2>Test Pyramid</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                         TESTING PYRAMID                                  │
└─────────────────────────────────────────────────────────────────────────┘

                        ┌─────────────┐
                       ╱               ╲
                      ╱   E2E Tests     ╲        5%
                     ╱   (Integration)   ╲       • Full app flows
                    ╱─────────────────────╲      • Real Firebase
                   ╱                       ╲
                  ╱     Widget Tests        ╲    15%
                 ╱     (Component)           ╲   • UI interactions
                ╱───────────────────────────╲   • Widget rendering
               ╱                             ╲
              ╱       Unit Tests              ╲  80%
             ╱       (Logic)                   ╲ • BLoCs, UseCases
            ╱─────────────────────────────────╲  • Repositories
           ╱                                   ╲ • Models, Utils

Test Directory Structure:
test/
├── unit/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── matching/
│   │   └── chat/
│   └── core/
├── widget/
│   ├── features/
│   └── shared/
├── integration/
│   ├── auth_flow_test.dart
│   ├── matching_flow_test.dart
│   └── chat_flow_test.dart
├── fixtures/
│   └── json/
└── mocks/
    └── generated/
            </code></pre>

            <h2>Test Flow Architecture</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                        UNIT TEST FLOW                                    │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Arrange   │────▶│     Act     │────▶│   Assert    │────▶│   Verify    │
│   Setup     │     │   Execute   │     │   Check     │     │   Mocks     │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
      │                   │                   │                   │
      ▼                   ▼                   ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│• Mock deps  │     │• Call method│     │• Check state│     │• Verify     │
│• Set state  │     │• Trigger    │     │• Check value│     │  calls      │
│• Create SUT │     │  events     │     │• Check side │     │• Check args │
│             │     │             │     │  effects    │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘

SUT = System Under Test
            </code></pre>

            <h2>BLoC Unit Test Example</h2>
            <p><strong>File:</strong> <code>test/unit/features/auth/presentation/bloc/auth_bloc_test.dart</code></p>
            <pre><code class="language-dart">
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([SignInUseCase, SignUpUseCase, SignOutUseCase])
void main() {
  late AuthBloc authBloc;
  late MockSignInUseCase mockSignIn;
  late MockSignUpUseCase mockSignUp;
  late MockSignOutUseCase mockSignOut;

  setUp(() {
    mockSignIn = MockSignInUseCase();
    mockSignUp = MockSignUpUseCase();
    mockSignOut = MockSignOutUseCase();
    authBloc = AuthBloc(
      signIn: mockSignIn,
      signUp: mockSignUp,
      signOut: mockSignOut,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('SignIn', () {
    const email = 'test@example.com';
    const password = 'password123';
    final user = UserEntity(id: '1', email: email, name: 'Test');

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] when sign in succeeds',
      build: () {
        when(mockSignIn(any)).thenAnswer((_) async => Right(user));
        return authBloc;
      },
      act: (bloc) => bloc.add(SignInRequested(
        email: email,
        password: password,
      )),
      expect: () => [
        AuthLoading(),
        AuthAuthenticated(user),
      ],
      verify: (_) {
        verify(mockSignIn(SignInParams(
          email: email,
          password: password,
        ))).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Error] when sign in fails',
      build: () {
        when(mockSignIn(any)).thenAnswer(
          (_) async => Left(AuthFailure(
            message: 'Invalid credentials',
            type: AuthFailureType.invalidCredentials,
          )),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(SignInRequested(
        email: email,
        password: password,
      )),
      expect: () => [
        AuthLoading(),
        const AuthError('Invalid email or password'),
      ],
    );
  });
}
            </code></pre>

            <h2>Repository Test Example</h2>
            <p><strong>File:</strong> <code>test/unit/features/auth/data/repositories/auth_repository_impl_test.dart</code></p>
            <pre><code class="language-dart">
@GenerateMocks([
  AuthRemoteDataSource,
  AuthLocalDataSource,
  NetworkInfo,
])
void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('signIn', () {
    const email = 'test@example.com';
    const password = 'password';
    final userModel = UserModel(id: '1', email: email, name: 'Test');

    test('should return user when online and credentials valid', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.signInWithEmail(email, password))
          .thenAnswer((_) async => userModel);
      when(mockLocalDataSource.cacheUser(userModel))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.signIn(email, password);

      // Assert
      expect(result, Right(userModel.toEntity()));
      verify(mockRemoteDataSource.signInWithEmail(email, password));
      verify(mockLocalDataSource.cacheUser(userModel));
    });

    test('should return NetworkFailure when offline', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.signIn(email, password);

      // Assert
      expect(result, Left(NetworkFailure(message: 'No internet')));
      verifyNever(mockRemoteDataSource.signInWithEmail(any, any));
    });
  });
}
            </code></pre>

            <h2>Widget Test Example</h2>
            <p><strong>File:</strong> <code>test/widget/features/auth/presentation/screens/login_screen_test.dart</code></p>
            <pre><code class="language-dart">
void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginScreen(),
      ),
    );
  }

  testWidgets('shows loading indicator when authenticating', (tester) async {
    // Arrange
    when(() => mockAuthBloc.state).thenReturn(AuthLoading());

    // Act
    await tester.pumpWidget(createTestWidget());

    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message on auth failure', (tester) async {
    // Arrange
    when(() => mockAuthBloc.state)
        .thenReturn(const AuthError('Invalid credentials'));

    // Act
    await tester.pumpWidget(createTestWidget());

    // Assert
    expect(find.text('Invalid credentials'), findsOneWidget);
  });

  testWidgets('triggers SignInRequested on button tap', (tester) async {
    // Arrange
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());

    // Act
    await tester.pumpWidget(createTestWidget());
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'test@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'password',
    );
    await tester.tap(find.byKey(const Key('signInButton')));

    // Assert
    verify(() => mockAuthBloc.add(any(that: isA<SignInRequested>()))).called(1);
  });
}
            </code></pre>

            <h2>Test Coverage Requirements</h2>
            <table>
                <thead>
                    <tr><th>Layer</th><th>Target</th><th>Focus Areas</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Domain</strong></td>
                        <td>95%</td>
                        <td>Use Cases, Entities, Value Objects</td>
                    </tr>
                    <tr>
                        <td><strong>Data</strong></td>
                        <td>90%</td>
                        <td>Repositories, Data Sources, Models</td>
                    </tr>
                    <tr>
                        <td><strong>Presentation</strong></td>
                        <td>85%</td>
                        <td>BLoCs, Critical Widgets</td>
                    </tr>
                    <tr>
                        <td><strong>Core</strong></td>
                        <td>90%</td>
                        <td>Utils, Services, Error Handling</td>
                    </tr>
                </tbody>
            </table>

            <h2>Running Tests</h2>
            <pre><code class="language-bash">
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/features/auth/presentation/bloc/auth_bloc_test.dart

# Run integration tests
flutter test integration_test/

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
            </code></pre>
        `
    }
];

// Create page HTML
function createPageHTML(page) {
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${page.title} - GreenGo Documentation</title>
    <link rel="stylesheet" href="../css/styles.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body>
    <nav class="sidebar" id="sidebar">
        <div class="sidebar-header">
            <div class="logo">
                <span class="logo-icon">🌿</span>
                <a href="../index.html" class="logo-text" style="text-decoration: none; color: #D4AF37;">GreenGo</a>
            </div>
        </div>
        <div class="search-box">
            <i class="fas fa-search"></i>
            <input type="text" id="searchInput" placeholder="Search...">
        </div>
        <ul class="nav-menu" id="navMenu">
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-building"></i><span>Architecture</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="09-clean-architecture.html">Clean Architecture</a></li>
                    <li><a href="10-feature-modules.html">Feature Modules</a></li>
                    <li><a href="11-state-management.html">State Management</a></li>
                    <li><a href="12-dependency-injection.html">Dependency Injection</a></li>
                    <li><a href="13-repository-pattern.html">Repository Pattern</a></li>
                    <li><a href="14-data-flow.html">Data Flow</a></li>
                    <li><a href="15-error-handling.html">Error Handling</a></li>
                    <li><a href="16-navigation.html">Navigation</a></li>
                    <li><a href="17-api-layer.html">API Layer</a></li>
                    <li><a href="18-caching.html">Caching Strategy</a></li>
                    <li><a href="19-real-time.html">Real-time</a></li>
                    <li><a href="20-testing-architecture.html">Testing Architecture</a></li>
                </ul>
            </li>
        </ul>
    </nav>

    <main class="main-content">
        <header class="top-header">
            <button class="mobile-menu-toggle" id="mobileMenuToggle"><i class="fas fa-bars"></i></button>
            <div class="header-title"><h1>${page.title}</h1></div>
        </header>

        <div class="content-wrapper">
            <div class="page-header">
                <div class="breadcrumb">
                    <a href="../index.html">Home</a> / <a href="#">Architecture</a> / ${page.title}
                </div>
            </div>

            <div class="page-content">
                ${page.content}
            </div>
        </div>
    </main>

    <script src="../js/main.js"></script>
</body>
</html>`;
}

// Generate pages
const pagesDir = path.join(__dirname, 'pages');

architecturePages.forEach(page => {
    const filepath = path.join(pagesDir, page.file);
    const html = createPageHTML(page);
    fs.writeFileSync(filepath, html);
    console.log(`Created: ${page.file} with expert diagrams`);
});

console.log(`\nGenerated ${architecturePages.length} remaining architecture pages with detailed system design diagrams!`);
