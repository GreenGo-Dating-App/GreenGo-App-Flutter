# Comprehensive Test Suite for All 143 Cloud Functions

## Test Coverage Overview

This document outlines the complete test strategy for all 12 microservices (143 functions).

### Test Structure

```
__tests__/
├── setup.ts                          # Global test setup
├── utils/
│   ├── test-helpers.ts              # Test utilities
│   └── mock-data.ts                 # Mock data generators
├── unit/                            # Unit tests for each service
│   ├── media.test.ts               # 10 functions
│   ├── messaging.test.ts           # 8 functions
│   ├── backup.test.ts              # 8 functions
│   ├── subscription.test.ts        # 4 functions
│   ├── coins.test.ts               # 6 functions
│   ├── notification.test.ts        # 9 functions
│   ├── safety.test.ts              # 11 functions
│   ├── gamification.test.ts        # 8 functions
│   ├── security.test.ts            # 5 functions
│   ├── video.test.ts               # 21 functions
│   ├── admin.test.ts               # 31 functions
│   └── analytics.test.ts           # 22 functions
└── integration/                     # Integration tests
    ├── user-flow.test.ts           # End-to-end user flows
    ├── subscription-flow.test.ts   # Subscription lifecycle
    └── moderation-flow.test.ts     # Content moderation flow
```

---

## Test Categories

### 1. Unit Tests (143 functions)

Each function should have tests for:
- ✅ Success cases
- ✅ Error handling
- ✅ Authentication/Authorization
- ✅ Input validation
- ✅ Edge cases
- ✅ Mock external services

### 2. Integration Tests

Test complete workflows:
- User registration → Profile setup → First match
- Purchase subscription → Upgrade tier → Cancel
- Send message → Translate → Schedule
- Report content → Moderate → Ban user
- Start call → Record → End → Archive

### 3. Performance Tests

- Load testing for high-traffic functions
- Concurrency testing for scheduled jobs
- Memory usage optimization

---

## Service-by-Service Test Plans

### 1. Media Processing Service (10 functions)

#### compressUploadedImage (Storage Trigger)
```typescript
describe('compressUploadedImage', () => {
  it('should compress image to <2MB', async () => {
    // Mock: 5MB image upload
    // Expected: Compressed to 1.8MB using Sharp
    // Verify: New file created, original deleted
  });

  it('should preserve EXIF data', async () => {
    // Mock: Image with GPS coordinates
    // Expected: EXIF data maintained
  });

  it('should handle corrupted images', async () => {
    // Mock: Invalid image file
    // Expected: Error logged, original file kept
  });
});
```

#### compressImage (HTTP Callable)
```typescript
describe('compressImage', () => {
  it('should accept valid image URL', async () => {
    // Input: { imageUrl, quality: 85 }
    // Expected: { success: true, compressedUrl }
  });

  it('should validate authentication', async () => {
    // Input: No auth token
    // Expected: UNAUTHENTICATED error
  });

  it('should reject invalid URLs', async () => {
    // Input: { imageUrl: 'not-a-url' }
    // Expected: Invalid URL error
  });
});
```

**Remaining 8 functions follow same pattern:**
- processUploadedVideo
- generateVideoThumbnail
- transcribeVoiceMessage
- transcribeAudio
- batchTranscribe
- cleanupDisappearingMedia
- markMediaAsDisappearing

---

### 2. Messaging Service (8 functions)

#### translateMessage (HTTP Callable)
```typescript
describe('translateMessage', () => {
  it('should translate to target language', async () => {
    // Input: { messageId, targetLanguage: 'es' }
    // Mock: Translation API returns Spanish text
    // Expected: Translated message saved to Firestore
  });

  it('should support 20+ languages', async () => {
    const languages = ['en', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh'];
    // Test each language
  });

  it('should cache translations', async () => {
    // Translate same message twice
    // Expected: Second call uses cache
  });
});
```

#### autoTranslateMessage (Firestore Trigger)
```typescript
describe('autoTranslateMessage', () => {
  it('should auto-translate based on user preferences', async () => {
    // Mock: User has preferredLanguage: 'es'
    // Event: New message created
    // Expected: Translation stored automatically
  });

  it('should skip if languages match', async () => {
    // Mock: Both users speak English
    // Expected: No translation performed
  });
});
```

**Remaining 6 functions:**
- batchTranslateMessages
- getSupportedLanguages
- scheduleMessage
- sendScheduledMessages
- cancelScheduledMessage
- getScheduledMessages

---

### 3. Backup & Export Service (8 functions)

