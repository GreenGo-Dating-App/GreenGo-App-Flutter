const fs = require('fs');
const path = require('path');

// Expert-level architecture documentation with detailed diagrams
const architecturePages = [
    {
        file: '09-clean-architecture.html',
        title: 'Clean Architecture',
        content: `
            <h2>Clean Architecture Overview</h2>
            <p>GreenGo implements Uncle Bob's Clean Architecture to achieve separation of concerns, testability, and independence from frameworks. This architecture ensures the business logic remains isolated and the codebase scales efficiently.</p>

            <div class="info-box">
                <strong>Key Principle:</strong> Dependencies always point inward. The inner layers know nothing about outer layers.
            </div>

            <h2>Architecture Layers Diagram</h2>
            <pre><code>┌─────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Screens   │  │   Widgets   │  │    BLoCs    │              │
│  │   (Pages)   │  │ (Components)│  │   (State)   │              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
│         │                │                │                      │
│         └────────────────┼────────────────┘                      │
│                          │                                       │
├──────────────────────────┼───────────────────────────────────────┤
│                          ▼                                       │
│                    DOMAIN LAYER                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  Entities   │  │  Use Cases  │  │ Repository  │              │
│  │  (Models)   │  │  (Interac.) │  │ (Abstract)  │              │
│  └─────────────┘  └──────┬──────┘  └──────┬──────┘              │
│                          │                │                      │
├──────────────────────────┼────────────────┼──────────────────────┤
│                          ▼                ▼                      │
│                      DATA LAYER                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Models    │  │ Repository  │  │ DataSources │              │
│  │   (DTOs)    │  │   (Impl)    │  │(Remote/Local)│             │
│  └─────────────┘  └──────┬──────┘  └──────┬──────┘              │
│                          │                │                      │
├──────────────────────────┼────────────────┼──────────────────────┤
│                          ▼                ▼                      │
│                 EXTERNAL SERVICES                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  Firebase   │  │   REST API  │  │Local Storage│              │
│  │  Services   │  │   (Django)  │  │(Hive/Prefs) │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘</code></pre>

            <h2>Dependency Flow</h2>
            <pre><code>
    OUTER                                              INNER
    ─────────────────────────────────────────────────►

    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │   UI     │───▶│   BLoC   │───▶│ Use Case │───▶│  Entity  │
    │(Widgets) │    │ (State)  │    │(Business)│    │ (Core)   │
    └──────────┘    └──────────┘    └──────────┘    └──────────┘
         │               │               │
         │               │               ▼
         │               │         ┌──────────┐
         │               │         │Repository│
         │               │         │(Abstract)│
         │               │         └──────────┘
         │               │               ▲
         │               ▼               │
         │         ┌──────────┐    ┌──────────┐
         │         │Repository│───▶│DataSource│
         │         │  (Impl)  │    │ (Remote) │
         │         └──────────┘    └──────────┘
         │               │
         ▼               ▼
    ┌─────────────────────────┐
    │    External Services    │
    │  (Firebase, APIs, DB)   │
    └─────────────────────────┘</code></pre>

            <h2>Layer Responsibilities</h2>

            <h3>1. Presentation Layer</h3>
            <table>
                <tr><th>Component</th><th>Responsibility</th><th>Dependencies</th></tr>
                <tr>
                    <td><strong>Screens</strong></td>
                    <td>Display UI, handle user interactions</td>
                    <td>BLoC, Widgets</td>
                </tr>
                <tr>
                    <td><strong>Widgets</strong></td>
                    <td>Reusable UI components</td>
                    <td>Theme, Constants</td>
                </tr>
                <tr>
                    <td><strong>BLoC</strong></td>
                    <td>State management, UI logic</td>
                    <td>Use Cases, Entities</td>
                </tr>
            </table>

            <h3>2. Domain Layer (Core)</h3>
            <table>
                <tr><th>Component</th><th>Responsibility</th><th>Dependencies</th></tr>
                <tr>
                    <td><strong>Entities</strong></td>
                    <td>Core business objects</td>
                    <td>None (pure Dart)</td>
                </tr>
                <tr>
                    <td><strong>Use Cases</strong></td>
                    <td>Business logic operations</td>
                    <td>Entities, Repository (abstract)</td>
                </tr>
                <tr>
                    <td><strong>Repository (Abstract)</strong></td>
                    <td>Data operation contracts</td>
                    <td>Entities</td>
                </tr>
            </table>

            <h3>3. Data Layer</h3>
            <table>
                <tr><th>Component</th><th>Responsibility</th><th>Dependencies</th></tr>
                <tr>
                    <td><strong>Models</strong></td>
                    <td>Data transfer objects with serialization</td>
                    <td>Entities</td>
                </tr>
                <tr>
                    <td><strong>Repository (Impl)</strong></td>
                    <td>Implements abstract repository</td>
                    <td>DataSources, Models</td>
                </tr>
                <tr>
                    <td><strong>DataSources</strong></td>
                    <td>Fetches data from external sources</td>
                    <td>External APIs, Firebase, Local DB</td>
                </tr>
            </table>

            <h2>Request-Response Flow</h2>
            <pre><code>
┌─────────┐   Event    ┌─────────┐  Params   ┌─────────┐
│   UI    │ ─────────▶ │  BLoC   │ ────────▶ │Use Case │
│ Screen  │            │         │           │         │
└─────────┘            └─────────┘           └────┬────┘
                                                  │
                            ┌─────────────────────┘
                            │
                            ▼
                       ┌─────────┐           ┌──────────┐
                       │Abstract │ ────────▶ │Repository│
                       │  Repo   │           │   Impl   │
                       └─────────┘           └────┬─────┘
                                                  │
                            ┌─────────────────────┘
                            │
                            ▼
                       ┌──────────┐          ┌──────────┐
                       │  Remote  │ ───────▶ │ Firebase │
                       │DataSource│          │   API    │
                       └──────────┘          └────┬─────┘
                                                  │
                            ┌─────────────────────┘
                            │ JSON Response
                            ▼
┌─────────┐   State    ┌─────────┐  Entity   ┌─────────┐
│   UI    │ ◀───────── │  BLoC   │ ◀──────── │  Model  │
│ Screen  │            │         │           │  Parse  │
└─────────┘            └─────────┘           └─────────┘</code></pre>

            <h2>File Organization</h2>
            <pre><code>lib/
├── core/                           # Shared across features
│   ├── errors/
│   │   ├── failures.dart           # Domain failures
│   │   └── exceptions.dart         # Data exceptions
│   ├── usecases/
│   │   └── usecase.dart            # Base use case class
│   ├── network/
│   │   └── network_info.dart       # Connectivity checker
│   └── di/
│       └── injection_container.dart # Dependency injection
│
└── features/
    └── [feature_name]/
        ├── domain/                 # INNER LAYER
        │   ├── entities/           # Business objects
        │   ├── repositories/       # Abstract contracts
        │   └── usecases/           # Business logic
        │
        ├── data/                   # MIDDLE LAYER
        │   ├── models/             # DTOs
        │   ├── repositories/       # Implementations
        │   └── datasources/        # API calls
        │
        └── presentation/           # OUTER LAYER
            ├── bloc/               # State management
            ├── screens/            # UI pages
            └── widgets/            # UI components</code></pre>

            <h2>Implementation Example: User Feature</h2>

            <h3>Step 1: Define Entity (Domain Layer)</h3>
            <pre><code>// lib/features/profile/domain/entities/user.dart

import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isVerified;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.createdAt,
    required this.isVerified,
  });

  // Business logic methods
  bool get hasCompletedProfile => name.isNotEmpty && photoUrl != null;

  int get accountAgeInDays => DateTime.now().difference(createdAt).inDays;

  @override
  List<Object?> get props => [id, email, name, photoUrl, createdAt, isVerified];
}</code></pre>

            <h3>Step 2: Define Repository Contract (Domain Layer)</h3>
            <pre><code>// lib/features/profile/domain/repositories/user_repository.dart

import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../../../../core/errors/failures.dart';

abstract class UserRepository {
  Future<Either<Failure, User>> getUser(String userId);
  Future<Either<Failure, User>> updateUser(User user);
  Future<Either<Failure, void>> deleteUser(String userId);
  Stream<User> watchUser(String userId);
}</code></pre>

            <h3>Step 3: Create Use Case (Domain Layer)</h3>
            <pre><code>// lib/features/profile/domain/usecases/get_user.dart

import 'package:dartz/dartz.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GetUser implements UseCase<User, String> {
  final UserRepository repository;

  GetUser(this.repository);

  @override
  Future<Either<Failure, User>> call(String userId) {
    return repository.getUser(userId);
  }
}</code></pre>

            <h3>Step 4: Create Model (Data Layer)</h3>
            <pre><code>// lib/features/profile/data/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required String id,
    required String email,
    required String name,
    String? photoUrl,
    required DateTime createdAt,
    required bool isVerified,
  }) : super(
          id: id,
          email: email,
          name: name,
          photoUrl: photoUrl,
          createdAt: createdAt,
          isVerified: isVerified,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt,
      isVerified: user.isVerified,
    );
  }
}</code></pre>

            <h3>Step 5: Implement DataSource (Data Layer)</h3>
            <pre><code>// lib/features/profile/data/datasources/user_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../../../core/errors/exceptions.dart';

abstract class UserRemoteDataSource {
  Future<UserModel> getUser(String userId);
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser(String userId);
  Stream<UserModel> watchUser(String userId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore firestore;

  UserRemoteDataSourceImpl(this.firestore);

  @override
  Future<UserModel> getUser(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        throw ServerException('User not found');
      }

      return UserModel.fromJson({...doc.data()!, 'id': doc.id});
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to get user');
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      await firestore.collection('users').doc(user.id).update(user.toJson());
      return user;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to update user');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await firestore.collection('users').doc(userId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to delete user');
    }
  }

  @override
  Stream<UserModel> watchUser(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => UserModel.fromJson({...doc.data()!, 'id': doc.id}));
  }
}</code></pre>

            <h3>Step 6: Implement Repository (Data Layer)</h3>
            <pre><code>// lib/features/profile/data/repositories/user_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';
import '../datasources/user_local_datasource.dart';
import '../models/user_model.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> getUser(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteUser = await remoteDataSource.getUser(userId);
        await localDataSource.cacheUser(remoteUser);
        return Right(remoteUser);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      try {
        final localUser = await localDataSource.getCachedUser(userId);
        return Right(localUser);
      } on CacheException {
        return Left(CacheFailure('No cached data available'));
      }
    }
  }

  @override
  Future<Either<Failure, User>> updateUser(User user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      final updatedUser = await remoteDataSource.updateUser(userModel);
      await localDataSource.cacheUser(updatedUser);
      return Right(updatedUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      await remoteDataSource.deleteUser(userId);
      await localDataSource.clearUser(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Stream<User> watchUser(String userId) {
    return remoteDataSource.watchUser(userId);
  }
}</code></pre>

            <h2>Benefits of This Architecture</h2>
            <table>
                <tr><th>Benefit</th><th>Description</th><th>Example</th></tr>
                <tr>
                    <td><strong>Testability</strong></td>
                    <td>Each layer can be tested independently</td>
                    <td>Mock repository in BLoC tests</td>
                </tr>
                <tr>
                    <td><strong>Maintainability</strong></td>
                    <td>Changes are isolated to specific layers</td>
                    <td>Switch from Firebase to REST without touching domain</td>
                </tr>
                <tr>
                    <td><strong>Scalability</strong></td>
                    <td>Easy to add new features</td>
                    <td>New feature follows same pattern</td>
                </tr>
                <tr>
                    <td><strong>Framework Independence</strong></td>
                    <td>Business logic doesn't depend on Flutter</td>
                    <td>Domain layer is pure Dart</td>
                </tr>
                <tr>
                    <td><strong>Separation of Concerns</strong></td>
                    <td>Clear responsibilities for each component</td>
                    <td>BLoC handles state, Use Case handles logic</td>
                </tr>
            </table>
        `
    },

    {
        file: '10-feature-modules.html',
        title: 'Feature Modules',
        content: `
            <h2>Feature-Based Organization</h2>
            <p>GreenGo organizes code by feature rather than by type, making it easier to understand, maintain, and scale the application.</p>

            <h2>Feature Module Architecture</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────┐
│                     FEATURE MODULE                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   PRESENTATION                        │  │
│  │  ┌─────────┐   ┌─────────┐   ┌─────────┐            │  │
│  │  │  BLoC   │   │ Screens │   │ Widgets │            │  │
│  │  │ Events  │   │  Pages  │   │  Custom │            │  │
│  │  │ States  │   │   UI    │   │  Comps  │            │  │
│  │  └────┬────┘   └────┬────┘   └────┬────┘            │  │
│  │       └─────────────┴─────────────┘                  │  │
│  └───────────────────────┬───────────────────────────────┘  │
│                          │                                   │
│  ┌───────────────────────▼───────────────────────────────┐  │
│  │                     DOMAIN                            │  │
│  │  ┌─────────┐   ┌─────────┐   ┌─────────┐            │  │
│  │  │Entities │   │Use Cases│   │  Repos  │            │  │
│  │  │ (Pure)  │   │(Business│   │(Abstract│            │  │
│  │  │         │   │  Logic) │   │Contract)│            │  │
│  │  └─────────┘   └────┬────┘   └────┬────┘            │  │
│  │                     └─────────────┘                  │  │
│  └───────────────────────┬───────────────────────────────┘  │
│                          │                                   │
│  ┌───────────────────────▼───────────────────────────────┐  │
│  │                      DATA                             │  │
│  │  ┌─────────┐   ┌─────────┐   ┌─────────┐            │  │
│  │  │ Models  │   │  Repos  │   │  Data   │            │  │
│  │  │ (DTOs)  │   │  (Impl) │   │ Sources │            │  │
│  │  └─────────┘   └─────────┘   └─────────┘            │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘</code></pre>

            <h2>Complete Feature List</h2>
            <table>
                <tr><th>Feature</th><th>Description</th><th>Dependencies</th><th>Status</th></tr>
                <tr>
                    <td><strong>authentication</strong></td>
                    <td>Login, register, password reset</td>
                    <td>Firebase Auth</td>
                    <td>✅ Complete</td>
                </tr>
                <tr>
                    <td><strong>profile</strong></td>
                    <td>User profiles, onboarding</td>
                    <td>Firestore, Storage</td>
                    <td>✅ Complete</td>
                </tr>
                <tr>
                    <td><strong>matching</strong></td>
                    <td>Compatibility algorithm</td>
                    <td>Vertex AI, Firestore</td>
                    <td>✅ Complete</td>
                </tr>
                <tr>
                    <td><strong>discovery</strong></td>
                    <td>Swipe interface, matches</td>
                    <td>matching, profile</td>
                    <td>✅ Complete</td>
                </tr>
                <tr>
                    <td><strong>chat</strong></td>
                    <td>Real-time messaging</td>
                    <td>Firestore, Storage</td>
                    <td>✅ Complete</td>
                </tr>
                <tr>
                    <td><strong>notifications</strong></td>
                    <td>Push and in-app alerts</td>
                    <td>FCM, Firestore</td>
                    <td>✅ Complete</td>
                </tr>
                <tr>
                    <td><strong>subscription</strong></td>
                    <td>Premium tiers</td>
                    <td>IAP, Firestore</td>
                    <td>✅ Complete</td>
                </tr>
                <tr>
                    <td><strong>coins</strong></td>
                    <td>Virtual currency</td>
                    <td>IAP, Firestore</td>
                    <td>✅ Complete</td>
                </tr>
                <tr>
                    <td><strong>gamification</strong></td>
                    <td>XP, achievements</td>
                    <td>Firestore</td>
                    <td>✅ Complete</td>
                </tr>
                <tr>
                    <td><strong>analytics</strong></td>
                    <td>Event tracking</td>
                    <td>Firebase Analytics</td>
                    <td>✅ Complete</td>
                </tr>
                <tr>
                    <td><strong>safety</strong></td>
                    <td>Content moderation</td>
                    <td>Cloud Vision, Perspective</td>
                    <td>✅ Complete</td>
                </tr>
                <tr>
                    <td><strong>video_calling</strong></td>
                    <td>Video/voice calls</td>
                    <td>Agora.io</td>
                    <td>🚧 Disabled</td>
                </tr>
            </table>

            <h2>Feature Interdependencies</h2>
            <pre><code>
                    ┌──────────────┐
                    │authentication│
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
        ┌─────────┐  ┌─────────┐  ┌──────────┐
        │ profile │  │analytics│  │  safety  │
        └────┬────┘  └─────────┘  └──────────┘
             │
    ┌────────┼────────┬────────────┐
    │        │        │            │
    ▼        ▼        ▼            ▼
┌───────┐┌───────┐┌────────┐ ┌───────────┐
│matching││ chat │ │discovery│ │subscription│
└───┬───┘└───┬───┘└────┬───┘ └─────┬─────┘
    │        │         │           │
    └────────┼─────────┘           │
             │                     │
             ▼                     ▼
      ┌────────────┐        ┌──────────┐
      │gamification│        │  coins   │
      └────────────┘        └──────────┘</code></pre>

            <h2>Detailed Feature Structure</h2>
            <pre><code>lib/features/authentication/
├── domain/
│   ├── entities/
│   │   └── user.dart                    # User entity
│   ├── repositories/
│   │   └── auth_repository.dart         # Abstract repository
│   └── usecases/
│       ├── login_user.dart              # Login use case
│       ├── register_user.dart           # Register use case
│       ├── logout_user.dart             # Logout use case
│       ├── reset_password.dart          # Password reset
│       ├── get_current_user.dart        # Get auth state
│       ├── google_sign_in.dart          # Google auth
│       ├── facebook_sign_in.dart        # Facebook auth
│       └── apple_sign_in.dart           # Apple auth
│
├── data/
│   ├── models/
│   │   └── user_model.dart              # User DTO
│   ├── datasources/
│   │   ├── auth_remote_datasource.dart  # Firebase Auth
│   │   └── auth_local_datasource.dart   # Local token storage
│   └── repositories/
│       └── auth_repository_impl.dart    # Repository impl
│
└── presentation/
    ├── bloc/
    │   ├── auth_bloc.dart               # Auth state management
    │   ├── auth_event.dart              # Auth events
    │   └── auth_state.dart              # Auth states
    ├── screens/
    │   ├── login_screen.dart            # Login UI
    │   ├── register_screen.dart         # Register UI
    │   ├── forgot_password_screen.dart  # Password reset UI
    │   └── auth_wrapper.dart            # Auth state wrapper
    └── widgets/
        ├── auth_text_field.dart         # Custom text field
        ├── auth_button.dart             # Auth buttons
        ├── social_login_button.dart     # Social buttons
        └── password_strength_indicator.dart</code></pre>

            <h2>Creating a New Feature</h2>
            <h3>Step-by-Step Guide</h3>

            <h4>Step 1: Create Directory Structure</h4>
            <pre><code>lib/features/new_feature/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/
│   ├── models/
│   ├── datasources/
│   └── repositories/
└── presentation/
    ├── bloc/
    ├── screens/
    └── widgets/</code></pre>

            <h4>Step 2: Define Entities</h4>
            <pre><code>// domain/entities/new_entity.dart
class NewEntity extends Equatable {
  final String id;
  final String name;

  const NewEntity({required this.id, required this.name});

  @override
  List<Object> get props => [id, name];
}</code></pre>

            <h4>Step 3: Define Repository Contract</h4>
            <pre><code>// domain/repositories/new_repository.dart
abstract class NewRepository {
  Future<Either<Failure, NewEntity>> get(String id);
  Future<Either<Failure, void>> create(NewEntity entity);
}</code></pre>

            <h4>Step 4: Create Use Cases</h4>
            <pre><code>// domain/usecases/get_new_entity.dart
class GetNewEntity implements UseCase<NewEntity, String> {
  final NewRepository repository;
  GetNewEntity(this.repository);

  @override
  Future<Either<Failure, NewEntity>> call(String id) {
    return repository.get(id);
  }
}</code></pre>

            <h4>Step 5: Implement Data Layer</h4>
            <pre><code>// data/repositories/new_repository_impl.dart
class NewRepositoryImpl implements NewRepository {
  final NewRemoteDataSource remoteDataSource;

  NewRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, NewEntity>> get(String id) async {
    try {
      final result = await remoteDataSource.get(id);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}</code></pre>

            <h4>Step 6: Create BLoC</h4>
            <pre><code>// presentation/bloc/new_bloc.dart
class NewBloc extends Bloc<NewEvent, NewState> {
  final GetNewEntity getNewEntity;

  NewBloc(this.getNewEntity) : super(NewInitial()) {
    on<LoadNew>(_onLoadNew);
  }

  Future<void> _onLoadNew(LoadNew event, Emitter<NewState> emit) async {
    emit(NewLoading());
    final result = await getNewEntity(event.id);
    result.fold(
      (failure) => emit(NewError(failure.message)),
      (entity) => emit(NewLoaded(entity)),
    );
  }
}</code></pre>

            <h4>Step 7: Register in DI Container</h4>
            <pre><code>// core/di/injection_container.dart
void _initNewFeature() {
  // BLoC
  sl.registerFactory(() => NewBloc(sl()));

  // Use Cases
  sl.registerLazySingleton(() => GetNewEntity(sl()));

  // Repository
  sl.registerLazySingleton<NewRepository>(
    () => NewRepositoryImpl(sl()),
  );

  // Data Sources
  sl.registerLazySingleton<NewRemoteDataSource>(
    () => NewRemoteDataSourceImpl(sl()),
  );
}</code></pre>

            <h2>Feature Communication</h2>
            <pre><code>
┌─────────────┐        ┌─────────────┐
│  Feature A  │        │  Feature B  │
│             │        │             │
│  ┌───────┐  │        │  ┌───────┐  │
│  │ BLoC  │  │        │  │ BLoC  │  │
│  └───┬───┘  │        │  └───┬───┘  │
└──────┼──────┘        └──────┼──────┘
       │                      │
       │    ┌──────────┐      │
       └───▶│  Shared  │◀─────┘
            │ Use Case │
            └────┬─────┘
                 │
            ┌────▼─────┐
            │  Shared  │
            │Repository│
            └──────────┘</code></pre>

            <p>Features communicate through:</p>
            <ul>
                <li><strong>Shared Use Cases:</strong> Business logic used by multiple features</li>
                <li><strong>Event Bus:</strong> For decoupled communication</li>
                <li><strong>Shared State:</strong> Via repository patterns</li>
            </ul>
        `
    },

    {
        file: '11-state-management.html',
        title: 'State Management (BLoC)',
        content: `
            <h2>BLoC Pattern Overview</h2>
            <p>GreenGo uses flutter_bloc for predictable, testable state management following the BLoC (Business Logic Component) pattern.</p>

            <h2>BLoC Architecture</h2>
            <pre><code>
┌────────────────────────────────────────────────────────────┐
│                      UI LAYER                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                     Widget                            │  │
│  │  ┌─────────────────┐    ┌─────────────────┐          │  │
│  │  │  BlocProvider   │    │  BlocBuilder    │          │  │
│  │  │  (Provides BLoC)│    │  (Builds UI)    │          │  │
│  │  └────────┬────────┘    └────────┬────────┘          │  │
│  │           │                      │                    │  │
│  │           │    ┌─────────────────┘                    │  │
│  │           │    │                                      │  │
│  │           ▼    ▼                                      │  │
│  │  ┌─────────────────────────┐                         │  │
│  │  │    BlocListener         │                         │  │
│  │  │  (Side Effects)         │                         │  │
│  │  └─────────────────────────┘                         │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                  │
│                    Events│                                  │
│                          ▼                                  │
├─────────────────────────────────────────────────────────────┤
│                      BLOC LAYER                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                       BLoC                            │  │
│  │  ┌─────────────┐              ┌─────────────┐        │  │
│  │  │   Events    │──────────────▶   States    │        │  │
│  │  │  (Input)    │              │  (Output)   │        │  │
│  │  └─────────────┘              └─────────────┘        │  │
│  │         │                            ▲               │  │
│  │         │    ┌──────────────┐        │               │  │
│  │         └───▶│  Event       │────────┘               │  │
│  │              │  Handlers    │                        │  │
│  │              └──────┬───────┘                        │  │
│  │                     │                                │  │
│  └─────────────────────┼────────────────────────────────┘  │
│                        │                                    │
│                 Use Case Calls                               │
│                        ▼                                    │
├─────────────────────────────────────────────────────────────┤
│                   DOMAIN LAYER                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    Use Cases                          │  │
│  │                    Repositories                       │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘</code></pre>

            <h2>Event-State Flow</h2>
            <pre><code>
User Action          Event              Handler           State             UI Update
    │                  │                   │                │                   │
    ▼                  ▼                   ▼                ▼                   ▼
┌───────┐        ┌─────────┐        ┌──────────┐     ┌──────────┐        ┌─────────┐
│Button │───────▶│LoginReq │───────▶│_onLogin  │────▶│Loading   │───────▶│Spinner  │
│Press  │        │Event    │        │Handler   │     │State     │        │Widget   │
└───────┘        └─────────┘        └────┬─────┘     └──────────┘        └─────────┘
                                         │
                                         ▼
                                   ┌──────────┐
                                   │Use Case  │
                                   │  Call    │
                                   └────┬─────┘
                                        │
                              ┌─────────┴─────────┐
                              │                   │
                              ▼                   ▼
                        ┌──────────┐        ┌──────────┐
                        │ Success  │        │ Failure  │
                        └────┬─────┘        └────┬─────┘
                             │                   │
                             ▼                   ▼
                       ┌──────────┐        ┌──────────┐
                       │Logged In │        │  Error   │
                       │  State   │        │  State   │
                       └────┬─────┘        └────┬─────┘
                            │                   │
                            ▼                   ▼
                       ┌──────────┐        ┌──────────┐
                       │Home      │        │Error     │
                       │Screen    │        │Dialog    │
                       └──────────┘        └──────────┘</code></pre>

            <h2>Complete BLoC Implementation</h2>

            <h3>Events Definition</h3>
            <pre><code>// lib/features/authentication/presentation/bloc/auth_event.dart

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check current authentication state
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Login with email and password
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const LoginRequested({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [email, password, rememberMe];
}

/// Register new account
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final bool acceptedTerms;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.acceptedTerms,
  });

  @override
  List<Object?> get props => [email, password, name, acceptedTerms];
}

/// Logout current user
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Request password reset
class PasswordResetRequested extends AuthEvent {
  final String email;

  const PasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Google sign in
class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

/// Facebook sign in
class FacebookSignInRequested extends AuthEvent {
  const FacebookSignInRequested();
}

/// Apple sign in
class AppleSignInRequested extends AuthEvent {
  const AppleSignInRequested();
}</code></pre>

            <h3>States Definition</h3>
            <pre><code>// lib/features/authentication/presentation/bloc/auth_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any check
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state during auth operations
class AuthLoading extends AuthState {
  final String? message;

  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// User is authenticated
class Authenticated extends AuthState {
  final User user;
  final bool isNewUser;

  const Authenticated({
    required this.user,
    this.isNewUser = false,
  });

  @override
  List<Object?> get props => [user, isNewUser];
}

/// User is not authenticated
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Authentication error occurred
class AuthError extends AuthState {
  final String message;
  final String? code;

  const AuthError({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Password reset email sent successfully
class PasswordResetSent extends AuthState {
  final String email;

  const PasswordResetSent({required this.email});

  @override
  List<Object?> get props => [email];
}</code></pre>

            <h3>BLoC Implementation</h3>
            <pre><code>// lib/features/authentication/presentation/bloc/auth_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/usecases/logout_user.dart';
import '../../domain/usecases/reset_password.dart';
import '../../domain/usecases/get_current_user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUser loginUser;
  final RegisterUser registerUser;
  final LogoutUser logoutUser;
  final ResetPassword resetPassword;
  final GetCurrentUser getCurrentUser;

  AuthBloc({
    required this.loginUser,
    required this.registerUser,
    required this.logoutUser,
    required this.resetPassword,
    required this.getCurrentUser,
  }) : super(const AuthInitial()) {
    // Register event handlers
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
  }

  /// Check if user is already authenticated
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Checking authentication...'));

    final result = await getCurrentUser(NoParams());

    result.fold(
      (failure) => emit(const Unauthenticated()),
      (user) {
        if (user != null) {
          emit(Authenticated(user: user));
        } else {
          emit(const Unauthenticated());
        }
      },
    );
  }

  /// Handle login request
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing in...'));

    final result = await loginUser(
      LoginParams(
        email: event.email,
        password: event.password,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(
        message: failure.message,
        code: failure.code,
      )),
      (user) => emit(Authenticated(user: user)),
    );
  }

  /// Handle registration request
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Creating account...'));

    final result = await registerUser(
      RegisterParams(
        email: event.email,
        password: event.password,
        name: event.name,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(
        message: failure.message,
        code: failure.code,
      )),
      (user) => emit(Authenticated(
        user: user,
        isNewUser: true,
      )),
    );
  }

  /// Handle logout request
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing out...'));

    final result = await logoutUser(NoParams());

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const Unauthenticated()),
    );
  }

  /// Handle password reset request
  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Sending reset email...'));

    final result = await resetPassword(event.email);

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(PasswordResetSent(email: event.email)),
    );
  }
}</code></pre>

            <h2>UI Integration Patterns</h2>

            <h3>BlocProvider Setup</h3>
            <pre><code>// Providing BLoC to widget tree
BlocProvider<AuthBloc>(
  create: (context) => sl<AuthBloc>()..add(const AuthCheckRequested()),
  child: MaterialApp(
    home: AuthWrapper(),
  ),
)</code></pre>

            <h3>BlocBuilder Pattern</h3>
            <pre><code>// Building UI based on state
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) {
      return LoadingScreen(message: state.message);
    }

    if (state is Authenticated) {
      return HomeScreen(user: state.user);
    }

    if (state is AuthError) {
      return ErrorScreen(message: state.message);
    }

    return LoginScreen();
  },
)</code></pre>

            <h3>BlocListener Pattern</h3>
            <pre><code>// Handling side effects (navigation, dialogs, etc.)
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }

    if (state is Authenticated && state.isNewUser) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }

    if (state is PasswordResetSent) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Email Sent'),
          content: Text('Check \${state.email} for reset link'),
        ),
      );
    }
  },
  child: LoginForm(),
)</code></pre>

            <h3>BlocConsumer (Builder + Listener)</h3>
            <pre><code>// Combined pattern for both UI building and side effects
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  builder: (context, state) {
    return LoginForm(
      isLoading: state is AuthLoading,
      onLogin: (email, password) {
        context.read<AuthBloc>().add(
          LoginRequested(email: email, password: password),
        );
      },
    );
  },
)</code></pre>

            <h2>Testing BLoC</h2>
            <pre><code>// test/features/authentication/presentation/bloc/auth_bloc_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

void main() {
  late AuthBloc authBloc;
  late MockLoginUser mockLoginUser;

  setUp(() {
    mockLoginUser = MockLoginUser();
    authBloc = AuthBloc(loginUser: mockLoginUser, ...);
  });

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, Authenticated] when login succeeds',
    build: () {
      when(mockLoginUser(any)).thenAnswer(
        (_) async => Right(testUser),
      );
      return authBloc;
    },
    act: (bloc) => bloc.add(LoginRequested(
      email: 'test@test.com',
      password: 'password123',
    )),
    expect: () => [
      isA<AuthLoading>(),
      isA<Authenticated>(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthError] when login fails',
    build: () {
      when(mockLoginUser(any)).thenAnswer(
        (_) async => Left(ServerFailure('Invalid credentials')),
      );
      return authBloc;
    },
    act: (bloc) => bloc.add(LoginRequested(
      email: 'test@test.com',
      password: 'wrong',
    )),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthError>().having(
        (e) => e.message,
        'message',
        'Invalid credentials',
      ),
    ],
  );
}</code></pre>
        `
    },

    {
        file: '12-dependency-injection.html',
        title: 'Dependency Injection',
        content: `
            <h2>Dependency Injection Overview</h2>
            <p>GreenGo uses GetIt as a service locator for dependency injection, providing loose coupling and improved testability.</p>

            <h2>DI Container Architecture</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────┐
│                    INJECTION CONTAINER                      │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  EXTERNAL SERVICES                    │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  │  │
│  │  │Firebase │  │Firebase │  │Firebase │  │  Shared │  │  │
│  │  │  Auth   │  │Firestore│  │ Storage │  │  Prefs  │  │  │
│  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘  │  │
│  │       └──────────┬─┴──────────┬─┴───────────┘        │  │
│  └──────────────────┼────────────┼──────────────────────┘  │
│                     │            │                          │
│  ┌──────────────────▼────────────▼──────────────────────┐  │
│  │                   DATA SOURCES                        │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │  │
│  │  │   Remote    │  │   Remote    │  │   Local     │   │  │
│  │  │  AuthDS     │  │  ProfileDS  │  │   CacheDS   │   │  │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │  │
│  │         └────────────┬───┴────────────────┘          │  │
│  └──────────────────────┼───────────────────────────────┘  │
│                         │                                   │
│  ┌──────────────────────▼───────────────────────────────┐  │
│  │                   REPOSITORIES                        │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │  │
│  │  │    Auth     │  │   Profile   │  │   Matching  │   │  │
│  │  │    Repo     │  │    Repo     │  │    Repo     │   │  │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │  │
│  │         └────────────┬───┴────────────────┘          │  │
│  └──────────────────────┼───────────────────────────────┘  │
│                         │                                   │
│  ┌──────────────────────▼───────────────────────────────┐  │
│  │                    USE CASES                          │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  │  │
│  │  │ Login   │  │Register │  │  Get    │  │  Get    │  │  │
│  │  │  User   │  │  User   │  │ Profile │  │ Matches │  │  │
│  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘  │  │
│  │       └──────────┬─┴──────────┬─┴───────────┘        │  │
│  └──────────────────┼────────────┼──────────────────────┘  │
│                     │            │                          │
│  ┌──────────────────▼────────────▼──────────────────────┐  │
│  │                      BLOCS                            │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │  │
│  │  │   Auth      │  │   Profile   │  │  Discovery  │   │  │
│  │  │   BLoC      │  │    BLoC     │  │    BLoC     │   │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘</code></pre>

            <h2>Complete Injection Container</h2>
            <pre><code>// lib/core/di/injection_container.dart

import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features
  _initAuthentication();
  _initProfile();
  _initMatching();
  _initDiscovery();
  _initChat();
  _initNotifications();
  _initSubscription();
  _initCoins();
  _initGamification();

  //! Core
  _initCore();

  //! External
  await _initExternal();
}

// ==================== AUTHENTICATION ====================
void _initAuthentication() {
  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      loginUser: sl(),
      registerUser: sl(),
      logoutUser: sl(),
      resetPassword: sl(),
      getCurrentUser: sl(),
      googleSignIn: sl(),
      facebookSignIn: sl(),
      appleSignIn: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerLazySingleton(() => LogoutUser(sl()));
  sl.registerLazySingleton(() => ResetPassword(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => GoogleSignIn(sl()));
  sl.registerLazySingleton(() => FacebookSignIn(sl()));
  sl.registerLazySingleton(() => AppleSignIn(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
    ),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );
}

// ==================== PROFILE ====================
void _initProfile() {
  // BLoC
  sl.registerFactory(
    () => ProfileBloc(
      getProfile: sl(),
      updateProfile: sl(),
      uploadPhoto: sl(),
      deletePhoto: sl(),
    ),
  );

  sl.registerFactory(
    () => OnboardingBloc(
      createProfile: sl(),
      uploadPhoto: sl(),
      updatePreferences: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetProfile(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
  sl.registerLazySingleton(() => CreateProfile(sl()));
  sl.registerLazySingleton(() => UploadPhoto(sl()));
  sl.registerLazySingleton(() => DeletePhoto(sl()));
  sl.registerLazySingleton(() => UpdatePreferences(sl()));

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(
      firestore: sl(),
      storage: sl(),
    ),
  );

  sl.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );
}

// ==================== MATCHING ====================
void _initMatching() {
  // BLoC
  sl.registerFactory(
    () => MatchingBloc(
      getMatchCandidates: sl(),
      likeUser: sl(),
      passUser: sl(),
      superLikeUser: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetMatchCandidates(sl()));
  sl.registerLazySingleton(() => LikeUser(sl()));
  sl.registerLazySingleton(() => PassUser(sl()));
  sl.registerLazySingleton(() => SuperLikeUser(sl()));
  sl.registerLazySingleton(() => CalculateCompatibility(sl()));

  // Repository
  sl.registerLazySingleton<MatchingRepository>(
    () => MatchingRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<MatchingRemoteDataSource>(
    () => MatchingRemoteDataSourceImpl(
      firestore: sl(),
    ),
  );
}

// ==================== CHAT ====================
void _initChat() {
  // BLoC
  sl.registerFactory(
    () => ChatBloc(
      getMessages: sl(),
      sendMessage: sl(),
      markAsRead: sl(),
      addReaction: sl(),
    ),
  );

  sl.registerFactory(
    () => ConversationsBloc(
      getConversations: sl(),
      archiveConversation: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetMessages(sl()));
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerLazySingleton(() => MarkAsRead(sl()));
  sl.registerLazySingleton(() => AddReaction(sl()));
  sl.registerLazySingleton(() => GetConversations(sl()));
  sl.registerLazySingleton(() => ArchiveConversation(sl()));

  // Repository
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(
      firestore: sl(),
      storage: sl(),
    ),
  );
}

// ==================== CORE ====================
void _initCore() {
  // Network Info
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  // Connectivity
  sl.registerLazySingleton(() => Connectivity());
}

// ==================== EXTERNAL ====================
Future<void> _initExternal() async {
  // Firebase
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);

  // Shared Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}</code></pre>

            <h2>Registration Types</h2>
            <table>
                <tr><th>Method</th><th>Behavior</th><th>Use For</th></tr>
                <tr>
                    <td><code>registerFactory</code></td>
                    <td>New instance every time</td>
                    <td>BLoCs (need fresh state)</td>
                </tr>
                <tr>
                    <td><code>registerLazySingleton</code></td>
                    <td>Single instance, created on first use</td>
                    <td>Repositories, Use Cases, Services</td>
                </tr>
                <tr>
                    <td><code>registerSingleton</code></td>
                    <td>Single instance, created immediately</td>
                    <td>Core services that must exist</td>
                </tr>
            </table>

            <h2>Initialization Flow</h2>
            <pre><code>
┌─────────────┐
│   main()    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  init() DI  │
└──────┬──────┘
       │
       ├─────────────────────────────┐
       │                             │
       ▼                             ▼
┌─────────────┐              ┌─────────────┐
│  Register   │              │  Register   │
│   Features  │              │  External   │
└──────┬──────┘              └──────┬──────┘
       │                             │
       ▼                             │
┌─────────────┐                      │
│   BLoCs     │                      │
│  Use Cases  │                      │
│   Repos     │                      │
│ DataSources │                      │
└──────┬──────┘                      │
       │                             │
       └──────────────┬──────────────┘
                      │
                      ▼
               ┌─────────────┐
               │   runApp()  │
               └─────────────┘</code></pre>

            <h2>Usage Examples</h2>
            <h3>Providing BLoC to Widget</h3>
            <pre><code>// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await init(); // Initialize DI
  runApp(MyApp());
}

// In widget
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => sl<ProfileBloc>(),
        ),
      ],
      child: MaterialApp(...),
    );
  }
}</code></pre>

            <h3>Accessing Dependencies in Tests</h3>
            <pre><code>// In tests
void main() {
  late AuthBloc authBloc;
  late MockLoginUser mockLoginUser;

  setUp(() {
    // Reset GetIt
    sl.reset();

    // Register mocks
    mockLoginUser = MockLoginUser();
    sl.registerFactory(() => mockLoginUser);

    authBloc = AuthBloc(loginUser: sl());
  });
}</code></pre>
        `
    },

    {
        file: '14-data-flow.html',
        title: 'Data Flow Diagram',
        content: `
            <h2>Complete Data Flow Architecture</h2>
            <p>This diagram shows how data flows through all layers of the GreenGo application.</p>

            <h2>High-Level Data Flow</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                          │
│                                                                     │
│  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐       │
│  │   Screen    │──────▶│    BLoC     │──────▶│   Widget    │       │
│  │ (User Input)│ Event │   (State)   │ State │  (Render)   │       │
│  └─────────────┘       └──────┬──────┘       └─────────────┘       │
│                               │                                     │
└───────────────────────────────┼─────────────────────────────────────┘
                                │
                          Use Case Call
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│                          DOMAIN LAYER                               │
│                                                                     │
│  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐       │
│  │  Use Case   │──────▶│ Repository  │──────▶│   Entity    │       │
│  │   (Logic)   │       │ (Interface) │       │  (Return)   │       │
│  └─────────────┘       └──────┬──────┘       └─────────────┘       │
│                               │                                     │
└───────────────────────────────┼─────────────────────────────────────┘
                                │
                        Impl. Call
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│                           DATA LAYER                                │
│                                                                     │
│  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐       │
│  │ Repository  │──────▶│ DataSource  │──────▶│    Model    │       │
│  │   (Impl)    │       │  (Fetch)    │       │   (Parse)   │       │
│  └─────────────┘       └──────┬──────┘       └─────────────┘       │
│                               │                                     │
└───────────────────────────────┼─────────────────────────────────────┘
                                │
                          API Call
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│                        EXTERNAL SERVICES                            │
│                                                                     │
│  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐       │
│  │  Firebase   │       │  REST API   │       │   Local     │       │
│  │  Services   │       │   (Django)  │       │  Storage    │       │
│  └─────────────┘       └─────────────┘       └─────────────┘       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘</code></pre>

            <h2>Detailed Request Flow</h2>
            <pre><code>
┌──────┐  User    ┌───────┐  Event   ┌──────┐  Params   ┌────────┐
│Screen│ ──────▶  │BlocBui│ ───────▶ │ BLoC │ ────────▶ │UseCase │
│      │  Tap     │lder   │  Login   │      │  Email/   │        │
└──────┘          └───────┘  Request └──┬───┘  Pass     └───┬────┘
                                        │                    │
          emit(Loading)                 │                    │
                                        ▼                    │
                                   ┌────────┐                │
                                   │ State: │                │
                                   │Loading │                │
                                   └────────┘                │
                                                             │
                              ┌──────────────────────────────┘
                              │
                              ▼
                         ┌─────────┐
                         │Abstract │
                         │  Repo   │
                         └────┬────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │    Repository     │
                    │  Implementation   │
                    └─────────┬─────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
             ┌───────────┐       ┌───────────┐
             │  Remote   │       │   Local   │
             │DataSource │       │DataSource │
             └─────┬─────┘       └─────┬─────┘
                   │                   │
                   ▼                   ▼
             ┌───────────┐       ┌───────────┐
             │ Firebase  │       │   Hive    │
             │   Auth    │       │  Cache    │
             └─────┬─────┘       └───────────┘
                   │
                   │ JSON Response
                   ▼
             ┌───────────┐
             │   User    │
             │   Model   │
             │ fromJson()│
             └─────┬─────┘
                   │
                   │ UserModel (extends User Entity)
                   ▼
             ┌───────────┐
             │Either<F,U>│
             │ Right(u)  │
             └─────┬─────┘
                   │
                   │ fold()
                   ▼
             ┌───────────┐
             │   BLoC    │
             │emit(state)│
             └─────┬─────┘
                   │
                   ▼
             ┌───────────┐
             │  State:   │
             │Authenticated│
             │  (user)   │
             └─────┬─────┘
                   │
                   │ BlocBuilder rebuilds
                   ▼
             ┌───────────┐
             │   Home    │
             │  Screen   │
             └───────────┘</code></pre>

            <h2>Real-Time Data Flow (Firestore Streams)</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────┐
│                    FIRESTORE DATABASE                       │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Document Change Event                   │   │
│  │         (User updates their profile)                 │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                   │
└─────────────────────────┼───────────────────────────────────┘
                          │
                    Snapshot Event
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                     DATA SOURCE                             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  firestore.collection('users').doc(id).snapshots()  │   │
│  │              .map(UserModel.fromDoc)                 │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                   │
└─────────────────────────┼───────────────────────────────────┘
                          │
                    Stream<UserModel>
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                     REPOSITORY                              │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │     Stream<User> watchUser(String userId)           │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                   │
└─────────────────────────┼───────────────────────────────────┘
                          │
                    Stream<User>
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                        BLOC                                 │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  _subscription = watchUser(id).listen((user) {      │   │
│  │    emit(ProfileLoaded(user));                       │   │
│  │  });                                                │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                   │
└─────────────────────────┼───────────────────────────────────┘
                          │
                    emit(State)
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                         UI                                  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  BlocBuilder<ProfileBloc, ProfileState>(            │   │
│  │    builder: (context, state) {                      │   │
│  │      if (state is ProfileLoaded) {                  │   │
│  │        return ProfileWidget(state.user);            │   │
│  │      }                                              │   │
│  │    },                                               │   │
│  │  )                                                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘</code></pre>

            <h2>Error Handling Flow</h2>
            <pre><code>
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│ DataSource  │──────▶│ Repository  │──────▶│    BLoC     │
│  throws     │       │  catches    │       │   emits     │
│ Exception   │       │  returns    │       │   Error     │
│             │       │  Failure    │       │   State     │
└─────────────┘       └─────────────┘       └─────────────┘
      │                      │                      │
      │                      │                      │
      ▼                      ▼                      ▼

ServerException        ServerFailure           AuthError
CacheException    ──▶  CacheFailure     ──▶    (message)
NetworkException       NetworkFailure

Example:

try {
  final doc = await firestore
    .collection('users')
    .doc(id)
    .get();

  if (!doc.exists) {
    throw ServerException(
      'User not found'
    );
  }

  return UserModel.fromDoc(doc);

} on FirebaseException catch (e) {
  throw ServerException(
    e.message ?? 'Firebase error'
  );
}

         │
         ▼

@override
Future<Either<Failure, User>>
  getUser(String id) async {
  try {
    final user = await
      remoteDataSource.getUser(id);
    return Right(user);
  } on ServerException catch (e) {
    return Left(
      ServerFailure(e.message)
    );
  }
}

         │
         ▼

result.fold(
  (failure) => emit(
    AuthError(
      message: failure.message
    )
  ),
  (user) => emit(
    Authenticated(user: user)
  ),
);</code></pre>
        `
    }
];

