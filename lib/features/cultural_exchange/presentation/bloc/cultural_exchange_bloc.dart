import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/cultural_exchange_repository.dart';

part 'cultural_exchange_event.dart';
part 'cultural_exchange_state.dart';

class CulturalExchangeBloc
    extends Bloc<CulturalExchangeEvent, CulturalExchangeState> {

  CulturalExchangeBloc({required this.repository})
      : super(const CulturalExchangeState()) {
    // Initialization
    on<LoadCulturalExchangeData>(_onLoadCulturalExchangeData);

    // Spotlight
    on<LoadActiveSpotlight>(_onLoadActiveSpotlight);
    on<LoadSpotlightHistory>(_onLoadSpotlightHistory);

    // Cultural Tips
    on<LoadCulturalTips>(_onLoadCulturalTips);
    on<SubmitCulturalTip>(_onSubmitCulturalTip);
    on<LikeCulturalTip>(_onLikeCulturalTip);

    // Dating Etiquette
    on<LoadDatingEtiquette>(_onLoadDatingEtiquette);
    on<LoadAvailableCountries>(_onLoadAvailableCountries);
  }
  final CulturalExchangeRepository repository;

  // ==================== Initialization ====================

  Future<void> _onLoadCulturalExchangeData(
    LoadCulturalExchangeData event,
    Emitter<CulturalExchangeState> emit,
  ) async {
    emit(state.copyWith(status: CulturalExchangeStatus.loading));

    // Load all initial data in parallel. The hub shows the 10 newest tips,
    // so fetch exactly those (was 50). The hub renders right away with
    // per-section loaders (as before); the handler stays alive until all
    // three finish.
    final all = Future.wait([
      _loadSpotlight(emit),
      _loadTips(const LoadCulturalTips(limit: _hubTipsLimit), emit),
      _loadCountries(emit),
    ]);

    emit(state.copyWith(status: CulturalExchangeStatus.loaded));
    await all;
  }

  // ==================== Spotlight Handlers ====================

  /// Tips shown on the hub.
  static const int _hubTipsLimit = 10;

  Future<void> _onLoadActiveSpotlight(
    LoadActiveSpotlight event,
    Emitter<CulturalExchangeState> emit,
  ) =>
      _loadSpotlight(emit);

  Future<void> _loadSpotlight(Emitter<CulturalExchangeState> emit) async {
    emit(state.copyWith(isSpotlightLoading: true));

    // Instant paint of the spotlight shown last time (local), then refresh.
    if (state.activeSpotlight == null) {
      final cached = await repository.getCachedActiveSpotlight();
      if (cached != null && state.activeSpotlight == null) {
        emit(state.copyWith(activeSpotlight: cached));
      }
    }

    try {
      final spotlight = await repository.getActiveSpotlight();
      emit(state.copyWith(
        isSpotlightLoading: false,
        activeSpotlight: spotlight,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSpotlightLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadSpotlightHistory(
    LoadSpotlightHistory event,
    Emitter<CulturalExchangeState> emit,
  ) async {
    emit(state.copyWith(isSpotlightLoading: true));

    try {
      final history = await repository.getSpotlightHistory();
      emit(state.copyWith(
        isSpotlightLoading: false,
        spotlightHistory: history,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSpotlightLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  // ==================== Cultural Tips Handlers ====================

  Future<void> _onLoadCulturalTips(
    LoadCulturalTips event,
    Emitter<CulturalExchangeState> emit,
  ) =>
      _loadTips(event, emit);

  Future<void> _loadTips(
    LoadCulturalTips event,
    Emitter<CulturalExchangeState> emit,
  ) async {
    emit(state.copyWith(isTipsLoading: true));

    try {
      final tips = await repository.getCulturalTips(
        country: event.country,
        category: event.category,
        limit: event.limit,
      );
      emit(state.copyWith(
        isTipsLoading: false,
        culturalTips: tips,
      ));
    } catch (e) {
      emit(state.copyWith(
        isTipsLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSubmitCulturalTip(
    SubmitCulturalTip event,
    Emitter<CulturalExchangeState> emit,
  ) async {
    try {
      await repository.submitCulturalTip(event.tip);
      // Refresh tips after submission
      add(const LoadCulturalTips(limit: _hubTipsLimit));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onLikeCulturalTip(
    LikeCulturalTip event,
    Emitter<CulturalExchangeState> emit,
  ) async {
    try {
      await repository.likeCulturalTip(event.tipId, event.userId);

      // Optimistically update the like count in the local state
      final updatedTips = state.culturalTips.map((tip) {
        if (tip.id == event.tipId) {
          return tip.copyWith(likes: tip.likes + 1);
        }
        return tip;
      }).toList();

      emit(state.copyWith(culturalTips: updatedTips));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  // ==================== Dating Etiquette Handlers ====================

  Future<void> _onLoadDatingEtiquette(
    LoadDatingEtiquette event,
    Emitter<CulturalExchangeState> emit,
  ) async {
    emit(state.copyWith(isEtiquetteLoading: true));

    try {
      final etiquette = await repository.getDatingEtiquette(event.country);
      emit(state.copyWith(
        isEtiquetteLoading: false,
        selectedEtiquette: etiquette,
      ));
    } catch (e) {
      emit(state.copyWith(
        isEtiquetteLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadAvailableCountries(
    LoadAvailableCountries event,
    Emitter<CulturalExchangeState> emit,
  ) =>
      _loadCountries(emit);

  Future<void> _loadCountries(Emitter<CulturalExchangeState> emit) async {
    // The list is admin-seeded and rarely changes: a copy saved within the
    // last day is used as-is (no full-collection read); an older one paints
    // first while the server refreshes it.
    final fresh = await repository.getCachedAvailableCountries(
        maxAge: const Duration(days: 1));
    if (fresh.isNotEmpty) {
      emit(state.copyWith(availableCountries: fresh));
      return;
    }
    if (state.availableCountries.isEmpty) {
      final stale = await repository.getCachedAvailableCountries();
      if (stale.isNotEmpty) emit(state.copyWith(availableCountries: stale));
    }
    try {
      final countries = await repository.getAvailableCountries();
      emit(state.copyWith(availableCountries: countries));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
