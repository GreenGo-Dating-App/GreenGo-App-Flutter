const fs = require('fs');
const path = require('path');

// Page definitions with content
const pages = [
    // Project Overview (1-8)
    {
        num: '02', title: 'Technology Stack', section: 'Project Overview',
        content: `
        <h2>Overview</h2>
        <p>GreenGo is built on a modern, scalable technology stack designed for cross-platform mobile development with cloud-native backend services.</p>

        <h2>Frontend - Flutter</h2>
        <div class="info-box">
            <strong>Framework:</strong> Flutter 3.0+<br>
            <strong>Language:</strong> Dart<br>
            <strong>Platforms:</strong> iOS, Android, Web
        </div>

        <h3>Key Packages</h3>
        <table>
            <tr><th>Package</th><th>Version</th><th>Purpose</th></tr>
            <tr><td>flutter_bloc</td><td>8.1.3</td><td>State Management</td></tr>
            <tr><td>get_it</td><td>7.6.4</td><td>Dependency Injection</td></tr>
            <tr><td>dio</td><td>5.4.0</td><td>HTTP Client</td></tr>
            <tr><td>hive</td><td>2.2.3</td><td>Local Storage</td></tr>
            <tr><td>firebase_core</td><td>2.24.2</td><td>Firebase SDK</td></tr>
        </table>

        <h2>Backend - Firebase & GCP</h2>
        <h3>Firebase Services</h3>
        <ul>
            <li><strong>Authentication:</strong> User identity management</li>
            <li><strong>Firestore:</strong> NoSQL database</li>
            <li><strong>Storage:</strong> File storage</li>
            <li><strong>Cloud Functions:</strong> Serverless compute</li>
            <li><strong>Messaging:</strong> Push notifications</li>
            <li><strong>Analytics:</strong> Usage tracking</li>
            <li><strong>Crashlytics:</strong> Crash reporting</li>
        </ul>

        <h3>Google Cloud Platform</h3>
        <ul>
            <li><strong>Cloud Vision API:</strong> Image analysis</li>
            <li><strong>Cloud Translation:</strong> Message translation</li>
            <li><strong>Vertex AI:</strong> ML matching</li>
            <li><strong>BigQuery:</strong> Analytics warehouse</li>
            <li><strong>Cloud KMS:</strong> Key management</li>
        </ul>

        <h2>Backend API - Django</h2>
        <ul>
            <li><strong>Framework:</strong> Django 4.2.7</li>
            <li><strong>API:</strong> Django REST Framework</li>
            <li><strong>Database:</strong> PostgreSQL</li>
            <li><strong>Cache:</strong> Redis</li>
            <li><strong>Task Queue:</strong> Celery</li>
        </ul>

        <h2>Infrastructure</h2>
        <ul>
            <li><strong>IaC:</strong> Terraform</li>
            <li><strong>Containers:</strong> Docker</li>
            <li><strong>CI/CD:</strong> GitHub Actions</li>
        </ul>
        `
    },
    {
        num: '03', title: 'Repository Structure', section: 'Project Overview',
        content: `
        <h2>Root Directory</h2>
        <pre><code>GreenGo-App-Flutter/
├── lib/                    # Flutter source code
├── android/                # Android platform code
├── ios/                    # iOS platform code
├── web/                    # Web platform code
├── test/                   # Test files
├── functions/              # Firebase Cloud Functions
├── backend/                # Django backend
├── docker/                 # Docker configuration
├── terraform/              # Infrastructure as Code
├── docs/                   # Project documentation
├── devops/                 # DevOps scripts
├── security_audit/         # Security testing
└── assets/                 # Images, fonts, icons</code></pre>

        <h2>Flutter Source (lib/)</h2>
        <pre><code>lib/
├── main.dart               # App entry point
├── core/                   # Shared utilities
│   ├── config/             # App configuration
│   ├── constants/          # Colors, dimensions
│   ├── di/                 # Dependency injection
│   ├── errors/             # Error handling
│   ├── network/            # API client
│   ├── providers/          # State providers
│   ├── theme/              # App theming
│   ├── usecases/           # Base use case
│   └── widgets/            # Shared widgets
├── features/               # Feature modules
│   ├── authentication/     # Login, register
│   ├── profile/            # User profiles
│   ├── matching/           # Match algorithm
│   ├── discovery/          # Swipe UI
│   ├── chat/               # Messaging
│   ├── notifications/      # Notifications
│   ├── subscription/       # Premium features
│   ├── coins/              # Virtual currency
│   ├── gamification/       # XP, achievements
│   └── ...
├── l10n/                   # Localization files
└── generated/              # Generated code</code></pre>

        <h2>Feature Module Structure</h2>
        <p>Each feature follows Clean Architecture:</p>
        <pre><code>feature/
├── domain/
│   ├── entities/           # Business objects
│   ├── repositories/       # Abstract repos
│   └── usecases/           # Business logic
├── data/
│   ├── models/             # Data models
│   ├── datasources/        # API/local sources
│   └── repositories/       # Implementations
└── presentation/
    ├── bloc/               # State management
    ├── screens/            # UI screens
    └── widgets/            # UI components</code></pre>

        <h2>Cloud Functions (functions/)</h2>
        <pre><code>functions/src/
├── index.ts                # Function exports
├── media/                  # Image/video processing
├── messaging/              # Message handling
├── subscriptions/          # Payment webhooks
├── coins/                  # Currency logic
├── analytics/              # Data analytics
├── gamification/           # XP and rewards
├── safety/                 # Content moderation
├── admin/                  # Admin functions
└── notifications/          # Push notifications</code></pre>
        `
    },
    {
        num: '04', title: 'Version History', section: 'Project Overview',
        content: `
        <h2>Current Version</h2>
        <div class="info-box">
            <strong>Version:</strong> 1.0.0+1<br>
            <strong>Status:</strong> MVP Development<br>
            <strong>Flutter SDK:</strong> >=3.0.0 <4.0.0
        </div>

        <h2>Changelog</h2>

        <h3>v1.0.0 (Current)</h3>
        <p><strong>Release Date:</strong> In Development</p>
        <h4>Features</h4>
        <ul>
            <li>Email/password authentication</li>
            <li>8-step profile onboarding</li>
            <li>ML-based matching algorithm</li>
            <li>Swipe-based discovery</li>
            <li>Real-time chat messaging</li>
            <li>Push notifications</li>
            <li>Subscription tiers (Basic, Silver, Gold)</li>
            <li>Virtual currency system</li>
            <li>Gamification (XP, achievements, leaderboards)</li>
            <li>7 language support</li>
        </ul>

        <h4>Architecture</h4>
        <ul>
            <li>Clean Architecture implementation</li>
            <li>BLoC state management</li>
            <li>Firebase backend integration</li>
            <li>70+ Cloud Functions</li>
            <li>Terraform infrastructure</li>
            <li>Docker development environment</li>
        </ul>

        <h4>Known Limitations (MVP)</h4>
        <ul>
            <li>Social authentication disabled</li>
            <li>Biometric authentication disabled</li>
            <li>Video calling disabled</li>
            <li>Voice messages disabled</li>
        </ul>

        <h2>Roadmap</h2>
        <h3>v1.1.0 (Planned)</h3>
        <ul>
            <li>Enable social authentication</li>
            <li>Enable video calling with Agora</li>
            <li>Add voice messages</li>
            <li>Performance optimizations</li>
        </ul>

        <h3>v1.2.0 (Planned)</h3>
        <ul>
            <li>Advanced AI matching improvements</li>
            <li>Group events feature</li>
            <li>Enhanced analytics dashboard</li>
        </ul>
        `
    },
    {
        num: '05', title: 'Getting Started', section: 'Project Overview',
        content: `
        <h2>Prerequisites</h2>
        <h3>Required Software</h3>
        <ul>
            <li><strong>Flutter SDK:</strong> 3.0.0 or higher</li>
            <li><strong>Dart SDK:</strong> 2.17.0 or higher</li>
            <li><strong>Node.js:</strong> 18.x (for Cloud Functions)</li>
            <li><strong>Docker:</strong> For local development</li>
            <li><strong>Git:</strong> Version control</li>
        </ul>

        <h3>Recommended IDEs</h3>
        <ul>
            <li>VS Code with Flutter extension</li>
            <li>Android Studio with Flutter plugin</li>
            <li>IntelliJ IDEA with Dart plugin</li>
        </ul>

        <h2>Installation Steps</h2>
        <h3>1. Clone the Repository</h3>
        <pre><code>git clone https://github.com/greengochat/greengo-app-flutter.git
cd greengo-app-flutter</code></pre>

        <h3>2. Install Flutter Dependencies</h3>
        <pre><code>flutter pub get</code></pre>

        <h3>3. Configure Environment</h3>
        <pre><code>cp .env.example .env
# Edit .env with your API keys</code></pre>

        <h3>4. Start Docker Services</h3>
        <pre><code>cd docker
docker-compose up -d</code></pre>

        <h3>5. Run the App</h3>
        <pre><code>flutter run</code></pre>

        <h2>Environment Configuration</h2>
        <p>Key environment variables in <code>.env</code>:</p>
        <pre><code># Firebase
USE_FIREBASE_EMULATORS=true

# Features
ENABLE_VIDEO_CALLING=false
ENABLE_IN_APP_PURCHASES=true
ENABLE_FIREBASE_ANALYTICS=true

# API Keys (for production)
AGORA_APP_ID=your_agora_id
STRIPE_PUBLISHABLE_KEY=your_stripe_key
SENDGRID_API_KEY=your_sendgrid_key</code></pre>

        <div class="warning-box">
            <strong>Important:</strong> Never commit API keys to version control. Use environment variables or secure secret management.
        </div>
        `
    },
    {
        num: '06', title: 'Development Environment', section: 'Project Overview',
        content: `
        <h2>IDE Setup</h2>
        <h3>VS Code</h3>
        <p>Recommended extensions:</p>
        <ul>
            <li>Flutter</li>
            <li>Dart</li>
            <li>Flutter Widget Snippets</li>
            <li>Bracket Pair Colorizer</li>
            <li>GitLens</li>
            <li>Docker</li>
            <li>Terraform</li>
        </ul>

        <h3>Recommended Settings</h3>
        <pre><code>{
  "editor.formatOnSave": true,
  "dart.lineLength": 100,
  "[dart]": {
    "editor.rulers": [100],
    "editor.defaultFormatter": "Dart-Code.dart-code"
  }
}</code></pre>

        <h2>Flutter Configuration</h2>
        <pre><code># Check Flutter installation
flutter doctor

# Enable platforms
flutter config --enable-web
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
flutter config --enable-windows-desktop</code></pre>

        <h2>Firebase CLI</h2>
        <pre><code># Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize project
firebase init</code></pre>

        <h2>Docker Environment</h2>
        <p>The Docker setup provides:</p>
        <ul>
            <li>Firebase Emulators</li>
            <li>PostgreSQL database</li>
            <li>Redis cache</li>
            <li>Nginx reverse proxy</li>
            <li>Admin UIs (Adminer, Redis Commander)</li>
        </ul>

        <h3>Starting Services</h3>
        <pre><code>cd docker
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down</code></pre>

        <h2>Code Generation</h2>
        <p>Run build_runner for generated code:</p>
        <pre><code>flutter pub run build_runner build --delete-conflicting-outputs</code></pre>
        `
    },
    {
        num: '07', title: 'Quick Start Tutorial', section: 'Project Overview',
        content: `
        <h2>10-Minute Setup</h2>
        <p>Get the app running locally in under 10 minutes.</p>

        <h3>Step 1: Clone & Install (2 min)</h3>
        <pre><code>git clone https://github.com/greengochat/greengo-app-flutter.git
cd greengo-app-flutter
flutter pub get</code></pre>

        <h3>Step 2: Start Docker (3 min)</h3>
        <pre><code>cd docker
docker-compose up -d
cd ..</code></pre>

        <div class="info-box">
            Wait for all containers to start. Check with <code>docker ps</code>
        </div>

        <h3>Step 3: Configure Environment (1 min)</h3>
        <pre><code>cp .env.example .env</code></pre>
        <p>The default settings work for local development.</p>

        <h3>Step 4: Run the App (2 min)</h3>
        <pre><code># For Chrome
flutter run -d chrome

# For connected device
flutter run

# For specific device
flutter devices
flutter run -d &lt;device-id&gt;</code></pre>

        <h3>Step 5: Create Test Account (2 min)</h3>
        <ol>
            <li>Open the app</li>
            <li>Click "Create Account"</li>
            <li>Enter email: <code>test@example.com</code></li>
            <li>Enter password: <code>Test123!</code></li>
            <li>Complete the 8-step onboarding</li>
        </ol>

        <h2>Accessing Services</h2>
        <table>
            <tr><th>Service</th><th>URL</th></tr>
            <tr><td>Firebase Emulator UI</td><td>http://localhost:4000</td></tr>
            <tr><td>Firestore</td><td>http://localhost:8080</td></tr>
            <tr><td>Auth Emulator</td><td>http://localhost:9099</td></tr>
            <tr><td>Adminer (DB)</td><td>http://localhost:8081</td></tr>
            <tr><td>Redis Commander</td><td>http://localhost:8082</td></tr>
        </table>

        <h2>Next Steps</h2>
        <ul>
            <li>Read the <a href="09-clean-architecture.html">Architecture Guide</a></li>
            <li>Explore <a href="10-feature-modules.html">Feature Modules</a></li>
            <li>Understand <a href="11-state-management.html">State Management</a></li>
        </ul>
        `
    },
    {
        num: '08', title: 'Glossary & Terminology', section: 'Project Overview',
        content: `
        <h2>Architecture Terms</h2>
        <table>
            <tr><th>Term</th><th>Definition</th></tr>
            <tr><td>BLoC</td><td>Business Logic Component - State management pattern</td></tr>
            <tr><td>Clean Architecture</td><td>Separation of concerns into domain, data, and presentation layers</td></tr>
            <tr><td>Entity</td><td>Core business object in the domain layer</td></tr>
            <tr><td>Model</td><td>Data representation with serialization in the data layer</td></tr>
            <tr><td>Use Case</td><td>Single business operation encapsulation</td></tr>
            <tr><td>Repository</td><td>Data access abstraction layer</td></tr>
            <tr><td>DataSource</td><td>Concrete data fetching implementation (remote/local)</td></tr>
        </table>

        <h2>App-Specific Terms</h2>
        <table>
            <tr><th>Term</th><th>Definition</th></tr>
            <tr><td>Match</td><td>Mutual like between two users</td></tr>
            <tr><td>Super Like</td><td>Premium like that notifies the user</td></tr>
            <tr><td>Boost</td><td>Temporary profile visibility increase</td></tr>
            <tr><td>Coins</td><td>Virtual currency for premium actions</td></tr>
            <tr><td>XP</td><td>Experience points for gamification</td></tr>
            <tr><td>Compatibility Score</td><td>ML-calculated match percentage</td></tr>
        </table>

        <h2>Technical Terms</h2>
        <table>
            <tr><th>Term</th><th>Definition</th></tr>
            <tr><td>FCM</td><td>Firebase Cloud Messaging - Push notifications</td></tr>
            <tr><td>Firestore</td><td>Firebase NoSQL document database</td></tr>
            <tr><td>Cloud Functions</td><td>Serverless backend functions</td></tr>
            <tr><td>GetIt</td><td>Service locator for dependency injection</td></tr>
            <tr><td>Either</td><td>Functional type for error handling (Left=error, Right=success)</td></tr>
        </table>

        <h2>Subscription Terms</h2>
        <table>
            <tr><th>Term</th><th>Definition</th></tr>
            <tr><td>Basic</td><td>Free tier with limited features</td></tr>
            <tr><td>Silver</td><td>Mid-tier subscription ($9.99/mo)</td></tr>
            <tr><td>Gold</td><td>Premium subscription ($19.99/mo)</td></tr>
            <tr><td>IAP</td><td>In-App Purchase</td></tr>
        </table>
        `
    },

    // Architecture (9-20)
    {
        num: '09', title: 'Clean Architecture', section: 'Architecture',
        content: `
        <h2>Overview</h2>
        <p>GreenGo implements Clean Architecture to maintain separation of concerns, testability, and scalability.</p>

        <h2>Layer Structure</h2>
        <h3>1. Domain Layer (Innermost)</h3>
        <p>Contains business logic, independent of any framework.</p>
        <ul>
            <li><strong>Entities:</strong> Core business objects</li>
            <li><strong>Repositories:</strong> Abstract data interfaces</li>
            <li><strong>Use Cases:</strong> Business operations</li>
        </ul>

        <h3>2. Data Layer</h3>
        <p>Implements data operations and external integrations.</p>
        <ul>
            <li><strong>Models:</strong> Data objects with serialization</li>
            <li><strong>DataSources:</strong> API and local data access</li>
            <li><strong>Repository Implementations:</strong> Concrete repos</li>
        </ul>

        <h3>3. Presentation Layer (Outermost)</h3>
        <p>UI and state management.</p>
        <ul>
            <li><strong>BLoCs:</strong> State management</li>
            <li><strong>Screens:</strong> UI pages</li>
            <li><strong>Widgets:</strong> Reusable UI components</li>
        </ul>

        <h2>Dependency Rule</h2>
        <div class="info-box">
            Dependencies point inward. Domain has no dependencies. Data depends on Domain. Presentation depends on Domain.
        </div>

        <h2>Example Flow</h2>
        <pre><code>UI (Screen)
  → BLoC (Event)
    → Use Case
      → Repository (Abstract)
        → Repository Impl
          → DataSource
            → API/Database</code></pre>

        <h2>Benefits</h2>
        <ul>
            <li><strong>Testability:</strong> Each layer can be tested independently</li>
            <li><strong>Maintainability:</strong> Changes are isolated</li>
            <li><strong>Scalability:</strong> Easy to add new features</li>
            <li><strong>Framework Independence:</strong> Business logic is portable</li>
        </ul>
        `
    },
    {
        num: '10', title: 'Feature Modules', section: 'Architecture',
        content: `
        <h2>Overview</h2>
        <p>Each feature is self-contained with its own domain, data, and presentation layers.</p>

        <h2>Feature List</h2>
        <table>
            <tr><th>Feature</th><th>Purpose</th><th>Location</th></tr>
            <tr><td>Authentication</td><td>User login/register</td><td>lib/features/authentication/</td></tr>
            <tr><td>Profile</td><td>User profiles</td><td>lib/features/profile/</td></tr>
            <tr><td>Matching</td><td>Compatibility algorithm</td><td>lib/features/matching/</td></tr>
            <tr><td>Discovery</td><td>Swipe interface</td><td>lib/features/discovery/</td></tr>
            <tr><td>Chat</td><td>Messaging</td><td>lib/features/chat/</td></tr>
            <tr><td>Notifications</td><td>Push/in-app alerts</td><td>lib/features/notifications/</td></tr>
            <tr><td>Subscription</td><td>Premium tiers</td><td>lib/features/subscription/</td></tr>
            <tr><td>Coins</td><td>Virtual currency</td><td>lib/features/coins/</td></tr>
            <tr><td>Gamification</td><td>XP/achievements</td><td>lib/features/gamification/</td></tr>
            <tr><td>Analytics</td><td>Event tracking</td><td>lib/features/analytics/</td></tr>
            <tr><td>Safety</td><td>Moderation</td><td>lib/features/safety/</td></tr>
            <tr><td>Admin</td><td>Admin panel</td><td>lib/features/admin/</td></tr>
        </table>

        <h2>Module Structure</h2>
        <pre><code>feature_name/
├── domain/
│   ├── entities/
│   │   └── user.dart
│   ├── repositories/
│   │   └── user_repository.dart
│   └── usecases/
│       └── get_user.dart
├── data/
│   ├── models/
│   │   └── user_model.dart
│   ├── datasources/
│   │   ├── user_remote_datasource.dart
│   │   └── user_local_datasource.dart
│   └── repositories/
│       └── user_repository_impl.dart
└── presentation/
    ├── bloc/
    │   ├── user_bloc.dart
    │   ├── user_event.dart
    │   └── user_state.dart
    ├── screens/
    │   └── user_screen.dart
    └── widgets/
        └── user_card.dart</code></pre>
        `
    },
    {
        num: '11', title: 'State Management (BLoC)', section: 'Architecture',
        content: `
        <h2>Overview</h2>
        <p>GreenGo uses flutter_bloc for state management, following the BLoC pattern.</p>

        <h2>Core Concepts</h2>
        <ul>
            <li><strong>Event:</strong> Input to the BLoC</li>
            <li><strong>State:</strong> Output from the BLoC</li>
            <li><strong>BLoC:</strong> Transforms events into states</li>
        </ul>

        <h2>Example Implementation</h2>
        <h3>Events</h3>
        <pre><code>abstract class AuthEvent extends Equatable {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested(this.email, this.password);

  @override
  List&lt;Object&gt; get props => [email, password];
}</code></pre>

        <h3>States</h3>
        <pre><code>abstract class AuthState extends Equatable {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final User user;
  AuthSuccess(this.user);
}
class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}</code></pre>

        <h3>BLoC</h3>
        <pre><code>class AuthBloc extends Bloc&lt;AuthEvent, AuthState&gt; {
  final LoginUseCase loginUseCase;

  AuthBloc(this.loginUseCase) : super(AuthInitial()) {
    on&lt;LoginRequested&gt;(_onLoginRequested);
  }

  Future&lt;void&gt; _onLoginRequested(
    LoginRequested event,
    Emitter&lt;AuthState&gt; emit,
  ) async {
    emit(AuthLoading());

    final result = await loginUseCase(
      LoginParams(event.email, event.password),
    );

    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => emit(AuthSuccess(user)),
    );
  }
}</code></pre>

        <h2>Usage in UI</h2>
        <pre><code>BlocBuilder&lt;AuthBloc, AuthState&gt;(
  builder: (context, state) {
    if (state is AuthLoading) {
      return CircularProgressIndicator();
    }
    if (state is AuthSuccess) {
      return HomeScreen(user: state.user);
    }
    return LoginForm();
  },
)</code></pre>
        `
    },
    {
        num: '12', title: 'Dependency Injection', section: 'Architecture',
        content: `
        <h2>Overview</h2>
        <p>GreenGo uses GetIt as a service locator for dependency injection.</p>

        <h2>Configuration</h2>
        <p>Location: <code>lib/core/di/injection_container.dart</code></p>

        <h3>Registration</h3>
        <pre><code>final sl = GetIt.instance;

Future&lt;void&gt; init() async {
  // BLoCs
  sl.registerFactory(() => AuthBloc(sl()));
  sl.registerFactory(() => ProfileBloc(sl(), sl()));

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));

  // Repositories
  sl.registerLazySingleton&lt;AuthRepository&gt;(
    () => AuthRepositoryImpl(sl(), sl()),
  );

  // Data Sources
  sl.registerLazySingleton&lt;AuthRemoteDataSource&gt;(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
}</code></pre>

        <h2>Usage</h2>
        <pre><code>// In main.dart
void main() async {
  await init();
  runApp(MyApp());
}

// Accessing dependencies
BlocProvider(
  create: (_) => sl&lt;AuthBloc&gt;(),
  child: LoginScreen(),
)</code></pre>

        <h2>Registration Types</h2>
        <table>
            <tr><th>Method</th><th>Description</th><th>Use For</th></tr>
            <tr><td>registerFactory</td><td>New instance each time</td><td>BLoCs</td></tr>
            <tr><td>registerLazySingleton</td><td>Single instance, lazy</td><td>Services, Repos</td></tr>
            <tr><td>registerSingleton</td><td>Single instance, immediate</td><td>Core services</td></tr>
        </table>
        `
    },
    {
        num: '13', title: 'Navigation Architecture', section: 'Architecture',
        content: `
        <h2>Overview</h2>
        <p>GreenGo uses Flutter's Navigator 2.0 with named routes.</p>

        <h2>Route Configuration</h2>
        <pre><code>MaterialApp(
  initialRoute: '/',
  routes: {
    '/': (context) => AuthWrapper(),
    '/login': (context) => LoginScreen(),
    '/register': (context) => RegisterScreen(),
    '/forgot-password': (context) => ForgotPasswordScreen(),
    '/home': (context) => MainNavigationScreen(),
  },
)</code></pre>

        <h2>Main Navigation</h2>
        <p>Bottom navigation with 4 tabs:</p>
        <ol>
            <li><strong>Discover:</strong> Swipe cards</li>
            <li><strong>Matches:</strong> Match list</li>
            <li><strong>Chat:</strong> Conversations</li>
            <li><strong>Profile:</strong> User profile</li>
        </ol>

        <h2>Navigation Flow</h2>
        <pre><code>App Start
  → AuthWrapper
    → Authenticated?
      → Yes: MainNavigationScreen
      → No: LoginScreen
        → Register / Forgot Password
          → Onboarding (8 steps)
            → MainNavigationScreen</code></pre>

        <h2>Programmatic Navigation</h2>
        <pre><code>// Push named route
Navigator.pushNamed(context, '/home');

// Push with arguments
Navigator.pushNamed(
  context,
  '/chat',
  arguments: {'matchId': '123'},
);

// Replace
Navigator.pushReplacementNamed(context, '/home');

// Pop
Navigator.pop(context);</code></pre>
        `
    },
    {
        num: '14', title: 'Data Flow Diagram', section: 'Architecture',
        content: `
        <h2>Overview</h2>
        <p>Visual representation of how data flows through the application.</p>

        <h2>Request Flow</h2>
        <pre><code>┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Screen    │────▶│    BLoC     │────▶│  Use Case   │
│   (Event)   │     │   (Event)   │     │  (Params)   │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Repository  │◀────│ Repository  │◀────│  Abstract   │
│    Impl     │     │   (Impl)    │     │   Repo      │
└─────────────┘     └─────────────┘     └─────────────┘
       │
       ▼
┌─────────────┐     ┌─────────────┐
│ DataSource  │────▶│  Firebase/  │
│  (Remote)   │     │    API      │
└─────────────┘     └─────────────┘</code></pre>

        <h2>Response Flow</h2>
        <pre><code>┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Firebase   │────▶│ DataSource  │────▶│   Model     │
│   Response  │     │  (Parse)    │     │  (JSON)     │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Screen    │◀────│    BLoC     │◀────│   Entity    │
│   (State)   │     │   (State)   │     │  (Domain)   │
└─────────────┘     └─────────────┘     └─────────────┘</code></pre>

        <h2>Real-time Data Flow</h2>
        <pre><code>Firestore Stream
       │
       ▼
DataSource (StreamController)
       │
       ▼
Repository (Transform to Entity)
       │
       ▼
BLoC (Listen & Emit State)
       │
       ▼
UI (BlocBuilder)</code></pre>
        `
    },
    {
        num: '15', title: 'Repository Pattern', section: 'Architecture',
        content: `
        <h2>Overview</h2>
        <p>Repositories abstract data sources from the domain layer.</p>

        <h2>Abstract Repository</h2>
        <pre><code>// domain/repositories/user_repository.dart
abstract class UserRepository {
  Future&lt;Either&lt;Failure, User&gt;&gt; getUser(String id);
  Future&lt;Either&lt;Failure, void&gt;&gt; updateUser(User user);
  Stream&lt;User&gt; watchUser(String id);
}</code></pre>

        <h2>Repository Implementation</h2>
        <pre><code>// data/repositories/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl(
    this.remoteDataSource,
    this.localDataSource,
    this.networkInfo,
  );

  @override
  Future&lt;Either&lt;Failure, User&gt;&gt; getUser(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.getUser(id);
        await localDataSource.cacheUser(userModel);
        return Right(userModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      try {
        final userModel = await localDataSource.getCachedUser(id);
        return Right(userModel.toEntity());
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }
}</code></pre>

        <h2>Benefits</h2>
        <ul>
            <li>Domain layer doesn't know about data sources</li>
            <li>Easy to swap implementations</li>
            <li>Centralized error handling</li>
            <li>Offline support via local cache</li>
        </ul>
        `
    },
    {
        num: '16', title: 'Use Cases Design', section: 'Architecture',
        content: `
        <h2>Overview</h2>
        <p>Use cases encapsulate single business operations.</p>

        <h2>Base Use Case</h2>
        <pre><code>// core/usecases/usecase.dart
abstract class UseCase&lt;Type, Params&gt; {
  Future&lt;Either&lt;Failure, Type&gt;&gt; call(Params params);
}

class NoParams extends Equatable {
  @override
  List&lt;Object&gt; get props => [];
}</code></pre>

        <h2>Example Use Case</h2>
        <pre><code>class GetUserProfile implements UseCase&lt;User, String&gt; {
  final UserRepository repository;

  GetUserProfile(this.repository);

  @override
  Future&lt;Either&lt;Failure, User&gt;&gt; call(String userId) {
    return repository.getUser(userId);
  }
}

// With parameters
class LoginParams extends Equatable {
  final String email;
  final String password;

  LoginParams(this.email, this.password);

  @override
  List&lt;Object&gt; get props => [email, password];
}

class LoginUser implements UseCase&lt;User, LoginParams&gt; {
  final AuthRepository repository;

  LoginUser(this.repository);

  @override
  Future&lt;Either&lt;Failure, User&gt;&gt; call(LoginParams params) {
    return repository.login(params.email, params.password);
  }
}</code></pre>

        <h2>Usage in BLoC</h2>
        <pre><code>class AuthBloc extends Bloc&lt;AuthEvent, AuthState&gt; {
  final LoginUser loginUser;

  Future&lt;void&gt; _onLogin(LoginEvent event, Emitter emit) async {
    final result = await loginUser(
      LoginParams(event.email, event.password),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthSuccess(user)),
    );
  }
}</code></pre>
        `
    },
    {
        num: '17', title: 'Entity vs Model', section: 'Architecture',
        content: `
        <h2>Overview</h2>
        <p>Entities and Models serve different purposes in Clean Architecture.</p>

        <h2>Entity (Domain Layer)</h2>
        <ul>
            <li>Core business object</li>
            <li>No dependencies on frameworks</li>
            <li>Contains business rules</li>
            <li>Immutable</li>
        </ul>

        <pre><code>// domain/entities/user.dart
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final int age;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.age,
  });

  bool get isAdult => age >= 18;

  @override
  List&lt;Object&gt; get props => [id, email, name, age];
}</code></pre>

        <h2>Model (Data Layer)</h2>
        <ul>
            <li>Data representation</li>
            <li>Serialization/deserialization</li>
            <li>Extends Entity</li>
            <li>Framework-specific annotations</li>
        </ul>

        <pre><code>// data/models/user_model.dart
class UserModel extends User {
  const UserModel({
    required String id,
    required String email,
    required String name,
    required int age,
  }) : super(id: id, email: email, name: name, age: age);

  factory UserModel.fromJson(Map&lt;String, dynamic&gt; json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      age: json['age'],
    );
  }

  Map&lt;String, dynamic&gt; toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      age: user.age,
    );
  }
}</code></pre>
        `
    },
    {
        num: '18', title: 'Error Handling', section: 'Architecture',
        content: `
        <h2>Overview</h2>
        <p>GreenGo uses the Either type from dartz for functional error handling.</p>

        <h2>Failure Classes</h2>
        <pre><code>// core/errors/failures.dart
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error'])
    : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error'])
    : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet'])
    : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Auth error'])
    : super(message);
}</code></pre>

        <h2>Exception Classes</h2>
        <pre><code>// core/errors/exceptions.dart
class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server error']);
}

class CacheException implements Exception {}
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}</code></pre>

        <h2>Either Usage</h2>
        <pre><code>Future&lt;Either&lt;Failure, User&gt;&gt; getUser(String id) async {
  try {
    final user = await remoteDataSource.getUser(id);
    return Right(user); // Success
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message)); // Error
  }
}

// In BLoC
final result = await getUser(id);

result.fold(
  (failure) => emit(ErrorState(failure.message)),
  (user) => emit(SuccessState(user)),
);</code></pre>
        `
    },
    {
        num: '19', title: 'Caching Strategy', section: 'Architecture',
        content: `
        <h2>Overview</h2>
        <p>GreenGo implements multi-level caching for performance.</p>

        <h2>Cache Layers</h2>
        <ol>
            <li><strong>Memory Cache:</strong> In-app runtime cache</li>
            <li><strong>Local Storage:</strong> Hive/SharedPreferences</li>
            <li><strong>Redis:</strong> Server-side cache</li>
        </ol>

        <h2>Local DataSource</h2>
        <pre><code>class UserLocalDataSource {
  final Box&lt;UserModel&gt; userBox;

  Future&lt;void&gt; cacheUser(UserModel user) async {
    await userBox.put(user.id, user);
  }

  Future&lt;UserModel&gt; getCachedUser(String id) async {
    final user = userBox.get(id);
    if (user == null) throw CacheException();
    return user;
  }

  Future&lt;void&gt; clearCache() async {
    await userBox.clear();
  }
}</code></pre>

        <h2>Cache-First Strategy</h2>
        <pre><code>Future&lt;Either&lt;Failure, User&gt;&gt; getUser(String id) async {
  // Try cache first
  try {
    final cached = await localDataSource.getCachedUser(id);

    // Refresh in background
    _refreshUser(id);

    return Right(cached.toEntity());
  } on CacheException {
    // Fetch from network
    return _fetchFromNetwork(id);
  }
}</code></pre>

        <h2>Cache Invalidation</h2>
        <ul>
            <li>TTL-based expiration</li>
            <li>Event-based invalidation</li>
            <li>Manual refresh</li>
        </ul>
        `
    },
    {
        num: '20', title: 'Offline-First Architecture', section: 'Architecture',
        content: `
        <h2>Overview</h2>
        <p>GreenGo supports offline functionality with sync capabilities.</p>

        <h2>Offline Features</h2>
        <ul>
            <li>View cached profiles</li>
            <li>Read existing messages</li>
            <li>Queue actions for sync</li>
            <li>Access settings</li>
        </ul>

        <h2>Sync Queue</h2>
        <pre><code>class SyncQueue {
  final Box&lt;SyncAction&gt; queue;

  Future&lt;void&gt; enqueue(SyncAction action) async {
    await queue.add(action);
  }

  Future&lt;void&gt; processQueue() async {
    for (final action in queue.values) {
      try {
        await action.execute();
        await action.delete();
      } catch (e) {
        // Retry later
      }
    }
  }
}</code></pre>

        <h2>Network Status</h2>
        <pre><code>class NetworkInfo {
  final Connectivity connectivity;

  Future&lt;bool&gt; get isConnected async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Stream&lt;bool&gt; get onConnectivityChanged {
    return connectivity.onConnectivityChanged
      .map((result) => result != ConnectivityResult.none);
  }
}</code></pre>

        <h2>Conflict Resolution</h2>
        <ul>
            <li><strong>Last Write Wins:</strong> Most recent timestamp</li>
            <li><strong>Server Authority:</strong> Server data takes precedence</li>
            <li><strong>Merge:</strong> Combine changes intelligently</li>
        </ul>
        `
    }
];

