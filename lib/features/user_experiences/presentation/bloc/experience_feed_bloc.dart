import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_experience.dart';
import '../../domain/repositories/user_experiences_repository.dart';

// ───────────────────────────────────────────────────────────── events

abstract class ExperienceFeedEvent extends Equatable {
  const ExperienceFeedEvent();
  @override
  List<Object?> get props => [];
}

/// (Re)load page 1 of the community feed — or, with [hostId], of the host's
/// own experiences ("My experiences").
class ExperienceFeedStarted extends ExperienceFeedEvent {
  const ExperienceFeedStarted({
    this.lat,
    this.lng,
    this.category,
    this.query = '',
    this.hostId,
  });
  final double? lat;
  final double? lng;
  final ExperienceCategory? category;
  final String query;
  final String? hostId;

  @override
  List<Object?> get props => [lat, lng, category, query, hostId];
}

class ExperienceFeedMoreRequested extends ExperienceFeedEvent {
  const ExperienceFeedMoreRequested();
}

class ExperienceFeedRefreshed extends ExperienceFeedEvent {
  const ExperienceFeedRefreshed();
}

/// Local list edits after create / edit / delete (no re-query needed).
class ExperienceFeedItemRemoved extends ExperienceFeedEvent {
  const ExperienceFeedItemRemoved(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class ExperienceFeedItemUpserted extends ExperienceFeedEvent {
  const ExperienceFeedItemUpserted(this.experience);
  final UserExperience experience;
  @override
  List<Object?> get props => [experience];
}

// ───────────────────────────────────────────────────────────── state

enum ExperienceFeedStatus { initial, loading, ready, failure }

class ExperienceFeedState extends Equatable {
  const ExperienceFeedState({
    this.status = ExperienceFeedStatus.initial,
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
  });

  final ExperienceFeedStatus status;
  final List<UserExperience> items;
  final bool hasMore;
  final bool loadingMore;

  ExperienceFeedState copyWith({
    ExperienceFeedStatus? status,
    List<UserExperience>? items,
    bool? hasMore,
    bool? loadingMore,
  }) =>
      ExperienceFeedState(
        status: status ?? this.status,
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );

  @override
  List<Object?> get props => [status, items, hasMore, loadingMore];
}

// ───────────────────────────────────────────────────────────── bloc

/// Paginated (20 per page) infinite-scroll feed of experiences.
class ExperienceFeedBloc extends Bloc<ExperienceFeedEvent, ExperienceFeedState> {
  ExperienceFeedBloc({required UserExperiencesRepository repository})
      : _repo = repository,
        super(const ExperienceFeedState()) {
    on<ExperienceFeedStarted>(_onStarted);
    on<ExperienceFeedMoreRequested>(_onMore);
    on<ExperienceFeedRefreshed>(_onRefresh);
    on<ExperienceFeedItemRemoved>(_onRemoved);
    on<ExperienceFeedItemUpserted>(_onUpserted);
  }

  final UserExperiencesRepository _repo;
  ExperienceFeedPager? _pager;
  ExperienceFeedStarted? _last;
  final Set<String> _ids = {};

  /// Empty pages a sparse nearest-first scan may return before the next ring;
  /// read on (bounded) so the list never sits empty while more exist.
  static const int _maxEmptyPages = 3;

  ExperienceFeedPager _newPager(ExperienceFeedStarted e) => e.hostId != null
      ? _repo.hostFeed(e.hostId!)
      : _repo.communityFeed(
          lat: e.lat, lng: e.lng, category: e.category, query: e.query);

  Future<List<UserExperience>> _page(ExperienceFeedPager pager) async {
    var page = await pager.next();
    var guard = 0;
    while (page.isEmpty && pager.hasMore && guard++ < _maxEmptyPages) {
      page = await pager.next();
    }
    return page;
  }

  List<UserExperience> _unique(Iterable<UserExperience> page) =>
      [for (final e in page) if (_ids.add(e.id)) e];

  Future<void> _onStarted(
      ExperienceFeedStarted e, Emitter<ExperienceFeedState> emit) async {
    _last = e;
    await _load(emit, keepVisible: false);
  }

  Future<void> _onRefresh(
      ExperienceFeedRefreshed e, Emitter<ExperienceFeedState> emit) async {
    if (_last == null) return;
    await _load(emit, keepVisible: true);
  }

  Future<void> _load(Emitter<ExperienceFeedState> emit,
      {required bool keepVisible}) async {
    final pager = _newPager(_last!);
    _pager = pager;
    if (!keepVisible) {
      emit(const ExperienceFeedState(status: ExperienceFeedStatus.loading));
    }
    try {
      final page = await _page(pager);
      if (!identical(pager, _pager)) return; // superseded
      _ids.clear();
      emit(ExperienceFeedState(
        status: ExperienceFeedStatus.ready,
        items: _unique(page),
        hasMore: pager.hasMore,
      ));
    } catch (_) {
      if (!identical(pager, _pager)) return;
      emit(state.copyWith(
        status: state.items.isEmpty
            ? ExperienceFeedStatus.failure
            : ExperienceFeedStatus.ready,
        hasMore: false,
      ));
    }
  }

  Future<void> _onMore(
      ExperienceFeedMoreRequested e, Emitter<ExperienceFeedState> emit) async {
    final pager = _pager;
    if (pager == null || state.loadingMore || !pager.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _page(pager);
      if (!identical(pager, _pager)) return;
      emit(state.copyWith(
        items: [...state.items, ..._unique(page)],
        hasMore: pager.hasMore,
        loadingMore: false,
      ));
    } catch (_) {
      if (!identical(pager, _pager)) return;
      emit(state.copyWith(loadingMore: false));
    }
  }

  void _onRemoved(
      ExperienceFeedItemRemoved e, Emitter<ExperienceFeedState> emit) {
    _ids.remove(e.id);
    emit(state.copyWith(
        items: state.items.where((x) => x.id != e.id).toList()));
  }

  void _onUpserted(
      ExperienceFeedItemUpserted e, Emitter<ExperienceFeedState> emit) {
    final x = e.experience;
    final i = state.items.indexWhere((it) => it.id == x.id);
    final items = [...state.items];
    if (i >= 0) {
      items[i] = x;
    } else {
      _ids.add(x.id);
      items.insert(0, x);
    }
    emit(state.copyWith(items: items, status: ExperienceFeedStatus.ready));
  }
}
