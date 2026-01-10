# Gamification Service Refactoring Checklist

## Status: 1/8 Functions Complete (12.5%)

### ✅ Completed
- [x] `handleGrantXP` - Extracted and tested

### ⏳ Remaining (Est. 2-3 hours)

---

## Function 2: Track Achievement Progress

### Step 1: Add to handlers.ts
```typescript
export interface TrackAchievementParams {
  uid: string;
  achievementId: string;
  progress: number;
}

export const ACHIEVEMENTS = {
  first_match: { name: 'First Match', xpReward: 50, coinReward: 10, icon: 'heart' },
  social_butterfly: { name: 'Social Butterfly', xpReward: 100, coinReward: 25, icon: 'chat', target: 100 },
  // ... copy all achievements from index.ts
} as const;

export async function handleTrackAchievementProgress(params: TrackAchievementParams) {
  // Copy logic from index.ts lines 194-252
}
```

### Step 2: Update Cloud Function in index.ts
```typescript
export const trackAchievementProgress = onCall<TrackAchievementProgressRequest>(
  { memory: '256MiB', timeoutSeconds: 60 },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      return await handleTrackAchievementProgress({
        uid,
        achievementId: request.data.achievementId,
        progress: request.data.progress,
      });
    } catch (error) {
      logError('Error tracking achievement:', error);
      throw handleError(error);
    }
  }
);
```

### Step 3: Update Test
Find test around line 320 in gamification.test.ts and update:
```typescript
const { handleTrackAchievementProgress } = require('../../src/gamification/handlers');
const result = await handleTrackAchievementProgress({
  uid: 'user-123',
  achievementId: 'first_match',
  progress: 1,
});
```

---

## Function 3: Unlock Achievement Reward

### Step 1: Add to handlers.ts
```typescript
export interface UnlockAchievementParams {
  uid: string;
  achievementId: string;
}

export async function handleUnlockAchievementReward(params: UnlockAchievementParams) {
  // Copy logic from index.ts lines 268-338
}
```

### Step 2: Update Cloud Function
```typescript
export const unlockAchievementReward = onCall<UnlockAchievementRewardRequest>(
  { memory: '256MiB', timeoutSeconds: 60 },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      return await handleUnlockAchievementReward({
        uid,
        achievementId: request.data.achievementId,
      });
    } catch (error) {
      logError('Error unlocking reward:', error);
      throw handleError(error);
    }
  }
);
```

### Step 3: Update Test (around line 380)

---

## Function 4: Claim Level Rewards

### Step 1: Add to handlers.ts
```typescript
export interface ClaimLevelParams {
  uid: string;
  level: number;
}

export async function handleClaimLevelRewards(params: ClaimLevelParams) {
  // Copy logic from index.ts lines 349-440
}
```

### Step 2: Update Cloud Function
### Step 3: Update Test (around line 450)

---

## Function 5: Track Challenge Progress

### Step 1: Add to handlers.ts
```typescript
export const DAILY_CHALLENGES = [
  { id: 'send_5_messages', name: 'Conversation Starter', target: 5, xpReward: 20, coinReward: 5 },
  // ... copy all challenges
] as const;

export interface TrackChallengeParams {
  uid: string;
  challengeId: string;
  progress: number;
}

export async function handleTrackChallengeProgress(params: TrackChallengeParams) {
  // Copy logic from index.ts lines 515-598
}
```

### Step 2: Update Cloud Function
### Step 3: Update Test (around line 520)

---

## Function 6: Claim Challenge Reward

### Step 1: Add to handlers.ts
```typescript
export interface ClaimChallengeParams {
  uid: string;
  challengeId: string;
}

export async function handleClaimChallengeReward(params: ClaimChallengeParams) {
  // Copy logic from index.ts lines 600-689
}
```

### Step 2: Update Cloud Function
### Step 3: Update Test (around line 610)

---

## Function 7: Reset Daily Challenges

**Note:** This is a scheduled function, not callable

### Step 1: Add to handlers.ts
```typescript
export async function handleResetDailyChallenges() {
  // Copy logic from index.ts lines 691-759
  // No uid parameter needed - runs for all users
}
```

### Step 2: Update Cloud Function
```typescript
export const resetDailyChallenges = onSchedule(
  { schedule: '0 0 * * *', timeZone: 'UTC' },
  async () => {
    try {
      await handleResetDailyChallenges();
    } catch (error) {
      logError('Error resetting challenges:', error);
    }
  }
);
```

### Step 3: Update Test (around line 750)
- No request object needed
- Call handler directly

---

## Function 8: Update Leaderboard Rankings

**Note:** This is a scheduled function

### Step 1: Add to handlers.ts
```typescript
export async function handleUpdateLeaderboardRankings() {
  // Copy logic from index.ts lines 761-end
}
```

### Step 2: Update Cloud Function
```typescript
export const updateLeaderboardRankings = onSchedule(
  { schedule: '0 */6 * * *', timeZone: 'UTC' },
  async () => {
    try {
      await handleUpdateLeaderboardRankings();
    } catch (error) {
      logError('Error updating leaderboard:', error);
    }
  }
);
```

### Step 3: Update Test (around line 850)

---

## Testing Commands

After each function:
```bash
# Test specific function
npm test -- gamification.test --testNamePattern="function name"

# Test entire file
npm test -- gamification.test

# Run with coverage
npm run test:coverage -- gamification.test
```

---

## Common Patterns

### Extracting Handler
1. Copy business logic from Cloud Function
2. Create interface for parameters
3. Add TypeScript types for return value
4. Move constants if needed

### Updating Cloud Function
1. Import handler at top
2. Keep only: verifyAuth, extract params, call handler
3. Keep error handling wrapper

### Updating Test
1. Change import from `../../src/gamification` to `../../src/gamification/handlers`
2. Remove `mockRequest` object
3. Call handler with plain object params
4. Remove `verifyAuth` expectations (that's in wrapper, not handler)

---

## Validation

After completing all 8 functions:

```bash
cd "C:\Users\Software Engineering\GreenGo App\GreenGo-App-Flutter\functions"
npm test -- gamification.test
```

**Expected Result:** All 35 tests passing ✅

---

## Time Estimates

- Function 2-6 (callable functions): ~20 min each = 1.5 hours
- Function 7-8 (scheduled functions): ~15 min each = 30 min
- Testing and fixes: 30 min
- **Total: 2-2.5 hours**

---

## Next Service After Gamification

Once gamification is 100% passing, apply same pattern to:

1. **Safety Service** (High Priority) - 11 functions
2. **Messaging Service** (High Priority) - 12 functions
3. **Video Service** (High Priority) - 21 functions
4. Others as prioritized

Each service follows the exact same 3-step pattern demonstrated here.
