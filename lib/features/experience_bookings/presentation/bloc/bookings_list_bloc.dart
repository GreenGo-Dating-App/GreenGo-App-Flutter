import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../bookings_first_page_cache.dart';

abstract class BookingsListEvent extends Equatable {
  const BookingsListEvent();
  @override
  List<Object?> get props => [];
}

class BookingsListStarted extends BookingsListEvent {
  const BookingsListStarted(this.query);
  final BookingsQuery query;
  @override
  List<Object?> get props => [query];
}

class BookingsListMoreRequested extends BookingsListEvent {
  const BookingsListMoreRequested();
}

class BookingsListRefreshed extends BookingsListEvent {
  const BookingsListRefreshed();
}

/// A booking changed on its detail page: patch it in place.
class BookingsListItemUpdated extends BookingsListEvent {
  const BookingsListItemUpdated(this.booking);
  final Booking booking;
  @override
  List<Object?> get props => [booking];
}

enum BookingsListStatus { loading, ready, failure }

class BookingsListState extends Equatable {
  const BookingsListState({
    this.status = BookingsListStatus.loading,
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
  });

  final BookingsListStatus status;
  final List<Booking> items;
  final bool hasMore;
  final bool loadingMore;

  BookingsListState copyWith({
    BookingsListStatus? status,
    List<Booking>? items,
    bool? hasMore,
    bool? loadingMore,
  }) =>
      BookingsListState(
        status: status ?? this.status,
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );

  @override
  List<Object?> get props => [status, items, hasMore, loadingMore];
}

/// One tab of "My bookings" / "Bookings received": pages of [pageSize] on
/// an indexed query, infinite scroll.
class BookingsListBloc extends Bloc<BookingsListEvent, BookingsListState> {
  BookingsListBloc({
    required BookingsRepository repository,
    BookingsFirstPageCache cache = const BookingsFirstPageCache(),
  })  : _repo = repository,
        _cache = cache,
        super(const BookingsListState()) {
    on<BookingsListStarted>(_onStarted);
    on<BookingsListRefreshed>(_onRefreshed);
    on<BookingsListMoreRequested>(_onMore);
    on<BookingsListItemUpdated>(_onItem);
  }

  static const int pageSize = 20;

  final BookingsRepository _repo;
  final BookingsFirstPageCache _cache;
  BookingsQuery? _query;
  Object? _cursor;

  Future<void> _onStarted(
      BookingsListStarted e, Emitter<BookingsListState> emit) async {
    _query = e.query;
    await _first(emit);
  }

  Future<void> _onRefreshed(
      BookingsListRefreshed e, Emitter<BookingsListState> emit) async {
    if (_query == null) return;
    await _first(emit, keepItems: true);
  }

  Future<void> _first(Emitter<BookingsListState> emit,
      {bool keepItems = false}) async {
    _cursor = null;
    final query = _query!;
    if (!keepItems) {
      emit(const BookingsListState());
      // Paint the page shown last time for this tab (local cache, ms); the
      // server page replaces it. Never paints an empty result.
      final cached = await _cache.load(query);
      if (cached.isNotEmpty && identical(query, _query)) {
        emit(BookingsListState(
          status: BookingsListStatus.ready,
          items: cached,
          // No paging until the real first page is in.
          hasMore: false,
        ));
      }
    }
    final r = await _repo.bookings(query, limit: pageSize);
    if (!identical(query, _query)) return; // superseded
    r.fold(
      (_) => emit(state.items.isNotEmpty && !keepItems
          // Keep the cached paint rather than replacing it with an error.
          ? state
          : state.copyWith(status: BookingsListStatus.failure)),
      (p) {
        _cursor = p.cursor;
        emit(BookingsListState(
          status: BookingsListStatus.ready,
          items: p.items,
          hasMore: p.hasMore,
        ));
        unawaited(_cache.save(query, p.items));
      },
    );
  }

  Future<void> _onMore(
      BookingsListMoreRequested e, Emitter<BookingsListState> emit) async {
    if (_query == null ||
        state.loadingMore ||
        !state.hasMore ||
        state.status != BookingsListStatus.ready) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    final r = await _repo.bookings(_query!, cursor: _cursor, limit: pageSize);
    r.fold(
      (_) => emit(state.copyWith(loadingMore: false)),
      (p) {
        _cursor = p.cursor;
        final known = state.items.map((b) => b.id).toSet();
        emit(state.copyWith(
          loadingMore: false,
          items: [...state.items, ...p.items.where((b) => !known.contains(b.id))],
          hasMore: p.hasMore,
        ));
      },
    );
  }

  void _onItem(BookingsListItemUpdated e, Emitter<BookingsListState> emit) {
    emit(state.copyWith(items: [
      for (final b in state.items) b.id == e.booking.id ? e.booking : b,
    ]));
  }
}