#### backupConversation (HTTP Callable)
```typescript
describe('backupConversation', () => {
  it('should create AES-256-GCM encrypted backup', async () => {
    // Input: { conversationId }
    // Expected: Encrypted file in Cloud Storage
    // Verify: encryptionKey, iv, authTag saved
  });

  it('should include all messages', async () => {
    // Mock: Conversation with 50 messages
    // Expected: All 50 messages in backup
  });

  it('should set 90-day expiration', async () => {
    // Expected: expiresAt = now + 90 days
  });
});
```

#### restoreConversation (HTTP Callable)
```typescript
describe('restoreConversation', () => {
  it('should decrypt and restore messages', async () => {
    // Input: { backupId }
    // Expected: Messages restored to Firestore
    // Verify: Decryption successful
  });

  it('should handle incorrect encryption key', async () => {
    // Input: Wrong encryption key
    // Expected: Decryption failure error
  });
});
```

#### exportConversationToPDF (HTTP Callable)
```typescript
describe('exportConversationToPDF', () => {
  it('should generate PDF with gold theme', async () => {
    // Input: { conversationId }
    // Expected: PDF with custom styling
    // Verify: PDFKit used, file uploaded to Storage
  });

  it('should include user avatars', async () => {
    // Expected: Avatar images in PDF
  });

  it('should set 7-day expiration', async () => {
    // Expected: expiresAt = now + 7 days
  });
});
```

**Remaining 5 functions:**
- listBackups
- deleteBackup
- autoBackupConversations
- listPDFExports
- cleanupExpiredExports

---

### 4. Subscription Service (4 functions)

#### handlePlayStoreWebhook (HTTP Request)
```typescript
describe('handlePlayStoreWebhook', () => {
  const webhookEvents = [
    { type: 1, name: 'SUBSCRIPTION_RECOVERED' },
    { type: 2, name: 'SUBSCRIPTION_RENEWED' },
    { type: 3, name: 'SUBSCRIPTION_CANCELED' },
    { type: 4, name: 'SUBSCRIPTION_PURCHASED' },
    { type: 5, name: 'SUBSCRIPTION_ON_HOLD' },
    { type: 6, name: 'SUBSCRIPTION_IN_GRACE_PERIOD' },
    { type: 7, name: 'SUBSCRIPTION_RESTARTED' },
    { type: 10, name: 'SUBSCRIPTION_EXPIRED' },
  ];

  webhookEvents.forEach(event => {
    it(`should handle ${event.name}`, async () => {
      // Mock: Webhook payload with event type
      // Expected: Subscription status updated
      // Verify: User tier updated if needed
    });
  });

  it('should verify webhook signature', async () => {
    // Input: Invalid signature
    // Expected: 401 Unauthorized
  });

  it('should handle grace period', async () => {
    // Event: SUBSCRIPTION_IN_GRACE_PERIOD
    // Expected: gracePeriodEnd = now + 7 days
  });
});
```

#### handleAppStoreWebhook (HTTP Request)
```typescript
describe('handleAppStoreWebhook', () => {
  const events = ['DID_RENEW', 'DID_CHANGE_RENEWAL_STATUS', 'EXPIRED', 'REFUND'];

  events.forEach(eventType => {
    it(`should handle ${eventType}`, async () => {
      // Test App Store event handling
    });
  });
});
```

**Remaining 2 functions:**
- checkExpiringSubscriptions
- handleExpiredGracePeriods

---

### 5. Coin Service (6 functions)

#### verifyGooglePlayCoinPurchase (HTTP Callable)
```typescript
describe('verifyGooglePlayCoinPurchase', () => {
  it('should verify IAP receipt', async () => {
    // Input: { purchaseToken, productId }
    // Mock: Google Play API verification
    // Expected: Coins granted to user
  });

  it('should prevent double-spending', async () => {
    // Use same purchaseToken twice
    // Expected: Second attempt rejected
  });

  it('should create coin batch with 365-day expiration', async () => {
    // Expected: Batch created with expiresAt
  });
});
```

#### processExpiredCoins (Scheduled)
```typescript
describe('processExpiredCoins', () => {
  it('should delete expired batches (FIFO)', async () => {
    // Mock: 3 batches, oldest is expired
    // Expected: Oldest batch deleted
    // Verify: Balance updated
  });

  it('should warn users 30 days before expiration', async () => {
    // Mock: Batch expiring in 29 days
    // Expected: Warning notification sent
  });
});
```

**Remaining 4 functions:**
- verifyAppStoreCoinPurchase
- grantMonthlyAllowances
- sendExpirationWarnings
- claimReward

---

### 6. Notification Service (9 functions)

