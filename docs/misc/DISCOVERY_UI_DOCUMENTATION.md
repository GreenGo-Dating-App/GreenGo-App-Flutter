# Discovery & Swipe UI - Implementation Documentation

## Overview

The Discovery & Swipe UI layer provides users with an intuitive interface to browse potential matches, make swipe decisions, view match details, and manage their matches. This is the primary user-facing feature for the dating experience.

**Implementation Date:** 2025-11-15
**Status:** ✅ Complete
**Points Completed:** 71-80 (Backend + UI Layer)

## Architecture

### Tech Stack
- **Framework:** Flutter with Material Design
- **State Management:** BLoC Pattern (Business Logic Component)
- **Navigation:** MaterialPageRoute with bottom navigation
- **Animations:** AnimationController, CurvedAnimation, GestureDetector
- **Dependency Injection:** GetIt service locator

### Feature Structure

```
lib/features/
├── discovery/
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── match.dart                    # Match entity
│   │   │   ├── swipe_action.dart             # Swipe action types
│   │   │   └── discovery_card.dart           # Card representation
│   │   ├── repositories/
│   │   │   └── discovery_repository.dart     # Repository contract
│   │   └── usecases/
│   │       ├── get_discovery_stack.dart      # Load candidates
│   │       ├── record_swipe.dart             # Record swipe actions
│   │       └── get_matches.dart              # Fetch user matches
│   ├── data/
│   │   ├── models/
│   │   │   ├── match_model.dart
│   │   │   └── swipe_action_model.dart
│   │   ├── datasources/
│   │   │   └── discovery_remote_datasource.dart
│   │   └── repositories/
│   │       └── discovery_repository_impl.dart
│   └── presentation/
│       ├── bloc/
│       │   ├── discovery_bloc.dart           # Discovery state management
│       │   ├── discovery_event.dart
│       │   ├── discovery_state.dart
│       │   ├── matches_bloc.dart             # Matches list management
│       │   ├── matches_event.dart
│       │   └── matches_state.dart
│       ├── screens/
│       │   ├── discovery_screen.dart         # Main swipe interface
│       │   ├── matches_screen.dart           # Matches list
│       │   ├── profile_detail_screen.dart    # Full profile view
│       │   └── discovery_preferences_screen.dart # Preferences
│       └── widgets/
│           ├── swipe_card.dart               # Swipeable card widget
│           ├── swipe_buttons.dart            # Action buttons
│           ├── match_notification.dart       # Match popup
│           └── match_card_widget.dart        # Match list item
├── main/
│   └── presentation/
│       └── screens/
│           └── main_navigation_screen.dart   # Bottom navigation
└── matching/
    └── domain/
        └── entities/
            └── match_preferences.dart        # Preference filters
```

## Features Implementation

### 1. Discovery Screen (`discovery_screen.dart`)

**Purpose:** Main interface for browsing and swiping through potential matches.

**Key Features:**
- Card stack with current + next card visible
- Swipe gestures (left/right/up)
- Action buttons (Pass/Like/SuperLike)
- Settings and preferences access
- Match notification on mutual like
- Empty state with preference adjustment
- Loading and error states

**BLoC Integration:**
```dart
BlocProvider(
  create: (context) => di.sl<DiscoveryBloc>()
    ..add(DiscoveryStackLoadRequested(
      userId: userId,
      preferences: MatchPreferences.defaultFor(userId),
    )),
  child: _DiscoveryScreenContent(userId: userId),
);
```

**State Management:**
- `DiscoveryLoading` → Show loading spinner
- `DiscoveryLoaded` → Display card stack
- `DiscoverySwiping` → Disable interactions during swipe
- `DiscoverySwipeCompleted` → Check for match, show notification
- `DiscoveryStackEmpty` → Show empty state with preferences button
- `DiscoveryError` → Show error with retry

**Navigation:**
- Settings icon → `DiscoveryPreferencesScreen`
- Tap on card → `ProfileDetailScreen`
- Match created → `MatchNotification` dialog

**File Location:** `lib/features/discovery/presentation/screens/discovery_screen.dart` (382 lines)

---

### 2. Swipe Card Widget (`swipe_card.dart`)

**Purpose:** Interactive card component with drag-to-swipe animations.

**Key Features:**
- Pan gesture detection for drag interactions
- Rotation animation based on drag position
- Visual overlays (LIKE/NOPE/SUPER LIKE)
- Automatic animation when swiped off screen
- Match percentage badge
- Profile photo carousel indicator
- Tap to view full profile

