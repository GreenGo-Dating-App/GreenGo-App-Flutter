# Subscription & Monetization System

Complete subscription management system with Google Play Billing and Apple StoreKit 2 integration.

## Features Implemented

### Points 146-155: Complete Subscription Lifecycle

✅ **Point 146**: Google Play Billing integration with in-app purchases
✅ **Point 147**: Apple StoreKit 2 with native StoreKit views
✅ **Point 148**: Three-tier subscription system (Basic, Silver $9.99, Gold $19.99)
✅ **Point 149**: Gold-highlighted premium features selection screen
✅ **Point 150**: Upgrade/downgrade flow with pro-rated billing support
✅ **Point 151**: Cancellation process with retention offers
✅ **Point 152**: Renewal notifications 3 days before expiration
✅ **Point 153**: Grace period handling (7 days for failed payments)
✅ **Point 154**: Subscription restoration for reinstalling users
✅ **Point 155**: Admin panel capabilities (Cloud Functions)

## Subscription Tiers

### Basic (Free)
- 10 daily likes
- 1 super like per day
- No rewinds
- No boosts
- Cannot see who likes you
- No advanced filters
- No read receipts
- Ads enabled

### Silver ($9.99/month)
- 100 daily likes
- 5 super likes per day
- 5 rewinds per day
- 1 boost per month
- See who likes you ✓
- Advanced filters ✓
- Read receipts ✓
- Ad-free ✓
- 1 profile boost

### Gold ($19.99/month)
- **Unlimited** daily likes
- 10 super likes per day
- **Unlimited** rewinds
- 3 boosts per month
- See who likes you ✓
- Advanced filters ✓
- Read receipts ✓
- Priority support ✓
- Ad-free ✓
- 5 profile boosts
- Incognito mode ✓

## Architecture

### Domain Layer
```dart
lib/features/subscription/domain/
├── entities/
│   ├── subscription.dart          // Subscription entity with tier logic
│   └── purchase.dart              // Purchase transaction entity
├── repositories/
│   └── subscription_repository.dart
└── usecases/
    ├── get_current_subscription.dart
    ├── purchase_subscription.dart
    ├── cancel_subscription.dart
    └── restore_purchases.dart
```

### Data Layer
```dart
lib/features/subscription/data/
├── models/
│   └── subscription_model.dart    // Firestore serialization
└── datasources/
    └── subscription_remote_datasource.dart  // In-app purchase handling
```

### Presentation Layer
```dart
lib/features/subscription/presentation/
├── bloc/
│   ├── subscription_bloc.dart
│   ├── subscription_event.dart
│   └── subscription_state.dart
└── screens/
    └── subscription_selection_screen.dart  // Premium UI with gold theme
```

## Setup Instructions

### 1. Install Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  in_app_purchase: ^3.1.11
  in_app_purchase_android: ^0.3.0
  in_app_purchase_storekit: ^0.3.6
```

Run:
```bash
flutter pub get
```

### 2. Configure Google Play Billing (Android)

#### Create Products in Google Play Console:
1. Go to Google Play Console > Your App > Monetization > In-app products
2. Create products:
   - **Product ID**: `silver_premium_monthly`
   - **Name**: Silver Premium
   - **Price**: $9.99

   - **Product ID**: `gold_premium_monthly`
   - **Name**: Gold Premium
   - **Price**: $19.99

#### Update AndroidManifest.xml:
```xml
<manifest>
    <uses-permission android:name="com.android.vending.BILLING" />
</manifest>
```

#### Configure Webhook:
1. Set up webhook endpoint in your Cloud Functions
2. Add URL to Google Play Console > Monetization > Real-time developer notifications
3. Webhook URL: `https://your-region-your-project.cloudfunctions.net/handlePlayStoreWebhook`

### 3. Configure Apple App Store (iOS)

#### Create Subscriptions in App Store Connect:
1. Go to App Store Connect > Your App > Subscriptions
2. Create subscription group: "Premium Membership"
3. Add subscriptions:
   - **Product ID**: `silver_premium_monthly`
   - **Reference Name**: Silver Premium
   - **Price**: $9.99/month

   - **Product ID**: `gold_premium_monthly`
   - **Reference Name**: Gold Premium
   - **Price**: $19.99/month

#### Enable StoreKit Configuration (for testing):
1. Xcode > File > New > File > StoreKit Configuration File
2. Add products matching App Store Connect

#### Configure Server Notifications:
1. App Store Connect > Your App > App Information
2. Set Server URL: `https://your-region-your-project.cloudfunctions.net/handleAppStoreWebhook`

### 4. Deploy Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions:handlePlayStoreWebhook,functions:handleAppStoreWebhook,functions:checkExpiringSubscriptions,functions:handleExpiredGracePeriods
```

### 5. Configure Firestore Security Rules

```javascript
// subscriptions collection
match /subscriptions/{subscriptionId} {
  allow read: if request.auth.uid == resource.data.userId;
  allow write: if false; // Only server can write
}

// purchases collection
match /purchases/{purchaseId} {
  allow read: if request.auth.uid == resource.data.userId;
  allow write: if false; // Only server can write
}
```

## Usage

### Show Subscription Screen

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (context) => SubscriptionBloc(
        getCurrentSubscription: getIt<GetCurrentSubscription>(),
        purchaseSubscription: getIt<PurchaseSubscription>(),
        cancelSubscription: getIt<CancelSubscription>(),
        restorePurchases: getIt<RestorePurchases>(),
        inAppPurchase: InAppPurchase.instance,
      ),
      child: const SubscriptionSelectionScreen(),
    ),
  ),
);
```

### Check Feature Access

