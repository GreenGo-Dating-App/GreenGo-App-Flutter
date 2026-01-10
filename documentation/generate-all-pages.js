const fs = require('fs');
const path = require('path');

// All pages with exact filenames matching index.html navigation
const pages = [
    // Project Overview (1-8)
    { file: '01-introduction.html', title: 'Project Introduction', section: 'Project Overview', prev: null, next: '02-tech-stack.html' },
    { file: '02-tech-stack.html', title: 'Technology Stack', section: 'Project Overview', prev: '01-introduction.html', next: '03-repository-structure.html' },
    { file: '03-repository-structure.html', title: 'Repository Structure', section: 'Project Overview', prev: '02-tech-stack.html', next: '04-version-history.html' },
    { file: '04-version-history.html', title: 'Version History', section: 'Project Overview', prev: '03-repository-structure.html', next: '05-getting-started.html' },
    { file: '05-getting-started.html', title: 'Getting Started', section: 'Project Overview', prev: '04-version-history.html', next: '06-dev-environment.html' },
    { file: '06-dev-environment.html', title: 'Development Environment', section: 'Project Overview', prev: '05-getting-started.html', next: '07-quick-start.html' },
    { file: '07-quick-start.html', title: 'Quick Start Tutorial', section: 'Project Overview', prev: '06-dev-environment.html', next: '08-glossary.html' },
    { file: '08-glossary.html', title: 'Glossary & Terminology', section: 'Project Overview', prev: '07-quick-start.html', next: '09-clean-architecture.html' },

    // Architecture (9-20)
    { file: '09-clean-architecture.html', title: 'Clean Architecture', section: 'Architecture', prev: '08-glossary.html', next: '10-feature-modules.html' },
    { file: '10-feature-modules.html', title: 'Feature Modules', section: 'Architecture', prev: '09-clean-architecture.html', next: '11-state-management.html' },
    { file: '11-state-management.html', title: 'State Management (BLoC)', section: 'Architecture', prev: '10-feature-modules.html', next: '12-dependency-injection.html' },
    { file: '12-dependency-injection.html', title: 'Dependency Injection', section: 'Architecture', prev: '11-state-management.html', next: '13-navigation.html' },
    { file: '13-navigation.html', title: 'Navigation Architecture', section: 'Architecture', prev: '12-dependency-injection.html', next: '14-data-flow.html' },
    { file: '14-data-flow.html', title: 'Data Flow Diagram', section: 'Architecture', prev: '13-navigation.html', next: '15-repository-pattern.html' },
    { file: '15-repository-pattern.html', title: 'Repository Pattern', section: 'Architecture', prev: '14-data-flow.html', next: '16-use-cases.html' },
    { file: '16-use-cases.html', title: 'Use Cases Design', section: 'Architecture', prev: '15-repository-pattern.html', next: '17-entities-models.html' },
    { file: '17-entities-models.html', title: 'Entity vs Model', section: 'Architecture', prev: '16-use-cases.html', next: '18-error-handling.html' },
    { file: '18-error-handling.html', title: 'Error Handling', section: 'Architecture', prev: '17-entities-models.html', next: '19-caching.html' },
    { file: '19-caching.html', title: 'Caching Strategy', section: 'Architecture', prev: '18-error-handling.html', next: '20-offline-first.html' },
    { file: '20-offline-first.html', title: 'Offline-First Architecture', section: 'Architecture', prev: '19-caching.html', next: '21-brand-guidelines.html' },

    // Design System (21-30)
    { file: '21-brand-guidelines.html', title: 'Brand Guidelines', section: 'Design System', prev: '20-offline-first.html', next: '22-color-palette.html' },
    { file: '22-color-palette.html', title: 'Color Palette', section: 'Design System', prev: '21-brand-guidelines.html', next: '23-typography.html' },
    { file: '23-typography.html', title: 'Typography System', section: 'Design System', prev: '22-color-palette.html', next: '24-spacing.html' },
    { file: '24-spacing.html', title: 'Spacing & Dimensions', section: 'Design System', prev: '23-typography.html', next: '25-components.html' },
    { file: '25-components.html', title: 'Component Library', section: 'Design System', prev: '24-spacing.html', next: '26-icons.html' },
    { file: '26-icons.html', title: 'Icon System', section: 'Design System', prev: '25-components.html', next: '27-animations.html' },
    { file: '27-animations.html', title: 'Animation Guidelines', section: 'Design System', prev: '26-icons.html', next: '28-theming.html' },
    { file: '28-theming.html', title: 'Dark/Light Theme', section: 'Design System', prev: '27-animations.html', next: '29-responsive.html' },
    { file: '29-responsive.html', title: 'Responsive Design', section: 'Design System', prev: '28-theming.html', next: '30-accessibility.html' },
    { file: '30-accessibility.html', title: 'Accessibility Guidelines', section: 'Design System', prev: '29-responsive.html', next: '31-auth-flow.html' },

    // Core Features (31-50)
    { file: '31-auth-flow.html', title: 'Authentication Flow', section: 'Core Features', prev: '30-accessibility.html', next: '32-social-auth.html' },
    { file: '32-social-auth.html', title: 'Social Authentication', section: 'Core Features', prev: '31-auth-flow.html', next: '33-biometric-auth.html' },
    { file: '33-biometric-auth.html', title: 'Biometric Authentication', section: 'Core Features', prev: '32-social-auth.html', next: '34-onboarding.html' },
    { file: '34-onboarding.html', title: 'Profile Onboarding', section: 'Core Features', prev: '33-biometric-auth.html', next: '35-photo-upload.html' },
    { file: '35-photo-upload.html', title: 'Photo Management', section: 'Core Features', prev: '34-onboarding.html', next: '36-profile-editing.html' },
    { file: '36-profile-editing.html', title: 'Profile Editing', section: 'Core Features', prev: '35-photo-upload.html', next: '37-matching-algorithm.html' },
    { file: '37-matching-algorithm.html', title: 'Matching Algorithm', section: 'Core Features', prev: '36-profile-editing.html', next: '38-discovery.html' },
    { file: '38-discovery.html', title: 'Discovery Interface', section: 'Core Features', prev: '37-matching-algorithm.html', next: '39-like-actions.html' },
    { file: '39-like-actions.html', title: 'Like/Pass Actions', section: 'Core Features', prev: '38-discovery.html', next: '40-match-system.html' },
    { file: '40-match-system.html', title: 'Match System', section: 'Core Features', prev: '39-like-actions.html', next: '41-chat.html' },
    { file: '41-chat.html', title: 'Real-time Chat', section: 'Core Features', prev: '40-match-system.html', next: '42-message-features.html' },
    { file: '42-message-features.html', title: 'Message Features', section: 'Core Features', prev: '41-chat.html', next: '43-push-notifications.html' },
    { file: '43-push-notifications.html', title: 'Push Notifications', section: 'Core Features', prev: '42-message-features.html', next: '44-in-app-notifications.html' },
    { file: '44-in-app-notifications.html', title: 'In-App Notifications', section: 'Core Features', prev: '43-push-notifications.html', next: '45-subscriptions.html' },
    { file: '45-subscriptions.html', title: 'Subscription Tiers', section: 'Core Features', prev: '44-in-app-notifications.html', next: '46-in-app-purchases.html' },
    { file: '46-in-app-purchases.html', title: 'In-App Purchases', section: 'Core Features', prev: '45-subscriptions.html', next: '47-coins.html' },
    { file: '47-coins.html', title: 'Virtual Currency', section: 'Core Features', prev: '46-in-app-purchases.html', next: '48-gamification.html' },
    { file: '48-gamification.html', title: 'Gamification System', section: 'Core Features', prev: '47-coins.html', next: '49-challenges.html' },
    { file: '49-challenges.html', title: 'Daily Challenges', section: 'Core Features', prev: '48-gamification.html', next: '50-leaderboards.html' },
    { file: '50-leaderboards.html', title: 'Leaderboards', section: 'Core Features', prev: '49-challenges.html', next: '51-firebase-overview.html' },

    // Backend Services (51-60)
    { file: '51-firebase-overview.html', title: 'Firebase Overview', section: 'Backend Services', prev: '50-leaderboards.html', next: '52-firestore.html' },
    { file: '52-firestore.html', title: 'Firestore Database', section: 'Backend Services', prev: '51-firebase-overview.html', next: '53-firebase-auth.html' },
    { file: '53-firebase-auth.html', title: 'Firebase Authentication', section: 'Backend Services', prev: '52-firestore.html', next: '54-firebase-storage.html' },
    { file: '54-firebase-storage.html', title: 'Firebase Storage', section: 'Backend Services', prev: '53-firebase-auth.html', next: '55-cloud-functions.html' },
    { file: '55-cloud-functions.html', title: 'Cloud Functions', section: 'Backend Services', prev: '54-firebase-storage.html', next: '56-django-backend.html' },
    { file: '56-django-backend.html', title: 'Django Backend', section: 'Backend Services', prev: '55-cloud-functions.html', next: '57-api-documentation.html' },
    { file: '57-api-documentation.html', title: 'API Documentation', section: 'Backend Services', prev: '56-django-backend.html', next: '58-realtime-sync.html' },
    { file: '58-realtime-sync.html', title: 'Real-time Sync', section: 'Backend Services', prev: '57-api-documentation.html', next: '59-background-processing.html' },
    { file: '59-background-processing.html', title: 'Background Processing', section: 'Backend Services', prev: '58-realtime-sync.html', next: '60-rate-limiting.html' },
    { file: '60-rate-limiting.html', title: 'Rate Limiting', section: 'Backend Services', prev: '59-background-processing.html', next: '61-firestore-schema.html' },

    // Database (61-68)
    { file: '61-firestore-schema.html', title: 'Firestore Schema', section: 'Database', prev: '60-rate-limiting.html', next: '62-postgresql-schema.html' },
    { file: '62-postgresql-schema.html', title: 'PostgreSQL Schema', section: 'Database', prev: '61-firestore-schema.html', next: '63-data-migration.html' },
    { file: '63-data-migration.html', title: 'Data Migration', section: 'Database', prev: '62-postgresql-schema.html', next: '64-indexing.html' },
    { file: '64-indexing.html', title: 'Indexing Strategy', section: 'Database', prev: '63-data-migration.html', next: '65-backup-recovery.html' },
    { file: '65-backup-recovery.html', title: 'Backup & Recovery', section: 'Database', prev: '64-indexing.html', next: '66-data-retention.html' },
    { file: '66-data-retention.html', title: 'Data Retention Policy', section: 'Database', prev: '65-backup-recovery.html', next: '67-redis-caching.html' },
    { file: '67-redis-caching.html', title: 'Redis Caching', section: 'Database', prev: '66-data-retention.html', next: '68-bigquery.html' },
    { file: '68-bigquery.html', title: 'BigQuery Analytics', section: 'Database', prev: '67-redis-caching.html', next: '69-security-architecture.html' },

    // Security (69-78)
    { file: '69-security-architecture.html', title: 'Security Architecture', section: 'Security', prev: '68-bigquery.html', next: '70-firestore-rules.html' },
    { file: '70-firestore-rules.html', title: 'Firestore Rules', section: 'Security', prev: '69-security-architecture.html', next: '71-storage-rules.html' },
    { file: '71-storage-rules.html', title: 'Storage Rules', section: 'Security', prev: '70-firestore-rules.html', next: '72-auth-security.html' },
    { file: '72-auth-security.html', title: 'Authentication Security', section: 'Security', prev: '71-storage-rules.html', next: '73-encryption.html' },
    { file: '73-encryption.html', title: 'Data Encryption', section: 'Security', prev: '72-auth-security.html', next: '74-app-check.html' },
    { file: '74-app-check.html', title: 'App Check', section: 'Security', prev: '73-encryption.html', next: '75-content-moderation.html' },
    { file: '75-content-moderation.html', title: 'Content Moderation', section: 'Security', prev: '74-app-check.html', next: '76-spam-detection.html' },
    { file: '76-spam-detection.html', title: 'Spam Detection', section: 'Security', prev: '75-content-moderation.html', next: '77-reporting-system.html' },
    { file: '77-reporting-system.html', title: 'Reporting System', section: 'Security', prev: '76-spam-detection.html', next: '78-security-audit.html' },
    { file: '78-security-audit.html', title: 'Security Audit', section: 'Security', prev: '77-reporting-system.html', next: '79-agora-video.html' },

    // Integrations (79-88)
    { file: '79-agora-video.html', title: 'Agora Video Calling', section: 'Integrations', prev: '78-security-audit.html', next: '80-stripe.html' },
    { file: '80-stripe.html', title: 'Stripe Payments', section: 'Integrations', prev: '79-agora-video.html', next: '81-sendgrid.html' },
    { file: '81-sendgrid.html', title: 'SendGrid Email', section: 'Integrations', prev: '80-stripe.html', next: '82-twilio.html' },
    { file: '82-twilio.html', title: 'Twilio SMS', section: 'Integrations', prev: '81-sendgrid.html', next: '83-google-maps.html' },
    { file: '83-google-maps.html', title: 'Google Maps', section: 'Integrations', prev: '82-twilio.html', next: '84-google-cloud-ai.html' },
    { file: '84-google-cloud-ai.html', title: 'Google Cloud AI', section: 'Integrations', prev: '83-google-maps.html', next: '85-mixpanel.html' },
    { file: '85-mixpanel.html', title: 'Mixpanel Analytics', section: 'Integrations', prev: '84-google-cloud-ai.html', next: '86-sentry.html' },
    { file: '86-sentry.html', title: 'Sentry Tracking', section: 'Integrations', prev: '85-mixpanel.html', next: '87-perspective-api.html' },
    { file: '87-perspective-api.html', title: 'Perspective API', section: 'Integrations', prev: '86-sentry.html', next: '88-revenuecat.html' },
    { file: '88-revenuecat.html', title: 'RevenueCat', section: 'Integrations', prev: '87-perspective-api.html', next: '89-terraform.html' },

    // DevOps (89-96)
    { file: '89-terraform.html', title: 'Terraform Infrastructure', section: 'DevOps', prev: '88-revenuecat.html', next: '90-docker.html' },
    { file: '90-docker.html', title: 'Docker Development', section: 'DevOps', prev: '89-terraform.html', next: '91-cicd.html' },
    { file: '91-cicd.html', title: 'CI/CD Pipeline', section: 'DevOps', prev: '90-docker.html', next: '92-environments.html' },
    { file: '92-environments.html', title: 'Environment Management', section: 'DevOps', prev: '91-cicd.html', next: '93-feature-flags.html' },
    { file: '93-feature-flags.html', title: 'Feature Flags', section: 'DevOps', prev: '92-environments.html', next: '94-pre-commit.html' },
    { file: '94-pre-commit.html', title: 'Pre-commit Hooks', section: 'DevOps', prev: '93-feature-flags.html', next: '95-deployment.html' },
    { file: '95-deployment.html', title: 'Deployment Scripts', section: 'DevOps', prev: '94-pre-commit.html', next: '96-firebase-hosting.html' },
    { file: '96-firebase-hosting.html', title: 'Firebase Hosting', section: 'DevOps', prev: '95-deployment.html', next: '97-unit-testing.html' },

    // Testing (97-100)
    { file: '97-unit-testing.html', title: 'Unit Testing', section: 'Testing', prev: '96-firebase-hosting.html', next: '98-widget-testing.html' },
    { file: '98-widget-testing.html', title: 'Widget Testing', section: 'Testing', prev: '97-unit-testing.html', next: '99-integration-testing.html' },
    { file: '99-integration-testing.html', title: 'Integration Testing', section: 'Testing', prev: '98-widget-testing.html', next: '100-firebase-test-lab.html' },
    { file: '100-firebase-test-lab.html', title: 'Firebase Test Lab', section: 'Testing', prev: '99-integration-testing.html', next: null }
];