**Gesture Handling:**
```dart
GestureDetector(
  onPanStart: _onPanStart,
  onPanUpdate: _onPanUpdate,
  onPanEnd: _onPanEnd,
  onTap: widget.onTap,
  child: Transform.rotate(
    angle: _angle,
    child: Transform.translate(
      offset: _position,
      child: Container(...),
    ),
  ),
)
```

**Swipe Direction Detection:**
```dart
if (_position.dx.abs() > screenWidth * 0.4) {
  direction = _position.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
} else if (_position.dy < -100) {
  direction = SwipeDirection.up;
}
```

**Animations:**
- `_position` offset for drag translation
- `_angle` for card rotation (-0.3 to 0.3 radians)
- Off-screen animation on swipe completion
- Reset animation on insufficient swipe

**File Location:** `lib/features/discovery/presentation/widgets/swipe_card.dart` (329 lines)

---

### 3. Match Notification (`match_notification.dart`)

**Purpose:** Animated popup dialog shown when a mutual match is created.

**Key Features:**
- Scale + fade animations
- Profile photo display
- "It's a Match!" celebration message
- Two action buttons:
  - **Send Message** → Navigate to chat (TODO: Points 81-100)
  - **Keep Swiping** → Dismiss and continue
- Non-dismissible (must choose action)

**Animations:**
```dart
AnimationController(
  duration: const Duration(milliseconds: 600),
  vsync: this,
);

_scaleAnimation = CurvedAnimation(
  parent: _controller,
  curve: Curves.elasticOut,
);

_fadeAnimation = CurvedAnimation(
  parent: _controller,
  curve: Curves.easeIn,
);
```

**Usage:**
```dart
showMatchNotification(
  context,
  matchedProfile: profile,
  onKeepSwiping: () {},
  onSendMessage: () {},
);
```

**File Location:** `lib/features/discovery/presentation/widgets/match_notification.dart` (218 lines)

---

### 4. Matches Screen (`matches_screen.dart`)

**Purpose:** Displays user's matches in a scrollable list with new/all sections.

**Key Features:**
- Separated "New Matches" section with gold styling
- "All Matches" section
- Pull-to-refresh functionality
- Unread count indicators
- Auto-mark as seen on tap
- Loading/Error/Empty states
- Efficient scrolling with Slivers

**BLoC Integration:**
```dart
BlocProvider(
  create: (context) => di.sl<MatchesBloc>()
    ..add(MatchesLoadRequested(userId: userId)),
  child: _MatchesScreenContent(userId: userId),
);
```

**State Management:**
- `MatchesLoading` → Show loading spinner
- `MatchesLoaded` → Display match lists
- `MatchesEmpty` → Show empty state
- `MatchesError` → Show error with retry

**List Sections:**
```dart
CustomScrollView(
  slivers: [
    // New Matches section
    if (newMatches.isNotEmpty) ...[
      SliverToBoxAdapter(/* Header */),
      SliverList(/* New matches */),
      SliverToBoxAdapter(/* Divider */),
    ],

    // All Matches section
    SliverToBoxAdapter(/* Header */),
    SliverList(/* All matches */),
  ],
)
```

**File Location:** `lib/features/discovery/presentation/screens/matches_screen.dart` (284 lines)

---

### 5. Profile Detail Screen (`profile_detail_screen.dart`)

**Purpose:** Full-screen profile view with photos, bio, interests, and details.

**Key Features:**
- Photo carousel with page indicators
- Profile information (name, age, location)
- Bio section
- Interest chips
- Additional details (height, education, occupation)
- Match badge if already matched
- Swipe action buttons (if not matched)
- Gradient overlay on photos

**Photo Carousel:**
```dart
PageView.builder(
  controller: _pageController,
  onPageChanged: (index) {
    setState(() {
      _currentPhotoIndex = index;
    });
  },
  itemCount: profile.photoUrls.length,
  itemBuilder: (context, index) {
    return Image.network(profile.photoUrls[index]);
  },
)
```

**Action Buttons:**
```dart
if (!isMatched && widget.onSwipe != null)
  Positioned(
    bottom: 24,
    child: SwipeButtons(
      onPass: () {
        widget.onSwipe!(SwipeActionType.pass);
        Navigator.pop();
      },
      onLike: () {
        widget.onSwipe!(SwipeActionType.like);
        Navigator.pop();
      },
      onSuperLike: () {
        widget.onSwipe!(SwipeActionType.superLike);
        Navigator.pop();
      },
    ),
  )
```