// Page template function
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
            <li class="nav-section active">
                <div class="nav-section-title"><i class="fas fa-sitemap"></i><span>Architecture</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="09-clean-architecture.html">9. Clean Architecture</a></li>
                    <li><a href="10-feature-modules.html">10. Feature Modules</a></li>
                    <li><a href="11-state-management.html">11. State Management</a></li>
                    <li><a href="12-dependency-injection.html">12. Dependency Injection</a></li>
                    <li><a href="13-navigation.html">13. Navigation</a></li>
                    <li><a href="14-data-flow.html">14. Data Flow</a></li>
                    <li><a href="15-repository-pattern.html">15. Repository Pattern</a></li>
                    <li><a href="16-use-cases.html">16. Use Cases</a></li>
                    <li><a href="17-entities-models.html">17. Entities & Models</a></li>
                    <li><a href="18-error-handling.html">18. Error Handling</a></li>
                    <li><a href="19-caching.html">19. Caching</a></li>
                    <li><a href="20-offline-first.html">20. Offline-First</a></li>
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

                <div class="page-navigation">
                    <a href="08-glossary.html" class="page-nav-link prev"><i class="fas fa-arrow-left"></i> Previous</a>
                    <a href="21-brand-guidelines.html" class="page-nav-link next">Next <i class="fas fa-arrow-right"></i></a>
                </div>
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

console.log(`\nGenerated ${architecturePages.length} architecture pages with detailed system design diagrams!`);
