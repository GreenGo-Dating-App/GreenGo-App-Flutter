import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/blind_date.dart';
import '../../domain/usecases/blind_date_usecases.dart';
import 'blind_date_event.dart';
import 'blind_date_state.dart';

/// Blind Date BLoC
/// Manages blind date mode, matching, and reveal
class BlindDateBloc extends Bloc<BlindDateEvent, BlindDateState> {
  final CreateBlindProfile createBlindProfile;
  final GetBlindProfile getBlindProfile;
  final DeactivateBlindProfile deactivateBlindProfile;
  final GetBlindCandidates getBlindCandidates;
  final LikeBlindProfile likeBlindProfile;
  final PassBlindProfile passBlindProfile;
  final GetBlindMatches getBlindMatches;
  final InstantReveal instantReveal;
  final GetRevealedProfile getRevealedProfile;

  // Cache
  List<BlindProfileView> _candidatesCache = [];
  int _currentIndex = 0;
  int? _userCoins;

  BlindDateBloc({
    required this.createBlindProfile,
    required this.getBlindProfile,
    required this.deactivateBlindProfile,
    required this.getBlindCandidates,
    required this.likeBlindProfile,
    required this.passBlindProfile,
    required this.getBlindMatches,
    required this.instantReveal,
    required this.getRevealedProfile,
  }) : super(const BlindDateInitial()) {
    on<ActivateBlindDateMode>(_onActivateBlindDateMode);
    on<DeactivateBlindDateMode>(_onDeactivateBlindDateMode);
    on<CheckBlindDateStatus>(_onCheckBlindDateStatus);
    on<LoadBlindCandidates>(_onLoadBlindCandidates);
    on<LikeBlindProfileEvent>(_onLikeBlindProfile);
    on<PassBlindProfileEvent>(_onPassBlindProfile);
    on<LoadBlindMatches>(_onLoadBlindMatches);
    on<SubscribeToBlindMatches>(_onSubscribeToBlindMatches);
    on<RequestInstantReveal>(_onRequestInstantReveal);
    on<LoadRevealedProfile>(_onLoadRevealedProfile);
    on<SelectBlindCandidate>(_onSelectBlindCandidate);
  }

  /// Set user coins for instant reveal check
  void setUserCoins(int coins) {
    _userCoins = coins;
  }

  /// Activate blind date mode
  Future<void> _onActivateBlindDateMode(
    ActivateBlindDateMode event,
    Emitter<BlindDateState> emit,
  ) async {
    emit(const BlindDateLoading());

    final result = await createBlindProfile(event.userId);

    result.fold(
      (failure) => emit(BlindDateError(failure.toString())),
      (profile) => emit(BlindDateModeActivated(profile)),
    );
  }

  /// Deactivate blind date mode
  Future<void> _onDeactivateBlindDateMode(
    DeactivateBlindDateMode event,
    Emitter<BlindDateState> emit,
  ) async {
    emit(const BlindDateLoading());

    final result = await deactivateBlindProfile(event.userId);

    result.fold(
      (failure) => emit(BlindDateError(failure.toString())),
      (_) => emit(const BlindDateModeDeactivated()),
    );
  }

  /// Check blind date status
  Future<void> _onCheckBlindDateStatus(
    CheckBlindDateStatus event,
    Emitter<BlindDateState> emit,
  ) async {
    emit(const BlindDateLoading());

    final result = await getBlindProfile(event.userId);

    result.fold(
      (failure) => emit(BlindDateError(failure.toString())),
      (profile) => emit(BlindDateStatusLoaded(
        profile: profile,
        isActive: profile?.isActive ?? false,
      )),
    );
  }

  /// Load blind candidates
  Future<void> _onLoadBlindCandidates(
    LoadBlindCandidates event,
    Emitter<BlindDateState> emit,
  ) async {
    emit(const BlindDateLoading());

    final result = await getBlindCandidates(
      userId: event.userId,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(BlindDateError(failure.toString())),
      (candidates) {
        _candidatesCache = candidates;
        _currentIndex = 0;

        if (candidates.isEmpty) {
          emit(const NoMoreCandidates());
        } else {
          emit(BlindCandidatesLoaded(
            candidates: candidates,
            currentIndex: 0,
            hasMore: candidates.length >= event.limit,
          ));
        }
      },
    );
  }

