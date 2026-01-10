const fs = require('fs');
const path = require('path');

const fullNavMenu = `<ul class="nav-menu" id="navMenu">
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-home"></i><span>Overview</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="01-introduction.html">1. Introduction</a></li>
                    <li><a href="02-tech-stack.html">2. Tech Stack</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-sitemap"></i><span>Architecture</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="09-clean-architecture.html">9. Clean Architecture</a></li>
                    <li><a href="14-data-flow.html">14. Data Flow</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-palette"></i><span>Design System</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="21-brand-guidelines.html">21. Brand</a></li>
                    <li><a href="22-color-palette.html">22. Colors</a></li>
                    <li><a href="25-components.html">25. Components</a></li>
                </ul>
            </li>
            <li class="nav-section">
                <div class="nav-section-title"><i class="fas fa-puzzle-piece"></i><span>Core Features</span><i class="fas fa-chevron-down arrow"></i></div>
                <ul class="nav-submenu">
                    <li><a href="31-auth-flow.html">31. Auth Flow</a></li>
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
                    <li><a href="69-security-architecture.html">69. Security</a></li>
                </ul>
            </li>
        </ul>`;

const coreFeaturePages = [
    {
        file: '34-onboarding.html',
        title: 'Profile Onboarding',
        section: 'Core Features',
        content: `
            <h2>8-Step Onboarding System</h2>
            <p>Comprehensive profile creation wizard with validation, progress persistence, and ML vector generation.</p>

            <h2>Onboarding Architecture</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      ONBOARDING STATE MACHINE                                        │
└─────────────────────────────────────────────────────────────────────────────────────┘

    ┌─────┐    ┌─────┐    ┌─────┐    ┌─────┐    ┌─────┐    ┌─────┐    ┌─────┐    ┌─────┐
    │  1  │───▶│  2  │───▶│  3  │───▶│  4  │───▶│  5  │───▶│  6  │───▶│  7  │───▶│  8  │
    │Basic│    │Photo│    │ Bio │    │Inter│    │Prefs│    │Prompt│   │Goal │    │Done │
    └──┬──┘    └──┬──┘    └──┬──┘    └──┬──┘    └──┬──┘    └──┬──┘    └──┬──┘    └──┬──┘
       │          │          │          │          │          │          │          │
       ▼          ▼          ▼          ▼          ▼          ▼          ▼          ▼
   ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐
   │Name   │  │Upload │  │Bio    │  │Select │  │Age    │  │Answer │  │Select │  │Review │
   │DOB    │  │Min 2  │  │Max    │  │5-10   │  │Range  │  │2-3    │  │Goal   │  │Submit │
   │Gender │  │photos │  │500chr │  │items  │  │Dist   │  │prompts│  │Type   │  │       │
   └───────┘  └───────┘  └───────┘  └───────┘  └───────┘  └───────┘  └───────┘  └───────┘

Progress Persistence:
• Auto-save after each step completion
• Resume from last completed step on app restart
• Draft state stored in Firestore users/{uid}/onboarding_draft
            </code></pre>

            <h2>Step Data Models</h2>
            <pre><code class="language-dart">
// lib/features/onboarding/domain/entities/onboarding_data.dart

class OnboardingData {
  // Step 1: Basic Info
  final String name;
  final DateTime birthDate;
  final Gender gender;

  // Step 2: Photos
  final List<PhotoData> photos; // min 2, max 6

  // Step 3: Bio
  final String bio; // max 500 chars

  // Step 4: Interests
  final List<String> interests; // 5-10 items

  // Step 5: Preferences
  final int minAge;
  final int maxAge;
  final int maxDistance; // in km
  final List<Gender> genderPreference;

  // Step 6: Prompts
  final List<PromptAnswer> prompts; // 2-3 answers

  // Step 7: Relationship Goal
  final RelationshipGoal goal;

  // Computed
  int get completedSteps => _calculateCompletedSteps();
  bool get isComplete => completedSteps == 8;
  double get progressPercent => completedSteps / 8;
}

class PhotoData {
  final String localPath;
  final String? uploadedUrl;
  final int order;
  final bool isUploading;
  final bool isVerified;
}

class PromptAnswer {
  final String promptId;
  final String question;
  final String answer; // max 300 chars
}

enum RelationshipGoal {
  longTerm,
  shortTerm,
  casual,
  friendship,
  unsure,
}
            </code></pre>

            <h2>Onboarding BLoC Implementation</h2>
            <pre><code class="language-dart">
// lib/features/onboarding/presentation/bloc/onboarding_bloc.dart

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final SaveOnboardingStepUseCase saveStep;
  final CompleteOnboardingUseCase completeOnboarding;
  final UploadPhotoUseCase uploadPhoto;
  final GenerateMLVectorUseCase generateMLVector;

  OnboardingBloc({
    required this.saveStep,
    required this.completeOnboarding,
    required this.uploadPhoto,
    required this.generateMLVector,
  }) : super(OnboardingInitial()) {
    on<LoadOnboardingData>(_onLoadData);
    on<UpdateBasicInfo>(_onUpdateBasicInfo);
    on<AddPhoto>(_onAddPhoto);
    on<RemovePhoto>(_onRemovePhoto);
    on<ReorderPhotos>(_onReorderPhotos);
    on<UpdateBio>(_onUpdateBio);
    on<UpdateInterests>(_onUpdateInterests);
    on<UpdatePreferences>(_onUpdatePreferences);
    on<UpdatePrompts>(_onUpdatePrompts);
    on<UpdateGoal>(_onUpdateGoal);
    on<CompleteOnboarding>(_onComplete);
    on<GoToStep>(_onGoToStep);
  }

  Future<void> _onComplete(
    CompleteOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingSubmitting());

    // 1. Upload any pending photos
    final photoResults = await _uploadPendingPhotos();
    if (photoResults.hasFailure) {
      emit(OnboardingError('Failed to upload photos'));
      return;
    }

    // 2. Generate ML vector from profile data
    final vectorResult = await generateMLVector(
      GenerateMLVectorParams(
        interests: state.data.interests,
        bio: state.data.bio,
        prompts: state.data.prompts,
        goal: state.data.goal,
      ),
    );

    if (vectorResult.isLeft()) {
      emit(OnboardingError('Failed to generate profile vector'));
      return;
    }

    // 3. Save complete profile
    final result = await completeOnboarding(
      CompleteOnboardingParams(
        data: state.data,
        mlVector: vectorResult.getRight(),
        photoUrls: photoResults.urls,
      ),
    );

    result.fold(
      (failure) => emit(OnboardingError(failure.message)),
      (_) => emit(OnboardingCompleted()),
    );
  }
}

// Events
abstract class OnboardingEvent {}

class UpdateBasicInfo extends OnboardingEvent {
  final String name;
  final DateTime birthDate;
  final Gender gender;
}

class AddPhoto extends OnboardingEvent {
  final File photo;
  final int position;
}

class UpdateInterests extends OnboardingEvent {
  final List<String> interests;
}

// States
abstract class OnboardingState {
  final OnboardingData data;
  final int currentStep;
}

class OnboardingInProgress extends OnboardingState {
  final bool isSaving;
}

class OnboardingSubmitting extends OnboardingState {}
class OnboardingCompleted extends OnboardingState {}
class OnboardingError extends OnboardingState {
  final String message;
}
            </code></pre>

            <h2>Step Validation Rules</h2>
            <table>
                <thead>
                    <tr><th>Step</th><th>Field</th><th>Validation</th><th>Error Message</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td rowspan="3"><strong>1. Basic</strong></td>
                        <td>Name</td>
                        <td>2-50 chars, letters only</td>
                        <td>"Name must be 2-50 characters"</td>
                    </tr>
                    <tr>
                        <td>Birth Date</td>
                        <td>Age 18-100</td>
                        <td>"You must be at least 18"</td>
                    </tr>
                    <tr>
                        <td>Gender</td>
                        <td>Required selection</td>
                        <td>"Please select your gender"</td>
                    </tr>
                    <tr>
                        <td rowspan="2"><strong>2. Photos</strong></td>
                        <td>Count</td>
                        <td>Minimum 2 photos</td>
                        <td>"Add at least 2 photos"</td>
                    </tr>
                    <tr>
                        <td>Content</td>
                        <td>Pass moderation</td>
                        <td>"Photo violates guidelines"</td>
                    </tr>
                    <tr>
                        <td><strong>3. Bio</strong></td>
                        <td>Bio</td>
                        <td>10-500 chars</td>
                        <td>"Bio must be 10-500 characters"</td>
                    </tr>
                    <tr>
                        <td><strong>4. Interests</strong></td>
                        <td>Selection</td>
                        <td>5-10 items</td>
                        <td>"Select 5-10 interests"</td>
                    </tr>
                    <tr>
                        <td rowspan="2"><strong>5. Preferences</strong></td>
                        <td>Age range</td>
                        <td>Min < Max, both 18-100</td>
                        <td>"Invalid age range"</td>
                    </tr>
                    <tr>
                        <td>Distance</td>
                        <td>1-500 km</td>
                        <td>"Distance must be 1-500 km"</td>
                    </tr>
                    <tr>
                        <td><strong>6. Prompts</strong></td>
                        <td>Answers</td>
                        <td>2-3 prompts, 10-300 chars each</td>
                        <td>"Answer 2-3 prompts"</td>
                    </tr>
                    <tr>
                        <td><strong>7. Goal</strong></td>
                        <td>Selection</td>
                        <td>Required</td>
                        <td>"Select relationship goal"</td>
                    </tr>
                </tbody>
            </table>

            <h2>Photo Upload Pipeline</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        PHOTO UPLOAD PIPELINE                                         │
└─────────────────────────────────────────────────────────────────────────────────────┘

User              App                Storage           Function          Vision API
 │                 │                    │                 │                  │
 │ Select photo    │                    │                 │                  │
 │────────────────▶│                    │                 │                  │
 │                 │ Compress           │                 │                  │
 │                 │ (max 1MB, 1080px)  │                 │                  │
 │                 │────────┐           │                 │                  │
 │                 │◀───────┘           │                 │                  │
 │                 │                    │                 │                  │
 │                 │ Upload to Storage  │                 │                  │
 │                 │───────────────────▶│                 │                  │
 │                 │                    │ onFinalize      │                  │
 │                 │                    │────────────────▶│                  │
 │                 │                    │                 │                  │
 │                 │                    │                 │ Moderate content │
 │                 │                    │                 │─────────────────▶│
 │                 │                    │                 │                  │
 │                 │                    │                 │ Safe/Unsafe      │
 │                 │                    │                 │◀─────────────────│
 │                 │                    │                 │                  │
 │                 │                    │                 │ Generate thumbs  │
 │                 │                    │                 │ 150px, 400px     │
 │                 │                    │◀────────────────│                  │
 │                 │                    │                 │                  │
 │                 │ URL + status       │                 │                  │
 │                 │◀───────────────────│                 │                  │
 │ Photo added ✓   │                    │                 │                  │
 │◀────────────────│                    │                 │                  │
            </code></pre>

            <h2>ML Vector Generation</h2>
            <pre><code class="language-typescript">
// functions/src/ml/generateUserVector.ts

export const generateUserVector = functions.https.onCall(async (data, context) => {
  const { interests, bio, prompts, goal } = data;

  // 1. Generate interest embedding (32 dims)
  const interestVector = await embedInterests(interests);

  // 2. Generate bio embedding using NLP (32 dims)
  const bioVector = await embedText(bio);

  // 3. Generate prompt embeddings (32 dims)
  const promptVector = await embedPrompts(prompts);

  // 4. Encode relationship goal (16 dims)
  const goalVector = encodeGoal(goal);

  // 5. Personality inference from text (16 dims)
  const personalityVector = await inferPersonality(bio, prompts);

  // Concatenate all vectors (128 dims total)
  const mlVector = [
    ...interestVector,    // 32
    ...bioVector,         // 32
    ...promptVector,      // 32
    ...goalVector,        // 16
    ...personalityVector, // 16
  ];

  // Normalize vector
  const normalized = normalizeVector(mlVector);

  return { vector: normalized };
});
            </code></pre>
        `
    },
    {
        file: '38-discovery.html',
        title: 'Discovery Interface',
        section: 'Core Features',
        content: `
            <h2>Discovery System Architecture</h2>
            <p>Swipe-based card interface with preloading, gesture detection, and action overlays.</p>

            <h2>Discovery Screen Architecture</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      DISCOVERY SCREEN ARCHITECTURE                                   │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              PRESENTATION                                            │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                         DiscoveryScreen                                      │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐              │   │
│  │  │  FilterBar      │  │  CardStack      │  │  ActionBar      │              │   │
│  │  │  (age,dist)     │  │  (swipeable)    │  │  (buttons)      │              │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘              │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              BLOC LAYER                                              │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                         DiscoveryBloc                                        │   │
│  │  State: {                                                                    │   │
│  │    cards: List<MatchCandidate>,                                              │   │
│  │    currentIndex: int,                                                        │   │
│  │    isLoading: bool,                                                          │   │
│  │    filters: DiscoveryFilters,                                                │   │
│  │    dailyLikesRemaining: int,                                                 │   │
│  │    canSuperLike: bool,                                                       │   │
│  │  }                                                                           │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
                    ▼                   ▼                   ▼
         ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
         │ GetPotential    │  │ RecordSwipe     │  │ UpdateFilters   │
         │ MatchesUseCase  │  │ UseCase         │  │ UseCase         │
         └─────────────────┘  └─────────────────┘  └─────────────────┘
            </code></pre>

            <h2>Card Stack Implementation</h2>
            <pre><code class="language-dart">
// lib/features/discovery/presentation/widgets/card_stack.dart

class CardStack extends StatefulWidget {
  final List<MatchCandidate> candidates;
  final Function(MatchCandidate, SwipeDirection) onSwipe;
  final VoidCallback onStackEmpty;

  @override
  _CardStackState createState() => _CardStackState();
}

class _CardStackState extends State<CardStack> with TickerProviderStateMixin {
  late List<CardController> _controllers;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers = List.generate(
      min(3, widget.candidates.length), // Only render top 3 cards
      (i) => CardController(vsync: this),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.candidates.length) {
      return EmptyStateWidget(
        message: 'No more profiles',
        action: 'Adjust filters',
      );
    }

    return Stack(
      children: List.generate(
        min(3, widget.candidates.length - _currentIndex),
        (i) {
          final cardIndex = _currentIndex + (2 - i);
          if (cardIndex >= widget.candidates.length) return SizedBox();

          final isTop = i == 2;
          return Positioned.fill(
            child: SwipeableCard(
              key: ValueKey(widget.candidates[cardIndex].id),
              candidate: widget.candidates[cardIndex],
              controller: _controllers[i],
              isInteractive: isTop,
              stackPosition: i,
              onSwipe: (direction) => _handleSwipe(cardIndex, direction),
            ),
          );
        },
      ),
    );
  }

  void _handleSwipe(int index, SwipeDirection direction) {
    widget.onSwipe(widget.candidates[index], direction);
    setState(() {
      _currentIndex++;
    });

    // Preload more cards when running low
    if (widget.candidates.length - _currentIndex < 5) {
      context.read<DiscoveryBloc>().add(LoadMoreCandidates());
    }
  }
}

// Individual swipeable card with gesture handling
class SwipeableCard extends StatefulWidget {
  final MatchCandidate candidate;
  final CardController controller;
  final bool isInteractive;
  final int stackPosition;
  final Function(SwipeDirection) onSwipe;

  @override
  _SwipeableCardState createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard> {
  Offset _dragOffset = Offset.zero;
  double _rotation = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onPanStart: widget.isInteractive ? _onPanStart : null,
      onPanUpdate: widget.isInteractive ? _onPanUpdate : null,
      onPanEnd: widget.isInteractive ? _onPanEnd : null,
      child: Transform(
        transform: Matrix4.identity()
          ..translate(_dragOffset.dx, _dragOffset.dy)
          ..rotateZ(_rotation),
        alignment: Alignment.center,
        child: Stack(
          children: [
            // Card content
            ProfileCard(candidate: widget.candidate),

            // Like overlay (green, right side)
            Positioned.fill(
              child: Opacity(
                opacity: (_dragOffset.dx / 100).clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.withOpacity(0.8), Colors.transparent],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'LIKE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Nope overlay (red, left side)
            Positioned.fill(
              child: Opacity(
                opacity: (-_dragOffset.dx / 100).clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.withOpacity(0.8), Colors.transparent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: 0.5,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'NOPE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _rotation = _dragOffset.dx / 1000; // Subtle rotation
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine if swipe threshold met
    if (_dragOffset.dx.abs() > screenWidth * 0.4 ||
        velocity.dx.abs() > 1000) {
      // Animate out
      final direction = _dragOffset.dx > 0
          ? SwipeDirection.right
          : SwipeDirection.left;
      _animateOut(direction);
    } else if (_dragOffset.dy < -screenWidth * 0.3 ||
        velocity.dy < -1000) {
      // Super like (swipe up)
      _animateOut(SwipeDirection.up);
    } else {
      // Return to center
      _animateBack();
    }
  }

  void _animateOut(SwipeDirection direction) async {
    // Animate card off screen
    await widget.controller.animateOut(direction);
    widget.onSwipe(direction);
  }

  void _animateBack() {
    // Spring animation back to center
    setState(() {
      _dragOffset = Offset.zero;
      _rotation = 0;
    });
  }
}
            </code></pre>

            <h2>Profile Card Content</h2>
            <pre><code class="language-dart">
// lib/features/discovery/presentation/widgets/profile_card.dart

class ProfileCard extends StatelessWidget {
  final MatchCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo carousel
            PhotoCarousel(photos: candidate.photos),

            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),

            // User info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '\${candidate.name}, \${candidate.age}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (candidate.isVerified)
                          Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.verified,
                              color: AppColors.gold,
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white70, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '\${candidate.distance} km away',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      candidate.bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    // Compatibility score
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '\${candidate.compatibilityScore}% Match',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Photo indicator dots
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: PhotoIndicator(
                total: candidate.photos.length,
                current: _currentPhotoIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
            </code></pre>

            <h2>Action Bar</h2>
            <pre><code class="language-dart">
// lib/features/discovery/presentation/widgets/action_bar.dart

class DiscoveryActionBar extends StatelessWidget {
  final VoidCallback onRewind;
  final VoidCallback onPass;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;
  final VoidCallback onBoost;
  final bool canRewind;
  final bool canSuperLike;
  final int superLikesRemaining;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Rewind (Gold feature)
          ActionButton(
            icon: Icons.replay,
            size: 44,
            color: AppColors.gold,
            onPressed: canRewind ? onRewind : null,
            tooltip: 'Rewind',
          ),

          // Pass
          ActionButton(
            icon: Icons.close,
            size: 56,
            color: AppColors.error,
            onPressed: onPass,
            tooltip: 'Pass',
          ),

          // Super Like
          ActionButton(
            icon: Icons.star,
            size: 44,
            color: AppColors.superLike,
            onPressed: canSuperLike ? onSuperLike : null,
            badge: superLikesRemaining > 0 ? '\$superLikesRemaining' : null,
            tooltip: 'Super Like',
          ),

          // Like
          ActionButton(
            icon: Icons.favorite,
            size: 56,
            color: AppColors.success,
            onPressed: onLike,
            tooltip: 'Like',
          ),

          // Boost
          ActionButton(
            icon: Icons.bolt,
            size: 44,
            color: AppColors.boost,
            onPressed: onBoost,
            tooltip: 'Boost',
          ),
        ],
      ),
    );
  }
}
            </code></pre>

            <h2>Preloading Strategy</h2>
            <table>
                <thead>
                    <tr><th>Trigger</th><th>Action</th><th>Count</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Initial load</td>
                        <td>Fetch candidates</td>
                        <td>50</td>
                    </tr>
                    <tr>
                        <td>Cards remaining < 5</td>
                        <td>Fetch more</td>
                        <td>25</td>
                    </tr>
                    <tr>
                        <td>Top 3 cards</td>
                        <td>Preload images</td>
                        <td>All photos</td>
                    </tr>
                    <tr>
                        <td>Card 4-6</td>
                        <td>Preload thumbnails</td>
                        <td>First photo only</td>
                    </tr>
                </tbody>
            </table>
        `
    },
    {
        file: '39-like-actions.html',
        title: 'Like/Pass Actions',
        section: 'Core Features',
        content: `
            <h2>Swipe Actions System</h2>
            <p>Complete implementation of Like, Pass, Super Like, and Rewind actions with rate limiting and subscription checks.</p>

            <h2>Action Types</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           ACTION TYPES                                               │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│      LIKE       │  │      PASS       │  │   SUPER LIKE    │  │     REWIND      │
├─────────────────┤  ├─────────────────┤  ├─────────────────┤  ├─────────────────┤
│ Direction:Right │  │ Direction:Left  │  │ Direction: Up   │  │ Undo last swipe │
│ Creates swipe   │  │ Creates swipe   │  │ Creates swipe   │  │ Removes swipe   │
│ Checks match    │  │ No match check  │  │ Notifies user   │  │ Returns card    │
│                 │  │                 │  │ Priority queue  │  │                 │
│ Limits:         │  │ Limits:         │  │ Limits:         │  │ Limits:         │
│ Basic: 100/day  │  │ Unlimited       │  │ Basic: 1/day    │  │ Gold only       │
│ Silver: Unlim   │  │                 │  │ Silver: 5/day   │  │ 1 per swipe     │
│ Gold: Unlimited │  │                 │  │ Gold: 5/day     │  │                 │
└─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘
            </code></pre>

            <h2>Swipe Recording Flow</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        SWIPE RECORDING SEQUENCE                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘

Client            BLoC              UseCase          Repository        Function
  │                │                   │                 │                │
  │ Swipe Right    │                   │                 │                │
  │───────────────▶│                   │                 │                │
  │                │                   │                 │                │
  │                │ Check limits      │                 │                │
  │                │────────┐          │                 │                │
  │                │◀───────┘          │                 │                │
  │                │                   │                 │                │
  │                │ RecordSwipe       │                 │                │
  │                │──────────────────▶│                 │                │
  │                │                   │ recordSwipe()   │                │
  │                │                   │────────────────▶│                │
  │                │                   │                 │ Callable       │
  │                │                   │                 │───────────────▶│
  │                │                   │                 │                │
  │                │                   │                 │ 1. Create doc  │
  │                │                   │                 │ 2. Check match │
  │                │                   │                 │ 3. Update stats│
  │                │                   │                 │ 4. Award XP    │
  │                │                   │                 │                │
  │                │                   │   SwipeResult   │                │
  │                │                   │◀────────────────│◀───────────────│
  │                │                   │                 │                │
  │                │ SwipeSuccess      │                 │                │
  │                │◀──────────────────│                 │                │
  │                │                   │                 │                │
  │ Update UI      │                   │                 │                │
  │◀───────────────│                   │                 │                │
  │                │                   │                 │                │
  │ If matched:    │                   │                 │                │
  │ Show animation │                   │                 │                │
  │                │                   │                 │                │
            </code></pre>

            <h2>Cloud Function Implementation</h2>
            <pre><code class="language-typescript">
// functions/src/matching/recordSwipe.ts

interface SwipeParams {
  swipedId: string;
  type: 'like' | 'superlike' | 'pass';
}

interface SwipeResult {
  success: boolean;
  matched: boolean;
  matchId?: string;
  conversationId?: string;
  error?: string;
}

export const recordSwipe = functions
  .runWith({ memory: '256MB', timeoutSeconds: 30 })
  .https.onCall(async (data: SwipeParams, context): Promise<SwipeResult> => {
    // 1. Authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    }

    const swiperId = context.auth.uid;
    const { swipedId, type } = data;

    // 2. Validate not swiping self
    if (swiperId === swipedId) {
      throw new functions.https.HttpsError('invalid-argument', 'Cannot swipe yourself');
    }

    // 3. Check for existing swipe
    const existingSwipe = await firestore
      .collection('swipes')
      .doc(\`\${swiperId}_\${swipedId}\`)
      .get();

    if (existingSwipe.exists) {
      return { success: false, matched: false, error: 'Already swiped' };
    }

    // 4. Get user data for limit checks
    const userDoc = await firestore.collection('users').doc(swiperId).get();
    const user = userDoc.data()!;

    // 5. Check daily limits
    if (type === 'like') {
      const likesResult = await checkDailyLikes(swiperId, user.subscription.tier);
      if (!likesResult.allowed) {
        return { success: false, matched: false, error: 'Daily like limit reached' };
      }
    } else if (type === 'superlike') {
      const superLikesResult = await checkSuperLikes(swiperId, user.subscription.tier);
      if (!superLikesResult.allowed) {
        return { success: false, matched: false, error: 'No super likes remaining' };
      }
    }

    // 6. Create swipe document
    const swipeRef = firestore.collection('swipes').doc(\`\${swiperId}_\${swipedId}\`);
    const swipeData = {
      id: swipeRef.id,
      swiperId,
      swipedId,
      type,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      matchCreated: false,
      source: 'discovery',
    };

    // 7. Check for mutual like (match)
    let matched = false;
    let matchId: string | undefined;
    let conversationId: string | undefined;

    if (type === 'like' || type === 'superlike') {
      const reverseSwipe = await firestore
        .collection('swipes')
        .doc(\`\${swipedId}_\${swiperId}\`)
        .get();

      if (reverseSwipe.exists) {
        const reverseData = reverseSwipe.data()!;
        if (reverseData.type === 'like' || reverseData.type === 'superlike') {
          // MATCH!
          matched = true;
          const matchResult = await createMatch(swiperId, swipedId);
          matchId = matchResult.matchId;
          conversationId = matchResult.conversationId;
          swipeData.matchCreated = true;
        }
      }
    }

    // 8. Write swipe and update stats in batch
    const batch = firestore.batch();

    batch.set(swipeRef, swipeData);

    // Update swiper stats
    batch.update(firestore.collection('users').doc(swiperId), {
      'stats.totalSwipes': admin.firestore.FieldValue.increment(1),
      ...(type !== 'pass' && {
        'stats.totalLikes': admin.firestore.FieldValue.increment(1),
      }),
      ...(type === 'superlike' && {
        'stats.superLikesUsed': admin.firestore.FieldValue.increment(1),
      }),
      ...(matched && {
        'stats.totalMatches': admin.firestore.FieldValue.increment(1),
      }),
    });

    // Award XP
    const xpAmount = type === 'superlike' ? 10 : type === 'like' ? 5 : 1;
    batch.update(firestore.collection('users').doc(swiperId), {
      xp: admin.firestore.FieldValue.increment(xpAmount),
    });

    await batch.commit();

    // 9. Send notifications if super like or match
    if (type === 'superlike' && !matched) {
      await sendSuperLikeNotification(swipedId, swiperId);
    }

    return {
      success: true,
      matched,
      matchId,
      conversationId,
    };
  });

async function createMatch(user1: string, user2: string) {
  const matchRef = firestore.collection('matches').doc();
  const conversationRef = firestore.collection('conversations').doc();

  // Get user profiles for match document
  const [user1Doc, user2Doc] = await Promise.all([
    firestore.collection('users').doc(user1).get(),
    firestore.collection('users').doc(user2).get(),
  ]);

  const user1Data = user1Doc.data()!;
  const user2Data = user2Doc.data()!;

  const batch = firestore.batch();

  // Create match document
  batch.set(matchRef, {
    id: matchRef.id,
    users: [user1, user2],
    userProfiles: {
      [user1]: {
        name: user1Data.name,
        photo: user1Data.photos[0]?.url,
        age: calculateAge(user1Data.birthDate),
      },
      [user2]: {
        name: user2Data.name,
        photo: user2Data.photos[0]?.url,
        age: calculateAge(user2Data.birthDate),
      },
    },
    conversationId: conversationRef.id,
    matchedAt: admin.firestore.FieldValue.serverTimestamp(),
    compatibilityScore: await calculateCompatibility(user1, user2),
    status: 'active',
  });

  // Create conversation document
  batch.set(conversationRef, {
    id: conversationRef.id,
    matchId: matchRef.id,
    participants: [user1, user2],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
    lastMessage: null,
    unreadCount: { [user1]: 0, [user2]: 0 },
    isActive: true,
  });

  await batch.commit();

  // Send match notifications to both users
  await Promise.all([
    sendMatchNotification(user1, user2Data.name, matchRef.id),
    sendMatchNotification(user2, user1Data.name, matchRef.id),
  ]);

  return {
    matchId: matchRef.id,
    conversationId: conversationRef.id,
  };
}
            </code></pre>

            <h2>Rate Limiting</h2>
            <table>
                <thead>
                    <tr><th>Action</th><th>Basic</th><th>Silver</th><th>Gold</th><th>Reset</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Likes</strong></td>
                        <td>100/day</td>
                        <td>Unlimited</td>
                        <td>Unlimited</td>
                        <td>Midnight UTC</td>
                    </tr>
                    <tr>
                        <td><strong>Super Likes</strong></td>
                        <td>1/day</td>
                        <td>5/day</td>
                        <td>5/day</td>
                        <td>Midnight UTC</td>
                    </tr>
                    <tr>
                        <td><strong>Rewind</strong></td>
                        <td>Not available</td>
                        <td>Not available</td>
                        <td>Unlimited</td>
                        <td>N/A</td>
                    </tr>
                    <tr>
                        <td><strong>Boost</strong></td>
                        <td>Purchase only</td>
                        <td>Purchase only</td>
                        <td>1 free/week</td>
                        <td>Weekly</td>
                    </tr>
                </tbody>
            </table>
        `
    },
    {
        file: '45-subscriptions.html',
        title: 'Subscription Tiers',
        section: 'Core Features',
        content: `
            <h2>Subscription System Architecture</h2>
            <p>Three-tier subscription model with Stripe integration, receipt validation, and entitlement management.</p>

            <h2>Subscription Tiers</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        SUBSCRIPTION TIER COMPARISON                                  │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┬─────────────────────┬─────────────────────┐
│       BASIC         │       SILVER        │        GOLD         │
│       (Free)        │     (\$9.99/mo)       │     (\$19.99/mo)      │
├─────────────────────┼─────────────────────┼─────────────────────┤
│ ✓ 100 likes/day     │ ✓ Unlimited likes   │ ✓ Unlimited likes   │
│ ✓ 1 Super Like/day  │ ✓ 5 Super Likes/day │ ✓ 5 Super Likes/day │
│ ✗ See who likes you │ ✓ See who likes you │ ✓ See who likes you │
│ ✗ Rewind            │ ✗ Rewind            │ ✓ Unlimited Rewind  │
│ ✗ Passport          │ ✗ Passport          │ ✓ Passport mode     │
│ ✗ Advanced filters  │ ✓ Advanced filters  │ ✓ Advanced filters  │
│ ✗ Read receipts     │ ✗ Read receipts     │ ✓ Read receipts     │
│ ✗ Priority likes    │ ✓ Priority likes    │ ✓ Priority likes    │
│ ✗ Boost             │ ✗ Boost             │ ✓ 1 free boost/week │
│ ✗ No ads            │ ✓ No ads            │ ✓ No ads            │
│ Standard support    │ Priority support    │ VIP support         │
└─────────────────────┴─────────────────────┴─────────────────────┘
            </code></pre>

            <h2>Subscription Flow</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      SUBSCRIPTION PURCHASE FLOW                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘

Client           App              Function           Stripe          Firestore
  │               │                  │                 │                │
  │ Select plan   │                  │                 │                │
  │──────────────▶│                  │                 │                │
  │               │                  │                 │                │
  │               │ createCheckout   │                 │                │
  │               │─────────────────▶│                 │                │
  │               │                  │                 │                │
  │               │                  │ Create customer │                │
  │               │                  │ (if new)        │                │
  │               │                  │────────────────▶│                │
  │               │                  │                 │                │
  │               │                  │ Create session  │                │
  │               │                  │────────────────▶│                │
  │               │                  │                 │                │
  │               │  sessionId       │   sessionId     │                │
  │               │◀─────────────────│◀────────────────│                │
  │               │                  │                 │                │
  │ Redirect to   │                  │                 │                │
  │ Stripe        │                  │                 │                │
  │──────────────▶│──────────────────┼────────────────▶│                │
  │               │                  │                 │                │
  │ Complete      │                  │                 │                │
  │ payment       │                  │                 │                │
  │───────────────┼──────────────────┼────────────────▶│                │
  │               │                  │                 │                │
  │               │                  │   Webhook       │                │
  │               │                  │◀────────────────│                │
  │               │                  │                 │                │
  │               │                  │ Update user     │                │
  │               │                  │────────────────▶│───────────────▶│
  │               │                  │                 │                │
  │ Redirect      │                  │                 │                │
  │ success       │                  │                 │                │
  │◀──────────────│◀─────────────────┼─────────────────│                │
  │               │                  │                 │                │
  │               │ Refresh user     │                 │                │
  │               │────────────────▶│                  │                │
  │               │                  │                 │                │
  │ Show premium  │ Premium features │                 │                │
  │ features      │ enabled          │                 │                │
  │◀──────────────│◀─────────────────│                 │                │
            </code></pre>

            <h2>Stripe Webhook Handler</h2>
            <pre><code class="language-typescript">
// functions/src/payments/stripeWebhook.ts

export const stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'] as string;
  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (err) {
    console.error('Webhook signature verification failed');
    res.status(400).send('Webhook Error');
    return;
  }

  switch (event.type) {
    case 'checkout.session.completed':
      await handleCheckoutComplete(event.data.object as Stripe.Checkout.Session);
      break;

    case 'customer.subscription.created':
    case 'customer.subscription.updated':
      await handleSubscriptionUpdate(event.data.object as Stripe.Subscription);
      break;

    case 'customer.subscription.deleted':
      await handleSubscriptionCanceled(event.data.object as Stripe.Subscription);
      break;

    case 'invoice.payment_succeeded':
      await handlePaymentSucceeded(event.data.object as Stripe.Invoice);
      break;

    case 'invoice.payment_failed':
      await handlePaymentFailed(event.data.object as Stripe.Invoice);
      break;
  }

  res.json({ received: true });
});

async function handleSubscriptionUpdate(subscription: Stripe.Subscription) {
  const userId = subscription.metadata.userId;
  if (!userId) return;

  const tier = mapPriceToTier(subscription.items.data[0].price.id);

  await firestore.collection('users').doc(userId).update({
    'subscription.tier': tier,
    'subscription.status': subscription.status,
    'subscription.stripeSubscriptionId': subscription.id,
    'subscription.currentPeriodEnd': new Date(subscription.current_period_end * 1000),
    'subscription.cancelAtPeriodEnd': subscription.cancel_at_period_end,
  });

  // Update subscription document
  await firestore.collection('subscriptions').doc(subscription.id).set({
    id: subscription.id,
    oderId,
    tier,
    status: subscription.status,
    stripeCustomerId: subscription.customer as string,
    currentPeriodStart: new Date(subscription.current_period_start * 1000),
    currentPeriodEnd: new Date(subscription.current_period_end * 1000),
    cancelAtPeriodEnd: subscription.cancel_at_period_end,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

function mapPriceToTier(priceId: string): string {
  const priceMap: Record<string, string> = {
    'price_silver_monthly': 'silver',
    'price_silver_yearly': 'silver',
    'price_gold_monthly': 'gold',
    'price_gold_yearly': 'gold',
  };
  return priceMap[priceId] || 'basic';
}
            </code></pre>

            <h2>Entitlement Checking</h2>
            <pre><code class="language-dart">
// lib/features/subscription/domain/entities/entitlements.dart

class UserEntitlements {
  final SubscriptionTier tier;
  final DateTime? expiresAt;

  bool get isActive => tier != SubscriptionTier.basic &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  bool get canSeeWhoLikesYou => tier.index >= SubscriptionTier.silver.index;
  bool get hasUnlimitedLikes => tier.index >= SubscriptionTier.silver.index;
  bool get canRewind => tier == SubscriptionTier.gold;
  bool get hasPassportMode => tier == SubscriptionTier.gold;
  bool get hasReadReceipts => tier == SubscriptionTier.gold;
  bool get hasAdvancedFilters => tier.index >= SubscriptionTier.silver.index;
  bool get hasNoAds => tier.index >= SubscriptionTier.silver.index;

  int get dailySuperLikes => switch (tier) {
    SubscriptionTier.basic => 1,
    SubscriptionTier.silver => 5,
    SubscriptionTier.gold => 5,
  };

  int get weeklyFreeBoosts => tier == SubscriptionTier.gold ? 1 : 0;
}

// Check entitlement before action
class RecordSwipeUseCase {
  Future<Either<Failure, SwipeResult>> call(SwipeParams params) async {
    final entitlements = await _getEntitlements();

    if (params.type == SwipeType.like && !entitlements.hasUnlimitedLikes) {
      final likesRemaining = await _checkDailyLikes();
      if (likesRemaining <= 0) {
        return Left(LimitReachedFailure(
          message: 'Daily like limit reached',
          upgradeRequired: true,
        ));
      }
    }

    // Proceed with swipe...
  }
}
            </code></pre>

            <h2>Subscription Data Model</h2>
            <pre><code>
// Firestore: subscriptions/{subscriptionId}

{
  "id": "sub_1234567890",
  "userId": "user_abc123",
  "tier": "gold",
  "status": "active", // active, canceled, past_due, unpaid
  "stripeSubscriptionId": "sub_1234567890",
  "stripeCustomerId": "cus_1234567890",
  "stripePriceId": "price_gold_monthly",
  "currentPeriodStart": "2024-01-01T00:00:00Z",
  "currentPeriodEnd": "2024-02-01T00:00:00Z",
  "cancelAtPeriodEnd": false,
  "canceledAt": null,
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
            </code></pre>
        `
    },
    {
        file: '48-gamification.html',
        title: 'Gamification System',
        section: 'Core Features',
        content: `
            <h2>Gamification Architecture</h2>
            <p>Complete XP, leveling, achievements, and rewards system to increase user engagement and retention.</p>

            <h2>Gamification Components</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      GAMIFICATION SYSTEM ARCHITECTURE                                │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              XP & LEVELING                                           │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │  Level 1 ──▶ Level 2 ──▶ Level 3 ──▶ ... ──▶ Level 50                       │   │
│  │   0 XP      100 XP      250 XP            50,000 XP                         │   │
│  │                                                                              │   │
│  │  XP Sources:                                                                 │   │
│  │  • Daily login: 10 XP           • Complete profile: 100 XP                  │   │
│  │  • Send message: 5 XP           • Get match: 25 XP                          │   │
│  │  • Like: 2 XP                   • Super Like: 5 XP                          │   │
│  │  • Complete challenge: 50 XP    • Refer friend: 200 XP                      │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                        │
              ┌─────────────────────────┼─────────────────────────┐
              │                         │                         │
              ▼                         ▼                         ▼
    ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
    │  ACHIEVEMENTS   │       │   CHALLENGES    │       │    STREAKS      │
    ├─────────────────┤       ├─────────────────┤       ├─────────────────┤
    │ • First Match   │       │ • Daily tasks   │       │ • Login streak  │
    │ • Chat Master   │       │ • Weekly goals  │       │ • Chat streak   │
    │ • Social Star   │       │ • Monthly bonus │       │ • Swipe streak  │
    │ • Profile Pro   │       │                 │       │                 │
    │ • Verified User │       │ Rewards:        │       │ Multipliers:    │
    │                 │       │ Coins, XP,      │       │ 7 days: 1.5x    │
    │ Rewards:        │       │ Boosts, Badge   │       │ 30 days: 2x     │
    │ Badges, Coins   │       │                 │       │ 100 days: 3x    │
    └─────────────────┘       └─────────────────┘       └─────────────────┘
            </code></pre>

            <h2>XP & Level System</h2>
            <pre><code class="language-dart">
// lib/features/gamification/domain/entities/level_system.dart

class LevelSystem {
  static const List<int> levelThresholds = [
    0,      // Level 1
    100,    // Level 2
    250,    // Level 3
    500,    // Level 4
    1000,   // Level 5
    1750,   // Level 6
    2750,   // Level 7
    4000,   // Level 8
    5500,   // Level 9
    7500,   // Level 10
    // ... up to level 50
    50000,  // Level 50
  ];

  static int getLevelForXP(int xp) {
    for (int i = levelThresholds.length - 1; i >= 0; i--) {
      if (xp >= levelThresholds[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  static int getXPForNextLevel(int currentLevel) {
    if (currentLevel >= levelThresholds.length) {
      return -1; // Max level
    }
    return levelThresholds[currentLevel];
  }

  static double getProgressToNextLevel(int xp) {
    final level = getLevelForXP(xp);
    if (level >= levelThresholds.length) return 1.0;

    final currentLevelXP = levelThresholds[level - 1];
    final nextLevelXP = levelThresholds[level];
    final progress = (xp - currentLevelXP) / (nextLevelXP - currentLevelXP);
    return progress.clamp(0.0, 1.0);
  }

  static LevelReward getRewardForLevel(int level) {
    return switch (level) {
      5 => LevelReward(coins: 50, badge: 'rising_star'),
      10 => LevelReward(coins: 100, superLikes: 5, badge: 'veteran'),
      20 => LevelReward(coins: 200, boost: 1, badge: 'expert'),
      30 => LevelReward(coins: 500, superLikes: 10, badge: 'master'),
      50 => LevelReward(coins: 1000, boost: 3, badge: 'legend'),
      _ => LevelReward(coins: level * 5),
    };
  }
}

class LevelReward {
  final int coins;
  final int superLikes;
  final int boost;
  final String? badge;

  const LevelReward({
    this.coins = 0,
    this.superLikes = 0,
    this.boost = 0,
    this.badge,
  });
}
            </code></pre>

            <h2>XP Award Function</h2>
            <pre><code class="language-typescript">
// functions/src/gamification/awardXP.ts

interface XPEvent {
  userId: string;
  action: XPAction;
  metadata?: Record<string, any>;
}

enum XPAction {
  DAILY_LOGIN = 'daily_login',
  SEND_MESSAGE = 'send_message',
  RECEIVE_MATCH = 'receive_match',
  COMPLETE_PROFILE = 'complete_profile',
  LIKE = 'like',
  SUPER_LIKE = 'super_like',
  COMPLETE_CHALLENGE = 'complete_challenge',
  REFER_FRIEND = 'refer_friend',
}

const XP_VALUES: Record<XPAction, number> = {
  [XPAction.DAILY_LOGIN]: 10,
  [XPAction.SEND_MESSAGE]: 5,
  [XPAction.RECEIVE_MATCH]: 25,
  [XPAction.COMPLETE_PROFILE]: 100,
  [XPAction.LIKE]: 2,
  [XPAction.SUPER_LIKE]: 5,
  [XPAction.COMPLETE_CHALLENGE]: 50,
  [XPAction.REFER_FRIEND]: 200,
};

export async function awardXP(event: XPEvent): Promise<void> {
  const { userId, action, metadata } = event;

  // Get user data
  const userRef = firestore.collection('users').doc(userId);
  const userDoc = await userRef.get();
  const user = userDoc.data()!;

  // Calculate XP with streak multiplier
  let baseXP = XP_VALUES[action];
  const multiplier = getStreakMultiplier(user.streakDays);
  const totalXP = Math.floor(baseXP * multiplier);

  // Get current and new level
  const oldXP = user.xp;
  const newXP = oldXP + totalXP;
  const oldLevel = getLevelForXP(oldXP);
  const newLevel = getLevelForXP(newXP);

  // Update user
  await userRef.update({
    xp: admin.firestore.FieldValue.increment(totalXP),
    level: newLevel,
  });

  // Record XP event
  await firestore.collection('users').doc(userId).collection('xp_history').add({
    action,
    amount: totalXP,
    multiplier,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    metadata,
  });

  // Check for level up
  if (newLevel > oldLevel) {
    await handleLevelUp(userId, newLevel);
  }

  // Check achievements
  await checkAchievements(userId, action);
}

async function handleLevelUp(userId: string, newLevel: number): Promise<void> {
  const reward = getLevelReward(newLevel);

  // Award rewards
  const updates: any = {};
  if (reward.coins > 0) {
    updates.coins = admin.firestore.FieldValue.increment(reward.coins);
  }

  await firestore.collection('users').doc(userId).update(updates);

  // Send notification
  await sendNotification(userId, {
    type: 'level_up',
    title: \`Level \${newLevel} Reached!\`,
    body: \`You earned \${reward.coins} coins!\`,
    data: { level: newLevel, reward },
  });

  // Award badge if applicable
  if (reward.badge) {
    await awardBadge(userId, reward.badge);
  }
}

function getStreakMultiplier(streakDays: number): number {
  if (streakDays >= 100) return 3.0;
  if (streakDays >= 30) return 2.0;
  if (streakDays >= 7) return 1.5;
  return 1.0;
}
            </code></pre>

            <h2>Achievement System</h2>
            <pre><code class="language-dart">
// lib/features/gamification/domain/entities/achievement.dart

enum AchievementId {
  firstMatch,
  tenMatches,
  hundredMatches,
  firstMessage,
  chatMaster,      // 1000 messages
  superStar,       // 100 super likes received
  profileComplete,
  verified,
  weekStreak,
  monthStreak,
  centuryStreak,   // 100 day streak
  socialButterfly, // Connected all social accounts
  earlyAdopter,
}

class Achievement {
  final AchievementId id;
  final String name;
  final String description;
  final String iconAsset;
  final int coinReward;
  final int xpReward;
  final bool isSecret;

  static const achievements = {
    AchievementId.firstMatch: Achievement(
      id: AchievementId.firstMatch,
      name: 'First Spark',
      description: 'Get your first match',
      iconAsset: 'assets/badges/first_match.png',
      coinReward: 20,
      xpReward: 50,
    ),
    AchievementId.hundredMatches: Achievement(
      id: AchievementId.hundredMatches,
      name: 'Match Master',
      description: 'Get 100 matches',
      iconAsset: 'assets/badges/match_master.png',
      coinReward: 500,
      xpReward: 1000,
    ),
    AchievementId.centuryStreak: Achievement(
      id: AchievementId.centuryStreak,
      name: 'Century Club',
      description: 'Maintain a 100 day login streak',
      iconAsset: 'assets/badges/century.png',
      coinReward: 1000,
      xpReward: 2000,
      isSecret: true,
    ),
    // ... more achievements
  };
}
            </code></pre>

            <h2>Gamification Data Model</h2>
            <pre><code>
// User gamification fields
{
  "xp": 2500,
  "level": 8,
  "streakDays": 15,
  "lastStreakDate": "2024-01-15T00:00:00Z",
  "achievements": [
    "firstMatch",
    "profileComplete",
    "weekStreak"
  ],
  "badges": [
    {
      "id": "rising_star",
      "earnedAt": "2024-01-10T00:00:00Z"
    }
  ]
}

// XP History: users/{userId}/xp_history/{eventId}
{
  "action": "receive_match",
  "amount": 37,  // 25 base * 1.5 multiplier
  "multiplier": 1.5,
  "timestamp": "2024-01-15T14:30:00Z"
}
            </code></pre>
        `
    },
    {
        file: '43-push-notifications.html',
        title: 'Push Notifications',
        section: 'Core Features',
        content: `
            <h2>Push Notification System</h2>
            <p>Firebase Cloud Messaging integration for real-time push notifications across iOS, Android, and Web.</p>

            <h2>Notification Architecture</h2>
            <pre><code>
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                    PUSH NOTIFICATION ARCHITECTURE                                    │
└─────────────────────────────────────────────────────────────────────────────────────┘

                              ┌─────────────────┐
                              │   TRIGGER       │
                              │   EVENT         │
                              └────────┬────────┘
                                       │
              ┌────────────────────────┼────────────────────────┐
              │                        │                        │
              ▼                        ▼                        ▼
    ┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
    │   NEW MATCH     │      │   NEW MESSAGE   │      │   SUPER LIKE    │
    │   onMatchCreate │      │  onMessageCreate│      │  onSwipeCreate  │
    └────────┬────────┘      └────────┬────────┘      └────────┬────────┘
             │                        │                        │
             └────────────────────────┼────────────────────────┘
                                      │
                           ┌──────────▼──────────┐
                           │  NOTIFICATION       │
                           │  SERVICE            │
                           │  • Build payload    │
                           │  • Check prefs      │
                           │  • Get FCM tokens   │
                           └──────────┬──────────┘
                                      │
                           ┌──────────▼──────────┐
                           │  FIREBASE CLOUD     │
                           │  MESSAGING          │
                           └──────────┬──────────┘
                                      │
              ┌───────────────────────┼───────────────────────┐
              │                       │                       │
              ▼                       ▼                       ▼
       ┌───────────┐           ┌───────────┐           ┌───────────┐
       │    iOS    │           │  Android  │           │    Web    │
       │   APNs    │           │   FCM     │           │   FCM     │
       └───────────┘           └───────────┘           └───────────┘
            </code></pre>

            <h2>Notification Types</h2>
            <table>
                <thead>
                    <tr><th>Type</th><th>Trigger</th><th>Priority</th><th>Sound</th><th>Action</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>New Match</strong></td>
                        <td>Match created</td>
                        <td>High</td>
                        <td>match.wav</td>
                        <td>Open matches</td>
                    </tr>
                    <tr>
                        <td><strong>New Message</strong></td>
                        <td>Message received</td>
                        <td>High</td>
                        <td>message.wav</td>
                        <td>Open chat</td>
                    </tr>
                    <tr>
                        <td><strong>Super Like</strong></td>
                        <td>Super like received</td>
                        <td>High</td>
                        <td>superlike.wav</td>
                        <td>Open discovery</td>
                    </tr>
                    <tr>
                        <td><strong>Profile View</strong></td>
                        <td>Profile viewed (Gold)</td>
                        <td>Normal</td>
                        <td>Default</td>
                        <td>Open likes</td>
                    </tr>
                    <tr>
                        <td><strong>Daily Reminder</strong></td>
                        <td>Scheduled</td>
                        <td>Normal</td>
                        <td>Default</td>
                        <td>Open app</td>
                    </tr>
                </tbody>
            </table>

            <h2>FCM Token Management</h2>
            <pre><code class="language-dart">
// lib/core/services/notification_service.dart

class NotificationService {
  final FirebaseMessaging _fcm;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _local;

  Future<void> initialize() async {
    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveToken(token);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_saveToken);
    }

    // Configure message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Configure local notifications
    await _configureLocalNotifications();
  }

  Future<void> _saveToken(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channels (Android)
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(AndroidNotificationChannel(
      'matches',
      'Matches',
      description: 'New match notifications',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('match'),
    ));

    await android?.createNotificationChannel(AndroidNotificationChannel(
      'messages',
      'Messages',
      description: 'New message notifications',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('message'),
    ));
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification when app is in foreground
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          message.data['channel'] ?? 'default',
          message.data['channelName'] ?? 'Default',
          icon: '@mipmap/ic_notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
            </code></pre>

            <h2>Cloud Function - Send Notification</h2>
            <pre><code class="language-typescript">
// functions/src/notifications/sendNotification.ts

interface NotificationPayload {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, string>;
  imageUrl?: string;
}

export async function sendPushNotification(payload: NotificationPayload): Promise<void> {
  const { userId, type, title, body, data, imageUrl } = payload;

  // Check user notification preferences
  const userDoc = await firestore.collection('users').doc(userId).get();
  const user = userDoc.data();

  if (!user?.settings?.pushEnabled) {
    return;
  }

  // Check specific notification type preference
  if (!isNotificationTypeEnabled(user.settings, type)) {
    return;
  }

  // Get FCM tokens
  const tokens = user.fcmTokens || [];
  if (tokens.length === 0) {
    return;
  }

  // Build FCM message
  const message: admin.messaging.MulticastMessage = {
    tokens,
    notification: {
      title,
      body,
      imageUrl,
    },
    data: {
      type,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      ...data,
    },
    android: {
      priority: 'high',
      notification: {
        channelId: getChannelForType(type),
        sound: getSoundForType(type),
        icon: '@mipmap/ic_notification',
        color: '#D4AF37',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: getSoundForType(type) + '.wav',
          badge: 1,
          'mutable-content': 1,
        },
      },
    },
  };

  // Send notification
  const response = await admin.messaging().sendEachForMulticast(message);

  // Handle failed tokens
  if (response.failureCount > 0) {
    const failedTokens: string[] = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        failedTokens.push(tokens[idx]);
      }
    });

    // Remove invalid tokens
    await firestore.collection('users').doc(userId).update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...failedTokens),
    });
  }

  // Store notification in database
  await firestore.collection('users').doc(userId).collection('notifications').add({
    type,
    title,
    body,
    data,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function getChannelForType(type: NotificationType): string {
  switch (type) {
    case 'match': return 'matches';
    case 'message': return 'messages';
    case 'superlike': return 'matches';
    default: return 'default';
  }
}
            </code></pre>
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

coreFeaturePages.forEach(page => {
    const filepath = path.join(pagesDir, page.file);
    const html = createPageHTML(page);
    fs.writeFileSync(filepath, html);
    console.log(`Created: ${page.file}`);
});

console.log(`\nGenerated ${coreFeaturePages.length} core feature pages with engineering-level documentation!`);
