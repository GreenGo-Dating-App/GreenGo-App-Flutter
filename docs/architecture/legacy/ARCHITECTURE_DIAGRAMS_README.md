# GreenGo App - Architecture Diagrams

This directory contains Python scripts to generate visual architecture diagrams for the GreenGo App MVP using Clean Architecture + BLoC pattern.

## 📋 Prerequisites

Install the Python diagrams library:

```bash
pip install diagrams
```

**Note:** The diagrams library also requires Graphviz to be installed on your system:
- **Windows:** Download from https://graphviz.org/download/ or use `choco install graphviz`
- **macOS:** `brew install graphviz`
- **Linux:** `sudo apt-get install graphviz` or `sudo yum install graphviz`

## 🎨 Available Diagrams

## Frontend Architecture Diagrams

### 1. **greengo_architecture_diagram.py** - Complete Architecture Overview
**Output:** `greengo_mvp_architecture.png`

**Best for:** Understanding the complete system architecture with all layers and connections

**Includes:**
- ✅ All 3 Clean Architecture layers (Presentation, Domain, Data)
- ✅ BLoC pattern components (Events, States, BLoC)
- ✅ 17 feature modules overview
- ✅ Core infrastructure (DI, Error Handling, Utils)
- ✅ Firebase backend services
- ✅ Third-party integrations
- ✅ Data flow connections between all components
- ✅ Dependency injection setup

**Use when:**
- Presenting the architecture to stakeholders
- Onboarding new developers
- Architecture review sessions
- Documentation

**Generate:**
```bash
python greengo_architecture_diagram.py
```

---

### 2. **greengo_detailed_architecture.py** - Feature Module Breakdown
**Output:** `greengo_detailed_architecture.png`

**Best for:** Understanding individual feature implementations and module structure

**Includes:**
- ✅ Detailed breakdown of first 5 features (Auth, Profile, Discovery, Matching, Chat)
- ✅ 3-layer architecture per feature
- ✅ List of all 17 features
- ✅ Dependency injection patterns (Factory, Singleton, External)
- ✅ Error handling flow
- ✅ State management explanation
- ✅ Firebase emulator setup
- ✅ Backend service connections

**Use when:**
- Implementing a new feature module
- Understanding feature-level architecture
- Planning feature development
- Code review for specific features

**Generate:**
```bash
python greengo_detailed_architecture.py
```

---

### 3. **greengo_simple_flow.py** - Clean Architecture Data Flow
**Output:** `greengo_simple_flow.png`

**Best for:** Understanding how data flows through the system

**Includes:**
- ✅ Clear numbered data flow sequence (1-10 steps)
- ✅ Presentation layer (BLoC pattern)
- ✅ Domain layer (Use Cases, Entities, Repository Interfaces)
- ✅ Data layer (Repository Impl, Models, Data Sources)
- ✅ External services (Firebase, APIs, Local Storage)
- ✅ Dependency injection explanation
- ✅ Error handling flow (Exception → Failure → Either)
- ✅ Clean, easy-to-follow layout

**Use when:**
- Learning the codebase for the first time
- Debugging data flow issues
- Teaching Clean Architecture principles
- Understanding request/response flow
- Planning API integrations

**Generate:**
```bash
python greengo_simple_flow.py
```

---

## Backend & Microservices Diagrams

### 4. **greengo_microservices_diagram.py** - Microservices Architecture
**Output:** `greengo_microservices_architecture.png`

**Best for:** Understanding the backend microservices, cloud functions, and infrastructure

**Includes:**
- ✅ 160+ Firebase Cloud Functions organized by service domain
- ✅ 12 microservice categories (Media, Messaging, Backup, etc.)
- ✅ Django REST Backend with 5 core services
- ✅ Docker containerized infrastructure
- ✅ Google Cloud Platform services (Vision API, Translation, Speech-to-Text, BigQuery)
- ✅ Third-party integrations (Agora, SendGrid, Twilio, Stripe)
- ✅ Data stores (Firestore, PostgreSQL, Redis, BigQuery)
- ✅ API Gateway (Nginx)
- ✅ Inter-service communication patterns

