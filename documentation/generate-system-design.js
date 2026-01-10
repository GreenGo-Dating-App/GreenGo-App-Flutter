const fs = require('fs');
const path = require('path');

// Complete navigation menu
const fullNavMenu = `
        <ul class="nav-menu" id="navMenu">
            <li class="nav-section">
                <div class="nav-section-title" data-section="overview">
                    <i class="fas fa-home"></i>
                    <span>Project Overview</span>
                    <i class="fas fa-chevron-down arrow"></i>
                </div>
                <ul class="nav-submenu">
                    <li><a href="01-introduction.html">1. Project Introduction</a></li>
                    <li><a href="02-tech-stack.html">2. Technology Stack</a></li>
                    <li><a href="03-repository-structure.html">3. Repository Structure</a></li>
                    <li><a href="04-version-history.html">4. Version History</a></li>
                    <li><a href="05-getting-started.html">5. Getting Started</a></li>
                    <li><a href="06-dev-environment.html">6. Development Environment</a></li>
                    <li><a href="07-quick-start.html">7. Quick Start Tutorial</a></li>
                    <li><a href="08-glossary.html">8. Glossary & Terminology</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title" data-section="architecture">
                    <i class="fas fa-sitemap"></i>
                    <span>Architecture</span>
                    <i class="fas fa-chevron-down arrow"></i>
                </div>
                <ul class="nav-submenu">
                    <li><a href="09-clean-architecture.html">9. Clean Architecture</a></li>
                    <li><a href="10-feature-modules.html">10. Feature Modules</a></li>
                    <li><a href="11-state-management.html">11. State Management (BLoC)</a></li>
                    <li><a href="12-dependency-injection.html">12. Dependency Injection</a></li>
                    <li><a href="13-repository-pattern.html">13. Repository Pattern</a></li>
                    <li><a href="14-data-flow.html">14. Data Flow Diagram</a></li>
                    <li><a href="15-error-handling.html">15. Error Handling</a></li>
                    <li><a href="16-navigation.html">16. Navigation & Routing</a></li>
                    <li><a href="17-api-layer.html">17. API & Network Layer</a></li>
                    <li><a href="18-caching.html">18. Caching Strategy</a></li>
                    <li><a href="19-real-time.html">19. Real-time Communication</a></li>
                    <li><a href="20-testing-architecture.html">20. Testing Architecture</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title" data-section="design">
                    <i class="fas fa-palette"></i>
                    <span>Design System</span>
                    <i class="fas fa-chevron-down arrow"></i>
                </div>
                <ul class="nav-submenu">
                    <li><a href="21-brand-guidelines.html">21. Brand Guidelines</a></li>
                    <li><a href="22-color-palette.html">22. Color Palette</a></li>
                    <li><a href="23-typography.html">23. Typography System</a></li>
                    <li><a href="24-spacing.html">24. Spacing & Dimensions</a></li>
                    <li><a href="25-components.html">25. Component Library</a></li>
                    <li><a href="26-icons.html">26. Icon System</a></li>
                    <li><a href="27-animations.html">27. Animation Guidelines</a></li>
                    <li><a href="28-theming.html">28. Dark/Light Theme</a></li>
                    <li><a href="29-responsive.html">29. Responsive Design</a></li>
                    <li><a href="30-accessibility.html">30. Accessibility Guidelines</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title" data-section="features">
                    <i class="fas fa-puzzle-piece"></i>
                    <span>Core Features</span>
                    <i class="fas fa-chevron-down arrow"></i>
                </div>
                <ul class="nav-submenu">
                    <li><a href="31-auth-flow.html">31. Authentication Flow</a></li>
                    <li><a href="32-social-auth.html">32. Social Authentication</a></li>
                    <li><a href="33-biometric-auth.html">33. Biometric Authentication</a></li>
                    <li><a href="34-onboarding.html">34. Profile Onboarding</a></li>
                    <li><a href="35-photo-upload.html">35. Photo Management</a></li>
                    <li><a href="36-profile-editing.html">36. Profile Editing</a></li>
                    <li><a href="37-matching-algorithm.html">37. Matching Algorithm</a></li>
                    <li><a href="38-discovery.html">38. Discovery Interface</a></li>
                    <li><a href="39-like-actions.html">39. Like/Pass Actions</a></li>
                    <li><a href="40-match-system.html">40. Match System</a></li>
                    <li><a href="41-chat.html">41. Real-time Chat</a></li>
                    <li><a href="42-message-features.html">42. Message Features</a></li>
                    <li><a href="43-push-notifications.html">43. Push Notifications</a></li>
                    <li><a href="44-in-app-notifications.html">44. In-App Notifications</a></li>
                    <li><a href="45-subscriptions.html">45. Subscription Tiers</a></li>
                    <li><a href="46-in-app-purchases.html">46. In-App Purchases</a></li>
                    <li><a href="47-coins.html">47. Virtual Currency</a></li>
                    <li><a href="48-gamification.html">48. Gamification System</a></li>
                    <li><a href="49-challenges.html">49. Daily Challenges</a></li>
                    <li><a href="50-leaderboards.html">50. Leaderboards</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title" data-section="backend">
                    <i class="fas fa-server"></i>
                    <span>Backend Services</span>
                    <i class="fas fa-chevron-down arrow"></i>
                </div>
                <ul class="nav-submenu">
                    <li><a href="51-firebase-overview.html">51. Firebase Overview</a></li>
                    <li><a href="52-firestore.html">52. Firestore Database</a></li>
                    <li><a href="53-firebase-auth.html">53. Firebase Authentication</a></li>
                    <li><a href="54-firebase-storage.html">54. Firebase Storage</a></li>
                    <li><a href="55-cloud-functions.html">55. Cloud Functions</a></li>
                    <li><a href="56-django-backend.html">56. Django Backend</a></li>
                    <li><a href="57-api-documentation.html">57. API Documentation</a></li>
                    <li><a href="58-realtime-sync.html">58. Real-time Sync</a></li>
                    <li><a href="59-background-processing.html">59. Background Processing</a></li>
                    <li><a href="60-rate-limiting.html">60. Rate Limiting</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title" data-section="database">
                    <i class="fas fa-database"></i>
                    <span>Database</span>
                    <i class="fas fa-chevron-down arrow"></i>
                </div>
                <ul class="nav-submenu">
                    <li><a href="61-firestore-schema.html">61. Firestore Schema</a></li>
                    <li><a href="62-postgresql-schema.html">62. PostgreSQL Schema</a></li>
                    <li><a href="63-data-migration.html">63. Data Migration</a></li>
                    <li><a href="64-indexing.html">64. Indexing Strategy</a></li>
                    <li><a href="65-backup-recovery.html">65. Backup & Recovery</a></li>
                    <li><a href="66-data-retention.html">66. Data Retention Policy</a></li>
                    <li><a href="67-redis-caching.html">67. Redis Caching</a></li>
                    <li><a href="68-bigquery.html">68. BigQuery Analytics</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title" data-section="security">
                    <i class="fas fa-shield-alt"></i>
                    <span>Security</span>
                    <i class="fas fa-chevron-down arrow"></i>
                </div>
                <ul class="nav-submenu">
                    <li><a href="69-security-architecture.html">69. Security Architecture</a></li>
                    <li><a href="70-firestore-rules.html">70. Firestore Rules</a></li>
                    <li><a href="71-storage-rules.html">71. Storage Rules</a></li>
                    <li><a href="72-auth-security.html">72. Authentication Security</a></li>
                    <li><a href="73-encryption.html">73. Data Encryption</a></li>
                    <li><a href="74-app-check.html">74. App Check</a></li>
                    <li><a href="75-content-moderation.html">75. Content Moderation</a></li>
                    <li><a href="76-spam-detection.html">76. Spam Detection</a></li>
                    <li><a href="77-reporting-system.html">77. Reporting System</a></li>
                    <li><a href="78-security-audit.html">78. Security Audit</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title" data-section="integrations">
                    <i class="fas fa-plug"></i>
                    <span>Integrations</span>
                    <i class="fas fa-chevron-down arrow"></i>
                </div>
                <ul class="nav-submenu">
                    <li><a href="79-agora-video.html">79. Agora Video Calling</a></li>
                    <li><a href="80-stripe.html">80. Stripe Payments</a></li>
                    <li><a href="81-sendgrid.html">81. SendGrid Email</a></li>
                    <li><a href="82-twilio.html">82. Twilio SMS</a></li>
                    <li><a href="83-google-maps.html">83. Google Maps</a></li>
                    <li><a href="84-google-cloud-ai.html">84. Google Cloud AI</a></li>
                    <li><a href="85-mixpanel.html">85. Mixpanel Analytics</a></li>
                    <li><a href="86-sentry.html">86. Sentry Tracking</a></li>
                    <li><a href="87-perspective-api.html">87. Perspective API</a></li>
                    <li><a href="88-revenuecat.html">88. RevenueCat</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title" data-section="devops">
                    <i class="fas fa-cogs"></i>
                    <span>DevOps</span>
                    <i class="fas fa-chevron-down arrow"></i>
                </div>
                <ul class="nav-submenu">
                    <li><a href="89-terraform.html">89. Terraform Infrastructure</a></li>
                    <li><a href="90-docker.html">90. Docker Development</a></li>
                    <li><a href="91-cicd.html">91. CI/CD Pipeline</a></li>
                    <li><a href="92-environments.html">92. Environment Management</a></li>
                    <li><a href="93-feature-flags.html">93. Feature Flags</a></li>
                    <li><a href="94-pre-commit.html">94. Pre-commit Hooks</a></li>
                    <li><a href="95-deployment.html">95. Deployment Scripts</a></li>
                    <li><a href="96-firebase-hosting.html">96. Firebase Hosting</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title" data-section="testing">
                    <i class="fas fa-vial"></i>
                    <span>Testing</span>
                    <i class="fas fa-chevron-down arrow"></i>
                </div>
                <ul class="nav-submenu">
                    <li><a href="97-unit-testing.html">97. Unit Testing</a></li>
                    <li><a href="98-widget-testing.html">98. Widget Testing</a></li>
                    <li><a href="99-integration-testing.html">99. Integration Testing</a></li>
                    <li><a href="100-firebase-test-lab.html">100. Firebase Test Lab</a></li>
                </ul>
            </li>
        </ul>`;

