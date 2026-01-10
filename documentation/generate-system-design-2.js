const fs = require('fs');
const path = require('path');

// Navigation menu (abbreviated for space)
const fullNavMenu = `<ul class="nav-menu" id="navMenu">
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-home"></i><span>Project Overview</span><i class="fas fa-chevron-down arrow"></i></div>
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
                <div class="nav-section-title"><i class="fas fa-sitemap"></i><span>Architecture</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="09-clean-architecture.html">9. Clean Architecture</a></li>
                    <li><a href="10-feature-modules.html">10. Feature Modules</a></li>
                    <li><a href="11-state-management.html">11. State Management</a></li>
                    <li><a href="12-dependency-injection.html">12. Dependency Injection</a></li>
                    <li><a href="13-repository-pattern.html">13. Repository Pattern</a></li>
                    <li><a href="14-data-flow.html">14. Data Flow</a></li>
                    <li><a href="15-error-handling.html">15. Error Handling</a></li>
                    <li><a href="16-navigation.html">16. Navigation</a></li>
                    <li><a href="17-api-layer.html">17. API Layer</a></li>
                    <li><a href="18-caching.html">18. Caching</a></li>
                    <li><a href="19-real-time.html">19. Real-time</a></li>
                    <li><a href="20-testing-architecture.html">20. Testing</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-palette"></i><span>Design System</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="21-brand-guidelines.html">21. Brand Guidelines</a></li>
                    <li><a href="22-color-palette.html">22. Color Palette</a></li>
                    <li><a href="23-typography.html">23. Typography</a></li>
                    <li><a href="24-spacing.html">24. Spacing</a></li>
                    <li><a href="25-components.html">25. Components</a></li>
                    <li><a href="26-icons.html">26. Icons</a></li>
                    <li><a href="27-animations.html">27. Animations</a></li>
                    <li><a href="28-theming.html">28. Theming</a></li>
                    <li><a href="29-responsive.html">29. Responsive</a></li>
                    <li><a href="30-accessibility.html">30. Accessibility</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-puzzle-piece"></i><span>Core Features</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="31-auth-flow.html">31. Authentication</a></li>
                    <li><a href="32-social-auth.html">32. Social Auth</a></li>
                    <li><a href="33-biometric-auth.html">33. Biometric</a></li>
                    <li><a href="34-onboarding.html">34. Onboarding</a></li>
                    <li><a href="35-photo-upload.html">35. Photos</a></li>
                    <li><a href="36-profile-editing.html">36. Profile</a></li>
                    <li><a href="37-matching-algorithm.html">37. Matching</a></li>
                    <li><a href="38-discovery.html">38. Discovery</a></li>
                    <li><a href="39-like-actions.html">39. Actions</a></li>
                    <li><a href="40-match-system.html">40. Matches</a></li>
                    <li><a href="41-chat.html">41. Chat</a></li>
                    <li><a href="42-message-features.html">42. Messages</a></li>
                    <li><a href="43-push-notifications.html">43. Push</a></li>
                    <li><a href="44-in-app-notifications.html">44. Notifications</a></li>
                    <li><a href="45-subscriptions.html">45. Subscriptions</a></li>
                    <li><a href="46-in-app-purchases.html">46. Purchases</a></li>
                    <li><a href="47-coins.html">47. Coins</a></li>
                    <li><a href="48-gamification.html">48. Gamification</a></li>
                    <li><a href="49-challenges.html">49. Challenges</a></li>
                    <li><a href="50-leaderboards.html">50. Leaderboards</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-server"></i><span>Backend</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="51-firebase-overview.html">51. Firebase</a></li>
                    <li><a href="52-firestore.html">52. Firestore</a></li>
                    <li><a href="53-firebase-auth.html">53. Auth</a></li>
                    <li><a href="54-firebase-storage.html">54. Storage</a></li>
                    <li><a href="55-cloud-functions.html">55. Functions</a></li>
                    <li><a href="56-django-backend.html">56. Django</a></li>
                    <li><a href="57-api-documentation.html">57. API Docs</a></li>
                    <li><a href="58-realtime-sync.html">58. Sync</a></li>
                    <li><a href="59-background-processing.html">59. Background</a></li>
                    <li><a href="60-rate-limiting.html">60. Rate Limit</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-database"></i><span>Database</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="61-firestore-schema.html">61. Schema</a></li>
                    <li><a href="62-postgresql-schema.html">62. PostgreSQL</a></li>
                    <li><a href="63-data-migration.html">63. Migration</a></li>
                    <li><a href="64-indexing.html">64. Indexing</a></li>
                    <li><a href="65-backup-recovery.html">65. Backup</a></li>
                    <li><a href="66-data-retention.html">66. Retention</a></li>
                    <li><a href="67-redis-caching.html">67. Redis</a></li>
                    <li><a href="68-bigquery.html">68. BigQuery</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-shield-alt"></i><span>Security</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="69-security-architecture.html">69. Architecture</a></li>
                    <li><a href="70-firestore-rules.html">70. Rules</a></li>
                    <li><a href="71-storage-rules.html">71. Storage</a></li>
                    <li><a href="72-auth-security.html">72. Auth</a></li>
                    <li><a href="73-encryption.html">73. Encryption</a></li>
                    <li><a href="74-app-check.html">74. App Check</a></li>
                    <li><a href="75-content-moderation.html">75. Moderation</a></li>
                    <li><a href="76-spam-detection.html">76. Spam</a></li>
                    <li><a href="77-reporting-system.html">77. Reports</a></li>
                    <li><a href="78-security-audit.html">78. Audit</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-plug"></i><span>Integrations</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="79-agora-video.html">79. Agora</a></li>
                    <li><a href="80-stripe.html">80. Stripe</a></li>
                    <li><a href="81-sendgrid.html">81. SendGrid</a></li>
                    <li><a href="82-twilio.html">82. Twilio</a></li>
                    <li><a href="83-google-maps.html">83. Maps</a></li>
                    <li><a href="84-google-cloud-ai.html">84. Cloud AI</a></li>
                    <li><a href="85-mixpanel.html">85. Mixpanel</a></li>
                    <li><a href="86-sentry.html">86. Sentry</a></li>
                    <li><a href="87-perspective-api.html">87. Perspective</a></li>
                    <li><a href="88-revenuecat.html">88. RevenueCat</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-cogs"></i><span>DevOps</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="89-terraform.html">89. Terraform</a></li>
                    <li><a href="90-docker.html">90. Docker</a></li>
                    <li><a href="91-cicd.html">91. CI/CD</a></li>
                    <li><a href="92-environments.html">92. Environments</a></li>
                    <li><a href="93-feature-flags.html">93. Flags</a></li>
                    <li><a href="94-pre-commit.html">94. Pre-commit</a></li>
                    <li><a href="95-deployment.html">95. Deployment</a></li>
                    <li><a href="96-firebase-hosting.html">96. Hosting</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-vial"></i><span>Testing</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="97-unit-testing.html">97. Unit</a></li>
                    <li><a href="98-widget-testing.html">98. Widget</a></li>
                    <li><a href="99-integration-testing.html">99. Integration</a></li>
                    <li><a href="100-firebase-test-lab.html">100. Test Lab</a></li>
                </ul>
            </li>
        </ul>`;