// Continue with more pages...
const morePages = [
    // Design System (21-30)
    { num: '21', title: 'Brand Guidelines', section: 'Design System', content: generateDesignContent('Brand Guidelines', 'Brand identity, logo usage, and visual guidelines for GreenGo.') },
    { num: '22', title: 'Color Palette', section: 'Design System', content: generateColorContent() },
    { num: '23', title: 'Typography System', section: 'Design System', content: generateTypographyContent() },
    { num: '24', title: 'Spacing & Dimensions', section: 'Design System', content: generateSpacingContent() },
    { num: '25', title: 'Component Library', section: 'Design System', content: generateComponentContent() },
    { num: '26', title: 'Icon System', section: 'Design System', content: generatePlaceholderContent('Icon System', 'Custom icons and iconography standards.') },
    { num: '27', title: 'Animation Guidelines', section: 'Design System', content: generatePlaceholderContent('Animation Guidelines', 'Lottie animations, transitions, and motion design.') },
    { num: '28', title: 'Dark/Light Theme', section: 'Design System', content: generatePlaceholderContent('Theming', 'Theme configuration and dark/light mode support.') },
    { num: '29', title: 'Responsive Design', section: 'Design System', content: generatePlaceholderContent('Responsive Design', 'Adaptive layouts for different screen sizes.') },
    { num: '30', title: 'Accessibility Guidelines', section: 'Design System', content: generatePlaceholderContent('Accessibility', 'A11y standards and screen reader support.') },

    // Features (31-50)
    { num: '31', title: 'Authentication Flow', section: 'Core Features', content: generateAuthContent() },
    { num: '32', title: 'Social Authentication', section: 'Core Features', content: generatePlaceholderContent('Social Auth', 'Google, Facebook, Apple sign-in integration.') },
    { num: '33', title: 'Biometric Authentication', section: 'Core Features', content: generatePlaceholderContent('Biometric Auth', 'Fingerprint and Face ID support.') },
    { num: '34', title: 'Profile Onboarding', section: 'Core Features', content: generateOnboardingContent() },
    { num: '35', title: 'Photo Management', section: 'Core Features', content: generatePlaceholderContent('Photo Management', 'Photo upload, verification, and compression.') },
    { num: '36', title: 'Profile Editing', section: 'Core Features', content: generatePlaceholderContent('Profile Editing', 'Edit bio, interests, and preferences.') },
    { num: '37', title: 'Matching Algorithm', section: 'Core Features', content: generateMatchingContent() },
    { num: '38', title: 'Discovery Interface', section: 'Core Features', content: generatePlaceholderContent('Discovery', 'Swipe-based user discovery interface.') },
    { num: '39', title: 'Like/Pass Actions', section: 'Core Features', content: generatePlaceholderContent('Like Actions', 'Like, Super Like, and Pass functionality.') },
    { num: '40', title: 'Match System', section: 'Core Features', content: generatePlaceholderContent('Match System', 'Mutual match detection and notification.') },
    { num: '41', title: 'Real-time Chat', section: 'Core Features', content: generateChatContent() },
    { num: '42', title: 'Message Features', section: 'Core Features', content: generatePlaceholderContent('Message Features', 'Reactions, read receipts, typing indicators.') },
    { num: '43', title: 'Push Notifications', section: 'Core Features', content: generatePlaceholderContent('Push Notifications', 'FCM setup and notification handling.') },
    { num: '44', title: 'In-App Notifications', section: 'Core Features', content: generatePlaceholderContent('In-App Notifications', 'Notification center and preferences.') },
    { num: '45', title: 'Subscription Tiers', section: 'Core Features', content: generateSubscriptionContent() },
    { num: '46', title: 'In-App Purchases', section: 'Core Features', content: generatePlaceholderContent('In-App Purchases', 'Store integration and purchase flow.') },
    { num: '47', title: 'Virtual Currency', section: 'Core Features', content: generatePlaceholderContent('Virtual Currency', 'Coin system, balance, and transactions.') },
    { num: '48', title: 'Gamification System', section: 'Core Features', content: generateGamificationContent() },
    { num: '49', title: 'Daily Challenges', section: 'Core Features', content: generatePlaceholderContent('Daily Challenges', 'Challenge mechanics and rewards.') },
    { num: '50', title: 'Leaderboards', section: 'Core Features', content: generatePlaceholderContent('Leaderboards', 'Ranking system and competition.') },

    // Backend (51-60)
    { num: '51', title: 'Firebase Overview', section: 'Backend Services', content: generateFirebaseContent() },
    { num: '52', title: 'Firestore Database', section: 'Backend Services', content: generatePlaceholderContent('Firestore', 'NoSQL database structure and queries.') },
    { num: '53', title: 'Firebase Authentication', section: 'Backend Services', content: generatePlaceholderContent('Firebase Auth', 'Authentication providers and flows.') },
    { num: '54', title: 'Firebase Storage', section: 'Backend Services', content: generatePlaceholderContent('Firebase Storage', 'File storage and management.') },
    { num: '55', title: 'Cloud Functions', section: 'Backend Services', content: generateCloudFunctionsContent() },
    { num: '56', title: 'Django Backend', section: 'Backend Services', content: generateDjangoContent() },
    { num: '57', title: 'API Documentation', section: 'Backend Services', content: generatePlaceholderContent('API Documentation', 'REST API endpoints and contracts.') },
    { num: '58', title: 'Real-time Sync', section: 'Backend Services', content: generatePlaceholderContent('Real-time Sync', 'Firestore listeners and data sync.') },
    { num: '59', title: 'Background Processing', section: 'Backend Services', content: generatePlaceholderContent('Background Processing', 'Celery task queue and workers.') },
    { num: '60', title: 'Rate Limiting', section: 'Backend Services', content: generatePlaceholderContent('Rate Limiting', 'API throttling and protection.') },

    // Database (61-68)
    { num: '61', title: 'Firestore Schema', section: 'Database', content: generateFirestoreSchemaContent() },
    { num: '62', title: 'PostgreSQL Schema', section: 'Database', content: generatePlaceholderContent('PostgreSQL', 'Relational database schema and tables.') },
    { num: '63', title: 'Data Migration', section: 'Database', content: generatePlaceholderContent('Data Migration', 'Schema evolution and migration strategies.') },
    { num: '64', title: 'Indexing Strategy', section: 'Database', content: generatePlaceholderContent('Indexing', 'Query optimization and indexes.') },
    { num: '65', title: 'Backup & Recovery', section: 'Database', content: generatePlaceholderContent('Backup & Recovery', 'Data backup and disaster recovery.') },
    { num: '66', title: 'Data Retention Policy', section: 'Database', content: generatePlaceholderContent('Data Retention', 'GDPR compliance and data lifecycle.') },
    { num: '67', title: 'Redis Caching', section: 'Database', content: generatePlaceholderContent('Redis', 'Cache configuration and patterns.') },
    { num: '68', title: 'BigQuery Analytics', section: 'Database', content: generatePlaceholderContent('BigQuery', 'Analytics data warehouse.') },

    // Security (69-78)
    { num: '69', title: 'Security Architecture', section: 'Security', content: generateSecurityContent() },
    { num: '70', title: 'Firestore Rules', section: 'Security', content: generatePlaceholderContent('Firestore Rules', 'Security rules for data access control.') },
    { num: '71', title: 'Storage Rules', section: 'Security', content: generatePlaceholderContent('Storage Rules', 'File access permissions.') },
    { num: '72', title: 'Authentication Security', section: 'Security', content: generatePlaceholderContent('Auth Security', 'JWT, sessions, and secure auth.') },
    { num: '73', title: 'Data Encryption', section: 'Security', content: generatePlaceholderContent('Encryption', 'KMS and at-rest encryption.') },
    { num: '74', title: 'App Check', section: 'Security', content: generatePlaceholderContent('App Check', 'Device attestation and protection.') },
    { num: '75', title: 'Content Moderation', section: 'Security', content: generatePlaceholderContent('Content Moderation', 'Photo and text filtering.') },
    { num: '76', title: 'Spam Detection', section: 'Security', content: generatePlaceholderContent('Spam Detection', 'Automated spam and scam detection.') },
    { num: '77', title: 'Reporting System', section: 'Security', content: generatePlaceholderContent('Reporting', 'User report handling system.') },
    { num: '78', title: 'Security Audit', section: 'Security', content: generatePlaceholderContent('Security Audit', 'Penetration testing and audits.') },

    // Integrations (79-88)
    { num: '79', title: 'Agora Video Calling', section: 'Integrations', content: generatePlaceholderContent('Agora', 'Video calling integration and setup.') },
    { num: '80', title: 'Stripe Payments', section: 'Integrations', content: generatePlaceholderContent('Stripe', 'Payment processing integration.') },
    { num: '81', title: 'SendGrid Email', section: 'Integrations', content: generatePlaceholderContent('SendGrid', 'Transactional email service.') },
    { num: '82', title: 'Twilio SMS', section: 'Integrations', content: generatePlaceholderContent('Twilio', 'SMS verification service.') },
    { num: '83', title: 'Google Maps', section: 'Integrations', content: generatePlaceholderContent('Google Maps', 'Location services integration.') },
    { num: '84', title: 'Google Cloud AI', section: 'Integrations', content: generatePlaceholderContent('Google Cloud AI', 'Vision, Translation, Speech APIs.') },
    { num: '85', title: 'Mixpanel Analytics', section: 'Integrations', content: generatePlaceholderContent('Mixpanel', 'Advanced analytics tracking.') },
    { num: '86', title: 'Sentry Tracking', section: 'Integrations', content: generatePlaceholderContent('Sentry', 'Error tracking and monitoring.') },
    { num: '87', title: 'Perspective API', section: 'Integrations', content: generatePlaceholderContent('Perspective API', 'Content moderation service.') },
    { num: '88', title: 'RevenueCat', section: 'Integrations', content: generatePlaceholderContent('RevenueCat', 'Subscription management alternative.') },

    // DevOps (89-96)
    { num: '89', title: 'Terraform Infrastructure', section: 'DevOps', content: generateTerraformContent() },
    { num: '90', title: 'Docker Development', section: 'DevOps', content: generateDockerContent() },
    { num: '91', title: 'CI/CD Pipeline', section: 'DevOps', content: generatePlaceholderContent('CI/CD', 'Continuous integration and deployment.') },
    { num: '92', title: 'Environment Management', section: 'DevOps', content: generateEnvironmentContent() },
    { num: '93', title: 'Feature Flags', section: 'DevOps', content: generatePlaceholderContent('Feature Flags', 'Remote configuration and toggles.') },
    { num: '94', title: 'Pre-commit Hooks', section: 'DevOps', content: generatePlaceholderContent('Pre-commit', 'Code quality automation.') },
    { num: '95', title: 'Deployment Scripts', section: 'DevOps', content: generatePlaceholderContent('Deployment', 'Release automation scripts.') },
    { num: '96', title: 'Firebase Hosting', section: 'DevOps', content: generatePlaceholderContent('Firebase Hosting', 'Web deployment and hosting.') },

    // Testing (97-100)
    { num: '97', title: 'Unit Testing', section: 'Testing', content: generateTestingContent('Unit Testing', 'BLoC and repository testing.') },
    { num: '98', title: 'Widget Testing', section: 'Testing', content: generateTestingContent('Widget Testing', 'UI component testing.') },
    { num: '99', title: 'Integration Testing', section: 'Testing', content: generateTestingContent('Integration Testing', 'End-to-end flow testing.') },
    { num: '100', title: 'Firebase Test Lab', section: 'Testing', content: generateTestingContent('Firebase Test Lab', 'Device farm testing.') }
];