**Microservice Categories:**
1. Media Processing (10 functions) - Image/video compression, transcription
2. Messaging (8 functions) - Translation, scheduled messages
3. Backup & Export (8 functions) - Conversation backup, PDF export
4. Subscription (4 functions) - Payment webhooks, renewal management
5. Coin Service (6 functions) - Virtual currency management
6. Analytics (20+ functions) - Revenue, cohort, churn prediction
7. Gamification (8 functions) - XP, achievements, challenges
8. Safety & Moderation (11 functions) - Content moderation, reporting
9. Admin Panel (25+ functions) - Dashboard, user management
10. Notifications (8 functions) - Push, email, SMS
11. Video Calling (21 functions) - WebRTC, Agora, group calls
12. Security (5 functions) - Security audits

**Use when:**
- Understanding backend architecture
- Planning new backend features
- DevOps and infrastructure planning
- Microservices design review
- Scaling strategy discussions

**Generate:**
```bash
python greengo_microservices_diagram.py
```

---

### 5. **greengo_functions_detailed.py** - Cloud Functions Breakdown
**Output:** `greengo_functions_detailed.png`

**Best for:** Understanding function types, triggers, and execution patterns

**Includes:**
- ✅ Function trigger types (HTTP Callable, Storage, Firestore, Scheduled, Webhooks)
- ✅ Detailed function breakdown by service domain
- ✅ Execution patterns and schedules
- ✅ Data flow between functions and services
- ✅ AI/ML service integrations

**Function Types:**
- **HTTP Callable (~120 functions):** User-facing API functions with authentication
- **Storage Triggered (~10 functions):** Auto-triggered on file uploads
- **Firestore Triggered (~15 functions):** React to database changes
- **Scheduled/Cron (~15 functions):** Time-based execution (hourly, daily, monthly)
- **Webhooks (~5 functions):** External service callbacks (Google Play, App Store)

**Use when:**
- Implementing new cloud functions
- Understanding function execution flow
- Debugging function triggers
- Planning scheduled jobs
- Understanding webhook integrations

**Generate:**
```bash
python greengo_functions_detailed.py
```

---

## 🚀 Quick Start

### Generate All Diagrams

```bash
# Install requirements
pip install diagrams

# Generate all diagrams
python greengo_architecture_diagram.py
python greengo_detailed_architecture.py
python greengo_simple_flow.py
python greengo_microservices_diagram.py
python greengo_functions_detailed.py
```

### Output Files

After running the scripts, you'll have five PNG files:

**Frontend Architecture:**
1. `greengo_mvp_architecture.png` (417KB) - Complete architecture
2. `greengo_detailed_architecture.png` (574KB) - Feature breakdown
3. `greengo_simple_flow.png` (273KB) - Data flow sequence

**Backend & Microservices:**
4. `greengo_microservices_architecture.png` (805KB) - Microservices architecture
5. `greengo_functions_detailed.png` (560KB) - Cloud functions breakdown

---

## 📐 Architecture Summary

### Pattern
**Clean Architecture + BLoC (Business Logic Component)**

### Core Principles
1. **Separation of Concerns** - Each layer has a specific responsibility
2. **Dependency Inversion** - Dependencies point inward (toward domain)
3. **Framework Independence** - Domain layer has no framework dependencies
4. **Testability** - Each layer can be tested independently
5. **Single Responsibility** - Each use case does one thing

### Layers

#### 1️⃣ Presentation Layer
- **Responsibility:** UI and user interaction
- **Components:**
  - Screens (full-page views)
  - Widgets (reusable UI components)
  - BLoC (business logic components)
  - Events (user actions)
  - States (UI states)
- **Dependencies:** Depends on Domain layer (use cases, entities)

#### 2️⃣ Domain Layer (Pure Business Logic)
- **Responsibility:** Business logic and rules
- **Components:**
  - Entities (business objects - plain Dart classes)
  - Use Cases (single-responsibility actions)
  - Repository Interfaces (abstract contracts)
