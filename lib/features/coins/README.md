# GreenGoCoins Virtual Currency System

Complete virtual currency implementation with coin purchases, rewards, gifts, and coin-based features.

## Features Implemented

### Points 156-165: Complete Virtual Currency System

✅ **Point 156**: Virtual currency economy with $0.99 = 100 coins exchange rate
✅ **Point 157**: Coin purchase interface with 4 packages (100/$0.99, 500/$3.99, 1000/$6.99, 5000/$29.99)
✅ **Point 158**: Animated gold coin balance display in navigation bar
✅ **Point 159**: Transaction history with earnings and spending timestamps
✅ **Point 160**: Coin rewards system (first match: 50, complete profile: 100, daily login: 10)
✅ **Point 161**: Coin-based features (Super Like: 5, Boost: 50, Undo: 3, See Who Liked You: 20)
✅ **Point 162**: Coin gifting system between matches
✅ **Point 163**: Monthly allowance (Silver: 100, Gold: 250 coins)
✅ **Point 164**: Coin expiration after 365 days with warnings
✅ **Point 165**: Promotional campaigns with bonus percentages

## Coin Economy

### Exchange Rate (Point 156)
- **Base Rate**: $0.99 = 100 coins
- **Packages offer better value at higher quantities**

### Coin Packages (Point 157)

| Package | Coins | Price | Value (coins/$) |
|---------|-------|-------|-----------------|
| Starter | 100   | $0.99 | 101 |
| Popular | 500   | $3.99 | 125 |
| Value   | 1,000 | $6.99 | 143 |
| Premium | 5,000 | $29.99| 167 |

### Coin-Based Features (Point 161)

| Feature | Cost | Description |
|---------|------|-------------|
| Super Like | 5 coins | Stand out with a special like |
| Profile Boost | 50 coins | Get seen by more people |
| Undo Last Swipe | 3 coins | Go back on your last decision |
| See Who Liked You | 20 coins | View all users who liked you |

### Reward System (Point 160)

| Achievement | Coins | Type |
|-------------|-------|------|
| First Match | 50 | One-time |
| Complete Profile | 100 | One-time |
| Daily Login | 10 | Daily |
| 7-Day Streak | 50 | Recurring |
| 30-Day Streak | 200 | Recurring |
| First Message | 25 | One-time |
| Photo Verified | 75 | One-time |
| Refer a Friend | 100 | Recurring |

### Monthly Allowance (Point 163)

| Tier | Monthly Coins |
|------|---------------|
| Basic | 0 |
| Silver | 100 |
| Gold | 250 |

## Architecture

### Domain Layer
```dart
lib/features/coins/domain/
├── entities/
│   ├── coin_balance.dart          // Balance with expiration tracking
│   ├── coin_package.dart           // Purchase packages
│   ├── coin_transaction.dart       // Transaction history
│   ├── coin_reward.dart            // Achievement rewards
│   ├── coin_gift.dart              // Gift system
│   └── coin_promotion.dart         // Promotional campaigns
├── repositories/
│   └── coin_repository.dart        // Repository interface
└── usecases/
    ├── get_coin_balance.dart
    ├── purchase_coins.dart
    ├── get_transaction_history.dart
    ├── claim_reward.dart
    ├── purchase_feature.dart
    ├── manage_gifts.dart
    ├── manage_allowance.dart
    ├── manage_expiration.dart
    └── manage_promotions.dart
```

### Data Layer
```dart
lib/features/coins/data/
├── models/
│   ├── coin_balance_model.dart     // Firestore serialization
│   ├── coin_transaction_model.dart
│   ├── coin_gift_model.dart
│   └── coin_promotion_model.dart
├── datasources/
│   └── coin_remote_datasource.dart // Firestore & in-app purchase handling
└── repositories/
    └── coin_repository_impl.dart   // Repository implementation
```

### Presentation Layer
```dart
lib/features/coins/presentation/
├── bloc/
│   ├── coin_bloc.dart              // State management
│   ├── coin_event.dart
│   └── coin_state.dart
├── screens/
│   ├── coin_shop_screen.dart       // Purchase interface
│   └── transaction_history_screen.dart
└── widgets/
    └── coin_balance_widget.dart    // Animated balance display
```

### Cloud Functions
```typescript
functions/src/coins/
└── coinManager.ts
    ├── verifyGooglePlayCoinPurchase    // Android purchase verification
    ├── verifyAppStoreCoinPurchase      // iOS purchase verification
    ├── grantMonthlyAllowances          // Monthly allowance distribution
    ├── processExpiredCoins             // Expire old coins
    ├── sendExpirationWarnings          // Notify before expiration
    └── claimReward                     // Process reward claims
```

## Setup Instructions

### 1. Install Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  in_app_purchase: ^3.1.11
  in_app_purchase_android: ^0.3.0
  in_app_purchase_storekit: ^0.3.6
  uuid: ^4.0.0
  intl: ^0.18.0