// Content for each page
const pageContent = {
    '01-introduction.html': `
        <h2>Overview</h2>
        <p>GreenGo is a next-generation dating application built with Flutter and Google Cloud Platform. The app combines modern mobile development practices with machine learning-powered matching to create meaningful connections.</p>

        <div class="info-box">
            <strong>Project Name:</strong> GreenGoChat<br>
            <strong>Version:</strong> 1.0.0+1<br>
            <strong>Platform:</strong> iOS, Android, Web<br>
            <strong>Status:</strong> MVP Development
        </div>

        <h2>Vision & Mission</h2>
        <h3>Vision</h3>
        <p>To create a premium dating experience that prioritizes authentic connections over superficial interactions, using advanced technology to bring compatible people together.</p>

        <h3>Mission</h3>
        <ul>
            <li>Provide a safe and secure environment for users to connect</li>
            <li>Use machine learning to improve match quality over time</li>
            <li>Create an engaging experience through gamification</li>
            <li>Support users throughout their journey with premium features</li>
        </ul>

        <h2>Key Features</h2>
        <table>
            <thead>
                <tr>
                    <th>Feature</th>
                    <th>Description</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <tr><td>Authentication</td><td>Email/password login with social options</td><td>✅ Complete</td></tr>
                <tr><td>Profile Onboarding</td><td>8-step guided profile creation</td><td>✅ Complete</td></tr>
                <tr><td>Matching Algorithm</td><td>ML-based compatibility scoring</td><td>✅ Complete</td></tr>
                <tr><td>Discovery & Swipe</td><td>Swipe-based user discovery</td><td>✅ Complete</td></tr>
                <tr><td>Real-time Chat</td><td>Instant messaging with rich features</td><td>✅ Complete</td></tr>
                <tr><td>Video Calling</td><td>Agora.io integration</td><td>🚧 MVP Disabled</td></tr>
                <tr><td>Subscriptions</td><td>Tiered premium subscriptions</td><td>✅ Complete</td></tr>
                <tr><td>Gamification</td><td>XP, achievements, leaderboards</td><td>✅ Complete</td></tr>
            </tbody>
        </table>

        <h2>Target Audience</h2>
        <p>GreenGo targets adults aged 18-45 looking for meaningful romantic connections. The premium gold/black design aesthetic appeals to users seeking a sophisticated, quality-focused dating experience.</p>

        <h2>Business Model</h2>
        <ul>
            <li><strong>Freemium:</strong> Basic features available free</li>
            <li><strong>Subscriptions:</strong> Silver ($9.99/mo), Gold ($19.99/mo) tiers</li>
            <li><strong>Virtual Currency:</strong> Coins for premium actions</li>
            <li><strong>In-App Purchases:</strong> Boosts, Super Likes, etc.</li>
        </ul>
    `,

    '02-tech-stack.html': `
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
            <tr><td>equatable</td><td>2.0.5</td><td>Value Equality</td></tr>
            <tr><td>dartz</td><td>0.10.1</td><td>Functional Programming</td></tr>
            <tr><td>cached_network_image</td><td>3.3.0</td><td>Image Caching</td></tr>
        </table>

        <h2>Backend - Firebase & GCP</h2>
        <h3>Firebase Services</h3>
        <ul>
            <li><strong>Authentication:</strong> User identity management</li>
            <li><strong>Firestore:</strong> NoSQL document database</li>
            <li><strong>Storage:</strong> File storage for photos/media</li>
            <li><strong>Cloud Functions:</strong> Serverless backend logic</li>
            <li><strong>Messaging:</strong> Push notifications (FCM)</li>
            <li><strong>Analytics:</strong> Usage tracking and metrics</li>
            <li><strong>Crashlytics:</strong> Crash reporting and analysis</li>
            <li><strong>Remote Config:</strong> Feature flags</li>
            <li><strong>App Check:</strong> Security attestation</li>
        </ul>

        <h3>Google Cloud Platform</h3>
        <ul>
            <li><strong>Cloud Vision API:</strong> Image analysis and moderation</li>
            <li><strong>Cloud Translation:</strong> Message translation</li>
            <li><strong>Cloud Speech:</strong> Voice transcription</li>
            <li><strong>Vertex AI:</strong> ML-based matching</li>
            <li><strong>BigQuery:</strong> Analytics data warehouse</li>
            <li><strong>Cloud KMS:</strong> Key management and encryption</li>
            <li><strong>Cloud CDN:</strong> Content delivery</li>
        </ul>

        <h2>Backend API - Django</h2>
        <table>
            <tr><th>Component</th><th>Technology</th></tr>
            <tr><td>Framework</td><td>Django 4.2.7</td></tr>
            <tr><td>API</td><td>Django REST Framework</td></tr>
            <tr><td>Database</td><td>PostgreSQL 15</td></tr>
            <tr><td>Cache</td><td>Redis 7</td></tr>
            <tr><td>Task Queue</td><td>Celery</td></tr>
            <tr><td>WebSockets</td><td>Django Channels</td></tr>
        </table>

        <h2>Infrastructure</h2>
        <ul>
            <li><strong>IaC:</strong> Terraform for GCP resources</li>
            <li><strong>Containers:</strong> Docker & Docker Compose</li>
            <li><strong>CI/CD:</strong> GitHub Actions</li>
            <li><strong>Monitoring:</strong> Firebase Performance, Sentry</li>
        </ul>
    `,

    '03-repository-structure.html': `
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
├── devops/                 # DevOps scripts & configs
├── security_audit/         # Security testing
├── assets/                 # Images, fonts, icons
├── l10n/                   # Localization files
├── pubspec.yaml            # Flutter dependencies
├── firebase.json           # Firebase configuration
├── .env.example            # Environment template
└── README.md               # Project readme</code></pre>

        <h2>Flutter Source (lib/)</h2>
        <pre><code>lib/
├── main.dart               # App entry point
├── core/                   # Shared utilities
│   ├── config/             # App configuration
│   │   └── app_config.dart
│   ├── constants/          # Colors, dimensions
│   │   ├── app_colors.dart
│   │   └── app_dimensions.dart
│   ├── di/                 # Dependency injection
│   │   └── injection_container.dart
│   ├── errors/             # Error handling
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── network/            # API client
│   ├── providers/          # State providers
│   ├── theme/              # App theming
│   ├── usecases/           # Base use case
│   └── widgets/            # Shared widgets
├── features/               # Feature modules
│   ├── authentication/
│   ├── profile/
│   ├── matching/
│   ├── discovery/
│   ├── chat/
│   ├── notifications/
│   ├── subscription/
│   ├── coins/
│   ├── gamification/
│   ├── analytics/
│   ├── safety/
│   ├── admin/
│   ├── video_calling/
│   ├── localization/
│   ├── accessibility/
│   └── main/
├── l10n/                   # ARB localization files
└── generated/              # Generated code</code></pre>

        <h2>Feature Module Structure</h2>
        <pre><code>feature/
├── domain/                 # Business logic layer
│   ├── entities/           # Business objects
│   ├── repositories/       # Abstract repositories
│   └── usecases/           # Use case classes
├── data/                   # Data layer
│   ├── models/             # Data models (JSON)
│   ├── datasources/        # API/local sources
│   └── repositories/       # Implementations
└── presentation/           # UI layer
    ├── bloc/               # BLoC state management
    │   ├── feature_bloc.dart
    │   ├── feature_event.dart
    │   └── feature_state.dart
    ├── screens/            # UI pages
    └── widgets/            # UI components</code></pre>

        <h2>Cloud Functions (functions/)</h2>
        <pre><code>functions/
├── src/
│   ├── index.ts            # Function exports
│   ├── media/              # Image/video processing
│   ├── messaging/          # Message handling
│   ├── subscriptions/      # Payment webhooks
│   ├── coins/              # Currency logic
│   ├── analytics/          # Data analytics
│   ├── gamification/       # XP and rewards
│   ├── safety/             # Content moderation
│   ├── admin/              # Admin functions
│   ├── notifications/      # Push notifications
│   ├── video_calling/      # Video call logic
│   └── security/           # Security audits
├── package.json
└── tsconfig.json</code></pre>

        <h2>Infrastructure (terraform/)</h2>
        <pre><code>terraform/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── terraform.tfvars.example
└── modules/
    ├── storage/
    ├── kms/
    ├── cloud_functions/
    ├── cdn/
    ├── network/
    ├── pubsub/
    ├── bigquery/
    └── monitoring/</code></pre>
    `,

    '04-version-history.html': `
        <h2>Current Version</h2>
        <div class="info-box">
            <strong>Version:</strong> 1.0.0+1<br>
            <strong>Status:</strong> MVP Development<br>
            <strong>Flutter SDK:</strong> >=3.0.0 <4.0.0<br>
            <strong>Dart SDK:</strong> >=2.17.0
        </div>

        <h2>Changelog</h2>

        <h3>v1.0.0 (Current - In Development)</h3>
        <p><strong>Release Type:</strong> Initial MVP Release</p>

        <h4>Core Features Implemented</h4>
        <ul>
            <li>✅ Email/password authentication</li>
            <li>✅ 8-step profile onboarding wizard</li>
            <li>✅ ML-based matching algorithm</li>
            <li>✅ Swipe-based discovery interface</li>
            <li>✅ Real-time chat messaging</li>
            <li>✅ Push notifications (FCM)</li>
            <li>✅ Subscription tiers (Basic, Silver, Gold)</li>
            <li>✅ Virtual currency system (Coins)</li>
            <li>✅ Gamification (XP, achievements, leaderboards)</li>
            <li>✅ 7 language support</li>
            <li>✅ Content moderation</li>
            <li>✅ User reporting system</li>
        </ul>

        <h4>Architecture & Infrastructure</h4>
        <ul>
            <li>✅ Clean Architecture implementation</li>
            <li>✅ BLoC state management</li>
            <li>✅ GetIt dependency injection</li>
            <li>✅ Firebase backend integration</li>
            <li>✅ 70+ Cloud Functions</li>
            <li>✅ Terraform infrastructure as code</li>
            <li>✅ Docker development environment</li>
            <li>✅ Django REST backend</li>
        </ul>

        <h4>MVP Disabled Features</h4>
        <ul>
            <li>🚧 Social authentication (Google, Facebook, Apple)</li>
            <li>🚧 Biometric authentication</li>
            <li>🚧 Video calling (Agora)</li>
            <li>🚧 Voice messages</li>
        </ul>

        <h2>Roadmap</h2>

        <h3>v1.1.0 (Planned)</h3>
        <ul>
            <li>Enable social authentication providers</li>
            <li>Enable video calling with Agora.io</li>
            <li>Add voice message support</li>
            <li>Performance optimizations</li>
            <li>Enhanced analytics</li>
        </ul>

        <h3>v1.2.0 (Planned)</h3>
        <ul>
            <li>Advanced AI matching improvements</li>
            <li>Group events feature</li>
            <li>Enhanced admin dashboard</li>
            <li>A/B testing framework</li>
        </ul>

        <h3>v2.0.0 (Future)</h3>
        <ul>
            <li>AR filters for video calls</li>
            <li>Virtual dates feature</li>
            <li>Personality assessments</li>
            <li>Premium matchmaking service</li>
        </ul>
    `,

    '05-getting-started.html': `
        <h2>Prerequisites</h2>

        <h3>Required Software</h3>
        <table>
            <tr><th>Software</th><th>Version</th><th>Purpose</th></tr>
            <tr><td>Flutter SDK</td><td>3.0.0+</td><td>Mobile framework</td></tr>
            <tr><td>Dart SDK</td><td>2.17.0+</td><td>Programming language</td></tr>
            <tr><td>Node.js</td><td>18.x</td><td>Cloud Functions</td></tr>
            <tr><td>Docker</td><td>Latest</td><td>Local development</td></tr>
            <tr><td>Git</td><td>Latest</td><td>Version control</td></tr>
        </table>

        <h3>Optional Software</h3>
        <ul>
            <li>Android Studio (for Android development)</li>
            <li>Xcode (for iOS development, macOS only)</li>
            <li>VS Code with Flutter/Dart extensions</li>
        </ul>

        <h2>Installation Steps</h2>

        <h3>1. Clone the Repository</h3>
        <pre><code>git clone https://github.com/greengochat/greengo-app-flutter.git
cd greengo-app-flutter</code></pre>

        <h3>2. Install Flutter Dependencies</h3>
        <pre><code>flutter pub get</code></pre>

        <h3>3. Configure Environment</h3>
        <pre><code># Copy environment template
cp .env.example .env

# Edit with your API keys (for production)
# For local development, defaults work fine</code></pre>

        <h3>4. Start Docker Services</h3>
        <pre><code>cd docker
docker-compose up -d
cd ..</code></pre>

        <h3>5. Generate Code</h3>
        <pre><code>flutter pub run build_runner build --delete-conflicting-outputs</code></pre>

        <h3>6. Run the App</h3>
        <pre><code># List available devices
flutter devices

# Run on Chrome
flutter run -d chrome

# Run on connected device
flutter run</code></pre>

        <h2>Environment Variables</h2>
        <pre><code># Firebase Emulators
USE_FIREBASE_EMULATORS=true

# Feature Flags
ENABLE_VIDEO_CALLING=false
ENABLE_IN_APP_PURCHASES=true
ENABLE_FIREBASE_ANALYTICS=true

# API Keys (production only)
AGORA_APP_ID=your_agora_app_id
STRIPE_PUBLISHABLE_KEY=your_stripe_key
SENDGRID_API_KEY=your_sendgrid_key
TWILIO_ACCOUNT_SID=your_twilio_sid</code></pre>

        <div class="warning-box">
            <strong>Security Warning:</strong> Never commit API keys to version control. Use environment variables or a secure secret manager for production deployments.
        </div>

        <h2>Verify Installation</h2>
        <pre><code># Check Flutter installation
flutter doctor

# Should show all green checkmarks for your target platforms</code></pre>
    `,

    '06-dev-environment.html': `
        <h2>IDE Setup</h2>

        <h3>VS Code (Recommended)</h3>
        <p>Required extensions:</p>
        <ul>
            <li><strong>Flutter</strong> - Flutter support</li>
            <li><strong>Dart</strong> - Dart language support</li>
        </ul>

        <p>Recommended extensions:</p>
        <ul>
            <li>Flutter Widget Snippets</li>
            <li>Bracket Pair Colorizer 2</li>
            <li>GitLens</li>
            <li>Docker</li>
            <li>Terraform</li>
            <li>ESLint</li>
        </ul>

        <h3>VS Code Settings</h3>
        <pre><code>{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  },
  "dart.lineLength": 100,
  "dart.previewFlutterUiGuides": true,
  "[dart]": {
    "editor.rulers": [100],
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.selectionHighlight": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": "off"
  }
}</code></pre>

        <h2>Flutter Configuration</h2>
        <pre><code># Verify Flutter installation
flutter doctor -v

# Enable all platforms
flutter config --enable-web
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
flutter config --enable-windows-desktop

# Update Flutter
flutter upgrade</code></pre>

        <h2>Firebase CLI Setup</h2>
        <pre><code># Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# List projects
firebase projects:list

# Use project
firebase use greengo-app</code></pre>

        <h2>Docker Environment</h2>
        <p>The Docker setup provides a complete local development environment:</p>

        <table>
            <tr><th>Service</th><th>Port</th><th>Purpose</th></tr>
            <tr><td>Firebase Emulator UI</td><td>4000</td><td>Emulator dashboard</td></tr>
            <tr><td>Firestore</td><td>8080</td><td>Database emulator</td></tr>
            <tr><td>Auth</td><td>9099</td><td>Auth emulator</td></tr>
            <tr><td>Storage</td><td>9199</td><td>Storage emulator</td></tr>
            <tr><td>Functions</td><td>5001</td><td>Functions emulator</td></tr>
            <tr><td>PostgreSQL</td><td>5432</td><td>Django database</td></tr>
            <tr><td>Redis</td><td>6379</td><td>Cache</td></tr>
            <tr><td>Adminer</td><td>8081</td><td>DB admin UI</td></tr>
            <tr><td>Redis Commander</td><td>8082</td><td>Redis UI</td></tr>
        </table>

        <h3>Docker Commands</h3>
        <pre><code># Start all services
cd docker && docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Restart specific service
docker-compose restart firebase</code></pre>

        <h2>Code Generation</h2>
        <pre><code># One-time build
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-rebuild)
flutter pub run build_runner watch --delete-conflicting-outputs</code></pre>
    `,

    '07-quick-start.html': `
        <h2>10-Minute Setup Guide</h2>
        <p>Get the GreenGo app running locally in under 10 minutes.</p>

        <h3>Step 1: Clone & Install (2 minutes)</h3>
        <pre><code># Clone repository
git clone https://github.com/greengochat/greengo-app-flutter.git
cd greengo-app-flutter

# Install dependencies
flutter pub get</code></pre>

        <h3>Step 2: Start Docker Services (3 minutes)</h3>
        <pre><code># Start Firebase emulators and databases
cd docker
docker-compose up -d

# Wait for services to start
docker-compose ps

# Return to project root
cd ..</code></pre>

        <div class="info-box">
            <strong>Tip:</strong> Wait until all containers show "healthy" status before proceeding.
        </div>

        <h3>Step 3: Configure Environment (1 minute)</h3>
        <pre><code># Copy environment template
cp .env.example .env

# Default settings work for local development
# No changes needed for basic testing</code></pre>

        <h3>Step 4: Run the App (2 minutes)</h3>
        <pre><code># Run on Chrome (fastest for testing)
flutter run -d chrome

# Or run on connected mobile device
flutter run

# Or specify device
flutter devices
flutter run -d <device-id></code></pre>

        <h3>Step 5: Create Test Account (2 minutes)</h3>
        <ol>
            <li>Click <strong>"Create Account"</strong> on the login screen</li>
            <li>Enter test email: <code>test@example.com</code></li>
            <li>Enter password: <code>Test123!</code></li>
            <li>Complete the 8-step onboarding process</li>
            <li>Start exploring the app!</li>
        </ol>

        <h2>Accessing Development Services</h2>
        <table>
            <tr><th>Service</th><th>URL</th><th>Purpose</th></tr>
            <tr><td>Firebase Emulator UI</td><td><a href="http://localhost:4000">localhost:4000</a></td><td>View all emulators</td></tr>
            <tr><td>Firestore</td><td><a href="http://localhost:8080">localhost:8080</a></td><td>Database browser</td></tr>
            <tr><td>Auth Emulator</td><td><a href="http://localhost:9099">localhost:9099</a></td><td>User management</td></tr>
            <tr><td>Adminer</td><td><a href="http://localhost:8081">localhost:8081</a></td><td>PostgreSQL admin</td></tr>
            <tr><td>Redis Commander</td><td><a href="http://localhost:8082">localhost:8082</a></td><td>Redis browser</td></tr>
        </table>

        <h2>Common Commands</h2>
        <pre><code># Hot reload (while app is running)
Press 'r' in terminal

# Hot restart
Press 'R' in terminal

# Stop app
Press 'q' in terminal

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .</code></pre>

        <h2>Next Steps</h2>
        <ul>
            <li>Read the <a href="09-clean-architecture.html">Architecture Guide</a></li>
            <li>Explore <a href="10-feature-modules.html">Feature Modules</a></li>
            <li>Learn about <a href="11-state-management.html">State Management</a></li>
            <li>Check out the <a href="22-color-palette.html">Design System</a></li>
        </ul>
    `,

    '08-glossary.html': `
        <h2>Architecture Terms</h2>
        <table>
            <tr><th>Term</th><th>Definition</th></tr>
            <tr><td><strong>BLoC</strong></td><td>Business Logic Component - A state management pattern that separates business logic from UI</td></tr>
            <tr><td><strong>Clean Architecture</strong></td><td>Software design philosophy separating code into domain, data, and presentation layers</td></tr>
            <tr><td><strong>Entity</strong></td><td>Core business object in the domain layer, framework-independent</td></tr>
            <tr><td><strong>Model</strong></td><td>Data representation with JSON serialization in the data layer</td></tr>
            <tr><td><strong>Use Case</strong></td><td>Single business operation encapsulating specific functionality</td></tr>
            <tr><td><strong>Repository</strong></td><td>Abstract interface for data operations, bridging domain and data layers</td></tr>
            <tr><td><strong>DataSource</strong></td><td>Concrete implementation for fetching data (remote API or local storage)</td></tr>
            <tr><td><strong>Either</strong></td><td>Functional type from dartz package: Left for errors, Right for success</td></tr>
            <tr><td><strong>Failure</strong></td><td>Domain-level error representation</td></tr>
        </table>

        <h2>Flutter/Dart Terms</h2>
        <table>
            <tr><th>Term</th><th>Definition</th></tr>
            <tr><td><strong>Widget</strong></td><td>Basic building block of Flutter UI</td></tr>
            <tr><td><strong>StatelessWidget</strong></td><td>Widget that doesn't maintain mutable state</td></tr>
            <tr><td><strong>StatefulWidget</strong></td><td>Widget that maintains mutable state</td></tr>
            <tr><td><strong>BuildContext</strong></td><td>Handle to location of widget in widget tree</td></tr>
            <tr><td><strong>GetIt</strong></td><td>Service locator for dependency injection</td></tr>
            <tr><td><strong>Equatable</strong></td><td>Package for value equality comparison</td></tr>
        </table>

        <h2>App-Specific Terms</h2>
        <table>
            <tr><th>Term</th><th>Definition</th></tr>
            <tr><td><strong>Match</strong></td><td>Mutual like between two users</td></tr>
            <tr><td><strong>Super Like</strong></td><td>Premium like action that notifies the recipient</td></tr>
            <tr><td><strong>Boost</strong></td><td>Temporary increase in profile visibility</td></tr>
            <tr><td><strong>Coins</strong></td><td>Virtual currency for premium actions</td></tr>
            <tr><td><strong>XP</strong></td><td>Experience points earned through app engagement</td></tr>
            <tr><td><strong>Compatibility Score</strong></td><td>ML-calculated match percentage between users</td></tr>
            <tr><td><strong>Onboarding</strong></td><td>8-step profile creation wizard for new users</td></tr>
        </table>

        <h2>Firebase Terms</h2>
        <table>
            <tr><th>Term</th><th>Definition</th></tr>
            <tr><td><strong>Firestore</strong></td><td>NoSQL document database</td></tr>
            <tr><td><strong>Collection</strong></td><td>Group of documents in Firestore</td></tr>
            <tr><td><strong>Document</strong></td><td>Single record in a Firestore collection</td></tr>
            <tr><td><strong>FCM</strong></td><td>Firebase Cloud Messaging - push notification service</td></tr>
            <tr><td><strong>Cloud Functions</strong></td><td>Serverless backend functions</td></tr>
            <tr><td><strong>Security Rules</strong></td><td>Access control rules for Firestore/Storage</td></tr>
        </table>

        <h2>Subscription Terms</h2>
        <table>
            <tr><th>Term</th><th>Definition</th></tr>
            <tr><td><strong>Basic</strong></td><td>Free tier with limited features</td></tr>
            <tr><td><strong>Silver</strong></td><td>Mid-tier subscription at $9.99/month</td></tr>
            <tr><td><strong>Gold</strong></td><td>Premium subscription at $19.99/month</td></tr>
            <tr><td><strong>IAP</strong></td><td>In-App Purchase</td></tr>
            <tr><td><strong>SKU</strong></td><td>Stock Keeping Unit - product identifier</td></tr>
        </table>
    `
};

