# 🌟 GreenGoChat - Premium Dating Application

<div align="center">

![GreenGoChat Logo](assets/images/logo.png)

**Discover Your Perfect Match**

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud-orange?logo=firebase)](https://firebase.google.com)
[![GCP](https://img.shields.io/badge/Google_Cloud-Platform-4285F4?logo=google-cloud)](https://cloud.google.com)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform)](https://terraform.io)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)

</div>

---

## 📖 Overview

GreenGoChat is a next-generation dating application that combines cutting-edge technology with an elegant user experience. Built with Flutter for cross-platform compatibility and powered by Google Cloud Platform for scalability and reliability.

### ✨ Key Features

- 💚 **Beautiful UI**: Gold and black themed premium design
- 🔐 **Secure Authentication**: Email, Google, Apple, Facebook, Phone, 2FA, Biometric
- 📸 **AI Photo Verification**: Cloud Vision AI for authenticity
- 🎯 **Smart Matching**: AI-powered compatibility algorithm with distance sorting
- 💬 **Real-time Messaging**: Instant messaging with rich media
- 📹 **Video Calling**: HD video calls with virtual backgrounds
- 💰 **Flexible Monetization**: Base Membership + Subscriptions (Silver, Gold, Platinum) + GreenGoCoins
- 🌍 **Localization**: 50+ languages supported
- ✈️ **Traveler Mode**: Temporarily set a new city and discover people there for 24 hours
- 🕵️ **Incognito Mode**: Hide your profile completely from discovery
- ♿ **Accessibility**: WCAG 2.1 AA compliant

---

## 🏗️ Architecture

```
Frontend (Flutter)
    ↓
Cloud Functions (Node.js/TypeScript)
    ↓
├── Cloud Firestore (Database)
├── Cloud Storage (Media)
├── Cloud Vision AI (Photo Verification)
├── Vertex AI (Matching Algorithm)
└── Pub/Sub (Events)
```

**Infrastructure**: Fully managed with Terraform for consistent deployments

---

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK**: 3.16 or higher
- **Node.js**: 18 or higher
- **Terraform**: 1.5 or higher
- **Firebase CLI**: Latest version
- **Google Cloud SDK**: Latest version

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/yourcompany/greengo-chat.git
cd greengo-chat

# 2. Install dependencies
flutter pub get
cd functions && npm install && cd ..

# 3. Configure environment
cp .env.example .env
cp functions/.env.example functions/.env
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit the .env files with your configuration

# 4. Deploy infrastructure
cd terraform
terraform init
terraform apply
cd ..

# 5. Configure Firebase
firebase login
firebase init
flutterfire configure

# 6. Deploy backend
cd functions
npm run build
firebase deploy --only functions
cd ..

# 7. Deploy security rules
firebase deploy --only firestore:rules,storage,firestore:indexes

# 8. Run the app
flutter run
```

For detailed setup instructions, see [MASTER_IMPLEMENTATION_GUIDE.md](MASTER_IMPLEMENTATION_GUIDE.md)

---

## 📂 Project Structure

```
GreenGo App/
├── lib/                    # Flutter application
│   ├── core/              # Core utilities
│   │   ├── utils/         # base_membership_gate.dart
│   │   ├── widgets/       # base_membership_dialog.dart, limit_reached_dialog.dart
│   │   └── services/      # photo_validation_service.dart
│   └── features/          # Feature modules
│       ├── authentication/
│       ├── chat/
│       ├── coins/
│       ├── discovery/
│       ├── matching/
│       ├── membership/
│       ├── profile/
│       └── ...
├── functions/             # Cloud Functions backend
│   └── src/              # TypeScript source
├── terraform/             # Infrastructure as Code
│   └── modules/          # Terraform modules
├── firestore.rules        # Firestore security rules
├── storage.rules          # Cloud Storage security rules
└── docs/                  # Documentation
```

---

## 🛠️ Technology Stack

### Frontend
- **Framework**: Flutter 3.16+
- **State Management**: BLoC Pattern
- **DI**: get_it, injectable
- **Storage**: Hive, SharedPreferences
- **Networking**: Dio, Retrofit

### Backend
- **Runtime**: Node.js 18+
- **Language**: TypeScript
- **Functions**: Google Cloud Functions Gen 2
- **Authentication**: Firebase Auth + JWT

### Infrastructure
- **IaC**: Terraform
- **Database**: Cloud Firestore
- **Storage**: Cloud Storage + CDN
- **AI/ML**: Cloud Vision, Vertex AI
- **Analytics**: BigQuery, Firebase Analytics

---

## 🌍 Environment Configuration

### Development
```env
ENVIRONMENT=development
USE_FIREBASE_EMULATORS=true
FIRESTORE_EMULATOR_HOST=localhost:8080
```

### Staging
```env
ENVIRONMENT=staging
USE_FIREBASE_EMULATORS=false
GCP_PROJECT_ID=greengo-chat-staging
```

### Production
```env
ENVIRONMENT=production
USE_FIREBASE_EMULATORS=false
GCP_PROJECT_ID=greengo-chat-prod
```

See [.env.example](.env.example) for all configuration options.

---

## 🔐 Security

- ✅ **Firestore Security Rules**: Row-level security
- ✅ **Cloud Storage Rules**: File-level access control
- ✅ **Authentication**: Multi-factor authentication
- ✅ **Encryption**: Data encrypted at rest and in transit
- ✅ **KMS**: Cloud Key Management Service
- ✅ **GDPR Compliance**: Data export and deletion

---

## 🧪 Testing

```bash
# Flutter tests
flutter test

# Cloud Functions tests
cd functions && npm test

# E2E tests with emulators
firebase emulators:exec "flutter test integration_test"

# Coverage
flutter test --coverage
```

---

## 📦 Deployment

### Deploy Infrastructure
```bash
cd terraform
terraform apply -var="environment=production"
```

### Deploy Backend
```bash
cd functions
npm run build
firebase deploy --only functions --project production
```

### Deploy Rules
```bash
firebase deploy --only firestore:rules,storage,firestore:indexes --project production
```

### Build Apps
```bash
# Android (release APK)
flutter build apk --release

# Android (App Bundle for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## 📊 Monitoring

- **Cloud Monitoring**: Real-time metrics
- **Cloud Logging**: Centralized logs
- **Firebase Analytics**: User behavior tracking
- **Crashlytics**: Crash reporting
- **Performance Monitoring**: App performance

Access dashboards:
- [GCP Console](https://console.cloud.google.com)
- [Firebase Console](https://console.firebase.google.com)

---

## 💰 Monetization

### Base Membership (Required)
- **GreenGo Base Membership** (`greengo_base_membership`): Yearly Google Play subscription required to interact with any profile (swipe, like, super like, chat). Users without active base membership see a purchase prompt on any interaction. `MembershipTier.test` users bypass this gate.

### Subscription Tiers
| Tier | Grid Profiles | Features |
|------|--------------|----------|
| **Free** | 3 rows × columns | Basic browsing |
| **Silver** | 30 rows × columns | Premium filters, more swipes |
| **Gold** | 60 rows × columns | All Silver + boosts |
| **Platinum** | 100 rows × columns | All Gold + unlimited features |

### GreenGoCoins
Virtual currency for in-app purchases:
- Super Like: 5 coins
- Boost: 50 coins
- Undo: 3 coins
- Extra Grid Batch: varies by tier

---

## ✈️ Traveler Mode

Users can temporarily set a different city as their active location:

- **Duration**: 24 hours from activation
- **Discovery**: Shows profiles near the traveler city, sorted by distance from that city
- **Distance display**: All distances calculated from the traveler position
- **Profile display**: Shows traveler city (with ✈️ icon) instead of home location on profile card, match list, and search results
- **Auto-refresh**: When traveler mode activates, the discovery grid automatically refreshes to show people near the new city
- **Expiry**: When the 24-hour session ends, home location is restored on next app start

---

## 🕵️ Incognito Mode

- Users in incognito mode are **completely hidden** from discovery (both grid and swipe views)
- Supports both **timed incognito** (hidden until expiry) and **permanent incognito** (no expiry, hidden indefinitely)
- Incognito users can still browse and swipe; they simply do not appear to others

---

## 🔍 Discovery

### Grid View (Default)
- Grid is the **default view** when opening the Discovery tab
- Profiles sorted by distance (closest first)
- **Pull-to-refresh**: Swipe down to reload profiles sorted by current position (or traveler position if active)
- Column selector: 2, 3, or 4 columns
- Swipe view available via the toggle button in the header

### Swipe View
- Classic card-stack swipe experience
- Swipe right = Like, left = Pass, up = Super Like, down = Skip
- Undo last swipe (costs 3 coins)

### Filters Applied
- Gender preference
- Sexual orientation
- Country filter (respects traveler location)
- Distance filter (uses effective location — home or traveler)
- Matched users excluded
- Blocked users excluded (bidirectional)
- Incognito users excluded

---

## 📚 Documentation

- [Master Implementation Guide](MASTER_IMPLEMENTATION_GUIDE.md) - Complete setup guide
- [Implementation Details](IMPLEMENTATION_GUIDE.md) - Detailed implementation
- [API Documentation](docs/api/README.md) - Backend API docs
- [Architecture](docs/architecture/README.md) - System architecture
- [Contributing](CONTRIBUTING.md) - Contribution guidelines

---

## 📋 Changelog

### Latest Updates (Feb 2026)

#### Discovery
- Grid view is now the **default** (swipe is secondary, accessible via toggle)
- Added **pull-to-refresh** on grid: reloads profiles sorted by distance, traveler-aware
- Fixed country filter to use `effectiveLocation` (respects traveler mode for candidates too)
- `BlocListener<ProfileBloc>` in discovery screen auto-refreshes stack when traveler activates or city changes

#### Traveler Feature
- Profile detail, match cards, and search results now display traveler city (with ✈️ icon) when active
- Discovery distances calculated from traveler coordinates via `effectiveLocation`
- Traveler location picker screen added

#### Incognito Mode
- Fixed bug: users with `isIncognito: true` and no expiry date (permanent incognito) were still appearing in discovery
- Corrected filter: hidden if `isIncognito && (incognitoExpiry == null || incognitoExpiry > now)`

#### Base Membership Gate
- Added `greengo_base_membership` yearly subscription as a prerequisite for all interactions
- Gate applied to: swipe, like, super like, opening chats, sending messages, match actions
- `MembershipTier.test` users bypass the gate entirely
- Profile page shows membership validity and expiry date

#### Coin Shop
- Fixed white/blank screen in release mode caused by unhandled exceptions in tab builders
- All three tabs (`_buildBuyCoinsTab`, `_buildMembershipTab`, `_buildVideoCoinsTab`) wrapped in `_safeBuild()` — shows visible error widget instead of blank screen
- Pre-populated `_cachedPackages` with `CoinPackages.standardPackages` as fallback when IAP is unavailable
- Type-safe promotion parsing via `.whereType<CoinPromotion>().toList()`

#### Other
- Removed Google Mobile Ads (`google_mobile_ads`) — `ad_service.dart` and `banner_ad_widget.dart` deleted
- Added `photo_validation_service.dart` for AI-based photo moderation
- Firestore security rules updated for ML collections and discovery permissions
- i18n keys added for photo validation error messages (6 languages)

---

## 🤝 Support

For issues, questions, or support:

1. Check the [documentation](docs/)
2. Review [existing issues](https://github.com/yourcompany/greengo-chat/issues)
3. Create a [new issue](https://github.com/yourcompany/greengo-chat/issues/new)
4. Contact: support@greengochat.com

---

## 📝 License

Copyright © 2025 GreenGoChat. All rights reserved.

This is proprietary software. Unauthorized copying, modification, distribution, or use of this software, via any medium, is strictly prohibited.

---

## 👥 Team

- **Lead Developer**: [Your Name]
- **Backend Engineer**: [Name]
- **UI/UX Designer**: [Name]
- **DevOps Engineer**: [Name]

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Google Cloud Platform for robust infrastructure
- Firebase for real-time capabilities
- All contributors and supporters

---

<div align="center">

**Made with 💚 by the GreenGoChat Team**

[Website](https://greengochat.com) • [Twitter](https://twitter.com/greengochat) • [Instagram](https://instagram.com/greengochat)

</div>