```

Run:
```bash
flutter pub get
```

### 2. Configure Google Play (Android)

#### Create Products:
1. Google Play Console > Your App > Monetization > In-app products
2. Create consumable products:
   - `greengo_coins_100` - $0.99
   - `greengo_coins_500` - $3.99
   - `greengo_coins_1000` - $6.99
   - `greengo_coins_5000` - $29.99

#### Update AndroidManifest.xml:
```xml
<manifest>
    <uses-permission android:name="com.android.vending.BILLING" />
</manifest>
```

### 3. Configure App Store (iOS)

#### Create Consumables:
1. App Store Connect > Your App > In-App Purchases
2. Create consumable products with matching IDs

#### Enable StoreKit (Testing):
1. Xcode > File > New > StoreKit Configuration File
2. Add products matching App Store Connect

### 4. Configure Firestore

#### Collections Structure:
```javascript
// coinBalances/{userId}
{
  userId: string,
  totalCoins: number,
  earnedCoins: number,
  purchasedCoins: number,
  giftedCoins: number,
  spentCoins: number,
  lastUpdated: timestamp,
  coinBatches: [{
    batchId: string,
    initialCoins: number,
    remainingCoins: number,
    source: 'purchase' | 'reward' | 'gift' | 'allowance' | 'promotion',
    acquiredDate: timestamp,
    expirationDate: timestamp
  }]
}

// coinTransactions/{transactionId}
{
  userId: string,
  type: 'credit' | 'debit',
  amount: number,
  balanceAfter: number,
  reason: string,
  relatedId?: string,
  relatedUserId?: string,
  metadata?: object,
  createdAt: timestamp
}

// coinGifts/{giftId}
{
  senderId: string,
  receiverId: string,
  amount: number,
  message?: string,
  status: 'pending' | 'accepted' | 'declined' | 'expired',
  sentAt: timestamp,
  receivedAt?: timestamp,
  expiresAt: timestamp
}

// coinPromotions/{promotionId}
{
  name: string,
  description: string,
  type: string,
  bonusPercentage?: number,
  bonusCoins?: number,
  startDate: timestamp,
  endDate: timestamp,
  isActive: boolean,
  applicablePackageIds?: string[],
  promoCode?: string
}

// claimedRewards/{claimId}
{
  userId: string,
  rewardId: string,
  coinAmount: number,
  claimedAt: timestamp
}
```

#### Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Coin balances - read only, server writes
    match /coinBalances/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if false; // Only Cloud Functions
    }

    // Transactions - read only
    match /coinTransactions/{transactionId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow write: if false; // Only Cloud Functions
    }

    // Gifts - read if involved, create by sender
    match /coinGifts/{giftId} {
      allow read: if request.auth.uid == resource.data.senderId
                  || request.auth.uid == resource.data.receiverId;
      allow create: if request.auth.uid == request.resource.data.senderId;
      allow update, delete: if false; // Only Cloud Functions
    }

    // Promotions - public read
    match /coinPromotions/{promotionId} {
      allow read: if true;
      allow write: if false; // Only admins via Cloud Functions
    }

    // Claimed rewards - read only
    match /claimedRewards/{claimId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow write: if false; // Only Cloud Functions
    }
  }
}
```

### 5. Deploy Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions:verifyGooglePlayCoinPurchase,functions:verifyAppStoreCoinPurchase,functions:grantMonthlyAllowances,functions:processExpiredCoins,functions:sendExpirationWarnings,functions:claimReward
```

### 6. Configure Scheduled Functions

The following functions run automatically:
- **grantMonthlyAllowances**: 1st of each month at midnight UTC
- **processExpiredCoins**: Daily at 2 AM UTC
- **sendExpirationWarnings**: Daily at 10 AM UTC

## Usage

### Display Coin Balance (Point 158)

```dart
// In app bar or navigation
CoinBalanceWidget(
  userId: currentUserId,
  compact: true, // Compact mode for app bar
)
```

### Open Coin Shop (Point 157)

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (context) => CoinBloc(
        getCoinBalance: getIt<GetCoinBalance>(),
        purchaseCoins: getIt<PurchaseCoins>(),
        // ... other dependencies
      ),
      child: CoinShopScreen(userId: currentUserId),
    ),
  ),
);
```

### View Transaction History (Point 159)

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => TransactionHistoryScreen(userId: currentUserId),
  ),
);
```

### Purchase Feature with Coins (Point 161)

```dart
// Check if user can afford
final canAfford = await canAffordFeature(
  userId: userId,
  cost: CoinFeaturePrices.superLike,
);

