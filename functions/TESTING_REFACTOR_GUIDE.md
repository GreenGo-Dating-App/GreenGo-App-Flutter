# Cloud Functions Testing Refactor Guide

## Problem

The current test suite tries to test Firebase Cloud Functions (wrapped with `onCall`, `onSchedule`, etc.) directly, which doesn't work because these wrappers expect specific Firebase context and structure.

## Solution

Extract business logic into separate handler functions that can be unit tested independently of the Cloud Function wrappers.

## Refactoring Pattern

### Step 1: Create a Handlers File

Create `src/<service>/handlers.ts` for each service to contain testable business logic.

**Example: `src/gamification/handlers.ts`**

```typescript
import { db, FieldValue, logInfo, logError } from '../shared/utils';

export interface GrantXPParams {
  uid: string;
  action: string;
  metadata?: any;
}

export interface GrantXPResult {
  success: boolean;
  xpGained: number;
  // ... other return fields
}

/**
 * Business logic for granting XP - testable function
 */
export async function handleGrantXP(params: GrantXPParams): Promise<GrantXPResult> {
  const { uid, action, metadata } = params;

  // All business logic here
  // ...

  return {
    success: true,
    xpGained,
    // ...
  };
}
```

### Step 2: Update Cloud Function to Use Handler

Modify the Cloud Function in `index.ts` to be a thin wrapper:

**Before:**
```typescript
export const grantXP = onCall<GrantXPRequest>(async (request) => {
  try {
    const uid = await verifyAuth(request.auth);
    const { action, metadata } = request.data;

    // 100+ lines of business logic here

    return { success: true, ... };
  } catch (error) {
    throw handleError(error);
  }
});
```

**After:**
```typescript
import { handleGrantXP } from './handlers';

export const grantXP = onCall<GrantXPRequest>(async (request) => {
  try {
    const uid = await verifyAuth(request.auth);
    const { action, metadata } = request.data;

    return await handleGrantXP({ uid, action, metadata });
  } catch (error) {
    logError('Error granting XP:', error);
    throw handleError(error);
  }
});
```

### Step 3: Update Tests to Test Handlers

**Before:**
```typescript
it('should grant XP for valid action', async () => {
  const mockRequest = {
    data: { action: 'first_message' },
    ...createMockAuthContext('user-123'),
  };

  const { grantXP } = require('../../src/gamification');
  const result = await grantXP(mockRequest);  // ❌ Doesn't work - wrapped function

  expect(result.success).toBe(true);
});
```

**After:**
```typescript
it('should grant XP for valid action', async () => {
  // Setup mocks for Firestore, etc.
  const mockDocRef = {
    get: jest.fn().mockResolvedValue(mockGamificationDoc),
    set: jest.fn(),
  };

  const { handleGrantXP } = require('../../src/gamification/handlers');

  const result = await handleGrantXP({
    uid: 'user-123',
    action: 'first_message',
    metadata: {},
  });  // ✅ Works - pure function

  expect(result.success).toBe(true);
  expect(result.xpGained).toBe(25);
});
```

## Benefits of This Approach

1. **Unit Testable**: Business logic is in pure functions that can be tested directly
2. **Clean Separation**: Cloud Function concerns (auth, error handling) separated from business logic
3. **Reusable**: Handlers can be called from multiple Cloud Functions or other parts of the codebase
4. **Easier to Mock**: No need to mock Firebase Functions infrastructure
5. **Better Type Safety**: Explicit input/output types for handlers

## Implementation Checklist

For each service, follow this process:

- [ ] **Safety Service** (11 functions)
  - [ ] Create `src/safety/handlers.ts`
  - [ ] Extract handlers for: moderatePhoto, moderateText, detectSpam, detectFakeProfile, detectScam, submitReport, reviewReport, submitAppeal, blockUser, unblockUser, getBlockList
  - [ ] Update `src/safety/index.ts` to use handlers
  - [ ] Update `__tests__/unit/safety.test.ts` to test handlers

- [ ] **Backup Service** (4 functions)
  - [ ] Create `src/backup/handlers.ts`
  - [ ] Extract handlers for: createBackup, restoreBackup, deleteBackup, exportToPDF
  - [ ] Update index and tests

- [ ] **Messaging Service** (12 functions)
  - [ ] Create `src/messaging/handlers.ts`
  - [ ] Extract handlers for all 12 messaging functions
  - [ ] Update index and tests

- [ ] **Notification Service** (8 functions)
  - [ ] Create `src/notification/handlers.ts`
  - [ ] Extract handlers for all 8 notification functions
  - [ ] Update index and tests

- [ ] **Security Service** (8 functions)
  - [ ] Create `src/security/handlers.ts`
  - [ ] Extract handlers for all 8 security functions
  - [ ] Update index and tests

- [x] **Gamification Service** (8 functions) - **STARTED**
  - [x] Created `src/gamification/handlers.ts`
  - [x] Extracted `handleGrantXP` as example
  - [x] Updated `grantXP` Cloud Function to use handler
  - [ ] Extract remaining 7 handlers
  - [ ] Update all tests to test handlers

- [ ] **Media Service** (9 functions)
  - [ ] Create `src/media/handlers.ts`
  - [ ] Extract handlers for all 9 media functions
  - [ ] Update index and tests

- [ ] **Video Service** (21 functions)
  - [ ] Create `src/video/handlers.ts`
  - [ ] Extract handlers for all 21 video functions
  - [ ] Update index and tests

- [ ] **Admin Service** (31 functions)
  - [ ] Create `src/admin/handlers.ts`
  - [ ] Extract handlers for all 31 admin functions
  - [ ] Update index and tests

- [ ] **Analytics Service** (22 functions)
  - [ ] Create `src/analytics/handlers.ts`
  - [ ] Extract handlers for all 22 analytics functions
  - [ ] Update index and tests

## Example: Complete Refactoring

See `src/gamification/handlers.ts` for a working example of:
- `handleGrantXP` - Extracted business logic
- Helper functions like `calculateLevel` and `calculateLevelRewards`
- Proper TypeScript types for params and returns

See `src/gamification/index.ts` line 167-183 for the refactored Cloud Function wrapper.

See `__tests__/unit/gamification.test.ts` line 74-119 for the updated test pattern.

## Notes

- **Authentication**: `verifyAuth` stays in the Cloud Function wrapper
- **Error Handling**: Basic try/catch in wrapper, specific errors in handlers
- **Logging**: Can be in both places - wrapper logs function calls, handlers log details
- **Transactions**: Firestore transactions stay in handlers since they contain business logic
- **Config/Constants**: Can be exported from handlers file if needed for testing

## Testing Strategy

1. **Unit Tests**: Test handlers with mocked Firestore/services (what we're implementing)
2. **Integration Tests**: Test Cloud Functions with Firebase emulator (future enhancement)
3. **E2E Tests**: Test via actual API calls in staging environment (future enhancement)

Current focus is on getting comprehensive unit test coverage using the handler pattern.
