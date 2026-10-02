import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';

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
  BookingsListBloc({required BookingsRepository repository})
      : _repo = repository,
        super(const BookingsListState()) {
    on<BookingsListStarted>(_onStarted);
    on<BookingsListRefreshed>(_onRefreshed);
    on<BookingsListMoreRequested>(_onMore);
    on<BookingsListItemUpdated>(_onItem);
  }

  static const int pageSize = 20;

  final BookingsRepository _repo;
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
    if (!keepItems) emit(const BookingsListState());
    final r = await _repo.bookings(_query!, limit: pageSize);
    r.fold(
      (_) => emit(state.copyWith(status: BookingsListStatus.failure)),
      (p) {
        _cursor = p.cursor;
        emit(BookingsListState(
          status: BookingsListStatus.ready,
          items: p.items,
          hasMore: p.hasMore,
        ));
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