// Content generators
function generatePlaceholderContent(title, description) {
    return `
        <h2>Overview</h2>
        <p>${description}</p>

        <div class="info-box">
            This section provides comprehensive documentation for ${title.toLowerCase()}.
        </div>

        <h2>Key Concepts</h2>
        <p>Understanding the core concepts of ${title.toLowerCase()} in the GreenGo application.</p>

        <h2>Implementation</h2>
        <p>Details on how ${title.toLowerCase()} is implemented in the codebase.</p>

        <h2>Configuration</h2>
        <p>Configuration options and settings for ${title.toLowerCase()}.</p>

        <h2>Best Practices</h2>
        <ul>
            <li>Follow established patterns</li>
            <li>Maintain consistency</li>
            <li>Document changes</li>
            <li>Test thoroughly</li>
        </ul>
    `;
}

function generateDesignContent(title, description) {
    return `
        <h2>Overview</h2>
        <p>${description}</p>

        <h2>Logo Usage</h2>
        <ul>
            <li>Minimum clear space around logo</li>
            <li>Approved color variations</li>
            <li>Minimum size requirements</li>
        </ul>

        <h2>Brand Voice</h2>
        <ul>
            <li><strong>Sophisticated:</strong> Premium, luxurious feel</li>
            <li><strong>Trustworthy:</strong> Safe and secure</li>
            <li><strong>Engaging:</strong> Fun and interactive</li>
        </ul>
    `;
}