const systemDesignPages = [
    {
        file: '31-auth-flow.html',
        title: 'Authentication Flow - System Design',
        section: 'Core Features',
        content: `
            <h2>Authentication System Architecture</h2>
            <p>Complete authentication flow design including email/password, social login, and session management.</p>

            <h2>Authentication Architecture</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION SYSTEM ARCHITECTURE                                │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                │
│  │ Email/Pass  │  │   Google    │  │  Facebook   │  │   Apple     │                │
│  │   Login     │  │   OAuth     │  │   Login     │  │  Sign-In    │                │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                │
│         └─────────────────┴─────────────────┴─────────────────┘                     │
│                                     │                                               │
│                          ┌──────────▼──────────┐                                    │
│                          │    AuthBloc         │                                    │
│                          │  State Management   │                                    │
│                          └──────────┬──────────┘                                    │
└─────────────────────────────────────┼───────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                            FIREBASE AUTH                                             │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • Identity verification                                                      │   │
│  │ • JWT token generation                                                       │   │
│  │ • Session management                                                         │   │
│  │ • MFA support                                                                │   │
│  │ • Rate limiting                                                              │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────┬───────────────────────────────────────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
         ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
         │  User Profile   │ │  Custom Claims  │ │  Cloud Function │
         │  Creation       │ │  Assignment     │ │  Triggers       │
         └─────────────────┘ └─────────────────┘ └─────────────────┘
            </code></pre>

            <h2>Complete Sign-Up Flow</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         EMAIL SIGN-UP SEQUENCE                                       │
└─────────────────────────────────────────────────────────────────────────────────────┘

User           UI              AuthBloc         Repository        Firebase        Function
 │              │                  │                │                │               │
 │ Enter email  │                  │                │                │               │
 │ + password   │                  │                │                │               │
 │─────────────▶│                  │                │                │               │
 │              │ Validate input   │                │                │               │
 │              │────────┐         │                │                │               │
 │              │◀───────┘         │                │                │               │
 │              │                  │                │                │               │
 │              │ SignUpRequested  │                │                │               │
 │              │─────────────────▶│                │                │               │
 │              │                  │ emit(Loading)  │                │               │
 │              │                  │────────┐       │                │               │
 │              │                  │◀───────┘       │                │               │
 │              │                  │                │                │               │
 │              │                  │ signUp()       │                │               │
 │              │                  │───────────────▶│                │               │
 │              │                  │                │ createUser     │               │
 │              │                  │                │───────────────▶│               │
 │              │                  │                │                │               │
 │              │                  │                │   UserCred     │               │
 │              │                  │                │◀───────────────│               │
 │              │                  │                │                │ onUserCreate  │
 │              │                  │                │                │──────────────▶│
 │              │                  │                │                │               │
 │              │                  │                │                │ • Create doc  │
 │              │                  │                │                │ • Send email  │
 │              │                  │                │                │ • Init stats  │
 │              │                  │                │                │               │
 │              │                  │  Right(User)   │                │               │
 │              │                  │◀───────────────│                │               │
 │              │                  │                │                │               │
 │              │                  │ emit(Success)  │                │               │
 │              │                  │────────┐       │                │               │
 │              │                  │◀───────┘       │                │               │
 │              │ Navigate to      │                │                │               │
 │              │ Onboarding       │                │                │               │
 │◀─────────────│◀─────────────────│                │                │               │
 │              │                  │                │                │               │
            </code></pre>

            <h2>Token Refresh Flow</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         TOKEN REFRESH MECHANISM                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘

                    ┌─────────────────┐
                    │   ID Token      │
                    │  (1 hour TTL)   │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
              ┌─────│  Token Valid?   │─────┐
              │     └─────────────────┘     │
            Yes                            No
              │                             │
              ▼                             ▼
    ┌─────────────────┐          ┌─────────────────┐
    │  Use Token      │          │  Refresh Token  │
    │  for Request    │          │  Exchange       │
    └─────────────────┘          └────────┬────────┘
                                          │
                                 ┌────────▼────────┐
                           ┌─────│ Refresh Valid?  │─────┐
                           │     └─────────────────┘     │
                         Yes                            No
                           │                             │
                           ▼                             ▼
                 ┌─────────────────┐          ┌─────────────────┐
                 │  Get New Token  │          │  Force Re-login │
                 │  Continue       │          │  Clear Session  │
                 └─────────────────┘          └─────────────────┘

Implementation:
┌─────────────────────────────────────────────────────────────────────┐
│ class AuthInterceptor {                                             │
│   Future<String> getValidToken() async {                            │
│     final user = FirebaseAuth.instance.currentUser;                 │
│     if (user == null) throw UnauthorizedException();                │
│                                                                     │
│     // Force refresh if token expires in < 5 minutes                │
│     final token = await user.getIdToken(                            │
│       user.metadata.lastSignInTime!                                 │
│         .add(Duration(hours: 1))                                    │
│         .difference(DateTime.now())                                 │
│         .inMinutes < 5                                              │
│     );                                                              │
│                                                                     │
│     return token;                                                   │
│   }                                                                 │
│ }                                                                   │
└─────────────────────────────────────────────────────────────────────┘
            </code></pre>

            <h2>Session Management</h2>
            <table>
                <thead>
                    <tr><th>Aspect</th><th>Implementation</th><th>Duration</th></tr>
                </thead>
                <tbody>
                    <tr><td><strong>ID Token</strong></td><td>JWT from Firebase Auth</td><td>1 hour</td></tr>
                    <tr><td><strong>Refresh Token</strong></td><td>Persistent, secure storage</td><td>30 days</td></tr>
                    <tr><td><strong>Session Cookie</strong></td><td>Web only, httpOnly</td><td>14 days</td></tr>
                    <tr><td><strong>Remember Me</strong></td><td>Extended refresh token</td><td>90 days</td></tr>
                </tbody>
            </table>
        `
    },
    {
        file: '41-chat.html',
        title: 'Real-time Chat - System Design',
        section: 'Core Features',
        content: `
            <h2>Chat System Architecture</h2>
            <p>Real-time messaging system with typing indicators, read receipts, media sharing, and offline support.</p>

            <h2>Chat Architecture Overview</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        CHAT SYSTEM ARCHITECTURE                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                                            │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                          ChatBloc                                            │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │   │
│  │  │  Messages   │  │   Typing    │  │   Online    │  │   Media     │        │   │
│  │  │   Stream    │  │  Indicator  │  │   Status    │  │   Upload    │        │   │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │   │
│  │         └─────────────────┴─────────────────┴─────────────────┘              │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                        │
              ┌─────────────────────────┼─────────────────────────┐
              │                         │                         │
              ▼                         ▼                         ▼
    ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
    │   FIRESTORE     │       │  CLOUD STORAGE  │       │   CLOUD FCM     │
    │   Real-time     │       │   Media Files   │       │   Push Notifs   │
    ├─────────────────┤       ├─────────────────┤       ├─────────────────┤
    │ • conversations │       │ • Images        │       │ • New message   │
    │ • messages      │       │ • Videos        │       │ • Match notif   │
    │ • typing status │       │ • Voice notes   │       │ • Read receipts │
    │ • read receipts │       │ • GIFs          │       │                 │
    └─────────────────┘       └─────────────────┘       └─────────────────┘
            </code></pre>

            <h2>Message Flow Sequence</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        SEND MESSAGE SEQUENCE                                         │
└─────────────────────────────────────────────────────────────────────────────────────┘

Sender            ChatBloc         Repository        Firestore         FCM          Receiver
  │                  │                 │                │               │               │
  │ Send "Hello"     │                 │                │               │               │
  │─────────────────▶│                 │                │               │               │
  │                  │                 │                │               │               │
  │                  │ Optimistic UI   │                │               │               │
  │                  │ (pending msg)   │                │               │               │
  │                  │────────┐        │                │               │               │
  │                  │◀───────┘        │                │               │               │
  │                  │                 │                │               │               │
  │                  │ sendMessage()   │                │               │               │
  │                  │────────────────▶│                │               │               │
  │                  │                 │ batch.write    │               │               │
  │                  │                 │───────────────▶│               │               │
  │                  │                 │                │               │               │
  │                  │                 │                │ onMessageCreate              │
  │                  │                 │                │──────────────▶│               │
  │                  │                 │                │               │               │
  │                  │                 │                │               │ Push "Hello"  │
  │                  │                 │                │               │──────────────▶│
  │                  │                 │                │               │               │
  │                  │                 │                │ Stream update │               │
  │                  │                 │◀───────────────│───────────────┼──────────────▶│
  │                  │                 │                │               │               │
  │                  │ Message sent ✓  │                │               │               │
  │                  │◀────────────────│                │               │               │
  │                  │                 │                │               │               │
  │ Update UI        │                 │                │               │ Display msg   │
  │ (sent status)    │                 │                │               │               │
  │◀─────────────────│                 │                │               │               │
  │                  │                 │                │               │               │
            </code></pre>

            <h2>Data Model</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        CHAT DATA MODEL                                               │
└─────────────────────────────────────────────────────────────────────────────────────┘

conversations/{conversationId}
├── id: string
├── matchId: string
├── participants: [userId1, userId2]
├── createdAt: timestamp
├── lastMessageAt: timestamp
├── lastMessage: {
│   ├── content: string
│   ├── senderId: string
│   ├── type: string
│   └── timestamp: timestamp
│   }
├── unreadCount: {
│   ├── userId1: number
│   └── userId2: number
│   }
└── messages/{messageId}  (subcollection)
    ├── id: string
    ├── conversationId: string
    ├── senderId: string
    ├── content: string
    ├── type: text | image | gif | voice | video
    ├── mediaUrl: string?
    ├── thumbnailUrl: string?
    ├── duration: number? (for voice/video)
    ├── replyTo: {
    │   ├── messageId: string
    │   ├── content: string
    │   └── senderId: string
    │   }?
    ├── reactions: {
    │   └── userId: emoji
    │   }
    ├── timestamp: timestamp
    ├── readAt: timestamp?
    ├── deliveredAt: timestamp?
    └── status: sending | sent | delivered | read | failed
            </code></pre>

            <h2>Typing Indicator System</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                     TYPING INDICATOR FLOW                                            │
└─────────────────────────────────────────────────────────────────────────────────────┘

User A (typing)              Firestore                    User B (watching)
     │                           │                              │
     │ onTextChanged             │                              │
     │ (debounce 300ms)          │                              │
     │──────────────────────────▶│                              │
     │                           │                              │
     │                           │ Update typing doc            │
     │                           │ {                            │
     │                           │   oderId: A,                │
     │                           │   timestamp: now             │
     │                           │ }                            │
     │                           │                              │
     │                           │ Stream snapshot              │
     │                           │─────────────────────────────▶│
     │                           │                              │
     │                           │                              │ Check timestamp
     │                           │                              │ < 5 seconds ago?
     │                           │                              │      │
     │                           │                              │      ▼
     │                           │                              │ Show "typing..."
     │                           │                              │
     │ Stop typing (5s timeout)  │                              │
     │──────────────────────────▶│                              │
     │                           │                              │
     │                           │ Stream snapshot              │
     │                           │─────────────────────────────▶│
     │                           │                              │
     │                           │                              │ Timestamp > 5s
     │                           │                              │ Hide indicator
     │                           │                              │
            </code></pre>

            <h2>Features Matrix</h2>
            <table>
                <thead>
                    <tr><th>Feature</th><th>Basic</th><th>Silver</th><th>Gold</th></tr>
                </thead>
                <tbody>
                    <tr><td>Text messages</td><td>✓</td><td>✓</td><td>✓</td></tr>
                    <tr><td>Image sharing</td><td>✓</td><td>✓</td><td>✓</td></tr>
                    <tr><td>GIFs</td><td>✓</td><td>✓</td><td>✓</td></tr>
                    <tr><td>Voice notes</td><td>✗</td><td>✓</td><td>✓</td></tr>
                    <tr><td>Video messages</td><td>✗</td><td>✗</td><td>✓</td></tr>
                    <tr><td>Read receipts</td><td>✗</td><td>✗</td><td>✓</td></tr>
                    <tr><td>Message reactions</td><td>✓</td><td>✓</td><td>✓</td></tr>
                    <tr><td>Unlimited history</td><td>30 days</td><td>✓</td><td>✓</td></tr>
                </tbody>
            </table>
        `
    },
    {
        file: '91-cicd.html',
        title: 'CI/CD Pipeline - System Design',
        section: 'DevOps',
        content: `
            <h2>CI/CD Pipeline Architecture</h2>
            <p>Automated build, test, and deployment pipeline using GitHub Actions for Flutter and Firebase.</p>

            <h2>Pipeline Architecture</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         CI/CD PIPELINE ARCHITECTURE                                  │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Developer     │     │    GitHub       │     │  GitHub Actions │
│   Push/PR       │────▶│   Repository    │────▶│   Workflows     │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                         │
                              ┌──────────────────────────┼──────────────────────────┐
                              │                          │                          │
                              ▼                          ▼                          ▼
                    ┌─────────────────┐        ┌─────────────────┐        ┌─────────────────┐
                    │   LINT & TEST   │        │     BUILD       │        │    DEPLOY       │
                    ├─────────────────┤        ├─────────────────┤        ├─────────────────┤
                    │ • flutter analyze│       │ • Android APK   │        │ • Firebase      │
                    │ • dart format    │       │ • iOS IPA       │        │ • Play Store    │
                    │ • Unit tests     │       │ • Web build     │        │ • App Store     │
                    │ • Widget tests   │       │ • Functions     │        │ • TestFlight    │
                    │ • Integration    │       │                 │        │                 │
                    └────────┬────────┘        └────────┬────────┘        └────────┬────────┘
                             │                          │                          │
                             └──────────────────────────┼──────────────────────────┘
                                                        │
                                               ┌────────▼────────┐
                                               │   ARTIFACTS     │
                                               │   & RELEASES    │
                                               └─────────────────┘

Environment Flow:
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   feature   │────▶│   develop   │────▶│   staging   │────▶│    main     │
│   branch    │     │   branch    │     │   branch    │     │  (production)│
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │                   │
       ▼                   ▼                   ▼                   ▼
   PR Tests           Dev Deploy         Staging Deploy       Prod Deploy
   Only               Firebase Dev       Firebase Staging     Firebase Prod
                                         TestFlight           App Store
                                         Play Internal        Play Store
            </code></pre>

            <h2>GitHub Actions Workflow</h2>
            <pre><code class="language-yaml">
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop, staging]
  pull_request:
    branches: [main, develop]

env:
  FLUTTER_VERSION: '3.16.0'
  JAVA_VERSION: '17'

jobs:
  # ============================================
  # LINT & ANALYZE
  # ============================================
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: \${{ env.FLUTTER_VERSION }}
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze code
        run: flutter analyze --fatal-infos

      - name: Check for outdated packages
        run: flutter pub outdated

  # ============================================
  # UNIT & WIDGET TESTS
  # ============================================
  test:
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: \${{ env.FLUTTER_VERSION }}
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Run tests with coverage
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info

  # ============================================
  # BUILD ANDROID
  # ============================================
  build-android:
    runs-on: ubuntu-latest
    needs: test
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: \${{ env.JAVA_VERSION }}

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: \${{ env.FLUTTER_VERSION }}
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Decode keystore
        run: echo "\${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks

      - name: Build APK
        run: |
          flutter build apk --release \\
            --dart-define=ENV=\${{ github.ref_name }}
        env:
          KEYSTORE_PASSWORD: \${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: \${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: \${{ secrets.KEY_PASSWORD }}

      - name: Build App Bundle
        run: flutter build appbundle --release

      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: android-release
          path: build/app/outputs/flutter-apk/app-release.apk

  # ============================================
  # BUILD iOS
  # ============================================
  build-ios:
    runs-on: macos-latest
    needs: test
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: \${{ env.FLUTTER_VERSION }}
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Install CocoaPods
        run: cd ios && pod install

      - name: Build iOS
        run: flutter build ios --release --no-codesign

      - name: Upload iOS build
        uses: actions/upload-artifact@v3
        with:
          name: ios-release
          path: build/ios/iphoneos/Runner.app

  # ============================================
  # DEPLOY TO FIREBASE
  # ============================================
  deploy-firebase:
    runs-on: ubuntu-latest
    needs: [build-android, build-ios]
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/staging'
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install Firebase CLI
        run: npm install -g firebase-tools

      - name: Deploy Functions
        run: |
          cd functions
          npm ci
          firebase deploy --only functions --project \${{ secrets.FIREBASE_PROJECT }}
        env:
          FIREBASE_TOKEN: \${{ secrets.FIREBASE_TOKEN }}

      - name: Deploy Rules
        run: |
          firebase deploy --only firestore:rules,storage --project \${{ secrets.FIREBASE_PROJECT }}
        env:
          FIREBASE_TOKEN: \${{ secrets.FIREBASE_TOKEN }}
            </code></pre>

            <h2>Deployment Stages</h2>
            <table>
                <thead>
                    <tr><th>Stage</th><th>Trigger</th><th>Actions</th><th>Target</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>PR Check</strong></td>
                        <td>Pull Request</td>
                        <td>Lint, Test, Analyze</td>
                        <td>None</td>
                    </tr>
                    <tr>
                        <td><strong>Dev Deploy</strong></td>
                        <td>Push to develop</td>
                        <td>Build, Deploy Functions</td>
                        <td>Firebase Dev</td>
                    </tr>
                    <tr>
                        <td><strong>Staging</strong></td>
                        <td>Push to staging</td>
                        <td>Full Build, Deploy</td>
                        <td>TestFlight, Play Internal</td>
                    </tr>
                    <tr>
                        <td><strong>Production</strong></td>
                        <td>Push to main</td>
                        <td>Full Build, Deploy, Tag</td>
                        <td>App Store, Play Store</td>
                    </tr>
                </tbody>
            </table>
        `
    },
    {
        file: '90-docker.html',
        title: 'Docker Development - System Design',
        section: 'DevOps',
        content: `
            <h2>Docker Development Environment</h2>
            <p>Containerized local development setup with Firebase emulators, PostgreSQL, and Redis.</p>

            <h2>Docker Architecture</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      DOCKER DEVELOPMENT ARCHITECTURE                                 │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           DOCKER COMPOSE NETWORK                                     │
│                                                                                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                     │
│  │   firebase-     │  │   postgres      │  │     redis       │                     │
│  │   emulators     │  │                 │  │                 │                     │
│  ├─────────────────┤  ├─────────────────┤  ├─────────────────┤                     │
│  │ • Auth: 9099    │  │ • Port: 5432    │  │ • Port: 6379    │                     │
│  │ • Firestore:8080│  │ • DB: greengo   │  │ • Cache layer   │                     │
│  │ • Storage: 9199 │  │ • User: dev     │  │                 │                     │
│  │ • Functions:5001│  │                 │  │                 │                     │
│  │ • Pub/Sub: 8085 │  │                 │  │                 │                     │
│  │ • UI: 4000      │  │                 │  │                 │                     │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                     │
│           │                    │                    │                              │
│           └────────────────────┼────────────────────┘                              │
│                                │                                                    │
│                       ┌────────▼────────┐                                          │
│                       │  greengo-net    │                                          │
│                       │  (bridge)       │                                          │
│                       └─────────────────┘                                          │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                 │
                        Host Machine
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
                    ▼            ▼            ▼
            ┌─────────────┐ ┌─────────┐ ┌─────────────┐
            │Flutter App  │ │ IDE     │ │ Browser     │
            │(Dev Mode)   │ │         │ │ :4000       │
            └─────────────┘ └─────────┘ └─────────────┘
            </code></pre>

            <h2>Docker Compose Configuration</h2>
            <pre><code class="language-yaml">
# docker-compose.yml
version: '3.8'

services:
  firebase-emulators:
    build:
      context: ./firebase
      dockerfile: Dockerfile.emulators
    ports:
      - "4000:4000"   # Emulator UI
      - "8080:8080"   # Firestore
      - "9099:9099"   # Auth
      - "9199:9199"   # Storage
      - "5001:5001"   # Functions
      - "8085:8085"   # Pub/Sub
    volumes:
      - ./firebase:/app/firebase
      - firebase-data:/app/firebase/data
    environment:
      - FIREBASE_PROJECT=greengo-dev
      - GOOGLE_APPLICATION_CREDENTIALS=/app/firebase/service-account.json
    networks:
      - greengo-net

  postgres:
    image: postgres:15-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpassword
      POSTGRES_DB: greengo
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dev -d greengo"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - greengo-net

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5
    networks:
      - greengo-net

  adminer:
    image: adminer
    ports:
      - "8081:8080"
    depends_on:
      - postgres
    networks:
      - greengo-net

volumes:
  firebase-data:
  postgres-data:
  redis-data:

networks:
  greengo-net:
    driver: bridge
            </code></pre>

            <h2>Development Commands</h2>
            <table>
                <thead>
                    <tr><th>Command</th><th>Description</th></tr>
                </thead>
                <tbody>
                    <tr><td><code>docker-compose up -d</code></td><td>Start all services</td></tr>
                    <tr><td><code>docker-compose down</code></td><td>Stop all services</td></tr>
                    <tr><td><code>docker-compose logs -f firebase</code></td><td>View Firebase logs</td></tr>
                    <tr><td><code>docker-compose exec postgres psql</code></td><td>Access PostgreSQL CLI</td></tr>
                    <tr><td><code>docker-compose exec redis redis-cli</code></td><td>Access Redis CLI</td></tr>
                </tbody>
            </table>

            <h2>Services Not Emulated</h2>
            <div class="warning-box">
                <strong>External APIs requiring real credentials:</strong>
                <ul>
                    <li>Stripe - Use test mode keys</li>
                    <li>SendGrid - Use sandbox mode</li>
                    <li>Twilio - Use test credentials</li>
                    <li>Agora - Use test app ID</li>
                    <li>Google Cloud AI - Requires API key</li>
                </ul>
            </div>
        `
    }
];

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

const pagesDir = path.join(__dirname, 'pages');

systemDesignPages.forEach(page => {
    const filepath = path.join(pagesDir, page.file);
    const html = createPageHTML(page);
    fs.writeFileSync(filepath, html);
    console.log(`Created: ${page.file}`);
});

console.log(`\nGenerated ${systemDesignPages.length} additional system design pages!`);