**File Location:** `lib/features/discovery/presentation/screens/profile_detail_screen.dart` (356 lines)

---

### 6. Discovery Preferences Screen (`discovery_preferences_screen.dart`)

**Purpose:** Configure match discovery preferences and filters.

**Key Features:**
- Age range slider (18-100)
- Maximum distance slider (1-200 km) or unlimited
- Gender preference (Men/Women/Everyone)
- Advanced filters:
  - Only verified profiles
  - Recently active (last 7 days)
- Deal breakers management
- Reset to default button
- Save button in app bar

**Preference Controls:**
```dart
RangeSlider(
  values: RangeValues(minAge.toDouble(), maxAge.toDouble()),
  min: 18,
  max: 100,
  divisions: 82,
  onChanged: (values) {
    _updatePreferences(preferences.copyWith(
      minAge: values.start.toInt(),
      maxAge: values.end.toInt(),
    ));
  },
)
```

**Save Callback:**
```dart
DiscoveryPreferencesScreen(
  userId: userId,
  currentPreferences: preferences,
  onSave: (newPreferences) {
    context.read<DiscoveryBloc>().add(
      DiscoveryStackRefreshRequested(
        userId: userId,
        preferences: newPreferences,
      ),
    );
  },
)
```

**File Location:** `lib/features/discovery/presentation/screens/discovery_preferences_screen.dart` (362 lines)

---

### 7. Main Navigation Screen (`main_navigation_screen.dart`)

**Purpose:** Bottom navigation with Discovery, Matches, and Profile tabs.

**Key Features:**
- 3 main tabs with icons and labels
- IndexedStack for preserving tab state
- Gold accent color for active tab
- Dark theme styling

**Navigation Structure:**
```dart
IndexedStack(
  index: _currentIndex,
  children: [
    DiscoveryScreen(userId: userId),
    MatchesScreen(userId: userId),
    EditProfileScreen(userId: userId),
  ],
)

BottomNavigationBar(
  items: [
    BottomNavigationBarItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Discover',
    ),
    BottomNavigationBarItem(
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite,
      label: 'Matches',
    ),
    BottomNavigationBarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ],
)
```

**Integration with Auth:**
```dart
// In main.dart AuthWrapper
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthAuthenticated) {
      return MainNavigationScreen(userId: state.user.uid);
    }
    // ...
  },
)
```

**File Location:** `lib/features/main/presentation/screens/main_navigation_screen.dart` (72 lines)

---

## BLoC State Management

### Discovery BLoC

**Events:**
```dart
DiscoveryStackLoadRequested(userId, preferences)
DiscoverySwipeRecorded(userId, targetUserId, actionType)
DiscoveryStackRefreshRequested(userId, preferences)
DiscoveryMoreCandidatesRequested(userId, preferences)
```

**States:**
```dart
DiscoveryInitial()
DiscoveryLoading()
DiscoveryLoaded(cards, currentIndex)
DiscoverySwiping(cards, currentIndex)
DiscoverySwipeCompleted(cards, currentIndex, createdMatch)
DiscoveryMatchCreated(match, remainingCards, currentIndex)
DiscoveryStackEmpty()
DiscoveryError(message)
```

**Key Flows:**
1. **Load Stack:** Get candidates from repository → Filter swiped users → Create cards
2. **Record Swipe:** Emit swiping state → Call API → Check for match → Update state
3. **Match Created:** Emit completed state → Show notification → Transition to loaded/empty

---

### Matches BLoC

**Events:**
```dart
MatchesLoadRequested(userId, activeOnly)
MatchesRefreshRequested(userId)
MatchMarkedAsSeen(matchId, userId)
MatchUnmatchRequested(matchId, userId)
```

**States:**
```dart
MatchesInitial()
MatchesLoading()
MatchesLoaded(matches, profiles, lastUpdated)
MatchesEmpty()
MatchesError(message)
```

**Key Flows:**
1. **Load Matches:** Fetch matches from repository → Fetch profiles → Emit loaded state
2. **Mark Seen:** Update Firestore → Emit updated state
3. **Refresh:** Reload matches → Update UI

---

## User Flows