function generateColorContent() {
    return `
        <h2>Brand Colors</h2>
        <table>
            <tr><th>Name</th><th>Hex</th><th>Usage</th></tr>
            <tr><td>Rich Gold</td><td>#D4AF37</td><td>Primary accent</td></tr>
            <tr><td>Accent Gold</td><td>#FFD700</td><td>Highlights</td></tr>
            <tr><td>Deep Black</td><td>#0A0A0A</td><td>Primary background</td></tr>
            <tr><td>Charcoal</td><td>#1A1A1A</td><td>Secondary background</td></tr>
        </table>

        <h2>Implementation</h2>
        <pre><code>// lib/core/constants/app_colors.dart
class AppColors {
  static const Color richGold = Color(0xFFD4AF37);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color deepBlack = Color(0xFF0A0A0A);
  static const Color charcoal = Color(0xFF1A1A1A);
}</code></pre>
    `;
}

function generateTypographyContent() {
    return `
        <h2>Font Family</h2>
        <p>GreenGo uses <strong>Poppins</strong> as the primary font family.</p>

        <h2>Font Weights</h2>
        <ul>
            <li><strong>Light (300):</strong> Subtle text</li>
            <li><strong>Regular (400):</strong> Body text</li>
            <li><strong>Medium (500):</strong> Emphasis</li>
            <li><strong>SemiBold (600):</strong> Headings</li>
            <li><strong>Bold (700):</strong> Strong emphasis</li>
        </ul>

        <h2>Scale</h2>
        <table>
            <tr><th>Size</th><th>Usage</th></tr>
            <tr><td>12px</td><td>Caption</td></tr>
            <tr><td>14px</td><td>Body small</td></tr>
            <tr><td>16px</td><td>Body</td></tr>
            <tr><td>18px</td><td>Body large</td></tr>
            <tr><td>24px</td><td>Heading</td></tr>
            <tr><td>32px</td><td>Display</td></tr>
        </table>
    `;
}