// Generate content for remaining pages
function generateContent(page) {
    if (pageContent[page.file]) {
        return pageContent[page.file];
    }

    // Generate content based on section and title
    const contents = {
        'Architecture': generateArchitectureContent,
        'Design System': generateDesignContent,
        'Core Features': generateFeatureContent,
        'Backend Services': generateBackendContent,
        'Database': generateDatabaseContent,
        'Security': generateSecurityContent,
        'Integrations': generateIntegrationContent,
        'DevOps': generateDevOpsContent,
        'Testing': generateTestingContent
    };

    const generator = contents[page.section] || generateGenericContent;
    return generator(page);
}

function generateArchitectureContent(page) {
    const specifics = {
        '09-clean-architecture.html': `
            <h2>Overview</h2>
            <p>GreenGo implements Clean Architecture to maintain separation of concerns, testability, and scalability. The architecture divides the codebase into three main layers.</p>

            <h2>Layer Structure</h2>
            <h3>1. Domain Layer (Innermost)</h3>
            <p>Contains pure business logic with no external dependencies.</p>
            <ul>
                <li><strong>Entities:</strong> Core business objects</li>
                <li><strong>Repositories:</strong> Abstract data interfaces</li>
                <li><strong>Use Cases:</strong> Business operations</li>
            </ul>

            <h3>2. Data Layer</h3>
            <p>Implements data operations and external integrations.</p>
            <ul>
                <li><strong>Models:</strong> Data objects with serialization</li>
                <li><strong>DataSources:</strong> Remote and local data access</li>
                <li><strong>Repository Implementations:</strong> Concrete implementations</li>
            </ul>

            <h3>3. Presentation Layer (Outermost)</h3>
            <p>UI and state management.</p>
            <ul>
                <li><strong>BLoCs:</strong> State management</li>
                <li><strong>Screens:</strong> UI pages</li>
                <li><strong>Widgets:</strong> Reusable components</li>
            </ul>

            <h2>Dependency Rule</h2>
            <div class="info-box">
                <strong>Key Principle:</strong> Dependencies always point inward. The domain layer has no dependencies on other layers.
            </div>

            <h2>Data Flow</h2>
            <pre><code>UI → BLoC → Use Case → Repository → DataSource → API/DB</code></pre>

            <h2>Benefits</h2>
            <ul>
                <li><strong>Testability:</strong> Each layer can be tested independently</li>
                <li><strong>Maintainability:</strong> Changes are isolated to specific layers</li>
                <li><strong>Scalability:</strong> Easy to add new features</li>
                <li><strong>Framework Independence:</strong> Business logic is portable</li>
            </ul>
        `,
        '10-feature-modules.html': `
            <h2>Overview</h2>
            <p>Each feature in GreenGo is self-contained with its own domain, data, and presentation layers.</p>

            <h2>Feature List</h2>
            <table>
                <tr><th>Feature</th><th>Purpose</th><th>Location</th></tr>
                <tr><td>Authentication</td><td>User login/register</td><td>lib/features/authentication/</td></tr>
                <tr><td>Profile</td><td>User profiles & onboarding</td><td>lib/features/profile/</td></tr>
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
        `,
        '11-state-management.html': `
            <h2>Overview</h2>
            <p>GreenGo uses flutter_bloc (v8.1.3) for state management, implementing the BLoC pattern throughout the app.</p>

            <h2>Core Concepts</h2>
            <ul>
                <li><strong>Event:</strong> Input to the BLoC (user action or system event)</li>
                <li><strong>State:</strong> Output from the BLoC (UI representation)</li>
                <li><strong>BLoC:</strong> Business logic that transforms events into states</li>
            </ul>

            <h2>Implementation Example</h2>
            <h3>Events</h3>
            <pre><code>abstract class AuthEvent extends Equatable {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}</code></pre>

            <h3>States</h3>
            <pre><code>abstract class AuthState extends Equatable {}

class AuthInitial extends AuthState {
  @override
  List<Object> get props => [];
}

class AuthLoading extends AuthState {
  @override
  List<Object> get props => [];
}

class AuthSuccess extends AuthState {
  final User user;
  AuthSuccess(this.user);

  @override
  List<Object> get props => [user];
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);

  @override
  List<Object> get props => [message];
}</code></pre>

            <h3>BLoC</h3>
            <pre><code>class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;

  AuthBloc(this.loginUseCase) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
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
            <pre><code>BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) {
      return CircularProgressIndicator();
    }
    if (state is AuthSuccess) {
      return HomeScreen(user: state.user);
    }
    if (state is AuthFailure) {
      return ErrorWidget(state.message);
    }
    return LoginForm();
  },
)</code></pre>
        `
    };

    return specifics[page.file] || generateGenericContent(page);
}