### Discovery Flow
1. User opens app → MainNavigationScreen → Discovery tab active
2. DiscoveryScreen loads → Shows loading spinner
3. DiscoveryBloc fetches candidates → Displays card stack
4. User can:
   - **Swipe left** → Pass (record swipe, move to next card)
   - **Swipe right** → Like (record swipe, check for match)
   - **Swipe up** → Super Like (record swipe, check for match)
   - **Tap card** → View ProfileDetailScreen
   - **Tap settings** → Adjust preferences
5. If match created → Show MatchNotification popup
6. If stack empty → Show empty state with preference adjustment

### Match Viewing Flow
1. User taps Matches tab → MatchesScreen loads
2. New matches shown at top with gold styling
3. All matches shown below
4. User taps match → ProfileDetailScreen opens
5. Match marked as seen automatically
6. User can view profile details, photos, bio

### Profile Detail Flow
1. From Discovery or Matches → ProfileDetailScreen
2. Swipe through photos with page indicators
3. Read bio, interests, details
4. If from Discovery (not matched):
   - Swipe buttons visible at bottom
   - User can like/pass/superlike
5. If from Matches (already matched):
   - Match badge shown
   - "Send Message" option (TODO: Points 81-100)

---

## Firestore Integration

### Collections Used

**swipes:**
```javascript
{
  userId: string,
  targetUserId: string,
  actionType: 'like' | 'pass' | 'superLike',
  timestamp: DateTime,
  createdMatch: boolean
}
```

**matches:**
```javascript
{
  matchId: string,
  userId1: string,
  userId2: string,
  matchedAt: DateTime,
  isActive: boolean,
  user1Seen: boolean,
  user2Seen: boolean,
  lastMessageAt: DateTime?,
  lastMessage: string?
}
```

**Composite Indexes:**
```json
[
  {
    "collectionGroup": "swipes",
    "fields": [
      { "fieldPath": "userId", "order": "ASCENDING" },
      { "fieldPath": "timestamp", "order": "DESCENDING" }
    ]
  },
  {
    "collectionGroup": "swipes",
    "fields": [
      { "fieldPath": "userId", "order": "ASCENDING" },
      { "fieldPath": "targetUserId", "order": "ASCENDING" }
    ]
  },
  {
    "collectionGroup": "swipes",
    "fields": [
      { "fieldPath": "targetUserId", "order": "ASCENDING" },
      { "fieldPath": "actionType", "order": "ASCENDING" }
    ]
  }
]
```

---

## Animations & UX Polish

### Swipe Card Animation
- **Drag:** Real-time position and rotation tracking
- **Release:** Smooth animation to off-screen or reset
- **Feedback:** Color overlays (green=like, red=pass, blue=superlike)
- **Duration:** 300ms for automatic swipes

### Match Notification
- **Entry:** 600ms elastic scale + fade-in
- **Exit:** Pop navigation with fade-out
- **Emphasis:** Gold accent color, large heart icon

### List Animations
- **Pull-to-refresh:** Material Design spinner
- **Scroll:** Smooth CustomScrollView with Slivers
- **Card tap:** Ripple effect with Material InkWell

### Transitions
- **Screen navigation:** MaterialPageRoute slide transition
- **Tab switching:** IndexedStack instant swap (preserves state)

---

## Testing Checklist

### Manual Testing
- [ ] Discovery screen loads candidates
- [ ] Swipe left records pass action
- [ ] Swipe right records like action
- [ ] Swipe up records super like action
- [ ] Match notification appears on mutual like
- [ ] Match notification dismisses correctly
- [ ] Matches screen displays all matches
- [ ] New matches section separates unseen matches
- [ ] Pull-to-refresh reloads matches
- [ ] Profile detail screen shows full profile
- [ ] Photo carousel swipes correctly
- [ ] Preferences screen updates filters
- [ ] Age/distance sliders work correctly
- [ ] Gender preference radio buttons work
- [ ] Reset to default restores original preferences
- [ ] Bottom navigation switches tabs
- [ ] Tab state preserved when switching
- [ ] Empty states display correctly
- [ ] Error states show retry button
- [ ] Loading states show spinner

### Edge Cases
- [ ] Empty discovery stack
- [ ] No matches
- [ ] Profile with no photos
- [ ] Profile with missing bio/interests
- [ ] Network error during swipe
- [ ] Rapid swipes (rate limiting)
- [ ] Simultaneous match from both users

---

## Performance Considerations

