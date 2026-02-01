import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/second_chance.dart';
import '../../domain/usecases/second_chance_usecases.dart';
import 'second_chance_event.dart';
import 'second_chance_state.dart';

/// Second Chance BLoC
class SecondChanceBloc extends Bloc<SecondChanceEvent, SecondChanceState> {
  final GetSecondChanceProfiles getSecondChanceProfiles;
  final GetSecondChanceUsage getSecondChanceUsage;
  final LikeSecondChance likeSecondChance;
  final PassSecondChance passSecondChance;
  final PurchaseUnlimitedSecondChances purchaseUnlimited;

  List<SecondChanceProfile> _profilesCache = [];
  SecondChanceUsage? _usageCache;
  int _currentIndex = 0;

  SecondChanceBloc({
    required this.getSecondChanceProfiles,
    required this.getSecondChanceUsage,
    required this.likeSecondChance,
    required this.passSecondChance,
    required this.purchaseUnlimited,
  }) : super(const SecondChanceInitial()) {
    on<LoadSecondChanceProfiles>(_onLoadProfiles);
    on<LoadSecondChanceUsage>(_onLoadUsage);
    on<LikeSecondChanceEvent>(_onLike);
    on<PassSecondChanceEvent>(_onPass);
    on<PurchaseUnlimitedEvent>(_onPurchaseUnlimited);
    on<SelectSecondChanceProfile>(_onSelectProfile);
  }

  /// Load second chance profiles
  Future<void> _onLoadProfiles(
    LoadSecondChanceProfiles event,
    Emitter<SecondChanceState> emit,
  ) async {
    emit(const SecondChanceLoading());

    // Load both profiles and usage
    final profilesResult = await getSecondChanceProfiles(event.userId);
    final usageResult = await getSecondChanceUsage(event.userId);

    profilesResult.fold(
      (failure) => emit(SecondChanceError(failure.toString())),
      (profiles) {
        usageResult.fold(
          (failure) => emit(SecondChanceError(failure.toString())),
          (usage) {
            _profilesCache = profiles;
            _usageCache = usage;
            _currentIndex = 0;

            if (profiles.isEmpty) {
              emit(const NoMoreSecondChances());
            } else {
              emit(SecondChanceProfilesLoaded(
                profiles: profiles,
                usage: usage,
                currentIndex: 0,
              ));
            }
          },
        );
      },
    );
  }

  /// Load usage only
  Future<void> _onLoadUsage(
    LoadSecondChanceUsage event,
    Emitter<SecondChanceState> emit,
  ) async {
    final result = await getSecondChanceUsage(event.userId);

    result.fold(
      (failure) => emit(SecondChanceError(failure.toString())),
      (usage) {
        _usageCache = usage;
        if (_profilesCache.isNotEmpty) {
          emit(SecondChanceProfilesLoaded(
            profiles: _profilesCache,
            usage: usage,
            currentIndex: _currentIndex,
          ));
        }
      },
    );
  }

  /// Like a second chance profile
  Future<void> _onLike(
    LikeSecondChanceEvent event,
    Emitter<SecondChanceState> emit,
  ) async {
    // Check if can use
    if (_usageCache != null && !_usageCache!.canUse) {
      emit(NeedMoreSecondChances(_usageCache!));
      return;
    }

    final result = await likeSecondChance(
      userId: event.userId,
      entryId: event.entryId,
    );

    result.fold(
      (failure) => emit(SecondChanceError(failure.toString())),
      (likeResult) {
        emit(SecondChanceLikeResult(
          isMatch: likeResult.isMatch,
          matchId: likeResult.matchId,
        ));
        _moveToNext(emit);
      },
    );
  }

  /// Pass on a second chance profile
  Future<void> _onPass(
    PassSecondChanceEvent event,
    Emitter<SecondChanceState> emit,
  ) async {
    final result = await passSecondChance(
      userId: event.userId,
      entryId: event.entryId,
    );

    result.fold(
      (failure) => emit(SecondChanceError(failure.toString())),
      (_) {
        emit(const SecondChancePassCompleted());
        _moveToNext(emit);
      },
    );
  }

  /// Move to next profile
  void _moveToNext(Emitter<SecondChanceState> emit) {
    // Remove current profile from cache
    if (_currentIndex < _profilesCache.length) {
      _profilesCache.removeAt(_currentIndex);
    }

    // Update usage if not unlimited
    if (_usageCache != null && !_usageCache!.hasUnlimited) {
      _usageCache = SecondChanceUsage(
        odldid: _usageCache!.odldid,
        date: _usageCache!.date,
        freeUsed: _usageCache!.freeUsed + 1,
        hasUnlimited: _usageCache!.hasUnlimited,
        unlimitedExpiresAt: _usageCache!.unlimitedExpiresAt,
      );
    }

    if (_profilesCache.isEmpty) {
      emit(const NoMoreSecondChances());
    } else {
      // Keep index at same position (next profile slides into position)
      if (_currentIndex >= _profilesCache.length) {
        _currentIndex = _profilesCache.length - 1;
      }
      emit(SecondChanceProfilesLoaded(
        profiles: _profilesCache,
        usage: _usageCache!,
        currentIndex: _currentIndex,
      ));
    }
  }

  /// Purchase unlimited second chances
  Future<void> _onPurchaseUnlimited(
    PurchaseUnlimitedEvent event,
    Emitter<SecondChanceState> emit,
  ) async {
    emit(const SecondChanceLoading());

    final result = await purchaseUnlimited(event.userId);

    result.fold(
      (failure) => emit(SecondChanceError(failure.toString())),
      (usage) {
        _usageCache = usage;
        emit(UnlimitedPurchased(usage));

        // If we have profiles, show them again
        if (_profilesCache.isNotEmpty) {
          emit(SecondChanceProfilesLoaded(
            profiles: _profilesCache,
            usage: usage,
            currentIndex: _currentIndex,
          ));
        }
      },
    );
  }

  /// Select a profile to view
  void _onSelectProfile(
    SelectSecondChanceProfile event,
    Emitter<SecondChanceState> emit,
  ) {
    if (event.index < 0 || event.index >= _profilesCache.length) return;

    _currentIndex = event.index;
    if (_usageCache != null) {
      emit(SecondChanceProfilesLoaded(
        profiles: _profilesCache,
        usage: _usageCache!,
        currentIndex: _currentIndex,
      ));
    }
  }
}