- **Dependencies:** NO dependencies on outer layers
- **Returns:** `Either<Failure, T>` (functional error handling)

#### 3️⃣ Data Layer
- **Responsibility:** Data management and external communication
- **Components:**
  - Repository Implementations (concrete classes)
  - Models (DTOs with serialization)
  - Data Sources (Remote & Local)
- **Dependencies:** Implements Domain interfaces
- **Converts:** Exceptions → Failures, Models → Entities

### State Management

**BLoC Pattern (Primary)**
```
User Interaction → Event → BLoC → Use Case → Repository → Data Source
                                                                ↓
UI Rebuild ← State ← BLoC ← Either<Failure, T> ← Repository ← Response
```

**Provider (Global State)**
- Language/Locale management
- App-wide settings

### Dependency Injection (GetIt)

- **Factory:** New instance per request (BLoCs)
- **LazySingleton:** Single instance, created on first use (Use Cases, Repositories)
- **External:** Third-party services (Firebase, APIs)

### Error Handling

**Functional Approach with dartz:**
```
Data Layer:         throw ServerException
                           ↓
Repository Layer:   catch → return Left(ServerFailure)
                           ↓
Domain Layer:       return Either<Failure, User>
                           ↓
Presentation:       emit ErrorState or SuccessState
                           ↓
UI:                 Display error or success
```

---

## 📦 Feature Modules (17 Total)

Each feature follows the same 3-layer Clean Architecture:

| # | Feature | Description |
|---|---------|-------------|
| 1 | **Authentication** | Email/password login, social auth, forgot password |
| 2 | **Profile** | User profiles, edit profile, onboarding |
| 3 | **Discovery** | Swipe interface, filters, preferences |
| 4 | **Matching** | Matching algorithm, compatibility scoring |
| 5 | **Chat** | Real-time messaging, conversations |
| 6 | **Notifications** | Push notifications, preferences |
| 7 | **Coins** | Virtual currency, purchase, transactions |
| 8 | **Gamification** | Achievements, badges, rewards |
| 9 | **Subscription** | Premium plans, in-app purchases |
| 10 | **Video Calling** | Video calls functionality |
| 11 | **Analytics** | Event tracking, user analytics |
| 12 | **Accessibility** | Accessibility features |
| 13 | **Safety** | Reporting, blocking, safety tools |
| 14 | **Localization** | Multi-language support |
| 15 | **Admin** | Admin panel features |
| 16 | **Main** | Main navigation, home screen |
| 17 | **Settings** | App settings, preferences |

---

## 🔥 Backend Services

### Firebase Suite
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - NoSQL database
- **Firebase Storage** - File/image storage
- **Cloud Messaging** - Push notifications
- **Firebase Analytics** - User analytics
- **Crashlytics** - Crash reporting
- **Performance Monitoring** - App performance
- **Remote Config** - Feature flags
- **App Check** - App attestation

### Third-Party APIs
- **Google Maps** - Location services
- **ML Kit** - Face detection, translation
- **In-App Purchase** - Subscriptions

### Local Storage
- **SharedPreferences** - Key-value settings
- **Hive** - NoSQL offline database

---

## 🛠️ Technology Stack

### Flutter & Dart
- **Flutter** - UI framework
- **Dart** - Programming language

### State Management
- `flutter_bloc: ^8.1.3` - BLoC pattern
- `provider: ^6.1.1` - Global state
- `equatable: ^2.0.5` - Value equality

### Dependency Injection
- `get_it: ^7.6.4` - Service locator
- `injectable: ^2.3.2` - DI code generation

### Functional Programming
- `dartz: ^0.10.1` - Either<L, R> for error handling

### Networking
- `dio: ^5.4.0` - HTTP client
- `retrofit: ^4.0.3` - Type-safe REST client

### Testing
- `flutter_test` - Flutter testing
- `mockito: ^5.4.4` - Mocking
- `bloc_test: ^9.1.5` - BLoC testing