#### sendPushNotification (HTTP Callable)
```typescript
describe('sendPushNotification', () => {
  it('should send FCM notification', async () => {
    // Input: { userId, title, body }
    // Mock: FCM sendToDevice
    // Expected: Notification sent successfully
  });

  it('should handle multiple FCM tokens', async () => {
    // Mock: User has 3 devices
    // Expected: Notification sent to all
  });

  it('should remove invalid tokens', async () => {
    // Mock: 1 invalid token
    // Expected: Token removed from database
  });
});
```

#### sendTransactionalEmail (HTTP Callable)
```typescript
describe('sendTransactionalEmail', () => {
  it('should send email via SendGrid', async () => {
    // Input: { userId, templateId }
    // Mock: SendGrid API
    // Expected: Email sent successfully
  });

  it('should use custom templates', async () => {
    const templates = [
      'welcome_email',
      'password_reset',
      'subscription_confirmation',
    ];
    // Test each template
  });
});
```

**Remaining 7 functions:**
- sendBundledNotifications
- trackNotificationOpened
- getNotificationAnalytics
- startWelcomeEmailSeries
- processWelcomeEmailSeries
- sendWeeklyDigestEmails
- sendReEngagementCampaign

---

### 7. Safety & Moderation Service (11 functions)

#### moderatePhoto (HTTP Callable)
```typescript
describe('moderatePhoto', () => {
  it('should detect adult content', async () => {
    // Input: { photoUrl }
    // Mock: Cloud Vision returns adult: VERY_LIKELY
    // Expected: Photo flagged, score >= 4
  });

  it('should detect violence', async () => {
    // Mock: Violence score = 5
    // Expected: Photo flagged
  });

  it('should allow safe images', async () => {
    // Mock: All scores = VERY_UNLIKELY
    // Expected: Photo approved
  });
});
```

#### moderateText (HTTP Callable)
```typescript
describe('moderateText', () => {
  it('should detect profanity', async () => {
    // Input: Text with curse words
    // Expected: Text flagged
  });

  it('should use Natural Language API', async () => {
    // Mock: Sentiment analysis
    // Expected: Toxic content detected
  });
});
```

#### detectSpam (HTTP Callable)
```typescript
describe('detectSpam', () => {
  it('should detect URLs', async () => {
    // Input: Text with multiple URLs
    // Expected: Spam detected
  });

  it('should detect promotional keywords', async () => {
    // Input: "BUY NOW! CLICK HERE!"
    // Expected: Spam detected
  });

  it('should detect repetitive patterns', async () => {
    // Input: Same message repeated
    // Expected: Spam detected
  });
});
```

**Remaining 8 functions:**
- detectFakeProfile
- detectScam
- submitReport
- reviewReport
- submitAppeal
- blockUser
- unblockUser
- getBlockList

---

### 8. Gamification Service (8 functions)

#### grantXP (HTTP Callable)
```typescript
describe('grantXP', () => {
  const xpActions = {
    profile_complete: 50,
    first_message: 25,
    daily_login: 10,
    match: 20,
    video_call: 100,
  };

  Object.entries(xpActions).forEach(([action, xp]) => {
    it(`should grant ${xp} XP for ${action}`, async () => {
      // Input: { action }
      // Expected: XP added to user
    });
  });

  it('should trigger level up', async () => {
    // Mock: User at 95 XP, needs 100 for level 2
    // Grant 10 XP
    // Expected: Level up to 2, rewards granted
  });
});
```

#### trackAchievementProgress (HTTP Callable)
```typescript
describe('trackAchievementProgress', () => {
  it('should update progress', async () => {
    // Input: { achievementId: 'social_butterfly', progress: 50 }
    // Target: 100 messages
    // Expected: Progress updated to 50/100
  });

  it('should unlock achievement at 100%', async () => {
    // Progress: 100/100
    // Expected: Achievement unlocked, notification sent
  });
});
```

**Remaining 6 functions:**
- unlockAchievementReward
- claimLevelRewards
- trackChallengeProgress
- claimChallengeReward
- resetDailyChallenges
- updateLeaderboardRankings

---

### 9. Security Service (5 functions)

#### runSecurityAudit (HTTP Callable - Admin)
```typescript
describe('runSecurityAudit', () => {
  it('should check user data access patterns', async () => {
    // Mock: User exported data 15 times
    // Expected: High data access finding
  });

  it('should check admin actions', async () => {
    // Mock: New admin role granted
    // Expected: Admin action logged
  });

  it('should check GDPR compliance', async () => {
    // Mock: Deletion request completed but user still exists
    // Expected: Critical GDPR violation found
  });

  it('should send alerts for critical findings', async () => {
    // Mock: 5 critical findings
    // Expected: Notification sent to all admins
  });
});
```