// System Design Pages
const systemDesignPages = [
    {
        file: '51-firebase-overview.html',
        title: 'Firebase Overview - System Design',
        section: 'Backend Services',
        content: `
            <h2>GreenGo Firebase System Architecture</h2>
            <p>Complete system design overview of GreenGo's Firebase-based backend infrastructure, showing all services, data flows, and integrations.</p>

            <h2>High-Level System Architecture</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          GREENGO SYSTEM ARCHITECTURE                                 │
└─────────────────────────────────────────────────────────────────────────────────────┘

                                 ┌─────────────────┐
                                 │   CLIENTS       │
                                 │  iOS/Android/Web│
                                 └────────┬────────┘
                                          │
                    ┌─────────────────────┼─────────────────────┐
                    │                     │                     │
                    ▼                     ▼                     ▼
         ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
         │  Firebase Auth   │  │    Firestore     │  │ Cloud Storage    │
         │  • Email/Pass    │  │  • Users         │  │ • Profile Photos │
         │  • Social Login  │  │  • Matches       │  │ • Chat Media     │
         │  • Phone Auth    │  │  • Messages      │  │ • Verification   │
         │  • Custom Tokens │  │  • Swipes        │  │ • Documents      │
         └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘
                  │                     │                     │
                  └─────────────────────┼─────────────────────┘
                                        │
                              ┌─────────▼─────────┐
                              │  CLOUD FUNCTIONS  │
                              │  (70+ Functions)  │
                              └─────────┬─────────┘
                                        │
         ┌──────────────────────────────┼──────────────────────────────┐
         │                              │                              │
         ▼                              ▼                              ▼
┌─────────────────┐          ┌─────────────────┐          ┌─────────────────┐
│  EXTERNAL APIs  │          │   GCP SERVICES  │          │   ANALYTICS     │
├─────────────────┤          ├─────────────────┤          ├─────────────────┤
│ • Stripe        │          │ • Cloud AI      │          │ • BigQuery      │
│ • SendGrid      │          │ • Vision API    │          │ • Mixpanel      │
│ • Twilio        │          │ • NLP API       │          │ • Crashlytics   │
│ • Agora         │          │ • Vertex AI     │          │ • Performance   │
│ • Google Maps   │          │ • Pub/Sub       │          │ • A/B Testing   │
└─────────────────┘          └─────────────────┘          └─────────────────┘
            </code></pre>

            <h2>Firebase Services Integration Map</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                       FIREBASE SERVICES INTEGRATION                                  │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              FIREBASE AUTH                                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                │
│  │Email/Pass   │  │Google OAuth │  │Facebook     │  │Apple Sign-In│                │
│  │             │  │             │  │             │  │             │                │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                │
│         └─────────────────┴─────────────────┴─────────────────┘                     │
│                                     │                                               │
│                          ┌──────────▼──────────┐                                    │
│                          │   User UID Token    │                                    │
│                          │   JWT with Claims   │                                    │
│                          └──────────┬──────────┘                                    │
└─────────────────────────────────────┼───────────────────────────────────────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
┌───────────────────────┐ ┌───────────────────┐ ┌───────────────────────┐
│      FIRESTORE        │ │   CLOUD STORAGE   │ │   CLOUD FUNCTIONS     │
├───────────────────────┤ ├───────────────────┤ ├───────────────────────┤
│                       │ │                   │ │                       │
│ Collections:          │ │ Buckets:          │ │ Triggers:             │
│ ├── users/            │ │ ├── profiles/     │ │ ├── onUserCreate      │
│ ├── matches/          │ │ ├── chat-media/   │ │ ├── onSwipeCreate     │
│ ├── conversations/    │ │ ├── verification/ │ │ ├── onMessageCreate   │
│ ├── swipes/           │ │ └── exports/      │ │ ├── onMatchCreate     │
│ ├── notifications/    │ │                   │ │ └── scheduledJobs     │
│ ├── subscriptions/    │ │ Security:         │ │                       │
│ ├── transactions/     │ │ • Storage Rules   │ │ HTTP Callable:        │
│ ├── reports/          │ │ • Signed URLs     │ │ ├── getPotentialMatch │
│ └── settings/         │ │ • CDN Caching     │ │ ├── processPayment    │
│                       │ │                   │ │ ├── moderateContent   │
│ Security:             │ │                   │ │ └── sendNotification  │
│ • Firestore Rules     │ │                   │ │                       │
│ • Field Validation    │ │                   │ │                       │
└───────────────────────┘ └───────────────────┘ └───────────────────────┘
            </code></pre>

            <h2>Data Flow Architecture</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          COMPLETE DATA FLOW                                          │
└─────────────────────────────────────────────────────────────────────────────────────┘

User Action          Client App         Firebase            Cloud Function      External
    │                    │                  │                     │               │
    │ Sign Up            │                  │                     │               │
    │───────────────────▶│                  │                     │               │
    │                    │ createUser       │                     │               │
    │                    │─────────────────▶│                     │               │
    │                    │                  │ onUserCreate        │               │
    │                    │                  │────────────────────▶│               │
    │                    │                  │                     │ SendGrid      │
    │                    │                  │                     │──────────────▶│
    │                    │                  │                     │ Welcome Email │
    │                    │                  │                     │◀──────────────│
    │                    │                  │ Create user doc     │               │
    │                    │                  │◀────────────────────│               │
    │                    │ User created     │                     │               │
    │◀───────────────────│◀─────────────────│                     │               │
    │                    │                  │                     │               │
    │ Upload Photo       │                  │                     │               │
    │───────────────────▶│                  │                     │               │
    │                    │ uploadFile       │                     │               │
    │                    │─────────────────▶│ Storage             │               │
    │                    │                  │ onFileUpload        │               │
    │                    │                  │────────────────────▶│               │
    │                    │                  │                     │ Vision API    │
    │                    │                  │                     │──────────────▶│
    │                    │                  │                     │ Moderation    │
    │                    │                  │                     │◀──────────────│
    │                    │                  │                     │ Resize Image  │
    │                    │                  │                     │───┐           │
    │                    │                  │                     │◀──┘           │
    │                    │                  │ Update user.photos  │               │
    │                    │                  │◀────────────────────│               │
    │                    │ Photo URL        │                     │               │
    │◀───────────────────│◀─────────────────│                     │               │
    │                    │                  │                     │               │
    │ Swipe Right        │                  │                     │               │
    │───────────────────▶│                  │                     │               │
    │                    │ recordSwipe      │                     │               │
    │                    │─────────────────▶│                     │               │
    │                    │                  │ onSwipeCreate       │               │
    │                    │                  │────────────────────▶│               │
    │                    │                  │                     │ Check Match   │
    │                    │                  │                     │───┐           │
    │                    │                  │                     │◀──┘           │
    │                    │                  │                     │ MATCH!        │
    │                    │                  │ Create match doc    │               │
    │                    │                  │◀────────────────────│               │
    │                    │                  │ Create conversation │               │
    │                    │                  │◀────────────────────│               │
    │                    │                  │                     │ FCM Push      │
    │                    │ Match notif      │                     │──────────────▶│
    │◀───────────────────│◀─────────────────│◀────────────────────│               │
    │                    │                  │                     │               │
            </code></pre>

            <h2>Firebase Project Configuration</h2>
            <table>
                <thead>
                    <tr><th>Service</th><th>Project ID</th><th>Region</th><th>Tier</th></tr>
                </thead>
                <tbody>
                    <tr><td>Firestore</td><td>greengo-prod</td><td>us-central1</td><td>Native Mode</td></tr>
                    <tr><td>Authentication</td><td>greengo-prod</td><td>Global</td><td>Spark→Blaze</td></tr>
                    <tr><td>Cloud Storage</td><td>greengo-prod</td><td>us-central1</td><td>Standard</td></tr>
                    <tr><td>Cloud Functions</td><td>greengo-prod</td><td>us-central1</td><td>Gen 2</td></tr>
                    <tr><td>Hosting</td><td>greengo-prod</td><td>Global CDN</td><td>Standard</td></tr>
                </tbody>
            </table>

            <h2>Environment Configuration</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                    MULTI-ENVIRONMENT SETUP                               │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   DEVELOPMENT   │     │    STAGING      │     │   PRODUCTION    │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│greengo-dev      │     │greengo-staging  │     │greengo-prod     │
│                 │     │                 │     │                 │
│• Local emulator │     │• Test data      │     │• Live users     │
│• Mock services  │     │• Real APIs      │     │• Full security  │
│• Debug logging  │     │• QA testing     │     │• Monitoring     │
│                 │     │                 │     │                 │
│Firestore:       │     │Firestore:       │     │Firestore:       │
│ └─ Emulated     │     │ └─ Test DB      │     │ └─ Production   │
│                 │     │                 │     │                 │
│Functions:       │     │Functions:       │     │Functions:       │
│ └─ Local        │     │ └─ Deployed     │     │ └─ Deployed     │
└─────────────────┘     └─────────────────┘     └─────────────────┘

Configuration Files:
├── firebase.json              # Firebase project config
├── .firebaserc                # Project aliases
├── firestore.rules            # Security rules
├── firestore.indexes.json     # Composite indexes
├── storage.rules              # Storage security
└── functions/
    ├── .env.dev              # Dev environment
    ├── .env.staging          # Staging environment
    └── .env.prod             # Production environment
            </code></pre>

            <h2>Cost Optimization Strategy</h2>
            <table>
                <thead>
                    <tr><th>Service</th><th>Optimization</th><th>Estimated Savings</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Firestore</strong></td>
                        <td>Composite indexes, denormalization, batch writes</td>
                        <td>40% read reduction</td>
                    </tr>
                    <tr>
                        <td><strong>Cloud Functions</strong></td>
                        <td>Min instances, memory optimization, cold start reduction</td>
                        <td>30% compute savings</td>
                    </tr>
                    <tr>
                        <td><strong>Storage</strong></td>
                        <td>Image compression, lifecycle policies, CDN caching</td>
                        <td>50% storage costs</td>
                    </tr>
                    <tr>
                        <td><strong>Authentication</strong></td>
                        <td>Session management, token caching</td>
                        <td>20% auth operations</td>
                    </tr>
                </tbody>
            </table>
        `
    },
    {
        file: '55-cloud-functions.html',
        title: 'Cloud Functions - System Design',
        section: 'Backend Services',
        content: `
            <h2>Cloud Functions Architecture</h2>
            <p>GreenGo uses 70+ Cloud Functions organized by domain, handling everything from user management to ML-powered matching.</p>

            <h2>Functions Organization</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      CLOUD FUNCTIONS ARCHITECTURE                                    │
└─────────────────────────────────────────────────────────────────────────────────────┘

functions/
├── src/
│   ├── index.ts                    # Main exports
│   ├── auth/                       # Authentication functions
│   │   ├── onUserCreate.ts         # New user setup
│   │   ├── onUserDelete.ts         # Cleanup on delete
│   │   └── customToken.ts          # Custom auth tokens
│   │
│   ├── users/                      # User management
│   │   ├── updateProfile.ts        # Profile updates
│   │   ├── uploadPhoto.ts          # Photo processing
│   │   ├── updateLocation.ts       # Geolocation
│   │   └── deleteAccount.ts        # GDPR deletion
│   │
│   ├── matching/                   # Matching system
│   │   ├── getPotentialMatches.ts  # ML recommendations
│   │   ├── recordSwipe.ts          # Like/Pass actions
│   │   ├── onMatchCreate.ts        # Match triggers
│   │   └── calculateScore.ts       # Compatibility
│   │
│   ├── chat/                       # Messaging
│   │   ├── onMessageCreate.ts      # Message triggers
│   │   ├── sendMessage.ts          # Send with validation
│   │   └── markAsRead.ts           # Read receipts
│   │
│   ├── notifications/              # Push notifications
│   │   ├── sendPush.ts             # FCM sending
│   │   ├── onNotificationCreate.ts # Notification triggers
│   │   └── scheduleReminder.ts     # Scheduled notifs
│   │
│   ├── payments/                   # Monetization
│   │   ├── processPayment.ts       # Stripe integration
│   │   ├── webhookHandler.ts       # Stripe webhooks
│   │   ├── createSubscription.ts   # Subscription mgmt
│   │   └── purchaseCoins.ts        # In-app purchases
│   │
│   ├── moderation/                 # Content safety
│   │   ├── moderatePhoto.ts        # Image moderation
│   │   ├── moderateText.ts         # Text moderation
│   │   ├── handleReport.ts         # User reports
│   │   └── autoban.ts              # Automatic bans
│   │
│   ├── gamification/               # Game mechanics
│   │   ├── awardXP.ts              # XP system
│   │   ├── checkAchievements.ts    # Achievement unlock
│   │   ├── dailyChallenge.ts       # Daily tasks
│   │   └── updateLeaderboard.ts    # Rankings
│   │
│   └── scheduled/                  # Cron jobs
│       ├── dailyDigest.ts          # Daily emails
│       ├── cleanupExpired.ts       # Data cleanup
│       ├── updateStats.ts          # Analytics
│       └── refreshML.ts            # ML model refresh
│
├── lib/                            # Shared utilities
│   ├── firebase.ts                 # Firebase admin
│   ├── stripe.ts                   # Stripe client
│   ├── sendgrid.ts                 # Email client
│   └── ml.ts                       # ML utilities
│
└── package.json
            </code></pre>

            <h2>Function Types & Triggers</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         FUNCTION TRIGGER TYPES                                       │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐
│  FIRESTORE TRIGGERS │
├─────────────────────┤
│                     │
│  onCreate ──────────┼──▶ onUserCreate, onSwipeCreate, onMessageCreate
│  onUpdate ──────────┼──▶ onProfileUpdate, onSubscriptionUpdate
│  onDelete ──────────┼──▶ onUserDelete, onMatchDelete
│  onWrite ───────────┼──▶ onSettingsChange
│                     │
└─────────────────────┘

┌─────────────────────┐
│  STORAGE TRIGGERS   │
├─────────────────────┤
│                     │
│  onFinalize ────────┼──▶ onPhotoUpload (resize, moderate)
│  onDelete ──────────┼──▶ onPhotoDelete (cleanup refs)
│                     │
└─────────────────────┘

┌─────────────────────┐
│  AUTH TRIGGERS      │
├─────────────────────┤
│                     │
│  onCreate ──────────┼──▶ onUserCreate (welcome email, init profile)
│  onDelete ──────────┼──▶ onUserDelete (cleanup all data)
│                     │
└─────────────────────┘

┌─────────────────────┐
│  HTTPS CALLABLE     │
├─────────────────────┤
│                     │
│  Authenticated ─────┼──▶ getPotentialMatches, recordSwipe, sendMessage
│                     │    processPayment, updateProfile, reportUser
│                     │
└─────────────────────┘

┌─────────────────────┐
│  SCHEDULED (CRON)   │
├─────────────────────┤
│                     │
│  Every minute ──────┼──▶ processNotificationQueue
│  Every hour ────────┼──▶ updateLeaderboards, cleanupExpiredBoosts
│  Daily at 8am ──────┼──▶ sendDailyDigest, generateDailyChallenges
│  Weekly ────────────┼──▶ generateWeeklyReport, refreshMLModels
│                     │
└─────────────────────┘

┌─────────────────────┐
│  PUB/SUB            │
├─────────────────────┤
│                     │
│  ml-predictions ────┼──▶ processMLPrediction
│  analytics-events ──┼──▶ processAnalyticsEvent
│                     │
└─────────────────────┘
            </code></pre>

            <h2>Matching Algorithm Function</h2>
            <p><strong>File:</strong> <code>functions/src/matching/getPotentialMatches.ts</code></p>
            <pre><code class="language-typescript">
import * as functions from 'firebase-functions';
import { firestore } from '../lib/firebase';
import { calculateCompatibility } from '../lib/ml';

interface MatchFilters {
  minAge: number;
  maxAge: number;
  maxDistance: number;
  genderPreference: string[];
}

export const getPotentialMatches = functions
  .runWith({
    memory: '1GB',
    timeoutSeconds: 60,
    minInstances: 1, // Keep warm
  })
  .https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be logged in'
      );
    }

    const userId = context.auth.uid;
    const { limit = 50, filters } = data as {
      limit: number;
      filters: MatchFilters;
    };

    // Get current user
    const userDoc = await firestore.collection('users').doc(userId).get();
    const user = userDoc.data();

    if (!user) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    // Get already swiped users
    const swipedSnapshot = await firestore
      .collection('swipes')
      .where('swiperId', '==', userId)
      .select('swipedId')
      .get();

    const swipedIds = new Set(swipedSnapshot.docs.map(d => d.data().swipedId));
    swipedIds.add(userId); // Exclude self

    // Build query for potential matches
    let query = firestore
      .collection('users')
      .where('isActive', '==', true)
      .where('isOnboardingComplete', '==', true);

    // Apply gender filter
    if (filters.genderPreference.length > 0) {
      query = query.where('gender', 'in', filters.genderPreference);
    }

    // Apply age filter
    const now = new Date();
    const minBirthDate = new Date(
      now.getFullYear() - filters.maxAge,
      now.getMonth(),
      now.getDate()
    );
    const maxBirthDate = new Date(
      now.getFullYear() - filters.minAge,
      now.getMonth(),
      now.getDate()
    );

    query = query
      .where('birthDate', '>=', minBirthDate)
      .where('birthDate', '<=', maxBirthDate);

    // Get candidates
    const candidatesSnapshot = await query.limit(limit * 3).get();

    // Filter and score candidates
    const candidates = [];

    for (const doc of candidatesSnapshot.docs) {
      if (swipedIds.has(doc.id)) continue;

      const candidate = doc.data();

      // Check distance
      const distance = calculateDistance(
        user.location,
        candidate.location
      );

      if (distance > filters.maxDistance) continue;

      // Calculate ML compatibility score
      const compatibilityScore = await calculateCompatibility(
        user.mlVector,
        candidate.mlVector
      );

      candidates.push({
        id: doc.id,
        ...candidate,
        distance,
        compatibilityScore,
      });
    }

    // Sort by compatibility score
    candidates.sort((a, b) => b.compatibilityScore - a.compatibilityScore);

    // Return top matches
    return {
      matches: candidates.slice(0, limit),
      hasMore: candidates.length > limit,
    };
  });

function calculateDistance(
  loc1: { latitude: number; longitude: number },
  loc2: { latitude: number; longitude: number }
): number {
  const R = 6371; // Earth's radius in km
  const dLat = toRad(loc2.latitude - loc1.latitude);
  const dLon = toRad(loc2.longitude - loc1.longitude);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(loc1.latitude)) *
      Math.cos(toRad(loc2.latitude)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(deg: number): number {
  return deg * (Math.PI / 180);
}
            </code></pre>

            <h2>Function Execution Flow</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                    SWIPE TO MATCH EXECUTION FLOW                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘

Client                recordSwipe           onSwipeCreate         onMatchCreate
  │                       │                      │                      │
  │ swipe(targetId,LIKE)  │                      │                      │
  │──────────────────────▶│                      │                      │
  │                       │                      │                      │
  │                       │ Validate auth        │                      │
  │                       │ Check rate limit     │                      │
  │                       │ Check subscription   │                      │
  │                       │         │            │                      │
  │                       │         ▼            │                      │
  │                       │ Write to swipes/     │                      │
  │                       │─────────────────────▶│                      │
  │                       │                      │                      │
  │                       │                      │ Query reverse swipe  │
  │                       │                      │         │            │
  │                       │                      │         ▼            │
  │                       │                      │ swiperId=target      │
  │                       │                      │ swipedId=user        │
  │                       │                      │ type=LIKE            │
  │                       │                      │         │            │
  │                       │                      │    MATCH FOUND!      │
  │                       │                      │         │            │
  │                       │                      │         ▼            │
  │                       │                      │ Create match doc     │
  │                       │                      │─────────────────────▶│
  │                       │                      │                      │
  │                       │                      │                      │ Create conversation
  │                       │                      │                      │ Send FCM to both
  │                       │                      │                      │ Award XP to both
  │                       │                      │                      │ Update stats
  │                       │                      │                      │
  │                       │ return {matched:true}│                      │
  │◀──────────────────────│◀─────────────────────│◀─────────────────────│
  │                       │                      │                      │
            </code></pre>

            <h2>Function Configuration</h2>
            <table>
                <thead>
                    <tr><th>Function</th><th>Memory</th><th>Timeout</th><th>Min Instances</th><th>Max Instances</th></tr>
                </thead>
                <tbody>
                    <tr><td>getPotentialMatches</td><td>1GB</td><td>60s</td><td>1</td><td>100</td></tr>
                    <tr><td>recordSwipe</td><td>256MB</td><td>30s</td><td>1</td><td>500</td></tr>
                    <tr><td>processPayment</td><td>512MB</td><td>60s</td><td>1</td><td>50</td></tr>
                    <tr><td>moderatePhoto</td><td>2GB</td><td>120s</td><td>0</td><td>20</td></tr>
                    <tr><td>sendPush</td><td>256MB</td><td>30s</td><td>1</td><td>200</td></tr>
                    <tr><td>onMessageCreate</td><td>256MB</td><td>30s</td><td>1</td><td>500</td></tr>
                </tbody>
            </table>
        `
    },
    {
        file: '61-firestore-schema.html',
        title: 'Firestore Schema - System Design',
        section: 'Database',
        content: `
            <h2>Firestore Database Schema</h2>
            <p>Complete schema design for GreenGo's Firestore database with collection structures, document fields, and relationships.</p>

            <h2>Database Schema Diagram</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        FIRESTORE SCHEMA ARCHITECTURE                                 │
└─────────────────────────────────────────────────────────────────────────────────────┘

                              ┌─────────────────┐
                              │     users/      │
                              │   {userId}      │
                              └────────┬────────┘
                                       │
          ┌────────────────────────────┼────────────────────────────┐
          │                            │                            │
          ▼                            ▼                            ▼
┌─────────────────┐          ┌─────────────────┐          ┌─────────────────┐
│   swipes/       │          │   matches/      │          │ notifications/  │
│   {swipeId}     │          │   {matchId}     │          │   {notifId}     │
└─────────────────┘          └────────┬────────┘          └─────────────────┘
                                      │
                                      ▼
                             ┌─────────────────┐
                             │ conversations/  │
                             │   {convId}      │
                             └────────┬────────┘
                                      │
                                      ▼
                             ┌─────────────────┐
                             │   messages/     │
                             │   (subcollection)│
                             └─────────────────┘

Additional Collections:
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ subscriptions/  │  │  transactions/  │  │    reports/     │
│   {subId}       │  │   {transId}     │  │   {reportId}    │
└─────────────────┘  └─────────────────┘  └─────────────────┘

┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  achievements/  │  │   challenges/   │  │  leaderboards/  │
│   {achieveId}   │  │   {challengeId} │  │   {boardId}     │
└─────────────────┘  └─────────────────┘  └─────────────────┘
            </code></pre>

            <h2>Users Collection Schema</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  COLLECTION: users/{userId}                                                          │
└─────────────────────────────────────────────────────────────────────────────────────┘

{
  // Identity
  "id": "string (auto)",
  "email": "string",
  "phone": "string?",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "lastActiveAt": "timestamp",

  // Profile
  "name": "string",
  "birthDate": "timestamp",
  "gender": "string (male|female|non-binary)",
  "bio": "string (max 500)",
  "occupation": "string?",
  "company": "string?",
  "education": "string?",

  // Photos (max 6)
  "photos": [
    {
      "url": "string",
      "thumbnailUrl": "string",
      "order": "number",
      "isVerified": "boolean",
      "uploadedAt": "timestamp"
    }
  ],

  // Location
  "location": {
    "latitude": "number",
    "longitude": "number",
    "city": "string",
    "country": "string",
    "geohash": "string"
  },

  // Preferences
  "preferences": {
    "minAge": "number (18-100)",
    "maxAge": "number (18-100)",
    "maxDistance": "number (km)",
    "genderPreference": ["string"],
    "showMe": "boolean"
  },

  // Interests & Personality
  "interests": ["string (max 10)"],
  "prompts": [
    {
      "question": "string",
      "answer": "string"
    }
  ],
  "personalityTraits": {
    "openness": "number (0-1)",
    "conscientiousness": "number (0-1)",
    "extraversion": "number (0-1)",
    "agreeableness": "number (0-1)",
    "neuroticism": "number (0-1)"
  },

  // ML Vector (for matching)
  "mlVector": ["number (128 dimensions)"],

  // Subscription & Economy
  "subscription": {
    "tier": "string (basic|silver|gold)",
    "expiresAt": "timestamp?",
    "autoRenew": "boolean"
  },
  "coins": "number",
  "boostsRemaining": "number",

  // Gamification
  "xp": "number",
  "level": "number",
  "achievements": ["string (achievementIds)"],
  "streakDays": "number",
  "lastStreakDate": "timestamp",

  // Stats
  "stats": {
    "totalSwipes": "number",
    "totalLikes": "number",
    "totalMatches": "number",
    "totalMessages": "number",
    "superLikesUsed": "number"
  },

  // Status Flags
  "isOnboardingComplete": "boolean",
  "isVerified": "boolean",
  "isActive": "boolean",
  "isBanned": "boolean",
  "banReason": "string?",

  // Settings
  "settings": {
    "pushEnabled": "boolean",
    "emailEnabled": "boolean",
    "showOnlineStatus": "boolean",
    "showLastActive": "boolean",
    "language": "string"
  },

  // Privacy
  "blockedUsers": ["string (userIds)"],
  "hiddenFromUsers": ["string (userIds)"]
}

Indexes:
- location.geohash + isActive + gender
- birthDate + isActive + gender
- subscription.tier + lastActiveAt
- xp (descending) for leaderboards
            </code></pre>

            <h2>Matches & Conversations Schema</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  COLLECTION: matches/{matchId}                                                       │
└─────────────────────────────────────────────────────────────────────────────────────┘

{
  "id": "string (auto)",
  "users": ["string (userId1)", "string (userId2)"],
  "userProfiles": {
    "{userId1}": {
      "name": "string",
      "photo": "string",
      "age": "number"
    },
    "{userId2}": {
      "name": "string",
      "photo": "string",
      "age": "number"
    }
  },
  "conversationId": "string",
  "matchedAt": "timestamp",
  "compatibilityScore": "number (0-100)",
  "status": "string (active|unmatched|blocked)",
  "unmatchedBy": "string? (userId)",
  "unmatchedAt": "timestamp?"
}

Indexes:
- users (array-contains) + matchedAt
- status + matchedAt

┌─────────────────────────────────────────────────────────────────────────────────────┐
│  COLLECTION: conversations/{conversationId}                                          │
└─────────────────────────────────────────────────────────────────────────────────────┘

{
  "id": "string (auto)",
  "matchId": "string",
  "participants": ["string (userId1)", "string (userId2)"],
  "createdAt": "timestamp",
  "lastMessageAt": "timestamp",
  "lastMessage": {
    "content": "string",
    "senderId": "string",
    "type": "string"
  },
  "unreadCount": {
    "{userId1}": "number",
    "{userId2}": "number"
  },
  "typing": {
    "{userId1}": "timestamp?",
    "{userId2}": "timestamp?"
  },
  "isActive": "boolean"
}

┌─────────────────────────────────────────────────────────────────────────────────────┐
│  SUBCOLLECTION: conversations/{conversationId}/messages/{messageId}                  │
└─────────────────────────────────────────────────────────────────────────────────────┘

{
  "id": "string (auto)",
  "senderId": "string",
  "content": "string",
  "type": "string (text|image|gif|voice|video)",
  "mediaUrl": "string?",
  "replyTo": "string? (messageId)",
  "reactions": {
    "{userId}": "string (emoji)"
  },
  "timestamp": "timestamp",
  "readAt": "timestamp?",
  "editedAt": "timestamp?",
  "deletedAt": "timestamp?"
}

Indexes:
- participants (array-contains) + lastMessageAt
- timestamp (for pagination)
            </code></pre>

            <h2>Swipes Collection Schema</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  COLLECTION: swipes/{swipeId}                                                        │
└─────────────────────────────────────────────────────────────────────────────────────┘

{
  "id": "string (swiperId_swipedId)",
  "swiperId": "string",
  "swipedId": "string",
  "type": "string (like|superlike|pass)",
  "timestamp": "timestamp",
  "matchCreated": "boolean",
  "source": "string (discovery|boost|rewind)"
}

Indexes:
- swiperId + timestamp (user's swipe history)
- swipedId + type + timestamp (who liked me)
- swiperId + swipedId (unique constraint check)

Query Patterns:
1. Get user's swipe history: swiperId == X, order by timestamp
2. Check for mutual like: swiperId == targetId AND swipedId == userId AND type == 'like'
3. Get users who liked me: swipedId == userId AND type IN ['like', 'superlike']
            </code></pre>

            <h2>Transactions & Subscriptions Schema</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  COLLECTION: subscriptions/{subscriptionId}                                          │
└─────────────────────────────────────────────────────────────────────────────────────┘

{
  "id": "string (auto)",
  "userId": "string",
  "tier": "string (silver|gold)",
  "status": "string (active|canceled|expired|past_due)",
  "stripeSubscriptionId": "string",
  "stripeCustomerId": "string",
  "currentPeriodStart": "timestamp",
  "currentPeriodEnd": "timestamp",
  "cancelAtPeriodEnd": "boolean",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}

┌─────────────────────────────────────────────────────────────────────────────────────┐
│  COLLECTION: transactions/{transactionId}                                            │
└─────────────────────────────────────────────────────────────────────────────────────┘

{
  "id": "string (auto)",
  "userId": "string",
  "type": "string (subscription|coins|boost|superlike)",
  "amount": "number",
  "currency": "string",
  "status": "string (pending|completed|failed|refunded)",
  "stripePaymentIntentId": "string?",
  "metadata": {
    "productId": "string",
    "quantity": "number"
  },
  "createdAt": "timestamp",
  "completedAt": "timestamp?"
}
            </code></pre>

            <h2>Data Relationships Diagram</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         DATA RELATIONSHIPS                                           │
└─────────────────────────────────────────────────────────────────────────────────────┘

users ─────────────┬────────────────────────────────────────────────────┐
  │                │                                                    │
  │ 1:N            │ 1:N                                                │ 1:N
  ▼                ▼                                                    ▼
swipes          matches ──────────── 1:1 ──────────── conversations   subscriptions
                   │                                        │
                   │                                        │ 1:N
                   │                                        ▼
                   │                                    messages
                   │
                   └─── notifications (to both users)

users ─────┬─────────────┬─────────────┬─────────────┐
           │             │             │             │
           │ 1:N         │ 1:N         │ 1:N         │ 1:N
           ▼             ▼             ▼             ▼
      transactions  achievements  challenges   reports
            </code></pre>
        `
    },
    {
        file: '37-matching-algorithm.html',
        title: 'Matching Algorithm - System Design',
        section: 'Core Features',
        content: `
            <h2>ML-Powered Matching System</h2>
            <p>GreenGo uses a sophisticated machine learning matching algorithm that combines collaborative filtering, content-based filtering, and behavioral signals.</p>

            <h2>Matching System Architecture</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      MATCHING ALGORITHM ARCHITECTURE                                 │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              USER DATA                                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                │
│  │  Profile    │  │  Behavior   │  │ Preferences │  │  Location   │                │
│  │  Data       │  │  History    │  │             │  │             │                │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                │
│         └─────────────────┴────────────────┴─────────────────┘                      │
│                                     │                                               │
│                           ┌─────────▼─────────┐                                     │
│                           │  FEATURE VECTOR   │                                     │
│                           │   GENERATION      │                                     │
│                           │  (128 dimensions) │                                     │
│                           └─────────┬─────────┘                                     │
└─────────────────────────────────────┼───────────────────────────────────────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
         ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
         │  COLLABORATIVE  │ │  CONTENT-BASED  │ │   BEHAVIORAL    │
         │   FILTERING     │ │   FILTERING     │ │    SIGNALS      │
         ├─────────────────┤ ├─────────────────┤ ├─────────────────┤
         │ Similar user    │ │ Profile match   │ │ Swipe patterns  │
         │ preferences     │ │ Interest overlap│ │ Chat engagement │
         │ Matrix factor   │ │ Personality fit │ │ Response time   │
         └────────┬────────┘ └────────┬────────┘ └────────┬────────┘
                  │                   │                   │
                  └───────────────────┼───────────────────┘
                                      │
                            ┌─────────▼─────────┐
                            │  ENSEMBLE MODEL   │
                            │  Score Fusion     │
                            │  (Weighted Avg)   │
                            └─────────┬─────────┘
                                      │
                            ┌─────────▼─────────┐
                            │  RANKING LAYER    │
                            │  • Boost factors  │
                            │  • Freshness      │
                            │  • Diversity      │
                            └─────────┬─────────┘
                                      │
                            ┌─────────▼─────────┐
                            │  FINAL MATCHES    │
                            │  Sorted by score  │
                            └───────────────────┘
            </code></pre>

            <h2>Feature Vector Generation</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      FEATURE VECTOR COMPONENTS                                       │
└─────────────────────────────────────────────────────────────────────────────────────┘

128-Dimensional Feature Vector:
┌─────────────────────────────────────────────────────────────────────────┐
│  Dimensions 0-31:   PROFILE FEATURES                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ • Age (normalized)           [0-1]                               │   │
│  │ • Height (normalized)        [0-1]                               │   │
│  │ • Education level            [0-1]                               │   │
│  │ • Occupation embedding       [16 dims]                           │   │
│  │ • Bio text embedding         [12 dims]                           │   │
│  └─────────────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────────┤
│  Dimensions 32-63:  INTEREST FEATURES                                   │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ • Interest category encoding [20 dims]                           │   │
│  │ • Music taste embedding      [4 dims]                            │   │
│  │ • Movie genre embedding      [4 dims]                            │   │
│  │ • Food preferences           [4 dims]                            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────────┤
│  Dimensions 64-79:  PERSONALITY FEATURES                                │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ • Big Five traits            [5 dims]                            │   │
│  │ • Communication style        [3 dims]                            │   │
│  │ • Relationship goals         [4 dims]                            │   │
│  │ • Lifestyle factors          [4 dims]                            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────────┤
│  Dimensions 80-111: BEHAVIORAL FEATURES                                 │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ • Swipe pattern encoding     [16 dims]                           │   │
│  │ • Activity time embedding    [8 dims]                            │   │
│  │ • Engagement metrics         [8 dims]                            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────────┤
│  Dimensions 112-127: PREFERENCE FEATURES                                │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ • Age preference range       [2 dims]                            │   │
│  │ • Distance preference        [1 dim]                             │   │
│  │ • Deal-breakers encoding     [8 dims]                            │   │
│  │ • Must-haves encoding        [5 dims]                            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
            </code></pre>

            <h2>Compatibility Score Calculation</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                    COMPATIBILITY SCORE ALGORITHM                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘

Input: User A vector (128d), User B vector (128d)
Output: Compatibility score (0-100)

Step 1: COSINE SIMILARITY
─────────────────────────
       A · B
cos = ───────
      |A||B|

base_score = (cos + 1) / 2 * 100    // Normalize to 0-100

Step 2: INTEREST OVERLAP BONUS
──────────────────────────────
common_interests = intersection(A.interests, B.interests)
interest_bonus = min(common_interests.length * 2, 10)

Step 3: PERSONALITY COMPATIBILITY
─────────────────────────────────
// Complementary traits boost score
if (A.extraversion + B.extraversion ≈ 1.0):
    personality_bonus += 3
if (abs(A.openness - B.openness) < 0.2):
    personality_bonus += 2

Step 4: BEHAVIORAL ALIGNMENT
────────────────────────────
// Similar usage patterns
activity_similarity = cosine(A.activity_times, B.activity_times)
behavior_bonus = activity_similarity * 5

Step 5: MUTUAL PREFERENCE FIT
─────────────────────────────
// Check if each user fits other's preferences
if A fits B.preferences AND B fits A.preferences:
    preference_bonus = 10
elif A fits B.preferences OR B fits A.preferences:
    preference_bonus = 5

Step 6: FINAL SCORE
───────────────────
final_score = base_score
            + interest_bonus
            + personality_bonus
            + behavior_bonus
            + preference_bonus

return clamp(final_score, 0, 100)
            </code></pre>

            <h2>Matching Pipeline Flow</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      MATCH GENERATION PIPELINE                                       │
└─────────────────────────────────────────────────────────────────────────────────────┘

Request                  Filter              Score               Rank              Return
   │                        │                   │                  │                  │
   │ getPotentialMatches    │                   │                  │                  │
   │───────────────────────▶│                   │                  │                  │
   │                        │                   │                  │                  │
   │                        │ 1. Hard Filters   │                  │                  │
   │                        │ ┌─────────────┐   │                  │                  │
   │                        │ │• Gender     │   │                  │                  │
   │                        │ │• Age range  │   │                  │                  │
   │                        │ │• Distance   │   │                  │                  │
   │                        │ │• Blocked    │   │                  │                  │
   │                        │ │• Already    │   │                  │                  │
   │                        │ │  swiped     │   │                  │                  │
   │                        │ └─────────────┘   │                  │                  │
   │                        │                   │                  │                  │
   │                        │ ~10K → ~500       │                  │                  │
   │                        │──────────────────▶│                  │                  │
   │                        │                   │                  │                  │
   │                        │                   │ 2. ML Scoring    │                  │
   │                        │                   │ ┌─────────────┐  │                  │
   │                        │                   │ │For each:    │  │                  │
   │                        │                   │ │ cosine_sim  │  │                  │
   │                        │                   │ │ + bonuses   │  │                  │
   │                        │                   │ └─────────────┘  │                  │
   │                        │                   │                  │                  │
   │                        │                   │ 500 scored       │                  │
   │                        │                   │─────────────────▶│                  │
   │                        │                   │                  │                  │
   │                        │                   │                  │ 3. Ranking      │
   │                        │                   │                  │ ┌─────────────┐ │
   │                        │                   │                  │ │• Sort by    │ │
   │                        │                   │                  │ │  score      │ │
   │                        │                   │                  │ │• Apply      │ │
   │                        │                   │                  │ │  boosts     │ │
   │                        │                   │                  │ │• Diversify  │ │
   │                        │                   │                  │ └─────────────┘ │
   │                        │                   │                  │                 │
   │                        │                   │                  │ Top 50          │
   │◀────────────────────────────────────────────────────────────────────────────────│
   │                        │                   │                  │                  │
            </code></pre>

            <h2>Model Training Pipeline</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        ML MODEL TRAINING                                             │
└─────────────────────────────────────────────────────────────────────────────────────┘

                    ┌─────────────────┐
                    │   DATA LAKE     │
                    │   (BigQuery)    │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │   Swipe     │  │   Match     │  │   Chat      │
    │   Events    │  │   Events    │  │   Events    │
    └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
           └────────────────┼────────────────┘
                            │
                   ┌────────▼────────┐
                   │  FEATURE        │
                   │  ENGINEERING    │
                   └────────┬────────┘
                            │
                   ┌────────▼────────┐
                   │  VERTEX AI      │
                   │  Training Job   │
                   └────────┬────────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
              ▼             ▼             ▼
    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │  Embedding  │  │  Ranking    │  │  A/B Test   │
    │   Model     │  │   Model     │  │   Shadow    │
    └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
           └────────────────┼────────────────┘
                            │
                   ┌────────▼────────┐
                   │  MODEL REGISTRY │
                   │  Versioning     │
                   └────────┬────────┘
                            │
                   ┌────────▼────────┐
                   │  DEPLOYMENT     │
                   │  Cloud Function │
                   └─────────────────┘

Training Schedule:
• Full retrain: Weekly (Sunday 3am)
• Incremental update: Daily (3am)
• Real-time feedback: Continuous
            </code></pre>

            <h2>Ranking Factors</h2>
            <table>
                <thead>
                    <tr><th>Factor</th><th>Weight</th><th>Description</th></tr>
                </thead>
                <tbody>
                    <tr><td><strong>ML Score</strong></td><td>60%</td><td>Base compatibility from vector similarity</td></tr>
                    <tr><td><strong>Freshness</strong></td><td>15%</td><td>Boost for recently active users</td></tr>
                    <tr><td><strong>Photo Quality</strong></td><td>10%</td><td>Verified photos, multiple photos</td></tr>
                    <tr><td><strong>Profile Completeness</strong></td><td>10%</td><td>Bio, prompts, interests filled</td></tr>
                    <tr><td><strong>Boost Active</strong></td><td>5%</td><td>Premium boost multiplier</td></tr>
                </tbody>
            </table>
        `
    },
    {
        file: '69-security-architecture.html',
        title: 'Security Architecture - System Design',
        section: 'Security',
        content: `
            <h2>Security Architecture Overview</h2>
            <p>GreenGo implements defense-in-depth security with multiple layers of protection for user data and application integrity.</p>

            <h2>Security Layers Diagram</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      SECURITY ARCHITECTURE LAYERS                                    │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│  LAYER 1: NETWORK SECURITY                                                           │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • HTTPS/TLS 1.3 for all traffic                                              │   │
│  │ • Certificate pinning in mobile apps                                         │   │
│  │ • DDoS protection via Cloud Armor                                            │   │
│  │ • WAF rules for common attacks                                               │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  LAYER 2: APPLICATION SECURITY                                                       │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • Firebase App Check (device attestation)                                    │   │
│  │ • Rate limiting per user/IP                                                  │   │
│  │ • Input validation and sanitization                                          │   │
│  │ • OWASP Top 10 protection                                                    │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  LAYER 3: AUTHENTICATION & AUTHORIZATION                                             │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • Firebase Auth with MFA option                                              │   │
│  │ • JWT tokens with short expiry                                               │   │
│  │ • Custom claims for roles/permissions                                        │   │
│  │ • Session management and revocation                                          │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  LAYER 4: DATA SECURITY                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • Firestore security rules                                                   │   │
│  │ • Storage security rules                                                     │   │
│  │ • Field-level encryption for sensitive data                                  │   │
│  │ • Data masking in logs                                                       │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  LAYER 5: CONTENT SECURITY                                                           │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • AI-powered content moderation                                              │   │
│  │ • Photo verification system                                                  │   │
│  │ • Spam and abuse detection                                                   │   │
│  │ • User reporting and review                                                  │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
            </code></pre>

            <h2>Authentication Flow</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                    SECURE AUTHENTICATION FLOW                                        │
└─────────────────────────────────────────────────────────────────────────────────────┘

Client              Firebase Auth        Cloud Function        Firestore
  │                      │                     │                   │
  │ signIn(email, pass)  │                     │                   │
  │─────────────────────▶│                     │                   │
  │                      │                     │                   │
  │                      │ Validate creds      │                   │
  │                      │ Check rate limit    │                   │
  │                      │ Check banned        │                   │
  │                      │         │           │                   │
  │                      │         ▼           │                   │
  │                      │ Generate JWT        │                   │
  │                      │ + Custom Claims     │                   │
  │                      │         │           │                   │
  │                      │         ▼           │                   │
  │   ID Token (JWT)     │                     │                   │
  │◀─────────────────────│                     │                   │
  │                      │                     │                   │
  │ Request + ID Token   │                     │                   │
  │──────────────────────┼────────────────────▶│                   │
  │                      │                     │                   │
  │                      │                     │ Verify token      │
  │                      │                     │ Extract UID       │
  │                      │                     │ Check claims      │
  │                      │                     │         │         │
  │                      │                     │         ▼         │
  │                      │                     │ Execute with      │
  │                      │                     │ auth context      │
  │                      │                     │────────────────▶│
  │                      │                     │                   │
  │   Response           │                     │     Data          │
  │◀─────────────────────┼─────────────────────│◀──────────────────│
  │                      │                     │                   │

JWT Token Structure:
{
  "iss": "https://securetoken.google.com/greengo-prod",
  "aud": "greengo-prod",
  "auth_time": 1234567890,
  "user_id": "abc123",
  "sub": "abc123",
  "iat": 1234567890,
  "exp": 1234571490,  // 1 hour expiry
  "email": "user@example.com",
  "email_verified": true,
  "firebase": {
    "identities": {...},
    "sign_in_provider": "password"
  },
  // Custom claims
  "subscription": "gold",
  "isVerified": true,
  "role": "user"
}
            </code></pre>

            <h2>Firestore Security Rules</h2>
            <p><strong>File:</strong> <code>firestore.rules</code></p>
            <pre><code class="language-javascript">
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    function isNotBanned() {
      return !get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isBanned;
    }

    function hasSubscription(tier) {
      let user = get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
      return user.subscription.tier == tier;
    }

    // Users collection
    match /users/{userId} {
      // Anyone authenticated can read basic profile
      allow read: if isAuthenticated() && isNotBanned();

      // Only owner can write their own profile
      allow create: if isOwner(userId);
      allow update: if isOwner(userId)
        && !request.resource.data.diff(resource.data).affectedKeys()
            .hasAny(['id', 'createdAt', 'isVerified', 'isBanned']);
      allow delete: if isOwner(userId);
    }

    // Matches collection
    match /matches/{matchId} {
      // Only participants can read
      allow read: if isAuthenticated()
        && request.auth.uid in resource.data.users;

      // Only system can create (via Cloud Function)
      allow create: if false;

      // Participants can unmatch
      allow update: if isAuthenticated()
        && request.auth.uid in resource.data.users
        && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['status', 'unmatchedBy', 'unmatchedAt']);
    }

    // Conversations collection
    match /conversations/{conversationId} {
      allow read: if isAuthenticated()
        && request.auth.uid in resource.data.participants;

      // Messages subcollection
      match /messages/{messageId} {
        allow read: if isAuthenticated()
          && request.auth.uid in get(/databases/$(database)/documents/
              conversations/$(conversationId)).data.participants;

        allow create: if isAuthenticated()
          && request.auth.uid in get(/databases/$(database)/documents/
              conversations/$(conversationId)).data.participants
          && request.resource.data.senderId == request.auth.uid
          && request.resource.data.content.size() <= 1000;
      }
    }

    // Swipes collection
    match /swipes/{swipeId} {
      // Can only read own swipes
      allow read: if isAuthenticated()
        && resource.data.swiperId == request.auth.uid;

      // Can only create own swipes
      allow create: if isAuthenticated()
        && request.resource.data.swiperId == request.auth.uid
        && request.resource.data.swiperId != request.resource.data.swipedId;
    }

    // Subscriptions - read only for owner
    match /subscriptions/{subId} {
      allow read: if isAuthenticated()
        && resource.data.userId == request.auth.uid;
      allow write: if false; // Only via Cloud Functions
    }

    // Reports - write only
    match /reports/{reportId} {
      allow read: if false;
      allow create: if isAuthenticated()
        && request.resource.data.reporterId == request.auth.uid;
    }
  }
}
            </code></pre>

            <h2>Data Encryption Strategy</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      DATA ENCRYPTION LAYERS                                          │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│  AT REST                                                                │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ • Firestore: AES-256 (Google managed keys)                       │   │
│  │ • Cloud Storage: AES-256 (Google managed keys)                   │   │
│  │ • Backups: Customer-managed encryption keys (CMEK)               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│  IN TRANSIT                                                             │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ • TLS 1.3 for all API calls                                      │   │
│  │ • Certificate pinning in mobile apps                             │   │
│  │ • mTLS for service-to-service                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│  APPLICATION-LEVEL                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ Sensitive Fields (additional encryption):                        │   │
│  │ • Phone numbers: AES-256-GCM                                     │   │
│  │ • Payment tokens: Tokenized via Stripe                           │   │
│  │ • Location (precise): Encrypted, only geohash public             │   │
│  │ • Chat messages: End-to-end encryption (optional)                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘

Key Management:
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Google KMS     │────▶│  Encryption     │────▶│  Rotation       │
│  Key Storage    │     │  Keys           │     │  (90 days)      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
            </code></pre>

            <h2>Security Monitoring</h2>
            <table>
                <thead>
                    <tr><th>Monitor</th><th>Tool</th><th>Alert Threshold</th></tr>
                </thead>
                <tbody>
                    <tr><td>Failed auth attempts</td><td>Cloud Monitoring</td><td>>10/min per IP</td></tr>
                    <tr><td>Unusual API patterns</td><td>Cloud Armor</td><td>Anomaly detection</td></tr>
                    <tr><td>Security rule denials</td><td>Firestore logs</td><td>>100/hour</td></tr>
                    <tr><td>Suspicious content</td><td>Content moderation</td><td>Immediate</td></tr>
                    <tr><td>Data exfiltration</td><td>DLP</td><td>Any PII in logs</td></tr>
                </tbody>
            </table>
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
        ${fullNavMenu}
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
            </div>
        </div>
    </main>

    <script src="../js/main.js"></script>
</body>
</html>`;
}

// Generate pages
const pagesDir = path.join(__dirname, 'pages');

systemDesignPages.forEach(page => {
    const filepath = path.join(pagesDir, page.file);
    const html = createPageHTML(page);
    fs.writeFileSync(filepath, html);
    console.log(`Created: ${page.file}`);
});

console.log(`\nGenerated ${systemDesignPages.length} system design pages with expert-level diagrams!`);