function generateDesignContent(page) {
    const specifics = {
        '22-color-palette.html': `
            <h2>Brand Colors</h2>
            <table>
                <tr><th>Name</th><th>Hex</th><th>RGB</th><th>Usage</th></tr>
                <tr><td>Rich Gold</td><td>#D4AF37</td><td>212, 175, 55</td><td>Primary accent, buttons, highlights</td></tr>
                <tr><td>Accent Gold</td><td>#FFD700</td><td>255, 215, 0</td><td>Hover states, active elements</td></tr>
                <tr><td>Deep Black</td><td>#0A0A0A</td><td>10, 10, 10</td><td>Primary background</td></tr>
                <tr><td>Charcoal</td><td>#1A1A1A</td><td>26, 26, 26</td><td>Secondary background, cards</td></tr>
            </table>

            <h2>Neutral Colors</h2>
            <table>
                <tr><th>Name</th><th>Hex</th><th>Usage</th></tr>
                <tr><td>Dark Gray</td><td>#2A2A2A</td><td>Borders, dividers</td></tr>
                <tr><td>Medium Gray</td><td>#4A4A4A</td><td>Secondary text</td></tr>
                <tr><td>Light Gray</td><td>#8A8A8A</td><td>Placeholder text</td></tr>
                <tr><td>Off White</td><td>#F5F5F5</td><td>Light backgrounds</td></tr>
                <tr><td>White</td><td>#FFFFFF</td><td>Text on dark backgrounds</td></tr>
            </table>

            <h2>Semantic Colors</h2>
            <table>
                <tr><th>Name</th><th>Hex</th><th>Usage</th></tr>
                <tr><td>Success</td><td>#4CAF50</td><td>Success states, confirmations</td></tr>
                <tr><td>Warning</td><td>#FF9800</td><td>Warnings, cautions</td></tr>
                <tr><td>Error</td><td>#F44336</td><td>Errors, destructive actions</td></tr>
                <tr><td>Info</td><td>#2196F3</td><td>Information, help</td></tr>
            </table>

            <h2>Implementation</h2>
            <pre><code>// lib/core/constants/app_colors.dart
class AppColors {
  // Brand
  static const Color richGold = Color(0xFFD4AF37);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color deepBlack = Color(0xFF0A0A0A);
  static const Color charcoal = Color(0xFF1A1A1A);

  // Neutral
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color mediumGray = Color(0xFF4A4A4A);
  static const Color lightGray = Color(0xFF8A8A8A);
  static const Color offWhite = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
}</code></pre>
        `,
        '23-typography.html': `
            <h2>Font Family</h2>
            <p>GreenGo uses <strong>Poppins</strong> as the primary font family across all platforms.</p>

            <h2>Font Weights</h2>
            <table>
                <tr><th>Weight</th><th>Value</th><th>Usage</th></tr>
                <tr><td>Light</td><td>300</td><td>Subtle, decorative text</td></tr>
                <tr><td>Regular</td><td>400</td><td>Body text, descriptions</td></tr>
                <tr><td>Medium</td><td>500</td><td>Emphasis, labels</td></tr>
                <tr><td>SemiBold</td><td>600</td><td>Subheadings, buttons</td></tr>
                <tr><td>Bold</td><td>700</td><td>Headings, strong emphasis</td></tr>
            </table>

            <h2>Type Scale</h2>
            <table>
                <tr><th>Name</th><th>Size</th><th>Weight</th><th>Usage</th></tr>
                <tr><td>Display</td><td>48px</td><td>Bold</td><td>Hero text</td></tr>
                <tr><td>H1</td><td>32px</td><td>Bold</td><td>Page titles</td></tr>
                <tr><td>H2</td><td>24px</td><td>SemiBold</td><td>Section headings</td></tr>
                <tr><td>H3</td><td>18px</td><td>SemiBold</td><td>Subsections</td></tr>
                <tr><td>Body Large</td><td>18px</td><td>Regular</td><td>Important body text</td></tr>
                <tr><td>Body</td><td>16px</td><td>Regular</td><td>Default body text</td></tr>
                <tr><td>Body Small</td><td>14px</td><td>Regular</td><td>Secondary text</td></tr>
                <tr><td>Caption</td><td>12px</td><td>Regular</td><td>Labels, hints</td></tr>
            </table>

            <h2>Line Heights</h2>
            <ul>
                <li><strong>Headings:</strong> 1.2 - 1.3</li>
                <li><strong>Body:</strong> 1.5 - 1.6</li>
                <li><strong>Buttons:</strong> 1.0</li>
            </ul>
        `
    };

    return specifics[page.file] || generateGenericContent(page);
}