**Remaining 4 functions:**
- scheduledSecurityAudit
- getSecurityAuditReport
- listSecurityAuditReports
- cleanupOldAuditReports

---

### 10. Video Calling Service (21 functions)

#### generateAgoraToken (HTTP Callable)
```typescript
describe('generateAgoraToken', () => {
  it('should generate Agora RTC token', async () => {
    // Input: { channelName, uid, role: 'publisher' }
    // Expected: Valid Agora token
    // Verify: Token expires in 1 hour
  });

  it('should support publisher role', async () => {
    // role: 'publisher'
    // Expected: RtcRole.PUBLISHER
  });

  it('should support subscriber role', async () => {
    // role: 'subscriber'
    // Expected: RtcRole.SUBSCRIBER
  });
});
```

#### initiateCall (HTTP Callable)
```typescript
describe('initiateCall', () => {
  it('should create 1-on-1 call', async () => {
    // Input: { recipientId, callType: 'video' }
    // Expected: Call document created
    // Verify: Notification sent to recipient
  });

  it('should check if users are blocked', async () => {
    // Mock: Recipient blocked caller
    // Expected: Cannot call this user error
  });

  it('should generate unique channel name', async () => {
    // Expected: call_user1_user2_timestamp
  });
});
```

#### answerCall (HTTP Callable)
```typescript
describe('answerCall', () => {
  it('should accept incoming call', async () => {
    // Input: { callId }
    // Expected: Call status = active
    // Verify: Participant added, startedAt set
  });

  it('should reject if not recipient', async () => {
    // Mock: Wrong user trying to answer
    // Expected: Not authorized error
  });
});
```

**Remaining 18 functions:**
- rejectCall, endCall, startCallRecording, muteParticipant, toggleVideo
- shareScreen, sendCallReaction, createGroupCall, joinGroupCall
- inviteToGroupCall, removeFromGroupCall, getCallHistory, getCallAnalytics
- onCallStarted, onCallEnded, cleanupMissedCalls, cleanupAbandonedCalls
- archiveOldCallRecords

---

### 11. Admin Service (31 functions)

#### Dashboard Functions (9)
```typescript
describe('Admin Dashboard', () => {
  it('getDashboardStats - should return comprehensive stats', async () => {
    // Expected: user counts, revenue, engagement, moderation stats
  });

  it('getUserGrowth - should show growth by interval', async () => {
    // Input: { startDate, endDate, interval: 'day' }
    // Expected: Daily user signup counts
  });

  it('getRevenueStats - should calculate total revenue', async () => {
    // Expected: Subscription + coin revenue breakdown
  });

  it('getConversionFunnel - should track conversion steps', async () => {
    // Expected: Signups → Profile → Match → Message → Subscribe
  });

  // 5 more dashboard functions...
});
```

#### Role Management (6)
```typescript
describe('Role Management', () => {
  it('assignRole - should grant admin role', async () => {
    // Input: { userId, role: 'admin' }
    // Expected: User role updated, logged to audit
  });

  it('createAdminInvite - should generate invite code', async () => {
    // Expected: Unique code, 7-day expiration
  });

  // 4 more role functions...
});
```

#### User Management (10)
```typescript
describe('User Management', () => {
  it('suspendUser - should suspend account', async () => {
    // Input: { userId, reason, duration: 7 }
    // Expected: Account suspended for 7 days
  });

  it('banUser - should permanently ban user', async () => {
    // Input: { userId, permanent: true }
    // Expected: User banned, all content hidden
  });

  // 8 more user management functions...
});
```

#### Moderation Queue (6)
```typescript
describe('Moderation Queue', () => {
  it('getModerationQueue - should list pending reports', async () => {
    // Input: { status: 'pending', limit: 50 }
    // Expected: List of pending reports
  });

  it('processReport - should take action on report', async () => {
    // Input: { reportId, action: 'ban' }
    // Expected: User banned, report resolved
  });

  // 4 more moderation functions...
});
```

---

### 12. Analytics Service (22 functions)

#### Event Tracking (2)
```typescript
describe('Event Tracking', () => {
  it('trackEvent - should log event to BigQuery', async () => {
    // Input: { eventName: 'button_click', eventData }
    // Expected: Event in BigQuery table
  });

  it('autoTrackUserEvent - should auto-log signup', async () => {
    // Trigger: User document created
    // Expected: user_signup event in BigQuery
  });
});
```

#### Revenue Analytics (2)
```typescript
describe('Revenue Analytics', () => {
  it('getRevenueDashboard - should query BigQuery', async () => {
    // Expected: Daily subscription + coin revenue
  });

  it('getMRRTrends - should calculate MRR by month', async () => {
    // Expected: Monthly recurring revenue trend
  });
});
```