function generateSpacingContent() {
    return `
        <h2>Spacing Scale</h2>
        <table>
            <tr><th>Token</th><th>Value</th><th>Usage</th></tr>
            <tr><td>xs</td><td>4px</td><td>Tight spacing</td></tr>
            <tr><td>sm</td><td>8px</td><td>Small gaps</td></tr>
            <tr><td>md</td><td>16px</td><td>Standard spacing</td></tr>
            <tr><td>lg</td><td>24px</td><td>Section spacing</td></tr>
            <tr><td>xl</td><td>32px</td><td>Large gaps</td></tr>
            <tr><td>2xl</td><td>48px</td><td>Page sections</td></tr>
        </table>

        <h2>Implementation</h2>
        <pre><code>// lib/core/constants/app_dimensions.dart
class AppDimensions {
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
}</code></pre>
    `;
}

function generateComponentContent() {
    return `
        <h2>Core Components</h2>
        <ul>
            <li><strong>Buttons:</strong> Primary, secondary, text buttons</li>
            <li><strong>Inputs:</strong> Text fields, dropdowns, checkboxes</li>
            <li><strong>Cards:</strong> Profile cards, match cards</li>
            <li><strong>Modals:</strong> Dialogs, bottom sheets</li>
            <li><strong>Navigation:</strong> Bottom nav, app bar</li>
        </ul>

        <h2>Widget Locations</h2>
        <ul>
            <li>Core widgets: <code>lib/core/widgets/</code></li>
            <li>Feature widgets: <code>lib/features/*/presentation/widgets/</code></li>
        </ul>
    `;
}

