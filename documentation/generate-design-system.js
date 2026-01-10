const fs = require('fs');
const path = require('path');

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
                    <li><a href="37-matching-algorithm.html">37. Matching</a></li>
                    <li><a href="41-chat.html">41. Chat</a></li>
                    <li><a href="45-subscriptions.html">45. Subscriptions</a></li>
                    <li><a href="48-gamification.html">48. Gamification</a></li>
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
                <div class="nav-section-title"><i class="fas fa-database"></i><span>Database</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="61-firestore-schema.html">61. Schema</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-shield-alt"></i><span>Security</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="69-security-architecture.html">69. Architecture</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-cogs"></i><span>DevOps</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="90-docker.html">90. Docker</a></li>
                    <li><a href="91-cicd.html">91. CI/CD</a></li>
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

const designSystemPages = [
    {
        file: '21-brand-guidelines.html',
        title: 'Brand Guidelines',
        section: 'Design System',
        content: `
            <h2>GreenGo Brand Identity</h2>
            <p>Comprehensive brand guidelines establishing GreenGo's visual identity, voice, and design principles.</p>

            <h2>Brand Overview</h2>
            <div class="info-box">
                <strong>Brand Name:</strong> GreenGo<br>
                <strong>Tagline:</strong> "Where Meaningful Connections Grow"<br>
                <strong>Brand Personality:</strong> Premium, Trustworthy, Sophisticated, Warm
            </div>

            <h2>Logo Specifications</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                         LOGO ANATOMY                                     │
└─────────────────────────────────────────────────────────────────────────┘

    Primary Logo:
    ┌─────────────────────────────────────┐
    │                                     │
    │     🌿  GreenGo                     │
    │    Icon  Wordmark                   │
    │                                     │
    └─────────────────────────────────────┘

    Minimum Sizes:
    • Digital: 32px height minimum
    • Print: 12mm height minimum

    Clear Space:
    • Minimum padding = Height of "G" character
    • No other elements within clear space zone

    Logo Variants:
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │   Primary    │  │   Light      │  │    Icon      │
    │  Gold/Black  │  │   White      │  │    Only      │
    │  (default)   │  │  (dark bg)   │  │  (app icon)  │
    └──────────────┘  └──────────────┘  └──────────────┘
            </code></pre>

            <h2>Brand Colors</h2>
            <table>
                <thead>
                    <tr><th>Color</th><th>Hex</th><th>RGB</th><th>Usage</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Rich Gold</strong></td>
                        <td>#D4AF37</td>
                        <td>212, 175, 55</td>
                        <td>Primary brand, CTAs, highlights</td>
                    </tr>
                    <tr>
                        <td><strong>Deep Black</strong></td>
                        <td>#0A0A0A</td>
                        <td>10, 10, 10</td>
                        <td>Primary backgrounds</td>
                    </tr>
                    <tr>
                        <td><strong>Charcoal</strong></td>
                        <td>#1A1A1A</td>
                        <td>26, 26, 26</td>
                        <td>Cards, elevated surfaces</td>
                    </tr>
                    <tr>
                        <td><strong>Pure White</strong></td>
                        <td>#FFFFFF</td>
                        <td>255, 255, 255</td>
                        <td>Primary text, icons</td>
                    </tr>
                </tbody>
            </table>

            <h2>Brand Voice & Tone</h2>
            <table>
                <thead>
                    <tr><th>Attribute</th><th>Description</th><th>Example</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Confident</strong></td>
                        <td>Assured but not arrogant</td>
                        <td>"Find your perfect match" not "Maybe find someone"</td>
                    </tr>
                    <tr>
                        <td><strong>Warm</strong></td>
                        <td>Friendly and approachable</td>
                        <td>"Welcome back!" not "User authenticated"</td>
                    </tr>
                    <tr>
                        <td><strong>Clear</strong></td>
                        <td>Simple, direct communication</td>
                        <td>"Upload a photo" not "Add visual media content"</td>
                    </tr>
                    <tr>
                        <td><strong>Encouraging</strong></td>
                        <td>Supportive and positive</td>
                        <td>"Great choice!" not "Selection confirmed"</td>
                    </tr>
                </tbody>
            </table>

            <h2>Design Principles</h2>
            <ol>
                <li><strong>Premium Feel:</strong> Every interaction should feel luxurious and refined</li>
                <li><strong>Clarity First:</strong> Function over decoration, clear visual hierarchy</li>
                <li><strong>Consistent Experience:</strong> Unified patterns across all touchpoints</li>
                <li><strong>Accessible to All:</strong> Inclusive design for all users</li>
                <li><strong>Delightful Details:</strong> Micro-interactions that surprise and delight</li>
            </ol>

            <h2>Do's and Don'ts</h2>
            <table>
                <thead>
                    <tr><th>Do</th><th>Don't</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Use gold as accent color</td>
                        <td>Use gold for large background areas</td>
                    </tr>
                    <tr>
                        <td>Maintain contrast ratios</td>
                        <td>Use light gray text on dark backgrounds</td>
                    </tr>
                    <tr>
                        <td>Keep logo proportions</td>
                        <td>Stretch, rotate, or modify the logo</td>
                    </tr>
                    <tr>
                        <td>Use approved fonts</td>
                        <td>Substitute with similar fonts</td>
                    </tr>
                </tbody>
            </table>
        `
    },
    {
        file: '22-color-palette.html',
        title: 'Color Palette',
        section: 'Design System',
        content: `
            <h2>Color System</h2>
            <p>Complete color palette with semantic colors, gradients, and usage guidelines for consistent visual design.</p>

            <h2>Primary Colors</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                        PRIMARY COLOR PALETTE                             │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   RICH GOLD     │  │   DEEP BLACK    │  │   CHARCOAL      │
│   #D4AF37       │  │   #0A0A0A       │  │   #1A1A1A       │
│                 │  │                 │  │                 │
│   Primary       │  │   Background    │  │   Surface       │
│   Accent        │  │   Primary       │  │   Cards         │
└─────────────────┘  └─────────────────┘  └─────────────────┘

Gold Variations:
┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│  50     │ │  100    │ │  500    │ │  700    │ │  900    │
│#FFF9E6  │ │#FFEEB3  │ │#D4AF37  │ │#B8962E  │ │#8C7223  │
│ Light   │ │         │ │ Default │ │ Pressed │ │ Dark    │
└─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘
            </code></pre>

            <h2>Semantic Colors</h2>
            <table>
                <thead>
                    <tr><th>Name</th><th>Hex</th><th>Usage</th><th>Example</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Success</strong></td>
                        <td>#4CAF50</td>
                        <td>Positive actions, confirmations</td>
                        <td>Match found, message sent</td>
                    </tr>
                    <tr>
                        <td><strong>Warning</strong></td>
                        <td>#FF9800</td>
                        <td>Caution, attention needed</td>
                        <td>Profile incomplete, low coins</td>
                    </tr>
                    <tr>
                        <td><strong>Error</strong></td>
                        <td>#F44336</td>
                        <td>Errors, destructive actions</td>
                        <td>Failed upload, unmatch action</td>
                    </tr>
                    <tr>
                        <td><strong>Info</strong></td>
                        <td>#2196F3</td>
                        <td>Informational messages</td>
                        <td>Tips, hints, updates</td>
                    </tr>
                </tbody>
            </table>

            <h2>Neutral Colors</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                        NEUTRAL GRAYSCALE                                 │
└─────────────────────────────────────────────────────────────────────────┘

 Gray 50    Gray 100   Gray 200   Gray 300   Gray 400   Gray 500
 #FAFAFA    #F5F5F5    #EEEEEE    #E0E0E0    #BDBDBD    #9E9E9E
 ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐
 │       │  │       │  │       │  │       │  │       │  │       │
 └───────┘  └───────┘  └───────┘  └───────┘  └───────┘  └───────┘

 Gray 600   Gray 700   Gray 800   Gray 900   Black
 #757575    #616161    #424242    #212121    #000000
 ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐
 │       │  │       │  │       │  │       │  │       │
 └───────┘  └───────┘  └───────┘  └───────┘  └───────┘
            </code></pre>

            <h2>Gradients</h2>
            <pre><code class="language-dart">
// lib/core/theme/gradients.dart

class AppGradients {
  // Primary gold gradient for buttons and highlights
  static const primaryGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD4AF37),  // Rich Gold
      Color(0xFFB8962E),  // Dark Gold
    ],
  );

  // Premium gradient for special elements
  static const premiumShine = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF9E6),  // Light Gold
      Color(0xFFD4AF37),  // Rich Gold
      Color(0xFF8C7223),  // Dark Gold
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Background gradient
  static const darkBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1A1A),  // Charcoal
      Color(0xFF0A0A0A),  // Deep Black
    ],
  );

  // Match card gradient overlay
  static const cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Colors.black.withOpacity(0.7),
    ],
  );
}
            </code></pre>

            <h2>Color Usage in Flutter</h2>
            <pre><code class="language-dart">
// lib/core/theme/app_colors.dart

class AppColors {
  // Primary
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFFFF9E6);
  static const goldDark = Color(0xFF8C7223);

  // Background
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceLight = Color(0xFF2A2A2A);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB3B3B3);
  static const textTertiary = Color(0xFF808080);

  // Semantic
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF2196F3);

  // Special
  static const superLike = Color(0xFF2196F3);
  static const boost = Color(0xFF9C27B0);
  static const verified = Color(0xFF4CAF50);

  // Opacity variants
  static Color goldWithOpacity(double opacity) => gold.withOpacity(opacity);
  static Color surfaceWithOpacity(double opacity) => surface.withOpacity(opacity);
}
            </code></pre>

            <h2>Contrast Requirements</h2>
            <table>
                <thead>
                    <tr><th>Combination</th><th>Ratio</th><th>WCAG Level</th><th>Usage</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td>White on Black (#0A0A0A)</td>
                        <td>19.4:1</td>
                        <td>AAA</td>
                        <td>Body text</td>
                    </tr>
                    <tr>
                        <td>Gold on Black (#0A0A0A)</td>
                        <td>8.2:1</td>
                        <td>AAA</td>
                        <td>Headings, buttons</td>
                    </tr>
                    <tr>
                        <td>White on Gold (#D4AF37)</td>
                        <td>2.4:1</td>
                        <td>Fail</td>
                        <td>Avoid - use black text</td>
                    </tr>
                    <tr>
                        <td>Black on Gold (#D4AF37)</td>
                        <td>8.2:1</td>
                        <td>AAA</td>
                        <td>Button text</td>
                    </tr>
                </tbody>
            </table>
        `
    },
    {
        file: '23-typography.html',
        title: 'Typography System',
        section: 'Design System',
        content: `
            <h2>Typography System</h2>
            <p>Complete type scale, font families, and text styles for consistent typography across the application.</p>

            <h2>Font Families</h2>
            <div class="info-box">
                <strong>Primary Font:</strong> Poppins (Google Fonts)<br>
                <strong>Fallback:</strong> SF Pro Display (iOS), Roboto (Android)<br>
                <strong>Monospace:</strong> SF Mono, Roboto Mono
            </div>

            <h2>Type Scale</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                           TYPE SCALE                                     │
└─────────────────────────────────────────────────────────────────────────┘

Style           Size    Weight    Line Height    Letter Spacing
─────────────────────────────────────────────────────────────────
Display Large   57px    400       64px           -0.25px
Display Medium  45px    400       52px           0px
Display Small   36px    400       44px           0px

Headline Large  32px    600       40px           0px
Headline Medium 28px    600       36px           0px
Headline Small  24px    600       32px           0px

Title Large     22px    500       28px           0px
Title Medium    16px    500       24px           0.15px
Title Small     14px    500       20px           0.1px

Body Large      16px    400       24px           0.5px
Body Medium     14px    400       20px           0.25px
Body Small      12px    400       16px           0.4px

Label Large     14px    500       20px           0.1px
Label Medium    12px    500       16px           0.5px
Label Small     11px    500       16px           0.5px
            </code></pre>

            <h2>Flutter Text Theme</h2>
            <pre><code class="language-dart">
// lib/core/theme/text_theme.dart

class AppTextTheme {
  static const String fontFamily = 'Poppins';

  static TextTheme get textTheme => const TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 57,
      fontWeight: FontWeight.w400,
      height: 1.12,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 45,
      fontWeight: FontWeight.w400,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 36,
      fontWeight: FontWeight.w400,
      height: 1.22,
    ),

    // Headline
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.33,
    ),

    // Title
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w500,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
      letterSpacing: 0.1,
    ),

    // Body
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.4,
    ),

    // Label
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.45,
      letterSpacing: 0.5,
    ),
  );
}
            </code></pre>

            <h2>Usage Examples</h2>
            <table>
                <thead>
                    <tr><th>Style</th><th>Use Case</th><th>Example</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>headlineLarge</strong></td>
                        <td>Page titles</td>
                        <td>"Discover", "Messages"</td>
                    </tr>
                    <tr>
                        <td><strong>headlineMedium</strong></td>
                        <td>Section headers</td>
                        <td>"New Matches", "Settings"</td>
                    </tr>
                    <tr>
                        <td><strong>titleLarge</strong></td>
                        <td>Card titles</td>
                        <td>User names on cards</td>
                    </tr>
                    <tr>
                        <td><strong>bodyLarge</strong></td>
                        <td>Primary body text</td>
                        <td>User bios, descriptions</td>
                    </tr>
                    <tr>
                        <td><strong>bodyMedium</strong></td>
                        <td>Secondary text</td>
                        <td>Chat messages</td>
                    </tr>
                    <tr>
                        <td><strong>labelLarge</strong></td>
                        <td>Button labels</td>
                        <td>"Sign In", "Send"</td>
                    </tr>
                    <tr>
                        <td><strong>labelSmall</strong></td>
                        <td>Metadata</td>
                        <td>Timestamps, distances</td>
                    </tr>
                </tbody>
            </table>

            <h2>Font Weight Reference</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                        FONT WEIGHTS                                      │
└─────────────────────────────────────────────────────────────────────────┘

Weight    Value    Usage
──────────────────────────────────────────
Light     300      Subtle text, large displays
Regular   400      Body text, descriptions
Medium    500      Titles, emphasized text
SemiBold  600      Headlines, important labels
Bold      700      Strong emphasis (use sparingly)
            </code></pre>
        `
    },
    {
        file: '24-spacing.html',
        title: 'Spacing & Dimensions',
        section: 'Design System',
        content: `
            <h2>Spacing System</h2>
            <p>Consistent spacing scale and dimension guidelines for layout, padding, and margins.</p>

            <h2>Spacing Scale</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                        SPACING SCALE (8px base)                          │
└─────────────────────────────────────────────────────────────────────────┘

Token      Value    Visual
─────────────────────────────────────────────────────────
space-0    0px
space-1    4px      ▌
space-2    8px      █
space-3    12px     █▌
space-4    16px     ██
space-5    20px     ██▌
space-6    24px     ███
space-7    32px     ████
space-8    40px     █████
space-9    48px     ██████
space-10   64px     ████████
space-11   80px     ██████████
space-12   96px     ████████████
            </code></pre>

            <h2>Flutter Spacing Constants</h2>
            <pre><code class="language-dart">
// lib/core/theme/spacing.dart

class AppSpacing {
  // Base unit
  static const double unit = 8.0;

  // Spacing scale
  static const double space0 = 0;
  static const double space1 = 4;    // 0.5x
  static const double space2 = 8;    // 1x
  static const double space3 = 12;   // 1.5x
  static const double space4 = 16;   // 2x
  static const double space5 = 20;   // 2.5x
  static const double space6 = 24;   // 3x
  static const double space7 = 32;   // 4x
  static const double space8 = 40;   // 5x
  static const double space9 = 48;   // 6x
  static const double space10 = 64;  // 8x
  static const double space11 = 80;  // 10x
  static const double space12 = 96;  // 12x

  // Semantic spacing
  static const double screenPadding = 16;
  static const double cardPadding = 16;
  static const double listItemSpacing = 12;
  static const double sectionSpacing = 24;
  static const double componentGap = 8;

  // Edge insets helpers
  static const EdgeInsets screenInsets = EdgeInsets.all(16);
  static const EdgeInsets cardInsets = EdgeInsets.all(16);
  static const EdgeInsets listInsets = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );
}
            </code></pre>

            <h2>Component Dimensions</h2>
            <table>
                <thead>
                    <tr><th>Component</th><th>Height</th><th>Padding</th><th>Border Radius</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Button (Large)</strong></td>
                        <td>56px</td>
                        <td>24px horizontal</td>
                        <td>28px</td>
                    </tr>
                    <tr>
                        <td><strong>Button (Medium)</strong></td>
                        <td>48px</td>
                        <td>20px horizontal</td>
                        <td>24px</td>
                    </tr>
                    <tr>
                        <td><strong>Button (Small)</strong></td>
                        <td>36px</td>
                        <td>16px horizontal</td>
                        <td>18px</td>
                    </tr>
                    <tr>
                        <td><strong>Input Field</strong></td>
                        <td>56px</td>
                        <td>16px</td>
                        <td>12px</td>
                    </tr>
                    <tr>
                        <td><strong>Card</strong></td>
                        <td>Auto</td>
                        <td>16px</td>
                        <td>16px</td>
                    </tr>
                    <tr>
                        <td><strong>Avatar (Small)</strong></td>
                        <td>32px</td>
                        <td>-</td>
                        <td>16px (circle)</td>
                    </tr>
                    <tr>
                        <td><strong>Avatar (Medium)</strong></td>
                        <td>48px</td>
                        <td>-</td>
                        <td>24px (circle)</td>
                    </tr>
                    <tr>
                        <td><strong>Avatar (Large)</strong></td>
                        <td>64px</td>
                        <td>-</td>
                        <td>32px (circle)</td>
                    </tr>
                    <tr>
                        <td><strong>Bottom Nav</strong></td>
                        <td>80px</td>
                        <td>-</td>
                        <td>-</td>
                    </tr>
                    <tr>
                        <td><strong>App Bar</strong></td>
                        <td>56px</td>
                        <td>16px horizontal</td>
                        <td>-</td>
                    </tr>
                </tbody>
            </table>

            <h2>Border Radius Scale</h2>
            <pre><code class="language-dart">
// lib/core/theme/radius.dart

class AppRadius {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 999;

  // BorderRadius helpers
  static const BorderRadius small = BorderRadius.all(Radius.circular(8));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(12));
  static const BorderRadius large = BorderRadius.all(Radius.circular(16));
  static const BorderRadius extraLarge = BorderRadius.all(Radius.circular(24));
  static const BorderRadius circular = BorderRadius.all(Radius.circular(999));
}
            </code></pre>

            <h2>Layout Grid</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                           LAYOUT GRID                                    │
└─────────────────────────────────────────────────────────────────────────┘

Mobile Layout (< 600px):
┌─────────────────────────────────────┐
│← 16px →┌───────────────┐← 16px →│
│        │               │          │
│        │   Content     │          │
│        │               │          │
│        └───────────────┘          │
└─────────────────────────────────────┘

Tablet Layout (600px - 960px):
┌─────────────────────────────────────────────────┐
│← 24px →┌─────────────────────────┐← 24px →│
│        │                         │          │
│        │        Content          │          │
│        │    (max-width: 720px)   │          │
│        │                         │          │
│        └─────────────────────────┘          │
└─────────────────────────────────────────────────┘
            </code></pre>
        `
    },
    {
        file: '25-components.html',
        title: 'Component Library',
        section: 'Design System',
        content: `
            <h2>Component Library</h2>
            <p>Reusable UI components with consistent styling and behavior across the application.</p>

            <h2>Component Architecture</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                      COMPONENT HIERARCHY                                 │
└─────────────────────────────────────────────────────────────────────────┘

lib/core/presentation/widgets/
├── buttons/
│   ├── primary_button.dart
│   ├── secondary_button.dart
│   ├── icon_button.dart
│   └── text_button.dart
├── inputs/
│   ├── text_field.dart
│   ├── password_field.dart
│   ├── search_field.dart
│   └── dropdown_field.dart
├── cards/
│   ├── profile_card.dart
│   ├── match_card.dart
│   └── message_card.dart
├── avatars/
│   ├── user_avatar.dart
│   └── avatar_group.dart
├── badges/
│   ├── notification_badge.dart
│   ├── subscription_badge.dart
│   └── verification_badge.dart
├── dialogs/
│   ├── confirmation_dialog.dart
│   ├── action_sheet.dart
│   └── bottom_sheet.dart
└── feedback/
    ├── loading_indicator.dart
    ├── empty_state.dart
    ├── error_state.dart
    └── snackbar.dart
            </code></pre>

            <h2>Button Components</h2>
            <pre><code class="language-dart">
// lib/core/presentation/widgets/buttons/primary_button.dart

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;

  const PrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isExpanded ? double.infinity : null,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Secondary Button
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryButton({
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: BorderSide(color: AppColors.gold, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
            </code></pre>

            <h2>Input Components</h2>
            <pre><code class="language-dart">
// lib/core/presentation/widgets/inputs/app_text_field.dart

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int maxLines;

  const AppTextField({
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textTertiary),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textSecondary)
                : null,
            suffix: suffix,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
            </code></pre>

            <h2>Component States</h2>
            <table>
                <thead>
                    <tr><th>Component</th><th>States</th><th>Visual Change</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Button</strong></td>
                        <td>Default, Hover, Pressed, Disabled, Loading</td>
                        <td>Color opacity, scale, spinner</td>
                    </tr>
                    <tr>
                        <td><strong>TextField</strong></td>
                        <td>Default, Focused, Error, Disabled</td>
                        <td>Border color, fill color</td>
                    </tr>
                    <tr>
                        <td><strong>Card</strong></td>
                        <td>Default, Pressed, Selected</td>
                        <td>Elevation, border</td>
                    </tr>
                    <tr>
                        <td><strong>Checkbox</strong></td>
                        <td>Unchecked, Checked, Indeterminate</td>
                        <td>Fill, checkmark</td>
                    </tr>
                </tbody>
            </table>
        `
    },
    {
        file: '26-icons.html',
        title: 'Icon System',
        section: 'Design System',
        content: `
            <h2>Icon System</h2>
            <p>Consistent iconography using Material Icons and custom icons for the GreenGo brand.</p>

            <h2>Icon Sources</h2>
            <div class="info-box">
                <strong>Primary:</strong> Material Icons (filled style)<br>
                <strong>Secondary:</strong> Material Icons Outlined<br>
                <strong>Custom:</strong> SVG icons for brand-specific elements
            </div>

            <h2>Icon Sizes</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                           ICON SIZES                                     │
└─────────────────────────────────────────────────────────────────────────┘

Size      Pixels    Usage
──────────────────────────────────────────────────
XS        16px      Inline with small text, badges
SM        20px      List items, small buttons
MD        24px      Default size, navigation, inputs
LG        32px      Feature icons, empty states
XL        48px      Large features, onboarding
XXL       64px      Hero icons, splash
            </code></pre>

            <h2>Icon Constants</h2>
            <pre><code class="language-dart">
// lib/core/theme/icons.dart

class AppIcons {
  // Navigation
  static const home = Icons.home_rounded;
  static const discover = Icons.explore_rounded;
  static const matches = Icons.favorite_rounded;
  static const messages = Icons.chat_bubble_rounded;
  static const profile = Icons.person_rounded;

  // Actions
  static const like = Icons.favorite_rounded;
  static const pass = Icons.close_rounded;
  static const superLike = Icons.star_rounded;
  static const boost = Icons.bolt_rounded;
  static const rewind = Icons.replay_rounded;

  // Features
  static const camera = Icons.camera_alt_rounded;
  static const gallery = Icons.photo_library_rounded;
  static const send = Icons.send_rounded;
  static const mic = Icons.mic_rounded;
  static const attachment = Icons.attach_file_rounded;

  // User
  static const verified = Icons.verified_rounded;
  static const premium = Icons.workspace_premium_rounded;
  static const settings = Icons.settings_rounded;
  static const edit = Icons.edit_rounded;

  // Status
  static const online = Icons.circle;
  static const typing = Icons.more_horiz_rounded;
  static const read = Icons.done_all_rounded;
  static const delivered = Icons.done_rounded;

  // Misc
  static const location = Icons.location_on_rounded;
  static const filter = Icons.tune_rounded;
  static const search = Icons.search_rounded;
  static const notification = Icons.notifications_rounded;
  static const help = Icons.help_outline_rounded;
  static const info = Icons.info_outline_rounded;
  static const warning = Icons.warning_rounded;
  static const error = Icons.error_rounded;
}

// Icon size constants
class IconSizes {
  static const double xs = 16;
  static const double sm = 20;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
  static const double xxl = 64;
}
            </code></pre>

            <h2>Icon Usage Guidelines</h2>
            <table>
                <thead>
                    <tr><th>Context</th><th>Size</th><th>Style</th><th>Color</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Bottom Navigation</td>
                        <td>24px</td>
                        <td>Filled (active), Outlined (inactive)</td>
                        <td>Gold (active), Gray (inactive)</td>
                    </tr>
                    <tr>
                        <td>App Bar Actions</td>
                        <td>24px</td>
                        <td>Outlined</td>
                        <td>White</td>
                    </tr>
                    <tr>
                        <td>List Item Leading</td>
                        <td>24px</td>
                        <td>Filled</td>
                        <td>Gold or contextual</td>
                    </tr>
                    <tr>
                        <td>Button Icon</td>
                        <td>20px</td>
                        <td>Filled</td>
                        <td>Matches button text</td>
                    </tr>
                    <tr>
                        <td>Input Prefix</td>
                        <td>20px</td>
                        <td>Outlined</td>
                        <td>Text secondary</td>
                    </tr>
                    <tr>
                        <td>Empty State</td>
                        <td>48-64px</td>
                        <td>Outlined</td>
                        <td>Gold with opacity</td>
                    </tr>
                </tbody>
            </table>

            <h2>Custom SVG Icons</h2>
            <pre><code class="language-dart">
// Custom icon widget
class SvgIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;

  const SvgIcon({
    required this.assetPath,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}

// Usage
SvgIcon(
  assetPath: 'assets/icons/super_like.svg',
  size: 32,
  color: AppColors.superLike,
)
            </code></pre>
        `
    },
    {
        file: '27-animations.html',
        title: 'Animation Guidelines',
        section: 'Design System',
        content: `
            <h2>Animation System</h2>
            <p>Motion design guidelines for consistent, performant animations that enhance user experience.</p>

            <h2>Animation Principles</h2>
            <ol>
                <li><strong>Purposeful:</strong> Every animation should serve a function</li>
                <li><strong>Quick:</strong> Animations should feel snappy, not sluggish</li>
                <li><strong>Natural:</strong> Follow physics-based motion curves</li>
                <li><strong>Consistent:</strong> Same actions = same animations</li>
            </ol>

            <h2>Duration Scale</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                        ANIMATION DURATIONS                               │
└─────────────────────────────────────────────────────────────────────────┘

Token          Duration    Usage
──────────────────────────────────────────────────────
instant        100ms       Micro-interactions, ripples
fast           200ms       Button states, toggles
normal         300ms       Page transitions, modals
slow           400ms       Complex transitions
slower         500ms       Elaborate animations
            </code></pre>

            <h2>Flutter Animation Constants</h2>
            <pre><code class="language-dart">
// lib/core/theme/animations.dart

class AppAnimations {
  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 500);

  // Curves
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeInOutQuart;

  // Page transitions
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Curve pageEnterCurve = Curves.easeOutCubic;
  static const Curve pageExitCurve = Curves.easeInCubic;
}
            </code></pre>

            <h2>Common Animation Patterns</h2>
            <pre><code class="language-dart">
// Fade In Animation
class FadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeIn({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
  });

  @override
  _FadeInState createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Scale Animation for buttons
class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ScaleOnTap({required this.child, this.onTap});

  @override
  _ScaleOnTapState createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
            </code></pre>

            <h2>Swipe Card Animation</h2>
            <pre><code class="language-dart">
// Match card swipe animation
class SwipeableCard extends StatefulWidget {
  final Widget child;
  final Function(SwipeDirection) onSwipe;

  @override
  _SwipeableCardState createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragOffset = Offset.zero;
  double _rotation = 0;

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _rotation = _dragOffset.dx / 300 * 0.4; // Max 0.4 radians
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;

    if (_dragOffset.dx.abs() > 100 || velocity.abs() > 500) {
      // Swipe detected
      final direction = _dragOffset.dx > 0
          ? SwipeDirection.right
          : SwipeDirection.left;

      _animateOut(direction).then((_) {
        widget.onSwipe(direction);
      });
    } else {
      // Return to center
      _animateBack();
    }
  }

  Future<void> _animateOut(SwipeDirection direction) async {
    // Animate card off screen
    await _controller.forward();
  }

  void _animateBack() {
    setState(() {
      _dragOffset = Offset.zero;
      _rotation = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: _rotation,
          child: widget.child,
        ),
      ),
    );
  }
}
            </code></pre>

            <h2>Animation Guidelines</h2>
            <table>
                <thead>
                    <tr><th>Interaction</th><th>Duration</th><th>Curve</th><th>Effect</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Button press</td>
                        <td>100ms</td>
                        <td>easeInOut</td>
                        <td>Scale to 0.95</td>
                    </tr>
                    <tr>
                        <td>Page transition</td>
                        <td>300ms</td>
                        <td>easeOutCubic</td>
                        <td>Slide + fade</td>
                    </tr>
                    <tr>
                        <td>Modal appear</td>
                        <td>300ms</td>
                        <td>easeOutCubic</td>
                        <td>Scale from 0.9 + fade</td>
                    </tr>
                    <tr>
                        <td>Swipe card</td>
                        <td>200ms</td>
                        <td>easeOut</td>
                        <td>Translate + rotate</td>
                    </tr>
                    <tr>
                        <td>Like heart</td>
                        <td>400ms</td>
                        <td>elasticOut</td>
                        <td>Scale bounce</td>
                    </tr>
                    <tr>
                        <td>Loading</td>
                        <td>1000ms</td>
                        <td>linear</td>
                        <td>Continuous rotation</td>
                    </tr>
                </tbody>
            </table>
        `
    },
    {
        file: '28-theming.html',
        title: 'Dark/Light Theme',
        section: 'Design System',
        content: `
            <h2>Theme System</h2>
            <p>Complete theme configuration supporting dark mode (primary) with light mode option.</p>

            <div class="info-box">
                <strong>Default Theme:</strong> Dark Mode<br>
                <strong>Secondary:</strong> Light Mode (optional)<br>
                <strong>System:</strong> Follow device settings
            </div>

            <h2>Theme Architecture</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                        THEME ARCHITECTURE                                │
└─────────────────────────────────────────────────────────────────────────┘

                    ┌─────────────────┐
                    │   ThemeMode     │
                    │  dark/light/sys │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
    ┌─────────────────┐ ┌─────────┐ ┌─────────────────┐
    │   Dark Theme    │ │  Light  │ │   System        │
    │   (default)     │ │  Theme  │ │   Theme         │
    └────────┬────────┘ └────┬────┘ └────────┬────────┘
             │               │               │
             └───────────────┼───────────────┘
                             │
                    ┌────────▼────────┐
                    │   ThemeData     │
                    │  colorScheme    │
                    │  textTheme      │
                    │  components     │
                    └─────────────────┘
            </code></pre>

            <h2>Theme Implementation</h2>
            <pre><code class="language-dart">
// lib/core/theme/app_theme.dart

class AppTheme {
  // Dark Theme (Primary)
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    textTheme: AppTextTheme.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        minimumSize: Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        minimumSize: Size(double.infinity, 56),
        side: BorderSide(color: AppColors.gold, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.gold, width: 2),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.surfaceLight,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // Dark Color Scheme
  static const _darkColorScheme = ColorScheme.dark(
    primary: AppColors.gold,
    onPrimary: AppColors.background,
    secondary: AppColors.gold,
    onSecondary: AppColors.background,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    background: AppColors.background,
    onBackground: AppColors.textPrimary,
    error: AppColors.error,
    onError: Colors.white,
  );

  // Light Theme (Secondary)
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
    textTheme: AppTextTheme.textTheme.apply(
      bodyColor: Color(0xFF1A1A1A),
      displayColor: Color(0xFF1A1A1A),
    ),
    scaffoldBackgroundColor: Color(0xFFFAFAFA),
    // ... similar configuration
  );

  static const _lightColorScheme = ColorScheme.light(
    primary: AppColors.goldDark,
    onPrimary: Colors.white,
    secondary: AppColors.goldDark,
    surface: Colors.white,
    onSurface: Color(0xFF1A1A1A),
    background: Color(0xFFFAFAFA),
    error: AppColors.error,
  );
}
            </code></pre>

            <h2>Theme Provider</h2>
            <pre><code class="language-dart">
// lib/core/theme/theme_provider.dart

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemePreference(mode);
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    _saveThemePreference(_themeMode);
    notifyListeners();
  }

  Future<void> _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme_mode') ?? 'dark';
    _themeMode = ThemeMode.values.byName(themeName);
    notifyListeners();
  }
}

// Usage in main.dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: context.watch<ThemeProvider>().themeMode,
  // ...
)
            </code></pre>

            <h2>Color Mapping</h2>
            <table>
                <thead>
                    <tr><th>Element</th><th>Dark Mode</th><th>Light Mode</th></tr>
                </thead>
                <tbody>
                    <tr><td>Background</td><td>#0A0A0A</td><td>#FAFAFA</td></tr>
                    <tr><td>Surface</td><td>#1A1A1A</td><td>#FFFFFF</td></tr>
                    <tr><td>Primary Text</td><td>#FFFFFF</td><td>#1A1A1A</td></tr>
                    <tr><td>Secondary Text</td><td>#B3B3B3</td><td>#666666</td></tr>
                    <tr><td>Accent</td><td>#D4AF37</td><td>#B8962E</td></tr>
                    <tr><td>Divider</td><td>#2A2A2A</td><td>#E0E0E0</td></tr>
                </tbody>
            </table>
        `
    },
    {
        file: '29-responsive.html',
        title: 'Responsive Design',
        section: 'Design System',
        content: `
            <h2>Responsive Design System</h2>
            <p>Adaptive layouts for phone, tablet, and web platforms with consistent user experience.</p>

            <h2>Breakpoints</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                         BREAKPOINTS                                      │
└─────────────────────────────────────────────────────────────────────────┘

Device          Width Range        Layout
────────────────────────────────────────────────────
Phone           0 - 599px          Single column
Tablet          600 - 1023px       Adaptive (1-2 col)
Desktop         1024px+            Multi-column

┌─────────────┐  ┌───────────────────┐  ┌───────────────────────┐
│   Phone     │  │      Tablet       │  │       Desktop         │
│  < 600px    │  │   600 - 1023px    │  │      1024px+          │
│             │  │                   │  │                       │
│ ┌─────────┐ │  │ ┌───────┬───────┐ │  │ ┌─────┬─────┬───────┐│
│ │         │ │  │ │       │       │ │  │ │     │     │       ││
│ │ Content │ │  │ │  Nav  │Content│ │  │ │ Nav │List │Detail ││
│ │         │ │  │ │       │       │ │  │ │     │     │       ││
│ └─────────┘ │  │ └───────┴───────┘ │  │ └─────┴─────┴───────┘│
│  + Bottom   │  │                   │  │                       │
│    Nav      │  │                   │  │                       │
└─────────────┘  └───────────────────┘  └───────────────────────┘
            </code></pre>

            <h2>Responsive Utilities</h2>
            <pre><code class="language-dart">
// lib/core/utils/responsive.dart

class Responsive {
  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static T value<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? phone;
    if (isTablet(context)) return tablet ?? phone;
    return phone;
  }
}

// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget phone;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    required this.phone,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return desktop ?? tablet ?? phone;
    }
    if (Responsive.isTablet(context)) {
      return tablet ?? phone;
    }
    return phone;
  }
}

// Usage
ResponsiveBuilder(
  phone: MobileLayout(),
  tablet: TabletLayout(),
  desktop: DesktopLayout(),
)
            </code></pre>

            <h2>Adaptive Layouts</h2>
            <pre><code class="language-dart">
// Responsive grid
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        double childAspectRatio = 1.0;

        if (constraints.maxWidth >= 1024) {
          crossAxisCount = 4;
          childAspectRatio = 0.75;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 2;
          childAspectRatio = 0.8;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

// Responsive padding
EdgeInsets responsivePadding(BuildContext context) {
  return Responsive.value(
    context,
    phone: EdgeInsets.all(16),
    tablet: EdgeInsets.all(24),
    desktop: EdgeInsets.all(32),
  );
}
            </code></pre>

            <h2>Platform-Specific Adaptations</h2>
            <table>
                <thead>
                    <tr><th>Element</th><th>iOS</th><th>Android</th><th>Web</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Navigation</td>
                        <td>iOS-style tab bar</td>
                        <td>Material bottom nav</td>
                        <td>Side rail / top nav</td>
                    </tr>
                    <tr>
                        <td>Dialogs</td>
                        <td>Cupertino alerts</td>
                        <td>Material dialogs</td>
                        <td>Centered modals</td>
                    </tr>
                    <tr>
                        <td>Date Picker</td>
                        <td>Cupertino picker</td>
                        <td>Material picker</td>
                        <td>Calendar widget</td>
                    </tr>
                    <tr>
                        <td>Scrolling</td>
                        <td>Bouncing physics</td>
                        <td>Clamping physics</td>
                        <td>Browser default</td>
                    </tr>
                </tbody>
            </table>
        `
    },
    {
        file: '30-accessibility.html',
        title: 'Accessibility Guidelines',
        section: 'Design System',
        content: `
            <h2>Accessibility Guidelines</h2>
            <p>Inclusive design guidelines ensuring GreenGo is usable by everyone, following WCAG 2.1 AA standards.</p>

            <h2>Accessibility Principles</h2>
            <ol>
                <li><strong>Perceivable:</strong> Information must be presentable in ways users can perceive</li>
                <li><strong>Operable:</strong> UI components must be operable by all users</li>
                <li><strong>Understandable:</strong> Information and UI must be understandable</li>
                <li><strong>Robust:</strong> Content must be robust enough for assistive technologies</li>
            </ol>

            <h2>Color Contrast Requirements</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                    WCAG CONTRAST REQUIREMENTS                            │
└─────────────────────────────────────────────────────────────────────────┘

Level AA (Minimum):
• Normal text: 4.5:1 contrast ratio
• Large text (18px+ or 14px bold): 3:1 contrast ratio
• UI components: 3:1 contrast ratio

Level AAA (Enhanced):
• Normal text: 7:1 contrast ratio
• Large text: 4.5:1 contrast ratio

GreenGo Compliance:
┌────────────────────────────┬─────────┬──────────┐
│ Combination                │ Ratio   │ Level    │
├────────────────────────────┼─────────┼──────────┤
│ White on #0A0A0A           │ 19.4:1  │ AAA      │
│ Gold (#D4AF37) on #0A0A0A  │ 8.2:1   │ AAA      │
│ #B3B3B3 on #0A0A0A         │ 7.4:1   │ AAA      │
│ Black on Gold              │ 8.2:1   │ AAA      │
└────────────────────────────┴─────────┴──────────┘
            </code></pre>

            <h2>Semantic Labels</h2>
            <pre><code class="language-dart">
// Always provide semantic labels for screen readers

// Images
Image.network(
  user.photoUrl,
  semanticLabel: '\${user.name}, \${user.age} years old',
)

// Buttons
IconButton(
  icon: Icon(Icons.favorite),
  onPressed: onLike,
  tooltip: 'Like \${user.name}',
)

// Custom widgets
Semantics(
  label: 'Match card for \${user.name}',
  hint: 'Swipe right to like, left to pass',
  child: MatchCard(user: user),
)

// Form fields
TextFormField(
  decoration: InputDecoration(
    labelText: 'Email',
    hintText: 'Enter your email address',
  ),
  keyboardType: TextInputType.emailAddress,
  autofillHints: [AutofillHints.email],
)
            </code></pre>

            <h2>Touch Targets</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────┐
│                    MINIMUM TOUCH TARGET SIZES                            │
└─────────────────────────────────────────────────────────────────────────┘

WCAG 2.1 Level AAA: 44x44 pixels minimum
Material Design: 48x48 pixels recommended
Apple HIG: 44x44 points minimum

GreenGo Standards:
• Primary buttons: 56px height (exceeds requirement)
• Icon buttons: 48x48px minimum
• List items: 56px height minimum
• Bottom nav items: 48px touch area
• Spacing between targets: 8px minimum
            </code></pre>

            <h2>Focus Management</h2>
            <pre><code class="language-dart">
// Proper focus handling for keyboard navigation

class AccessibleForm extends StatefulWidget {
  @override
  _AccessibleFormState createState() => _AccessibleFormState();
}

class _AccessibleFormState extends State<AccessibleForm> {
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          focusNode: _emailFocus,
          decoration: InputDecoration(labelText: 'Email'),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            _passwordFocus.requestFocus();
          },
        ),
        TextFormField(
          focusNode: _passwordFocus,
          decoration: InputDecoration(labelText: 'Password'),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
}

// Focus visibility indicator
Focus(
  child: Builder(
    builder: (context) {
      final focused = Focus.of(context).hasFocus;
      return Container(
        decoration: BoxDecoration(
          border: focused
              ? Border.all(color: AppColors.gold, width: 2)
              : null,
        ),
        child: child,
      );
    },
  ),
)
            </code></pre>

            <h2>Screen Reader Support</h2>
            <pre><code class="language-dart">
// Exclude decorative elements
ExcludeSemantics(
  child: Image.asset('assets/decorative_pattern.png'),
)

// Merge semantics for grouped elements
MergeSemantics(
  child: Row(
    children: [
      Icon(Icons.star, color: Colors.amber),
      Text('4.8'),
      Text('(120 reviews)'),
    ],
  ),
)

// Custom semantic actions
Semantics(
  customSemanticsActions: {
    CustomSemanticsAction(label: 'Super Like'): () => onSuperLike(),
    CustomSemanticsAction(label: 'Report User'): () => onReport(),
  },
  child: MatchCard(user: user),
)

// Announce dynamic changes
SemanticsService.announce(
  'New match with \${user.name}!',
  TextDirection.ltr,
);
            </code></pre>

            <h2>Accessibility Checklist</h2>
            <table>
                <thead>
                    <tr><th>Category</th><th>Requirement</th><th>Status</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Color</strong></td>
                        <td>4.5:1 contrast for text</td>
                        <td>✓</td>
                    </tr>
                    <tr>
                        <td><strong>Color</strong></td>
                        <td>Don't use color alone to convey info</td>
                        <td>✓</td>
                    </tr>
                    <tr>
                        <td><strong>Touch</strong></td>
                        <td>44x44px minimum touch targets</td>
                        <td>✓</td>
                    </tr>
                    <tr>
                        <td><strong>Text</strong></td>
                        <td>Support dynamic type scaling</td>
                        <td>✓</td>
                    </tr>
                    <tr>
                        <td><strong>Labels</strong></td>
                        <td>All images have semantic labels</td>
                        <td>✓</td>
                    </tr>
                    <tr>
                        <td><strong>Labels</strong></td>
                        <td>All buttons have labels/tooltips</td>
                        <td>✓</td>
                    </tr>
                    <tr>
                        <td><strong>Focus</strong></td>
                        <td>Logical focus order</td>
                        <td>✓</td>
                    </tr>
                    <tr>
                        <td><strong>Focus</strong></td>
                        <td>Visible focus indicators</td>
                        <td>✓</td>
                    </tr>
                    <tr>
                        <td><strong>Motion</strong></td>
                        <td>Respect reduced motion settings</td>
                        <td>✓</td>
                    </tr>
                    <tr>
                        <td><strong>Forms</strong></td>
                        <td>Clear error messages</td>
                        <td>✓</td>
                    </tr>
                </tbody>
            </table>
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

designSystemPages.forEach(page => {
    const filepath = path.join(pagesDir, page.file);
    const html = createPageHTML(page);
    fs.writeFileSync(filepath, html);
    console.log(`Created: ${page.file}`);
});

console.log(`\nGenerated ${designSystemPages.length} design system pages!`);