#### Churn Prediction (3)
```typescript
describe('Churn Prediction', () => {
  it('predictChurn - should calculate churn risk', async () => {
    // Factors: inactivity, low engagement, no matches
    // Expected: Churn score 0-100
  });

  it('scheduledChurnPrediction - should run daily', async () => {
    // Expected: All users analyzed, high-risk flagged
  });
});
```

#### A/B Testing (4)
```typescript
describe('A/B Testing', () => {
  it('createABTest - should create test', async () => {
    // Input: { name, variants: [control, variant_a] }
    // Expected: Test created, status: active
  });

  it('assignABTestVariant - should assign randomly by weight', async () => {
    // Weights: control 50%, variant_a 50%
    // Expected: ~50% distribution over 100 users
  });

  it('getABTestResults - should show variant counts', async () => {
    // Expected: control: 45, variant_a: 55
  });
});
```

**Remaining 11 functions:**
- getCohortAnalysis, getRetentionRates, getChurnRiskSegment
- endABTest, getUserMetrics, getEngagementMetrics, getConversionMetrics
- getMatchQualityMetrics, createUserSegment, getUserSegments
- getUsersInSegment, updateSegmentCriteria, deleteUserSegment

---

## Integration Tests

### User Onboarding Flow
```typescript
describe('User Onboarding Flow', () => {
  it('should complete full onboarding', async () => {
    // 1. User signs up (Analytics: track event)
    // 2. Upload profile photo (Media: compress image)
    // 3. Complete profile (Gamification: grant 50 XP)
    // 4. Send welcome email (Notification: welcome series)
    // 5. Get first match (Gamification: achievement unlocked)
    // Expected: All systems working together
  });
});
```

### Subscription Lifecycle
```typescript
describe('Subscription Lifecycle', () => {
  it('should handle full subscription lifecycle', async () => {
    // 1. Purchase Silver subscription (Subscription: verify IAP)
    // 2. Grant 100 monthly coins (Coins: monthly allowance)
    // 3. Subscription expires (Subscription: webhook)
    // 4. Grace period starts (Subscription: 7 days)
    // 5. User re-subscribes (Subscription: renewal)
    // Expected: Proper tier management throughout
  });
});
```

### Content Moderation Flow
```typescript
describe('Content Moderation Flow', () => {
  it('should moderate and ban user', async () => {
    // 1. User uploads inappropriate photo (Safety: moderate photo)
    // 2. Photo flagged by AI (Safety: adult content detected)
    // 3. Other user reports (Safety: submit report)
    // 4. Moderator reviews (Admin: process report)
    // 5. User banned (Admin: ban user)
    // 6. User appeals (Safety: submit appeal)
    // Expected: Full moderation workflow
  });
});
```

---

## Running Tests

### Run All Tests
```bash
npm test
```

### Run Specific Service
```bash
npm run test:service -- media
npm run test:service -- admin
```

### Run with Coverage
```bash
npm run test:coverage
```

### Watch Mode
```bash
npm run test:watch
```

### Integration Tests Only
```bash
npm run test:integration
```

---

## Coverage Goals

- **Unit Tests**: 143/143 functions (100%)
- **Code Coverage**: >70% lines, branches, functions
- **Integration Tests**: 10+ end-to-end flows
- **Performance Tests**: All scheduled functions

---

## Test Best Practices

1. **Mock External Services**: Always mock GCP APIs, Firebase services
2. **Use Realistic Data**: Use mock-data.ts generators
3. **Test Edge Cases**: Empty arrays, null values, boundary conditions
4. **Verify Side Effects**: Check database updates, notifications sent
5. **Clean Up**: Reset mocks between tests
6. **Async Handling**: Use async/await, not callbacks
7. **Descriptive Names**: Test names should describe what's being tested
8. **Arrange-Act-Assert**: Structure tests clearly
9. **One Assertion Per Test**: Keep tests focused
10. **Run Locally**: Test in emulator before deploying

---

## CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Test Functions

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'
      - run: npm install
      - run: npm test
      - run: npm run test:coverage
      - uses: codecov/codecov-action@v2
```

---

## Test Metrics

Once all tests are implemented:
- **Total Tests**: 500+ test cases
- **Test Files**: 15+ files
- **Coverage**: 70%+ across all services
- **Execution Time**: <5 minutes
- **Mock Services**: 10+ GCP services mocked

---

**Status**: Test framework complete, ready for full implementation
**Next Steps**: Implement all test cases following patterns above