function generateAuthContent() {
    return `
        <h2>Authentication Flow</h2>
        <pre><code>App Launch
  → AuthWrapper
    → Check Auth State
      → Logged In: Home
      → Not Logged In: Login Screen
        → Register / Forgot Password
          → Email Verification
            → Onboarding
              → Home</code></pre>

        <h2>Supported Methods</h2>
        <table>
            <tr><th>Method</th><th>Status</th></tr>
            <tr><td>Email/Password</td><td>✅ Active</td></tr>
            <tr><td>Google</td><td>🚧 MVP Disabled</td></tr>
            <tr><td>Facebook</td><td>🚧 MVP Disabled</td></tr>
            <tr><td>Apple</td><td>🚧 MVP Disabled</td></tr>
            <tr><td>Biometric</td><td>🚧 MVP Disabled</td></tr>
        </table>

        <h2>Key Files</h2>
        <ul>
            <li>BLoC: <code>lib/features/authentication/presentation/bloc/auth_bloc.dart</code></li>
            <li>Login: <code>lib/features/authentication/presentation/screens/login_screen.dart</code></li>
            <li>Register: <code>lib/features/authentication/presentation/screens/register_screen.dart</code></li>
        </ul>
    `;
}

function generateOnboardingContent() {
    return `
        <h2>8-Step Onboarding</h2>
        <ol>
            <li><strong>Basic Info:</strong> Name, birthdate, gender</li>
            <li><strong>Photos:</strong> Profile photo upload</li>
            <li><strong>Bio:</strong> About me text</li>
            <li><strong>Interests:</strong> Select interests/hobbies</li>
            <li><strong>Preferences:</strong> Match preferences</li>
            <li><strong>Location:</strong> Location settings</li>
            <li><strong>Notifications:</strong> Notification preferences</li>
            <li><strong>Preview:</strong> Review and confirm</li>
        </ol>

        <h2>BLoC Events</h2>
        <pre><code>OnboardingStepCompleted
OnboardingNextStep
OnboardingPreviousStep
OnboardingSubmit</code></pre>
    `;
}