function generateFeatureContent(page) {
    const specifics = {
        '31-auth-flow.html': `
            <h2>Authentication Flow</h2>
            <pre><code>App Launch
  → AuthWrapper
    → Check Firebase Auth State
      → Authenticated?
        → Yes: MainNavigationScreen
        → No: LoginScreen
          → Options:
            → Login (email/password)
            → Register (create account)
            → Forgot Password (reset)
          → Success: Onboarding / Home</code></pre>

            <h2>Supported Authentication Methods</h2>
            <table>
                <tr><th>Method</th><th>Status</th><th>Notes</th></tr>
                <tr><td>Email/Password</td><td>✅ Active</td><td>Primary auth method</td></tr>
                <tr><td>Google Sign-In</td><td>🚧 Disabled</td><td>MVP disabled</td></tr>
                <tr><td>Facebook Login</td><td>🚧 Disabled</td><td>MVP disabled</td></tr>
                <tr><td>Sign in with Apple</td><td>🚧 Disabled</td><td>MVP disabled</td></tr>
                <tr><td>Biometric</td><td>🚧 Disabled</td><td>MVP disabled</td></tr>
            </table>

            <h2>Key Components</h2>
            <h3>BLoC</h3>
            <p><code>lib/features/authentication/presentation/bloc/auth_bloc.dart</code></p>

            <h3>Screens</h3>
            <ul>
                <li><code>login_screen.dart</code> - Email/password login</li>
                <li><code>register_screen.dart</code> - Account creation</li>
                <li><code>forgot_password_screen.dart</code> - Password reset</li>
            </ul>

            <h3>Use Cases</h3>
            <ul>
                <li><code>login_user.dart</code></li>
                <li><code>register_user.dart</code></li>
                <li><code>reset_password.dart</code></li>
                <li><code>logout_user.dart</code></li>
            </ul>
        `,
        '37-matching-algorithm.html': `
            <h2>ML-Based Matching System</h2>
            <p>GreenGo uses machine learning to calculate compatibility scores between users.</p>

            <h2>Algorithm Components</h2>
            <ol>
                <li><strong>Feature Engineering</strong> - Convert user profiles to numerical vectors</li>
                <li><strong>Compatibility Scoring</strong> - ML model predicts match quality</li>
                <li><strong>Candidate Generation</strong> - Filter potential matches</li>
                <li><strong>Ranking</strong> - Order by compatibility score</li>
            </ol>

            <h2>Features Used</h2>
            <ul>
                <li>Age and age preference alignment</li>
                <li>Location and distance preferences</li>
                <li>Shared interests and hobbies</li>
                <li>Lifestyle preferences</li>
                <li>Relationship goals alignment</li>
                <li>Activity patterns</li>
            </ul>

            <h2>Key Files</h2>
            <ul>
                <li><code>lib/features/matching/domain/usecases/feature_engineer.dart</code></li>
                <li><code>lib/features/matching/domain/usecases/compatibility_scorer.dart</code></li>
                <li><code>lib/features/matching/domain/usecases/get_match_candidates.dart</code></li>
                <li><code>lib/features/matching/data/repositories/matching_repository_impl.dart</code></li>
            </ul>

            <h2>Scoring Process</h2>
            <pre><code>User Profile → Feature Vector → ML Model → Compatibility Score (0-100%)</code></pre>
        `,
        '41-chat.html': `
            <h2>Real-time Chat System</h2>
            <p>Firebase Firestore-powered real-time messaging between matched users.</p>

            <h2>Features</h2>
            <ul>
                <li>Real-time message synchronization</li>
                <li>Read receipts</li>
                <li>Typing indicators</li>
                <li>Message reactions</li>
                <li>Message search</li>
                <li>Conversation list</li>
            </ul>

            <h2>Data Structure</h2>
            <pre><code>conversations/{conversationId}
├── participants: [userId1, userId2]
├── lastMessage: {
│     text: "Hello!",
│     senderId: "userId1",
│     timestamp: Timestamp
│   }
├── createdAt: Timestamp
├── updatedAt: Timestamp
└── messages/{messageId}
    ├── senderId: string
    ├── text: string
    ├── timestamp: Timestamp
    ├── read: boolean
    └── reactions: Map</code></pre>

            <h2>BLoC Events</h2>
            <pre><code>// Chat Events
SendMessage
MarkAsRead
AddReaction
DeleteMessage

// Conversation Events
LoadConversations
SearchConversations
ArchiveConversation</code></pre>

            <h2>Key Files</h2>
            <ul>
                <li><code>lib/features/chat/presentation/bloc/chat_bloc.dart</code></li>
                <li><code>lib/features/chat/presentation/bloc/conversations_bloc.dart</code></li>
                <li><code>lib/features/chat/presentation/screens/chat_screen.dart</code></li>
                <li><code>lib/features/chat/presentation/widgets/enhanced_message_bubble.dart</code></li>
            </ul>
        `
    };

    return specifics[page.file] || generateGenericContent(page);
}