### Optimizations Implemented
1. **IndexedStack** for tab preservation (no rebuild on switch)
2. **Slivers** for efficient list scrolling
3. **Image caching** with `Image.network` built-in cache
4. **BLoC state management** prevents unnecessary rebuilds
5. **Lazy loading** of candidate profiles

### Future Optimizations (TODO)
- [ ] Prefetch next 3-5 candidate profiles
- [ ] Implement image preloading for smoother UX
- [ ] Add pagination for matches list (100+ matches)
- [ ] Cache swipe history locally for offline check
- [ ] Optimize Firestore queries with limits

---

## Known Limitations & TODOs

### Current Limitations
1. **Match notification** uses placeholder profile (needs actual profile fetch)
2. **Send Message** button not functional (requires chat feature from Points 81-100)
3. **Deal breakers** selection UI not implemented (empty state only)
4. **Profile detail** doesn't show match percentage/compatibility score

### Upcoming Work (Points 81-100)
- [ ] Real-time chat messaging
- [ ] Chat list screen
- [ ] Message notifications
- [ ] Typing indicators
- [ ] Read receipts
- [ ] Match → Chat navigation
- [ ] Unread message count on Matches tab

---

## Dependencies

### Flutter Packages
```yaml
dependencies:
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  get_it: ^7.6.0
  dartz: ^0.10.1
  cloud_firestore: ^4.13.0
  firebase_core: ^2.21.0
```

### Internal Dependencies
- `core/constants/app_colors.dart` - Color scheme
- `core/constants/app_dimensions.dart` - Spacing/radius constants
- `core/di/injection_container.dart` - Dependency injection
- `features/profile/domain/entities/profile.dart` - Profile entity
- `features/matching/domain/entities/match_preferences.dart` - Preferences

---

## Code Statistics

### Files Created
- **Screens:** 4 files (1,384 lines)
- **Widgets:** 4 files (723 lines)
- **BLoCs:** 6 files (464 lines)
- **Entities:** 3 files (241 lines)
- **Repositories:** 4 files (486 lines)
- **Use Cases:** 3 files (189 lines)
- **Navigation:** 1 file (72 lines)

**Total:** 25 files, ~3,559 lines of code

### Test Coverage
- Unit tests: TODO
- Widget tests: TODO
- Integration tests: TODO

---

## Deployment Notes

### Firebase Configuration Required
1. Deploy Firestore indexes:
   ```bash
   firebase deploy --only firestore:indexes
   ```

2. Verify security rules allow:
   - Reading/writing swipes for authenticated users
   - Reading/writing matches for authenticated users
   - Reading profiles for match candidates

### App Store Screenshots
- Discovery screen with card stack
- Match notification popup
- Matches list with new/all sections
- Profile detail screen
- Preferences screen

---

## Maintenance & Support

### Common Issues

**Issue:** Discovery stack empty immediately
**Solution:** Check Firestore has user profiles with matching preferences

**Issue:** Match notification not appearing
**Solution:** Verify both users have liked each other, check BLoC listener

**Issue:** Swipe gestures not working
**Solution:** Check GestureDetector not blocked by parent widget

**Issue:** Photos not loading
**Solution:** Verify Firebase Storage URLs are public or user has access

### Monitoring

**Key Metrics:**
- Swipe rate (swipes per user per session)
- Match rate (matches per 100 swipes)
- Profile view rate (taps per swipe)
- Preference adjustment rate
- Error rate on swipe recording

**Analytics Events:**
```dart
// TODO: Add Firebase Analytics tracking
- discovery_stack_loaded
- swipe_recorded(action_type)
- match_created
- profile_viewed
- preferences_updated
```

---

## Contributors

**Primary Developer:** Claude (AI Assistant)
**Implementation Date:** 2025-11-15
**Feature Owner:** GreenGoChat Product Team
**Review Status:** Pending human review

---

## Version History

**v1.0.0** (2025-11-15)
- Initial implementation of discovery/swipe UI
- Main navigation with bottom tabs
- Profile detail screen
- Preferences screen
- Match notification popup
- Complete BLoC state management
- Firestore integration

---

## Related Documentation
- [MATCHING_ALGORITHM_DOCUMENTATION.md](MATCHING_ALGORITHM_DOCUMENTATION.md) - ML matching backend
- [PROJECT_STATUS.md](PROJECT_STATUS.md) - Overall project progress
- [README.md](README.md) - Project overview