---

## 📊 Metrics

- **Total Dart Files:** 262
- **Feature Modules:** 17
- **Architecture Layers:** 3 per feature
- **Backend Services:** 9+ Firebase services
- **Third-Party APIs:** 3+ integrations

---

## 📚 Data Flow Example: Sign In

**Step-by-step flow:**

1. **UI:** User taps "Sign In" button on `LoginScreen`
2. **Event:** `AuthSignInWithEmailRequested(email, password)` dispatched
3. **BLoC:** `AuthBloc` receives event, emits `AuthLoading` state
4. **Use Case:** Calls `SignInWithEmail` use case
5. **Repository Interface:** Use case calls `AuthRepository.signInWithEmail()`
6. **Repository Impl:** `AuthRepositoryImpl` executes the call
7. **Data Source:** `AuthRemoteDataSource` calls Firebase Auth API
8. **Firebase:** Firebase authenticates user
9. **Response:** Returns `UserModel` (or throws exception)
10. **Conversion:** Repository converts `UserModel` → `User` entity
11. **Error Handling:** If exception: catch → convert to `Failure` → return `Left(Failure)`
12. **Success:** Return `Right(User)`
13. **BLoC:** Receives `Either<Failure, User>`
14. **State:** Emits `AuthAuthenticated(user)` or `AuthError(message)`
15. **UI:** `BlocBuilder` rebuilds, navigates to home or shows error

---

## 🎯 Best Practices

### When Adding a New Feature

1. **Create Feature Directory Structure:**
   ```
   lib/features/new_feature/
   ├── presentation/
   │   ├── bloc/
   │   ├── screens/
   │   └── widgets/
   ├── domain/
   │   ├── entities/
   │   ├── repositories/
   │   └── usecases/
   └── data/
       ├── datasources/
       ├── models/
       └── repositories/
   ```

2. **Follow Dependency Rule:**
   - Presentation → depends on → Domain
   - Domain → depends on → NOTHING (pure business logic)
   - Data → implements → Domain interfaces

3. **Use Cases:**
   - One use case = one action
   - Implements `UseCase<Type, Params>`
   - Returns `Either<Failure, Type>`

4. **Error Handling:**
   - Data layer: throw exceptions
   - Repository: convert exceptions to failures
   - Return `Either<Failure, T>` everywhere

5. **Register Dependencies:**
   - Update `injection_container.dart`
   - BLoCs: Factory
   - Use Cases, Repos: LazySingleton

---

## 🔍 Troubleshooting

### Diagram Generation Issues

**Problem:** `diagrams` package not found
```bash
# Solution
pip install diagrams
```

**Problem:** Graphviz not installed
```bash
# Windows
choco install graphviz

# macOS
brew install graphviz

# Linux
sudo apt-get install graphviz
```

**Problem:** Permission denied
```bash
# Run with admin/sudo
sudo pip install diagrams
```

### Output Issues

**Problem:** PNG file not generated
- Check console output for errors
- Ensure Graphviz is in PATH
- Try running with `show=True` to debug

**Problem:** Diagram too large/small
- Modify `graph_attr` in the Python file
- Adjust `fontsize`, `ranksep`, `nodesep` values

---

## 📖 Additional Resources

### Clean Architecture
- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture Guide](https://resocoder.com/flutter-clean-architecture-tdd/)

### BLoC Pattern
- [BLoC Library Documentation](https://bloclibrary.dev/)
- [Flutter BLoC Tutorial](https://bloclibrary.dev/tutorials/flutter-counter/)

### Firebase
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

---

## 👥 Contributing

When modifying the architecture:
1. Update the relevant Python diagram file
2. Regenerate the diagram
3. Update this README if necessary
4. Commit both code and diagram changes

---

## 📝 License

Part of the GreenGo App project.

---

**Generated diagrams provide a visual representation of the GreenGo App MVP architecture following Clean Architecture principles with BLoC pattern for state management.**