function generateMatchingContent() {
    return `
        <h2>ML-Based Matching</h2>
        <p>GreenGo uses machine learning for compatibility scoring.</p>

        <h2>Algorithm Components</h2>
        <ol>
            <li><strong>Feature Engineering:</strong> User vector creation</li>
            <li><strong>Compatibility Scoring:</strong> ML prediction</li>
            <li><strong>Candidate Generation:</strong> Filtered matches</li>
            <li><strong>Ranking:</strong> Score-based ordering</li>
        </ol>

        <h2>Key Files</h2>
        <ul>
            <li><code>lib/features/matching/domain/usecases/feature_engineer.dart</code></li>
            <li><code>lib/features/matching/domain/usecases/compatibility_scorer.dart</code></li>
            <li><code>lib/features/matching/domain/usecases/get_match_candidates.dart</code></li>
        </ul>
    `;
}

function generateChatContent() {
    return `
        <h2>Real-time Messaging</h2>
        <p>Firebase Firestore-based real-time chat system.</p>

        <h2>Features</h2>
        <ul>
            <li>Real-time message sync</li>
            <li>Read receipts</li>
            <li>Typing indicators</li>
            <li>Message reactions</li>
            <li>Message search</li>
        </ul>

        <h2>Data Structure</h2>
        <pre><code>conversations/{conversationId}
  - participants: [userId1, userId2]
  - lastMessage: {...}
  - updatedAt: timestamp

  /messages/{messageId}
    - senderId: string
    - text: string
    - timestamp: timestamp
    - read: boolean</code></pre>
    `;
}

function generateSubscriptionContent() {
    return `
        <h2>Subscription Tiers</h2>
        <table>
            <tr><th>Tier</th><th>Price</th><th>Features</th></tr>
            <tr>
                <td>Basic</td>
                <td>Free</td>
                <td>Limited swipes, basic chat</td>
            </tr>
            <tr>
                <td>Silver</td>
                <td>$9.99/mo</td>
                <td>Unlimited swipes, see who likes you</td>
            </tr>
            <tr>
                <td>Gold</td>
                <td>$19.99/mo</td>
                <td>All features, priority matching, boosts</td>
            </tr>
        </table>
    `;
}

function generateGamificationContent() {
    return `
        <h2>Gamification System</h2>
        <ul>
            <li><strong>XP System:</strong> Earn experience points</li>
            <li><strong>Levels:</strong> Progress through levels</li>
            <li><strong>Achievements:</strong> Unlock badges</li>
            <li><strong>Challenges:</strong> Daily/weekly tasks</li>
            <li><strong>Leaderboards:</strong> Compete with others</li>
        </ul>

        <h2>XP Actions</h2>
        <table>
            <tr><th>Action</th><th>XP</th></tr>
            <tr><td>Complete profile</td><td>100</td></tr>
            <tr><td>First match</td><td>50</td></tr>
            <tr><td>Send message</td><td>10</td></tr>
            <tr><td>Daily login</td><td>25</td></tr>
        </table>
    `;
}