  /// Like a blind profile
  Future<void> _onLikeBlindProfile(
    LikeBlindProfileEvent event,
    Emitter<BlindDateState> emit,
  ) async {
    final result = await likeBlindProfile(
      userId: event.userId,
      targetUserId: event.targetUserId,
    );

    result.fold(
      (failure) => emit(BlindDateError(failure.toString())),
      (likeResult) {
        emit(BlindLikeActionResult(result: likeResult));
        _moveToNextCandidate(emit);
      },
    );
  }

  /// Pass on a blind profile
  Future<void> _onPassBlindProfile(
    PassBlindProfileEvent event,
    Emitter<BlindDateState> emit,
  ) async {
    final result = await passBlindProfile(
      userId: event.userId,
      targetUserId: event.targetUserId,
    );

    result.fold(
      (failure) => emit(BlindDateError(failure.toString())),
      (_) {
        emit(const BlindPassActionCompleted());
        _moveToNextCandidate(emit);
      },
    );
  }

  /// Move to next candidate
  void _moveToNextCandidate(Emitter<BlindDateState> emit) {
    _currentIndex++;

    if (_currentIndex >= _candidatesCache.length) {
      emit(const NoMoreCandidates());
    } else {
      emit(BlindCandidatesLoaded(
        candidates: _candidatesCache,
        currentIndex: _currentIndex,
        hasMore: false,
      ));
    }
  }

  /// Load blind matches
  Future<void> _onLoadBlindMatches(
    LoadBlindMatches event,
    Emitter<BlindDateState> emit,
  ) async {
    emit(const BlindDateLoading());

    final result = await getBlindMatches(event.userId);

    result.fold(
      (failure) => emit(BlindDateError(failure.toString())),
      (matches) => emit(BlindMatchesLoaded(matches: matches)),
    );
  }

  /// Subscribe to blind matches stream
  Future<void> _onSubscribeToBlindMatches(
    SubscribeToBlindMatches event,
    Emitter<BlindDateState> emit,
  ) async {
    await emit.forEach(
      getBlindMatches.stream(event.userId),
      onData: (result) {
        return result.fold(
          (failure) => BlindDateError(failure.toString()),
          (matches) => BlindMatchesLoaded(matches: matches),
        );
      },
    );
  }

  /// Request instant reveal
  Future<void> _onRequestInstantReveal(
    RequestInstantReveal event,
    Emitter<BlindDateState> emit,
  ) async {
    // Check coins first
    if (_userCoins != null && _userCoins! < BlindDateConfig.instantRevealCost) {
      emit(InsufficientCoinsForReveal(
        required: BlindDateConfig.instantRevealCost,
        available: _userCoins!,
      ));
      return;
    }

    emit(const BlindDateLoading());

    final result = await instantReveal(
      userId: event.userId,
      matchId: event.matchId,
    );

    result.fold(
      (failure) => emit(BlindDateError(failure.toString())),
      (match) {
        if (_userCoins != null) {
          _userCoins = _userCoins! - BlindDateConfig.instantRevealCost;
        }
        emit(InstantRevealCompleted(
          match: match,
          coinsSpent: BlindDateConfig.instantRevealCost,
        ));
      },
    );
  }

  /// Load revealed profile
  Future<void> _onLoadRevealedProfile(
    LoadRevealedProfile event,
    Emitter<BlindDateState> emit,
  ) async {
    emit(const BlindDateLoading());

    final result = await getRevealedProfile(
      matchId: event.matchId,
      userId: event.userId,
    );

    result.fold(
      (failure) => emit(BlindDateError(failure.toString())),
      (profile) {
        // Would need to also load the match
        // For now just emit the profile
      },
    );
  }

  /// Select a candidate
  Future<void> _onSelectBlindCandidate(
    SelectBlindCandidate event,
    Emitter<BlindDateState> emit,
  ) async {
    if (event.index < 0 || event.index >= _candidatesCache.length) return;

    _currentIndex = event.index;
    emit(BlindCandidatesLoaded(
      candidates: _candidatesCache,
      currentIndex: _currentIndex,
      hasMore: false,
    ));
  }
}