if (canAfford) {
  // Purchase feature
  final result = await purchaseFeature(
    userId: userId,
    featureName: 'superlike',
    cost: CoinFeaturePrices.superLike,
    relatedId: targetUserId,
  );
}
```

### Claim Reward (Point 160)

```dart
// Claim first match reward
context.read<CoinBloc>().add(
  ClaimCoinReward(
    userId: currentUserId,
    reward: CoinRewards.firstMatch,
    metadata: {'matchId': matchId},
  ),
);
```

### Send Gift (Point 162)

```dart
context.read<CoinBloc>().add(
  SendCoinGiftEvent(
    senderId: currentUserId,
    receiverId: matchUserId,
    amount: 50,
    message: 'Here\'s a gift for you!',
  ),
);
```

### Check for Expiring Coins (Point 164)

```dart
// Check coins expiring in next 30 days
context.read<CoinBloc>().add(
  CheckExpiringCoins(
    userId: currentUserId,
    days: 30,
  ),
);

// Listen to state
BlocListener<CoinBloc, CoinState>(
  listener: (context, state) {
    if (state is ExpiringCoinsLoaded) {
      if (state.totalExpiringCoins > 0) {
        // Show warning to user
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Coins Expiring Soon'),
            content: Text(
              '${state.totalExpiringCoins} coins will expire in ${state.daysUntilExpiration} days!'
            ),
          ),
        );
      }
    }
  },
)
```

## Coin Expiration System (Point 164)

### How It Works:
1. **Acquisition**: Each coin batch has an expiration date (365 days from acquisition)
2. **FIFO Spending**: Oldest coins are spent first
3. **Warnings**: Users notified 30 days before expiration
4. **Processing**: Expired coins removed daily by Cloud Function
5. **Tracking**: All batches tracked separately by source

### Expiration Sources:
All coin sources expire after 365 days:
- Purchased coins
- Rewarded coins
- Gifted coins
- Monthly allowance
- Promotional bonuses

## Promotional Campaigns (Point 165)

### Seasonal Promotions:

```dart
// Black Friday: 50% bonus
final blackFriday = CoinPromotions.blackFriday(year: 2025);

// New Year: 40% bonus
final newYear = CoinPromotions.newYear(year: 2025);

// Valentine's Day: 30% bonus
final valentines = CoinPromotions.valentines(year: 2025);
```

### First Purchase Bonus:
```dart
// Automatic 100 coin bonus on first purchase
CoinPromotions.firstPurchase
```

### Weekend Flash Sales:
```dart
final weekend = CoinPromotions.weekendFlash(
  weekendStart: DateTime(2025, 6, 14),
);
```

### Apply Promo Code:
```dart
context.read<CoinBloc>().add(
  ApplyPromoCode('SUMMER2025'),
);
```

## Testing

### Test Coin Purchases (Android)

```bash
# Enable test mode in Google Play Console
# Use test credit cards
# Verify in Firebase Console > Firestore > coinBalances
```

### Test Coin Purchases (iOS)

1. Create sandbox tester in App Store Connect
2. Sign out of App Store on device
3. Run app and make purchase
4. Sign in with sandbox account

### Test Rewards

```bash
# Use Cloud Functions emulator
firebase emulators:start

# Call reward function
curl -X POST http://localhost:5001/your-project/us-central1/claimReward \
  -H "Content-Type: application/json" \
  -d '{"rewardId": "first_match", "metadata": {}}'
```

### Test Expiration

```javascript
// Manually set expiration date in Firestore
// Run processExpiredCoins function
// Verify coins removed and transaction created
```

## Monitoring

### View Coin Metrics

```bash
# Check coin balances
# Firestore Console > coinBalances

# View transactions
# Firestore Console > coinTransactions

# Monitor Cloud Functions
firebase functions:log --only processExpiredCoins
```

### Analytics Events

Track these events:
- `coin_purchase` - User bought coins
- `coin_reward_claimed` - User claimed reward
- `coin_feature_purchased` - User spent coins on feature
- `coin_gift_sent` - User sent gift
- `coins_expired` - Coins expired

## Cost Estimates

**For 10,000 users:**

**Revenue (Monthly):**
- Avg 20% purchase coins: 2,000 users
- Avg purchase: $3.99
- Monthly revenue: ~$8,000

**Costs:**
- Firestore reads/writes: ~$20/month
- Cloud Functions: ~$10/month
- In-app purchase fees (15%): ~$1,200

**Net revenue: ~$6,770/month**

## Troubleshooting

### Purchase Not Completing

1. Check Cloud Function logs
2. Verify product IDs match
3. Check Firestore security rules
4. Verify purchase token

### Rewards Not Claiming

1. Check if already claimed
2. Verify user authentication
3. Check Cloud Function logs
4. Verify Firestore permissions

### Balance Not Updating

1. Check BLoC subscription
2. Verify Firestore stream
3. Check security rules
4. Verify user ID

## Support

For issues:
- Check Cloud Function logs: `firebase functions:log`
- Review Firestore data structure
- Test in sandbox mode first
- Check [In-App Purchase Plugin docs](https://pub.dev/packages/in_app_purchase)