function generateFirebaseContent() {
    return `
        <h2>Firebase Services</h2>
        <table>
            <tr><th>Service</th><th>Purpose</th></tr>
            <tr><td>Authentication</td><td>User identity</td></tr>
            <tr><td>Firestore</td><td>NoSQL database</td></tr>
            <tr><td>Storage</td><td>File storage</td></tr>
            <tr><td>Cloud Functions</td><td>Backend logic</td></tr>
            <tr><td>Messaging</td><td>Push notifications</td></tr>
            <tr><td>Analytics</td><td>Usage tracking</td></tr>
            <tr><td>Crashlytics</td><td>Crash reports</td></tr>
            <tr><td>Remote Config</td><td>Feature flags</td></tr>
        </table>
    `;
}

function generateCloudFunctionsContent() {
    return `
        <h2>Cloud Functions</h2>
        <p>70+ serverless functions for backend logic.</p>

        <h2>Function Categories</h2>
        <ul>
            <li><strong>Media:</strong> Image/video processing</li>
            <li><strong>Messaging:</strong> Translation, scheduling</li>
            <li><strong>Subscriptions:</strong> Payment webhooks</li>
            <li><strong>Coins:</strong> Currency management</li>
            <li><strong>Analytics:</strong> Data processing</li>
            <li><strong>Gamification:</strong> XP and rewards</li>
            <li><strong>Safety:</strong> Content moderation</li>
            <li><strong>Notifications:</strong> Push delivery</li>
        </ul>

        <h2>Location</h2>
        <p><code>functions/src/</code></p>
    `;
}

function generateDjangoContent() {
    return `
        <h2>Django Backend</h2>
        <p>REST API backend for extended functionality.</p>

        <h2>Configuration</h2>
        <ul>
            <li><strong>Framework:</strong> Django 4.2.7</li>
            <li><strong>API:</strong> Django REST Framework</li>
            <li><strong>Database:</strong> PostgreSQL</li>
            <li><strong>Cache:</strong> Redis</li>
            <li><strong>Tasks:</strong> Celery</li>
        </ul>

        <h2>Apps</h2>
        <ul>
            <li>authentication</li>
            <li>users</li>
            <li>profiles</li>
            <li>matching</li>
            <li>messaging</li>
            <li>payments</li>
            <li>notifications</li>
        </ul>
    `;
}

function generateFirestoreSchemaContent() {
    return `
        <h2>Collections</h2>
        <ul>
            <li><strong>users</strong> - User accounts</li>
            <li><strong>profiles</strong> - User profiles</li>
            <li><strong>matches</strong> - Match records</li>
            <li><strong>likes</strong> - Like actions</li>
            <li><strong>conversations</strong> - Chat threads</li>
            <li><strong>subscriptions</strong> - Premium subs</li>
            <li><strong>transactions</strong> - Payments</li>
            <li><strong>reports</strong> - User reports</li>
            <li><strong>notifications</strong> - Alerts</li>
        </ul>
    `;
}

function generateSecurityContent() {
    return `
        <h2>Security Layers</h2>
        <ol>
            <li><strong>App Check:</strong> Device attestation</li>
            <li><strong>Authentication:</strong> Firebase Auth</li>
            <li><strong>Authorization:</strong> Security rules</li>
            <li><strong>Encryption:</strong> Data at rest</li>
            <li><strong>Moderation:</strong> Content filtering</li>
        </ol>

        <h2>Key Security Features</h2>
        <ul>
            <li>JWT token authentication</li>
            <li>Password strength validation</li>
            <li>Rate limiting</li>
            <li>Input validation</li>
            <li>Secret detection in CI</li>
        </ul>
    `;
}

function generateTerraformContent() {
    return `
        <h2>Infrastructure as Code</h2>
        <p>Terraform manages GCP infrastructure.</p>

        <h2>Resources</h2>
        <ul>
            <li>Cloud Storage buckets</li>
            <li>Cloud KMS keys</li>
            <li>Service accounts</li>
            <li>Cloud Functions</li>
            <li>VPC Network</li>
            <li>Pub/Sub topics</li>
            <li>BigQuery dataset</li>
            <li>Monitoring alerts</li>
        </ul>

        <h2>Location</h2>
        <p><code>terraform/</code></p>
    `;
}

function generateDockerContent() {
    return `
        <h2>Docker Services</h2>
        <table>
            <tr><th>Service</th><th>Port</th></tr>
            <tr><td>Firebase Emulators</td><td>4000, 8080, 9099</td></tr>
            <tr><td>PostgreSQL</td><td>5432</td></tr>
            <tr><td>Redis</td><td>6379</td></tr>
            <tr><td>Adminer</td><td>8081</td></tr>
            <tr><td>Redis Commander</td><td>8082</td></tr>
            <tr><td>Nginx</td><td>80, 443</td></tr>
        </table>

        <h2>Commands</h2>
        <pre><code># Start
docker-compose up -d

# Stop
docker-compose down

# Logs
docker-compose logs -f</code></pre>
    `;
}

function generateEnvironmentContent() {
    return `
        <h2>Environments</h2>
        <ul>
            <li><strong>Development:</strong> Local with emulators</li>
            <li><strong>Test:</strong> Staging environment</li>
            <li><strong>Production:</strong> Live environment</li>
        </ul>

        <h2>Configuration Files</h2>
        <ul>
            <li><code>devops/dev/config.env</code></li>
            <li><code>devops/test/config.env</code></li>
            <li><code>devops/prod/config.env</code></li>
        </ul>
    `;
}

function generateTestingContent(title, description) {
    return `
        <h2>Overview</h2>
        <p>${description}</p>

        <h2>Testing Framework</h2>
        <ul>
            <li>flutter_test</li>
            <li>mockito</li>
            <li>bloc_test</li>
        </ul>

        <h2>Running Tests</h2>
        <pre><code># All tests
flutter test

# Specific test
flutter test test/path/to/test.dart

# With coverage
flutter test --coverage</code></pre>
    `;
}

// Page template
function createPageHTML(page, prevPage, nextPage) {
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
            <li class="nav-section"><div class="nav-section-title"><i class="fas fa-home"></i><span>Project Overview</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="01-introduction.html">1. Introduction</a></li>
                    <li><a href="02-tech-stack.html">2. Tech Stack</a></li>
                    <li><a href="05-getting-started.html">5. Getting Started</a></li>
                    <li><a href="07-quick-start.html">7. Quick Start</a></li>
                </ul>
            </li>
            <li class="nav-section"><div class="nav-section-title"><i class="fas fa-sitemap"></i><span>Architecture</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="09-clean-architecture.html">9. Clean Architecture</a></li>
                    <li><a href="11-state-management.html">11. State Management</a></li>
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
                    <a href="../index.html">Home</a> / <a href="#">${page.section}</a> / ${page.title}
                </div>
            </div>

            <div class="page-content">
                ${page.content}

                <div class="page-navigation">
                    ${prevPage ? `<a href="${prevPage.num}-${prevPage.title.toLowerCase().replace(/[^a-z0-9]+/g, '-')}.html" class="page-nav-link prev"><i class="fas fa-arrow-left"></i> ${prevPage.title}</a>` : '<span></span>'}
                    ${nextPage ? `<a href="${nextPage.num}-${nextPage.title.toLowerCase().replace(/[^a-z0-9]+/g, '-')}.html" class="page-nav-link next">${nextPage.title} <i class="fas fa-arrow-right"></i></a>` : '<span></span>'}
                </div>
            </div>
        </div>
    </main>

    <script src="../js/main.js"></script>
</body>
</html>`;
}

// Generate all pages
const allPages = [...pages, ...morePages];

allPages.forEach((page, index) => {
    const prevPage = index > 0 ? allPages[index - 1] : null;
    const nextPage = index < allPages.length - 1 ? allPages[index + 1] : null;

    const filename = `${page.num}-${page.title.toLowerCase().replace(/[^a-z0-9]+/g, '-')}.html`;
    const filepath = path.join(__dirname, 'pages', filename);

    const html = createPageHTML(page, prevPage, nextPage);

    fs.writeFileSync(filepath, html);
    console.log(`Created: ${filename}`);
});

console.log(`\\nGenerated ${allPages.length} documentation pages!`);
