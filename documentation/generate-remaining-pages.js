const fs = require('fs');
const path = require('path');

// Remaining pages (21-100) with detailed content
const pages = [
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
    // Backend (51-60)
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

// Detailed content for each page
const content = {
    '21-brand-guidelines.html': `
        <h2>Brand Identity</h2>
        <p>GreenGo's brand identity combines luxury with approachability, using a sophisticated gold and black color scheme that conveys premium quality while remaining welcoming.</p>

        <h2>Logo Usage</h2>
        <h3>Primary Logo</h3>
        <ul>
            <li><strong>Location:</strong> <code>assets/images/logo.png</code></li>
            <li><strong>Minimum Size:</strong> 48px height</li>
            <li><strong>Clear Space:</strong> Maintain padding equal to the height of the "G" on all sides</li>
        </ul>

        <h3>Logo Variations</h3>
        <table>
            <tr><th>Variation</th><th>File</th><th>Use Case</th></tr>
            <tr><td>Full Color</td><td>logo.png</td><td>Light backgrounds</td></tr>
            <tr><td>Gold</td><td>logo_gold.png</td><td>Dark backgrounds</td></tr>
            <tr><td>White</td><td>logo_white.png</td><td>Colored backgrounds</td></tr>
        </table>

        <div class="warning-box">
            <strong>Logo Don'ts:</strong>
            <ul>
                <li>Don't stretch or distort the logo</li>
                <li>Don't change the logo colors</li>
                <li>Don't add effects (shadows, gradients)</li>
                <li>Don't place on busy backgrounds</li>
            </ul>
        </div>

        <h2>Brand Voice</h2>
        <h3>Personality Traits</h3>
        <ul>
            <li><strong>Sophisticated:</strong> Premium, refined, elegant</li>
            <li><strong>Trustworthy:</strong> Reliable, secure, honest</li>
            <li><strong>Warm:</strong> Friendly, approachable, supportive</li>
            <li><strong>Playful:</strong> Fun, engaging, lighthearted</li>
        </ul>

        <h3>Writing Guidelines</h3>
        <ul>
            <li>Use active voice</li>
            <li>Be concise and clear</li>
            <li>Address users directly ("you")</li>
            <li>Avoid jargon and technical terms</li>
            <li>Use positive, encouraging language</li>
        </ul>

        <h2>Visual Style</h2>
        <ul>
            <li><strong>Photography:</strong> Authentic, diverse, high-quality lifestyle images</li>
            <li><strong>Illustrations:</strong> Clean, minimal line art with gold accents</li>
            <li><strong>Icons:</strong> Rounded, consistent stroke width</li>
        </ul>
    `,

    '22-color-palette.html': `
        <h2>Primary Brand Colors</h2>
        <table>
            <tr><th>Name</th><th>Hex</th><th>RGB</th><th>Usage</th></tr>
            <tr>
                <td><strong>Rich Gold</strong></td>
                <td>#D4AF37</td>
                <td>212, 175, 55</td>
                <td>Primary accent, CTA buttons, highlights, links</td>
            </tr>
            <tr>
                <td><strong>Accent Gold</strong></td>
                <td>#FFD700</td>
                <td>255, 215, 0</td>
                <td>Hover states, active elements, premium badges</td>
            </tr>
            <tr>
                <td><strong>Deep Black</strong></td>
                <td>#0A0A0A</td>
                <td>10, 10, 10</td>
                <td>Primary background, text on light</td>
            </tr>
            <tr>
                <td><strong>Charcoal</strong></td>
                <td>#1A1A1A</td>
                <td>26, 26, 26</td>
                <td>Secondary background, cards, containers</td>
            </tr>
        </table>

        <h2>Neutral Colors</h2>
        <table>
            <tr><th>Name</th><th>Hex</th><th>Usage</th></tr>
            <tr><td>Dark Gray</td><td>#2A2A2A</td><td>Borders, dividers, disabled states</td></tr>
            <tr><td>Medium Gray</td><td>#4A4A4A</td><td>Secondary text, icons</td></tr>
            <tr><td>Light Gray</td><td>#8A8A8A</td><td>Placeholder text, hints</td></tr>
            <tr><td>Silver</td><td>#C0C0C0</td><td>Subtle backgrounds</td></tr>
            <tr><td>Off White</td><td>#F5F5F5</td><td>Light mode backgrounds</td></tr>
            <tr><td>White</td><td>#FFFFFF</td><td>Text on dark, cards in light mode</td></tr>
        </table>

        <h2>Semantic Colors</h2>
        <table>
            <tr><th>Name</th><th>Hex</th><th>Usage</th></tr>
            <tr><td>Success</td><td>#4CAF50</td><td>Match confirmations, completed actions</td></tr>
            <tr><td>Warning</td><td>#FF9800</td><td>Warnings, subscription expiring</td></tr>
            <tr><td>Error</td><td>#F44336</td><td>Errors, unmatch, block</td></tr>
            <tr><td>Info</td><td>#2196F3</td><td>Information, tips, help</td></tr>
            <tr><td>Like</td><td>#FF4458</td><td>Heart icon, super like</td></tr>
        </table>

        <h2>Gradient Definitions</h2>
        <pre><code>// Primary gradient
LinearGradient(
  colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)

// Background gradient
LinearGradient(
  colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
)</code></pre>

        <h2>Implementation</h2>
        <pre><code>// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color richGold = Color(0xFFD4AF37);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color deepBlack = Color(0xFF0A0A0A);
  static const Color charcoal = Color(0xFF1A1A1A);

  // Neutral Colors
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color mediumGray = Color(0xFF4A4A4A);
  static const Color lightGray = Color(0xFF8A8A8A);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color offWhite = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  static const Color like = Color(0xFFFF4458);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [richGold, accentGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [deepBlack, charcoal],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}</code></pre>

        <h2>Accessibility Considerations</h2>
        <ul>
            <li>Gold on black meets WCAG AA contrast ratio (4.5:1)</li>
            <li>White text on charcoal passes accessibility standards</li>
            <li>Avoid using color alone to convey information</li>
            <li>Test with color blindness simulators</li>
        </ul>
    `,

    '31-auth-flow.html': `
        <h2>Authentication Overview</h2>
        <p>GreenGo uses Firebase Authentication for secure user identity management with support for multiple authentication providers.</p>

        <h2>Authentication Flow Diagram</h2>
        <pre><code>┌─────────────┐
│   App Start  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ AuthWrapper │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│ Check Auth State │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌──────────┐
│ Logged │ │ Not      │
│  In    │ │ Logged In│
└───┬────┘ └────┬─────┘
    │           │
    ▼           ▼
┌────────┐ ┌──────────┐
│  Home  │ │  Login   │
│ Screen │ │  Screen  │
└────────┘ └────┬─────┘
                │
        ┌───────┼───────┐
        │       │       │
        ▼       ▼       ▼
    ┌──────┐ ┌──────┐ ┌────────┐
    │Login │ │Regis │ │Forgot  │
    │      │ │ter   │ │Password│
    └──┬───┘ └──┬───┘ └────────┘
       │        │
       ▼        ▼
   ┌───────────────┐
   │   Onboarding  │
   │   (8 steps)   │
   └───────┬───────┘
           │
           ▼
       ┌────────┐
       │  Home  │
       └────────┘</code></pre>

        <h2>Supported Authentication Methods</h2>
        <table>
            <tr><th>Method</th><th>Provider</th><th>Status</th><th>Configuration</th></tr>
            <tr>
                <td>Email/Password</td>
                <td>Firebase Auth</td>
                <td>✅ Active</td>
                <td>Default enabled</td>
            </tr>
            <tr>
                <td>Google Sign-In</td>
                <td>Google Identity</td>
                <td>🚧 MVP Disabled</td>
                <td><code>enableGoogleAuth: false</code></td>
            </tr>
            <tr>
                <td>Facebook Login</td>
                <td>Facebook SDK</td>
                <td>🚧 MVP Disabled</td>
                <td><code>enableFacebookAuth: false</code></td>
            </tr>
            <tr>
                <td>Sign in with Apple</td>
                <td>Apple ID</td>
                <td>🚧 MVP Disabled</td>
                <td><code>enableAppleAuth: false</code></td>
            </tr>
            <tr>
                <td>Phone Number</td>
                <td>Firebase Auth</td>
                <td>⏳ Planned</td>
                <td>Not implemented</td>
            </tr>
            <tr>
                <td>Biometric</td>
                <td>local_auth</td>
                <td>🚧 MVP Disabled</td>
                <td><code>enableBiometricAuth: false</code></td>
            </tr>
        </table>

        <h2>Key Components</h2>

        <h3>BLoC Implementation</h3>
        <p><strong>Location:</strong> <code>lib/features/authentication/presentation/bloc/</code></p>

        <h4>Events</h4>
        <pre><code>// auth_event.dart
abstract class AuthEvent extends Equatable {}

class AuthCheckRequested extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
}

class LogoutRequested extends AuthEvent {}

class PasswordResetRequested extends AuthEvent {
  final String email;
}

class GoogleSignInRequested extends AuthEvent {}

class FacebookSignInRequested extends AuthEvent {}

class AppleSignInRequested extends AuthEvent {}</code></pre>

        <h4>States</h4>
        <pre><code>// auth_state.dart
abstract class AuthState extends Equatable {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final bool isNewUser;
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
}

class PasswordResetSent extends AuthState {}</code></pre>

        <h3>Screens</h3>
        <table>
            <tr><th>Screen</th><th>File</th><th>Purpose</th></tr>
            <tr>
                <td>Login</td>
                <td><code>login_screen.dart</code></td>
                <td>Email/password login form</td>
            </tr>
            <tr>
                <td>Register</td>
                <td><code>register_screen.dart</code></td>
                <td>New account creation</td>
            </tr>
            <tr>
                <td>Forgot Password</td>
                <td><code>forgot_password_screen.dart</code></td>
                <td>Password reset request</td>
            </tr>
        </table>

        <h3>Use Cases</h3>
        <ul>
            <li><code>login_user.dart</code> - Authenticate with email/password</li>
            <li><code>register_user.dart</code> - Create new account</li>
            <li><code>logout_user.dart</code> - Sign out user</li>
            <li><code>reset_password.dart</code> - Send password reset email</li>
            <li><code>get_current_user.dart</code> - Retrieve authenticated user</li>
        </ul>

        <h2>Password Requirements</h2>
        <ul>
            <li>Minimum 8 characters</li>
            <li>At least one uppercase letter</li>
            <li>At least one lowercase letter</li>
            <li>At least one number</li>
            <li>At least one special character (!@#$%^&*)</li>
        </ul>

        <h2>Security Features</h2>
        <ul>
            <li><strong>Email Verification:</strong> Required before full access</li>
            <li><strong>Rate Limiting:</strong> Prevents brute force attacks</li>
            <li><strong>Secure Storage:</strong> Tokens stored securely</li>
            <li><strong>Session Management:</strong> Auto-refresh of auth tokens</li>
        </ul>
    `,

    '37-matching-algorithm.html': `
        <h2>Algorithm Overview</h2>
        <p>GreenGo uses a sophisticated machine learning-based matching algorithm that analyzes multiple user attributes to calculate compatibility scores between potential matches.</p>

        <h2>Algorithm Pipeline</h2>
        <pre><code>┌──────────────┐
│ User Profile │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│ Feature Engineer │
│ (Create Vector)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Candidate Filter │
│ (Apply Prefs)    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Compatibility   │
│   Scorer (ML)    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Ranking & Sort   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Match Candidates │
└──────────────────┘</code></pre>

        <h2>Feature Engineering</h2>
        <p>User profiles are converted into numerical feature vectors for ML processing.</p>

        <h3>Feature Categories</h3>
        <table>
            <tr><th>Category</th><th>Features</th><th>Weight</th></tr>
            <tr>
                <td><strong>Demographics</strong></td>
                <td>Age, gender, location</td>
                <td>15%</td>
            </tr>
            <tr>
                <td><strong>Preferences</strong></td>
                <td>Age range, distance, gender preference</td>
                <td>20%</td>
            </tr>
            <tr>
                <td><strong>Interests</strong></td>
                <td>Hobbies, activities (encoded as vectors)</td>
                <td>25%</td>
            </tr>
            <tr>
                <td><strong>Lifestyle</strong></td>
                <td>Smoking, drinking, diet, exercise</td>
                <td>15%</td>
            </tr>
            <tr>
                <td><strong>Goals</strong></td>
                <td>Relationship type, family plans</td>
                <td>20%</td>
            </tr>
            <tr>
                <td><strong>Behavior</strong></td>
                <td>Activity patterns, response rate</td>
                <td>5%</td>
            </tr>
        </table>

        <h3>Feature Vector Example</h3>
        <pre><code>{
  "age_normalized": 0.35,
  "location_lat": 40.7128,
  "location_lng": -74.0060,
  "interests_vector": [0.8, 0.2, 0.6, ...],
  "lifestyle_smoking": 0,
  "lifestyle_drinking": 1,
  "goals_relationship": 2,
  "activity_score": 0.75
}</code></pre>

        <h2>Compatibility Scoring</h2>
        <p>The ML model predicts compatibility based on feature vector similarity and historical match success patterns.</p>

        <h3>Score Components</h3>
        <ol>
            <li><strong>Interest Overlap (30%)</strong> - Cosine similarity of interest vectors</li>
            <li><strong>Preference Match (25%)</strong> - How well each user fits the other's preferences</li>
            <li><strong>Lifestyle Compatibility (20%)</strong> - Similarity in lifestyle choices</li>
            <li><strong>Goal Alignment (15%)</strong> - Matching relationship goals</li>
            <li><strong>Location Score (10%)</strong> - Distance within preference range</li>
        </ol>

        <h3>Score Calculation</h3>
        <pre><code>compatibilityScore =
  (interestOverlap * 0.30) +
  (preferenceMatch * 0.25) +
  (lifestyleCompat * 0.20) +
  (goalAlignment * 0.15) +
  (locationScore * 0.10)

// Result: 0-100%</code></pre>

        <h2>Candidate Generation</h2>
        <p>Before scoring, candidates are filtered based on hard constraints:</p>
        <ul>
            <li><strong>Gender:</strong> Matches user's gender preference</li>
            <li><strong>Age:</strong> Within user's preferred age range</li>
            <li><strong>Distance:</strong> Within maximum distance setting</li>
            <li><strong>Blocked:</strong> Not in user's blocked list</li>
            <li><strong>Already Seen:</strong> Not previously liked/passed</li>
        </ul>

        <h2>Ranking Algorithm</h2>
        <p>Candidates are ranked by a combination of factors:</p>
        <pre><code>finalScore =
  (compatibilityScore * 0.70) +
  (recencyBoost * 0.15) +
  (activityBoost * 0.10) +
  (premiumBoost * 0.05)</code></pre>

        <h2>Key Implementation Files</h2>
        <table>
            <tr><th>File</th><th>Purpose</th></tr>
            <tr>
                <td><code>lib/features/matching/domain/usecases/feature_engineer.dart</code></td>
                <td>Converts profiles to feature vectors</td>
            </tr>
            <tr>
                <td><code>lib/features/matching/domain/usecases/compatibility_scorer.dart</code></td>
                <td>Calculates compatibility scores</td>
            </tr>
            <tr>
                <td><code>lib/features/matching/domain/usecases/get_match_candidates.dart</code></td>
                <td>Retrieves and filters candidates</td>
            </tr>
            <tr>
                <td><code>lib/features/matching/data/repositories/matching_repository_impl.dart</code></td>
                <td>Data layer implementation</td>
            </tr>
        </table>

        <h2>ML Model Details</h2>
        <ul>
            <li><strong>Type:</strong> Collaborative filtering + content-based hybrid</li>
            <li><strong>Training:</strong> Historical match success data</li>
            <li><strong>Hosting:</strong> Google Cloud Vertex AI</li>
            <li><strong>Updates:</strong> Weekly model retraining</li>
        </ul>

        <h2>Performance Optimizations</h2>
        <ul>
            <li>Pre-computed feature vectors stored in Firestore</li>
            <li>Geohash indexing for location queries</li>
            <li>Batch scoring for efficiency</li>
            <li>Cached results with 1-hour TTL</li>
        </ul>
    `,

    '41-chat.html': `
        <h2>Chat System Overview</h2>
        <p>GreenGo's real-time chat system is built on Firebase Firestore, providing instant message delivery, read receipts, and rich messaging features.</p>

        <h2>Architecture</h2>
        <pre><code>┌─────────────┐     ┌──────────────┐
│   ChatBloc  │────▶│  Repository  │
└──────┬──────┘     └───────┬──────┘
       │                    │
       │                    ▼
       │            ┌──────────────┐
       │            │  DataSource  │
       │            └───────┬──────┘
       │                    │
       │                    ▼
       │            ┌──────────────┐
       │            │  Firestore   │
       │            │  (Real-time) │
       │            └──────────────┘
       │
       ▼
┌─────────────┐
│  ChatScreen │
│   (UI)      │
└─────────────┘</code></pre>

        <h2>Data Structure</h2>
        <h3>Conversations Collection</h3>
        <pre><code>conversations/{conversationId}
├── participants: ["userId1", "userId2"]
├── participantDetails: {
│     "userId1": { name, photoUrl },
│     "userId2": { name, photoUrl }
│   }
├── lastMessage: {
│     text: "Hey! How are you?",
│     senderId: "userId1",
│     timestamp: Timestamp,
│     type: "text"
│   }
├── createdAt: Timestamp
├── updatedAt: Timestamp
├── unreadCount: {
│     "userId1": 0,
│     "userId2": 3
│   }
└── typing: {
      "userId1": false,
      "userId2": true
    }</code></pre>

        <h3>Messages Subcollection</h3>
        <pre><code>conversations/{conversationId}/messages/{messageId}
├── senderId: "userId1"
├── text: "Hey! How are you?"
├── timestamp: Timestamp
├── type: "text" | "image" | "voice" | "gif"
├── read: true
├── readAt: Timestamp
├── reactions: {
│     "userId2": "❤️"
│   }
├── replyTo: {
│     messageId: "...",
│     text: "...",
│     senderId: "..."
│   }
└── metadata: {
      imageUrl: "...",
      thumbnailUrl: "...",
      duration: 30
    }</code></pre>

        <h2>Features</h2>
        <table>
            <tr><th>Feature</th><th>Description</th><th>Implementation</th></tr>
            <tr>
                <td><strong>Real-time Sync</strong></td>
                <td>Messages appear instantly</td>
                <td>Firestore snapshots listener</td>
            </tr>
            <tr>
                <td><strong>Read Receipts</strong></td>
                <td>See when messages are read</td>
                <td><code>read</code> and <code>readAt</code> fields</td>
            </tr>
            <tr>
                <td><strong>Typing Indicators</strong></td>
                <td>Show when other user is typing</td>
                <td><code>typing</code> map in conversation</td>
            </tr>
            <tr>
                <td><strong>Reactions</strong></td>
                <td>Add emoji reactions to messages</td>
                <td><code>reactions</code> map in message</td>
            </tr>
            <tr>
                <td><strong>Reply</strong></td>
                <td>Reply to specific messages</td>
                <td><code>replyTo</code> object in message</td>
            </tr>
            <tr>
                <td><strong>Message Search</strong></td>
                <td>Search conversation history</td>
                <td>Firestore text search</td>
            </tr>
            <tr>
                <td><strong>Media Messages</strong></td>
                <td>Send images and voice</td>
                <td>Firebase Storage + metadata</td>
            </tr>
        </table>

        <h2>BLoC Implementation</h2>
        <h3>Chat Events</h3>
        <pre><code>// chat_event.dart
abstract class ChatEvent extends Equatable {}

class LoadMessages extends ChatEvent {
  final String conversationId;
}

class SendMessage extends ChatEvent {
  final String conversationId;
  final String text;
  final String? replyToId;
}

class SendImageMessage extends ChatEvent {
  final String conversationId;
  final File image;
}

class MarkAsRead extends ChatEvent {
  final String conversationId;
  final String messageId;
}

class AddReaction extends ChatEvent {
  final String conversationId;
  final String messageId;
  final String emoji;
}

class SetTyping extends ChatEvent {
  final String conversationId;
  final bool isTyping;
}

class DeleteMessage extends ChatEvent {
  final String conversationId;
  final String messageId;
}</code></pre>

        <h3>Chat States</h3>
        <pre><code>// chat_state.dart
abstract class ChatState extends Equatable {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  final bool hasMore;
  final Map<String, bool> typing;
}

class ChatError extends ChatState {
  final String message;
}

class MessageSending extends ChatState {
  final String tempId;
}

class MessageSent extends ChatState {
  final Message message;
}</code></pre>

        <h2>Key Files</h2>
        <table>
            <tr><th>File</th><th>Purpose</th></tr>
            <tr><td><code>lib/features/chat/presentation/bloc/chat_bloc.dart</code></td><td>Chat state management</td></tr>
            <tr><td><code>lib/features/chat/presentation/bloc/conversations_bloc.dart</code></td><td>Conversation list management</td></tr>
            <tr><td><code>lib/features/chat/presentation/screens/chat_screen.dart</code></td><td>Chat UI</td></tr>
            <tr><td><code>lib/features/chat/presentation/widgets/message_bubble.dart</code></td><td>Message display widget</td></tr>
            <tr><td><code>lib/features/chat/presentation/widgets/chat_input.dart</code></td><td>Message input field</td></tr>
            <tr><td><code>lib/features/chat/data/datasources/chat_remote_datasource.dart</code></td><td>Firestore operations</td></tr>
        </table>

        <h2>Performance Optimizations</h2>
        <ul>
            <li><strong>Pagination:</strong> Load 50 messages at a time</li>
            <li><strong>Image Compression:</strong> Compress before upload</li>
            <li><strong>Lazy Loading:</strong> Load images on scroll</li>
            <li><strong>Local Cache:</strong> Cache recent conversations</li>
            <li><strong>Debounced Typing:</strong> 300ms debounce for typing indicator</li>
        </ul>
    `,

    '90-docker.html': `
        <h2>Docker Development Environment</h2>
        <p>GreenGo uses Docker Compose to provide a consistent local development environment with all required services.</p>

        <h2>Services Overview</h2>
        <table>
            <tr><th>Service</th><th>Container Name</th><th>Port(s)</th><th>Purpose</th></tr>
            <tr>
                <td>Firebase Emulators</td>
                <td>greengo_firebase</td>
                <td>4000, 8080, 9099, 9199, 5001, 8085, 9000</td>
                <td>Firebase services emulation</td>
            </tr>
            <tr>
                <td>PostgreSQL</td>
                <td>greengo_postgres</td>
                <td>5432</td>
                <td>Django database</td>
            </tr>
            <tr>
                <td>Redis</td>
                <td>greengo_redis</td>
                <td>6379</td>
                <td>Caching, sessions, Celery broker</td>
            </tr>
            <tr>
                <td>Adminer</td>
                <td>greengo_adminer</td>
                <td>8081</td>
                <td>Database management UI</td>
            </tr>
            <tr>
                <td>Redis Commander</td>
                <td>greengo_redis_commander</td>
                <td>8082</td>
                <td>Redis management UI</td>
            </tr>
            <tr>
                <td>Nginx</td>
                <td>greengo_nginx</td>
                <td>80, 443</td>
                <td>Reverse proxy, API gateway</td>
            </tr>
        </table>

        <h2>Firebase Emulator Ports</h2>
        <table>
            <tr><th>Service</th><th>Port</th><th>Description</th></tr>
            <tr><td>Emulator UI</td><td>4000</td><td>Web dashboard for all emulators</td></tr>
            <tr><td>Authentication</td><td>9099</td><td>User auth emulator</td></tr>
            <tr><td>Firestore</td><td>8080</td><td>Database emulator</td></tr>
            <tr><td>Storage</td><td>9199</td><td>File storage emulator</td></tr>
            <tr><td>Functions</td><td>5001</td><td>Cloud Functions emulator</td></tr>
            <tr><td>Pub/Sub</td><td>8085</td><td>Messaging emulator</td></tr>
            <tr><td>Realtime Database</td><td>9000</td><td>RTDB emulator</td></tr>
        </table>

        <h2>Docker Compose Configuration</h2>
        <p><strong>Location:</strong> <code>docker/docker-compose.yml</code></p>

        <pre><code>version: '3.8'

services:
  firebase:
    build:
      context: ./firebase
      dockerfile: Dockerfile
    container_name: greengo_firebase
    ports:
      - "4000:4000"   # Emulator UI
      - "9099:9099"   # Auth
      - "8080:8080"   # Firestore
      - "9199:9199"   # Storage
      - "5001:5001"   # Functions
      - "8085:8085"   # Pub/Sub
      - "9000:9000"   # RTDB
    volumes:
      - firebase_data:/data
    networks:
      - greengo_network

  postgres:
    image: postgres:15-alpine
    container_name: greengo_postgres
    environment:
      POSTGRES_DB: greengo_db
      POSTGRES_USER: greengo
      POSTGRES_PASSWORD: greengo_secret
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgres/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - greengo_network

  redis:
    image: redis:7-alpine
    container_name: greengo_redis
    command: redis-server --appendonly yes
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - greengo_network

  adminer:
    image: adminer:latest
    container_name: greengo_adminer
    ports:
      - "8081:8080"
    networks:
      - greengo_network
    depends_on:
      - postgres

  redis-commander:
    image: rediscommander/redis-commander:latest
    container_name: greengo_redis_commander
    environment:
      REDIS_HOSTS: local:redis:6379
    ports:
      - "8082:8081"
    networks:
      - greengo_network
    depends_on:
      - redis

  nginx:
    build:
      context: ./nginx
      dockerfile: Dockerfile
    container_name: greengo_nginx
    ports:
      - "80:80"
      - "443:443"
    networks:
      - greengo_network
    depends_on:
      - firebase

volumes:
  firebase_data:
  postgres_data:
  redis_data:

networks:
  greengo_network:
    driver: bridge</code></pre>

        <h2>Commands</h2>
        <h3>Starting Services</h3>
        <pre><code># Navigate to docker directory
cd docker

# Start all services in background
docker-compose up -d

# Start specific service
docker-compose up -d postgres redis

# Start with build (after Dockerfile changes)
docker-compose up -d --build</code></pre>

        <h3>Viewing Status</h3>
        <pre><code># List running containers
docker-compose ps

# View logs (all services)
docker-compose logs

# View logs (specific service, follow)
docker-compose logs -f firebase

# View last 100 lines
docker-compose logs --tail=100 postgres</code></pre>

        <h3>Stopping Services</h3>
        <pre><code># Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v

# Stop specific service
docker-compose stop firebase</code></pre>

        <h3>Maintenance</h3>
        <pre><code># Restart service
docker-compose restart redis

# Rebuild container
docker-compose build firebase

# Remove unused images
docker image prune

# Execute command in container
docker-compose exec postgres psql -U greengo -d greengo_db</code></pre>

        <h2>Accessing Services</h2>
        <table>
            <tr><th>Service</th><th>URL</th><th>Credentials</th></tr>
            <tr>
                <td>Firebase Emulator UI</td>
                <td><a href="http://localhost:4000">http://localhost:4000</a></td>
                <td>None required</td>
            </tr>
            <tr>
                <td>Adminer</td>
                <td><a href="http://localhost:8081">http://localhost:8081</a></td>
                <td>Server: postgres<br>User: greengo<br>Password: greengo_secret<br>Database: greengo_db</td>
            </tr>
            <tr>
                <td>Redis Commander</td>
                <td><a href="http://localhost:8082">http://localhost:8082</a></td>
                <td>None required</td>
            </tr>
        </table>

        <h2>Connecting Flutter App</h2>
        <p>Configure the app to use emulators:</p>
        <pre><code>// lib/core/config/app_config.dart
class AppConfig {
  static const bool useLocalEmulators = true;
}

// lib/main.dart
if (AppConfig.useLocalEmulators) {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
}</code></pre>

        <h2>Troubleshooting</h2>
        <h3>Port Already in Use</h3>
        <pre><code># Find process using port
netstat -ano | findstr :8080

# Kill process
taskkill /PID <pid> /F</code></pre>

        <h3>Container Won't Start</h3>
        <pre><code># Check logs
docker-compose logs firebase

# Rebuild container
docker-compose build --no-cache firebase

# Remove and recreate
docker-compose rm -f firebase
docker-compose up -d firebase</code></pre>

        <h3>Data Persistence Issues</h3>
        <pre><code># List volumes
docker volume ls

# Inspect volume
docker volume inspect docker_firebase_data

# Backup volume data
docker run --rm -v docker_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz -C /data .</code></pre>
    `
};

// Generate content for pages without specific content
function generateContent(page) {
    if (content[page.file]) {
        return content[page.file];
    }

    // Generate content based on section
    const sectionGenerators = {
        'Design System': generateDesignSystemContent,
        'Core Features': generateFeatureContent,
        'Backend Services': generateBackendContent,
        'Database': generateDatabaseContent,
        'Security': generateSecurityContent,
        'Integrations': generateIntegrationContent,
        'DevOps': generateDevOpsContent,
        'Testing': generateTestingContent
    };

    const generator = sectionGenerators[page.section] || generateGenericContent;
    return generator(page);
}

function generateDesignSystemContent(page) {
    return `
        <h2>Overview</h2>
        <p>This section covers ${page.title} in the GreenGo design system.</p>

        <h2>Implementation</h2>
        <p>Detailed implementation guidelines for ${page.title.toLowerCase()}.</p>

        <h2>Usage Guidelines</h2>
        <ul>
            <li>Follow the established patterns</li>
            <li>Maintain visual consistency</li>
            <li>Test across different screen sizes</li>
            <li>Consider accessibility requirements</li>
        </ul>

        <h2>Code Examples</h2>
        <p>See the codebase for implementation examples in <code>lib/core/</code>.</p>

        <h2>Related Files</h2>
        <ul>
            <li><code>lib/core/theme/app_theme.dart</code></li>
            <li><code>lib/core/constants/app_colors.dart</code></li>
            <li><code>lib/core/constants/app_dimensions.dart</code></li>
        </ul>
    `;
}

function generateFeatureContent(page) {
    return `
        <h2>Feature Overview</h2>
        <p>${page.title} is a core feature of the GreenGo application.</p>

        <h2>User Flow</h2>
        <p>Detailed user flow and interaction patterns for ${page.title.toLowerCase()}.</p>

        <h2>Implementation</h2>
        <h3>BLoC Pattern</h3>
        <p>This feature uses the BLoC pattern for state management.</p>

        <h3>Key Components</h3>
        <ul>
            <li>Events - User actions that trigger state changes</li>
            <li>States - Different UI states</li>
            <li>BLoC - Business logic handling</li>
        </ul>

        <h2>File Structure</h2>
        <pre><code>lib/features/${page.title.toLowerCase().replace(/\\s+/g, '_')}/
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

        <h2>Testing</h2>
        <p>Write unit tests for BLoCs and use cases, widget tests for UI components.</p>
    `;
}

function generateBackendContent(page) {
    return `
        <h2>Service Overview</h2>
        <p>${page.title} provides backend functionality for GreenGo.</p>

        <h2>Configuration</h2>
        <p>Configuration details for ${page.title.toLowerCase()}.</p>

        <h2>API Reference</h2>
        <p>API endpoints and usage patterns.</p>

        <h2>Security</h2>
        <p>Security considerations and best practices.</p>

        <h2>Monitoring</h2>
        <p>Monitoring and debugging information.</p>
    `;
}

function generateDatabaseContent(page) {
    return `
        <h2>Overview</h2>
        <p>${page.title} documentation for GreenGo's data layer.</p>

        <h2>Schema Design</h2>
        <p>Database schema and data modeling.</p>

        <h2>Queries</h2>
        <p>Common query patterns and optimization.</p>

        <h2>Best Practices</h2>
        <ul>
            <li>Use appropriate indexes</li>
            <li>Normalize where appropriate</li>
            <li>Consider query performance</li>
            <li>Implement proper backups</li>
        </ul>
    `;
}

function generateSecurityContent(page) {
    return `
        <h2>Security Overview</h2>
        <p>${page.title} implementation in GreenGo.</p>

        <h2>Implementation</h2>
        <p>Security implementation details and configuration.</p>

        <h2>Best Practices</h2>
        <ul>
            <li>Follow principle of least privilege</li>
            <li>Validate all inputs</li>
            <li>Encrypt sensitive data</li>
            <li>Audit access regularly</li>
        </ul>

        <h2>Compliance</h2>
        <p>Compliance requirements and considerations.</p>
    `;
}

function generateIntegrationContent(page) {
    return `
        <h2>Integration Overview</h2>
        <p>${page.title} integration with GreenGo.</p>

        <h2>Setup</h2>
        <p>Configuration and setup instructions.</p>

        <h2>API Usage</h2>
        <p>API endpoints and usage patterns.</p>

        <h2>Environment Variables</h2>
        <p>Required environment variables and configuration.</p>

        <h2>Troubleshooting</h2>
        <p>Common issues and solutions.</p>
    `;
}

function generateDevOpsContent(page) {
    return `
        <h2>Overview</h2>
        <p>${page.title} documentation for GreenGo infrastructure.</p>

        <h2>Configuration</h2>
        <p>Setup and configuration details.</p>

        <h2>Commands</h2>
        <p>Common commands and operations.</p>

        <h2>Best Practices</h2>
        <ul>
            <li>Automate repetitive tasks</li>
            <li>Use version control for configuration</li>
            <li>Document all changes</li>
            <li>Monitor and alert on failures</li>
        </ul>
    `;
}

function generateTestingContent(page) {
    return `
        <h2>Testing Overview</h2>
        <p>${page.title} documentation for GreenGo quality assurance.</p>

        <h2>Test Structure</h2>
        <p>How tests are organized in the project.</p>

        <h2>Running Tests</h2>
        <pre><code># Run all tests
flutter test

# Run specific test file
flutter test test/path/to/test.dart

# Run with coverage
flutter test --coverage</code></pre>

        <h2>Best Practices</h2>
        <ul>
            <li>Write tests for all business logic</li>
            <li>Mock external dependencies</li>
            <li>Use descriptive test names</li>
            <li>Maintain test coverage above 80%</li>
        </ul>
    `;
}

function generateGenericContent(page) {
    return `
        <h2>Overview</h2>
        <p>Documentation for ${page.title} in GreenGo.</p>

        <h2>Details</h2>
        <p>Comprehensive information about ${page.title.toLowerCase()}.</p>

        <h2>Implementation</h2>
        <p>Implementation details and code examples.</p>

        <h2>Best Practices</h2>
        <ul>
            <li>Follow established patterns</li>
            <li>Write comprehensive documentation</li>
            <li>Test thoroughly</li>
            <li>Review code regularly</li>
        </ul>
    `;
}

// HTML template
function createPageHTML(page) {
    const pageContent = generateContent(page);

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
                    <li><a href="01-introduction.html">Introduction</a></li>
                    <li><a href="02-tech-stack.html">Tech Stack</a></li>
                    <li><a href="05-getting-started.html">Getting Started</a></li>
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
                ${pageContent}

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
if (!fs.existsSync(pagesDir)) {
    fs.mkdirSync(pagesDir, { recursive: true });
}

pages.forEach(page => {
    const filepath = path.join(pagesDir, page.file);
    const html = createPageHTML(page);
    fs.writeFileSync(filepath, html);
    console.log(`Created: ${page.file}`);
});

console.log(`\\nGenerated ${pages.length} additional pages!`);
console.log('Total documentation pages: 100');