function generateBackendContent(page) {
    return generateGenericContent(page);
}

function generateDatabaseContent(page) {
    return generateGenericContent(page);
}

function generateSecurityContent(page) {
    return generateGenericContent(page);
}

function generateIntegrationContent(page) {
    return generateGenericContent(page);
}

function generateDevOpsContent(page) {
    const specifics = {
        '90-docker.html': `
            <h2>Docker Development Environment</h2>
            <p>Docker Compose setup for local development with all required services.</p>

            <h2>Services</h2>
            <table>
                <tr><th>Service</th><th>Container</th><th>Port</th></tr>
                <tr><td>Firebase Emulators</td><td>greengo_firebase</td><td>4000, 8080, 9099, 9199, 5001</td></tr>
                <tr><td>PostgreSQL</td><td>greengo_postgres</td><td>5432</td></tr>
                <tr><td>Redis</td><td>greengo_redis</td><td>6379</td></tr>
                <tr><td>Adminer</td><td>greengo_adminer</td><td>8081</td></tr>
                <tr><td>Redis Commander</td><td>greengo_redis_commander</td><td>8082</td></tr>
                <tr><td>Nginx</td><td>greengo_nginx</td><td>80, 443</td></tr>
            </table>

            <h2>Commands</h2>
            <pre><code># Start all services
cd docker
docker-compose up -d

# View running containers
docker-compose ps

# View logs
docker-compose logs -f
docker-compose logs -f firebase

# Stop all services
docker-compose down

# Rebuild containers
docker-compose build --no-cache

# Remove volumes (reset data)
docker-compose down -v</code></pre>

            <h2>Configuration</h2>
            <p>Location: <code>docker/docker-compose.yml</code></p>

            <h2>Accessing Services</h2>
            <ul>
                <li>Firebase UI: <a href="http://localhost:4000">http://localhost:4000</a></li>
                <li>Adminer: <a href="http://localhost:8081">http://localhost:8081</a></li>
                <li>Redis Commander: <a href="http://localhost:8082">http://localhost:8082</a></li>
            </ul>
        `
    };

    return specifics[page.file] || generateGenericContent(page);
}