```dart
// In your code
final subscription = await getIt<GetCurrentSubscription>()(userId);

subscription.fold(
  (failure) => print('Error loading subscription'),
  (sub) {
    if (sub?.hasFeature('seeWhoLikesYou') ?? false) {
      // Show who likes you feature
    }

    final dailyLikes = sub?.getLimit('dailyLikes') ?? 10;
    if (dailyLikes == -1) {
      // Unlimited likes
    }
  },
);
```

### Listen to Subscription Changes

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription<Subscription?> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = getIt<SubscriptionRepository>()
        .subscriptionStream(userId)
        .listen((result) {
      result.fold(
        (failure) => print('Error'),
        (subscription) {
          setState(() {
            // Update UI based on subscription
          });
        },
      );
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

## Cloud Functions

### Webhooks

#### Google Play Webhook
- **URL**: `/handlePlayStoreWebhook`
- **Method**: POST
- **Handles**: Subscription renewals, cancellations, refunds, grace periods

#### App Store Webhook
- **URL**: `/handleAppStoreWebhook`
- **Method**: POST
- **Handles**: Subscription renewals, cancellations, refunds

### Scheduled Functions

#### Check Expiring Subscriptions
- **Schedule**: Daily at 09:00 UTC
- **Purpose**: Send renewal notifications 3 days before expiration

#### Handle Expired Grace Periods
- **Schedule**: Every 1 hour
- **Purpose**: Downgrade users after 7-day grace period expires

## Testing

### Test on Android

```bash
flutter run --debug
```

1. Use test credit cards from Google Play Console
2. Test purchases in sandbox mode
3. Verify webhook events in Cloud Functions logs

### Test on iOS

1. Create sandbox tester account in App Store Connect
2. Sign out of App Store on device
3. Run app and make purchase
4. Sign in with sandbox account when prompted

### Test Webhooks Locally

```bash
# Start Firebase emulator
firebase emulators:start

# Send test webhook
curl -X POST http://localhost:5001/your-project/us-central1/handlePlayStoreWebhook \
  -H "Content-Type: application/json" \
  -d '{"message": {"data": "BASE64_ENCODED_DATA"}}'
```

## Monitoring

### View Subscription Metrics

```bash
# View Cloud Function logs
firebase functions:log --only handlePlayStoreWebhook

# Query active subscriptions
# In Firestore console, filter:
# status == 'active'
```

### Grace Period Monitoring

Check subscriptions in grace period:
```javascript
// Firestore query
db.collection('subscriptions')
  .where('inGracePeriod', '==', true)
  .get()
```

## Retention Strategies

### Cancellation Flow (Point 151)

When user cancels:
1. Show retention offer (50% off for 3 months)
2. Highlight features they'll lose
3. Offer downgrade to Silver instead
4. Survey why they're cancelling
5. Schedule win-back email campaign

### Grace Period (Point 153)

When payment fails:
1. Send immediate payment failed notification
2. Enter 7-day grace period
3. Send reminders on days 1, 3, 5, 7
4. Maintain premium access during grace period
5. Downgrade to Basic after 7 days

### Renewal Reminders (Point 152)

3 days before expiration:
1. In-app notification
2. Push notification
3. Email reminder
4. Highlight value received
5. Easy one-tap renewal

## Pro-Rated Billing (Point 150)

### Upgrade Flow
```dart
// User upgrading from Silver to Gold
// 1. Calculate pro-rated credit from Silver
final daysRemaining = subscription.daysRemaining;
final silverDailyRate = 9.99 / 30;
final credit = daysRemaining * silverDailyRate;

// 2. Apply credit to Gold purchase
final goldPrice = 19.99;
final chargeAmount = goldPrice - credit;

// 3. Purchase new tier
// (Handled by platform billing system)
```

### Downgrade Flow
```dart
// User downgrading from Gold to Silver
// 1. Calculate credit
// 2. Apply to next billing cycle
// 3. Maintain Gold until end of current period
// 4. Auto-switch to Silver on next billing date
```

## Security

### Purchase Verification

All purchases are verified server-side:
1. Client initiates purchase
2. Platform returns purchase token
3. Client sends token to Cloud Function
4. Function verifies with Google/Apple API
5. Function creates subscription in Firestore
6. Function completes purchase

### Fraud Prevention

- Server-side verification required
- No client-side subscription creation
- Purchase tokens validated
- Receipt validation with platform APIs
- Duplicate purchase detection

## Troubleshooting

### Purchase Not Completing

1. Check Cloud Function logs
2. Verify webhook configuration
3. Check Firestore security rules
4. Verify product IDs match

### Webhook Not Receiving Events

1. Check URL is publicly accessible
2. Verify SSL certificate
3. Check Cloud Function deployment
4. Test with manual POST request

### Restore Purchases Not Working

1. Verify user signed in to same account
2. Check platform purchase history
3. Verify product IDs
4. Check Firestore for existing subscription

## Cost Estimates

**Monthly costs for 10,000 users:**
- 1,000 Silver subscribers ($9.99 × 1,000 × 0.85 after fees) = $8,491.50
- 500 Gold subscribers ($19.99 × 500 × 0.85) = $8,495.75
- Total revenue: ~$17,000/month

**Platform fees:**
- Google Play: 15% (first $1M annually)
- App Store: 15% (first $1M annually)

**Cloud costs:**
- Firestore: ~$10/month
- Cloud Functions: ~$5/month
- Total: ~$15/month

**Net revenue: ~$16,750/month**

## Support

For issues or questions:
- Check logs: `firebase functions:log`
- Review documentation: [In-App Purchase Plugin](https://pub.dev/packages/in_app_purchase)
- Test in sandbox mode first