function generateTestingContent(page) {
    return generateGenericContent(page);
}

function generateGenericContent(page) {
    return `
        <h2>Overview</h2>
        <p>This section covers ${page.title.toLowerCase()} in the GreenGo application.</p>

        <div class="info-box">
            <strong>Section:</strong> ${page.section}<br>
            <strong>Topic:</strong> ${page.title}
        </div>

        <h2>Key Concepts</h2>
        <p>Understanding ${page.title.toLowerCase()} is essential for working with GreenGo.</p>

        <h2>Implementation Details</h2>
        <p>Detailed implementation information for ${page.title.toLowerCase()}.</p>

        <h2>Configuration</h2>
        <p>Configuration options and settings related to ${page.title.toLowerCase()}.</p>

        <h2>Best Practices</h2>
        <ul>
            <li>Follow established patterns and conventions</li>
            <li>Maintain consistency across the codebase</li>
            <li>Document all changes thoroughly</li>
            <li>Write tests for new functionality</li>
        </ul>

        <h2>Related Documentation</h2>
        <p>See related sections for more information on topics connected to ${page.title.toLowerCase()}.</p>
    `;
}

// HTML template
function createPageHTML(page) {
    const content = generateContent(page);

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
                <div class="nav-section-title"><i class="fas fa-home"></i><span>Overview</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="01-introduction.html">1. Introduction</a></li>
                    <li><a href="02-tech-stack.html">2. Tech Stack</a></li>
                    <li><a href="05-getting-started.html">5. Getting Started</a></li>
                    <li><a href="07-quick-start.html">7. Quick Start</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-sitemap"></i><span>Architecture</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="09-clean-architecture.html">9. Clean Architecture</a></li>
                    <li><a href="11-state-management.html">11. State Management</a></li>
                    <li><a href="12-dependency-injection.html">12. Dependency Injection</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-palette"></i><span>Design</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="22-color-palette.html">22. Colors</a></li>
                    <li><a href="23-typography.html">23. Typography</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-puzzle-piece"></i><span>Features</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="31-auth-flow.html">31. Authentication</a></li>
                    <li><a href="37-matching-algorithm.html">37. Matching</a></li>
                    <li><a href="41-chat.html">41. Chat</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-server"></i><span>Backend</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="51-firebase-overview.html">51. Firebase</a></li>
                    <li><a href="55-cloud-functions.html">55. Functions</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-cogs"></i><span>DevOps</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="89-terraform.html">89. Terraform</a></li>
                    <li><a href="90-docker.html">90. Docker</a></li>
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
                ${content}

                <div class="page-navigation">
                    ${page.prev ? `<a href="${page.prev}" class="page-nav-link prev"><i class="fas fa-arrow-left"></i> Previous</a>` : '<span></span>'}
                    ${page.next ? `<a href="${page.next}" class="page-nav-link next">Next <i class="fas fa-arrow-right"></i></a>` : '<span></span>'}
                </div>
            </div>
        </div>
    </main>

    <script src="../js/main.js"></script>
</body>
</html>`;
}

// Generate all pages
const pagesDir = path.join(__dirname, 'pages');

// Ensure pages directory exists
if (!fs.existsSync(pagesDir)) {
    fs.mkdirSync(pagesDir, { recursive: true });
}

// Generate each page
pages.forEach(page => {
    const filepath = path.join(pagesDir, page.file);
    const html = createPageHTML(page);
    fs.writeFileSync(filepath, html);
    console.log(`Created: ${page.file}`);
});

console.log(`\nSuccessfully generated ${pages.length} documentation pages!`);
