import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/buddy.dart';
import '../../domain/entities/buddy_status.dart';
import '../../domain/repositories/buddies_repository.dart';

// ---------------------------------------------------------------- events

sealed class BuddiesListEvent extends Equatable {
  const BuddiesListEvent();
  @override
  List<Object?> get props => [];
}

/// Start listening to the user's Buddies and load the plan status.
class BuddiesListStarted extends BuddiesListEvent {
  const BuddiesListStarted(this.uid);
  final String uid;
  @override
  List<Object?> get props => [uid];
}

/// Reload `getBuddyStatus` (after create / delete / a sent message).
class BuddiesStatusRequested extends BuddiesListEvent {
  const BuddiesStatusRequested();
}

class _BuddiesStatusLoaded extends BuddiesListEvent {
  const _BuddiesStatusLoaded(this.status);
  final BuddyStatus status;
  @override
  List<Object?> get props => [status];
}

// ----------------------------------------------------------------- state

/// One row of the Buddies tab.
class BuddyListItem extends Equatable {
  const BuddyListItem({required this.buddy, required this.locked});
  final Buddy buddy;

  /// Beyond the plan limit after a downgrade (the NEWEST Buddies; the server
  /// keeps the oldest [BuddyStatus.buddyLimit] usable).
  final bool locked;
  @override
  List<Object?> get props => [buddy, locked];
}

class BuddiesListState extends Equatable {
  const BuddiesListState({
    this.loading = true,
    this.items = const <BuddyListItem>[],
    this.status,
    this.error,
  });

  final bool loading;

  /// Most recent activity first.
  final List<BuddyListItem> items;
  final BuddyStatus? status;

  /// The list could not be loaded (raw error, for the user-error mapping).
  final Object? error;

  bool get isEmpty => !loading && items.isEmpty && error == null;

  /// Count shown in "2 of 3": the Buddies the user actually has.
  int get buddyCount => items.isNotEmpty ? items.length : (status?.buddyCount ?? 0);

  bool get canCreateMore => status == null || buddyCount < status!.buddyLimit;

  BuddiesListState copyWith({
    bool? loading,
    List<BuddyListItem>? items,
    BuddyStatus? status,
    Object? Function()? error,
  }) =>
      BuddiesListState(
        loading: loading ?? this.loading,
        items: items ?? this.items,
        status: status ?? this.status,
        error: error != null ? error() : this.error,
      );

  @override
  List<Object?> get props => [loading, items, status, error];
}

/// Locked = beyond the [limit] oldest Buddies (by creation), as on the server
/// (`activeBuddyIds`). Returned most-recent-activity first. Pure; tested.
List<BuddyListItem> buddyListItems(List<Buddy> buddies, int? limit) {
  final byCreation = [...buddies]..sort((a, b) {
      final ca = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final cb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return ca.compareTo(cb);
    });
  final active = <String>{
    for (var i = 0; i < byCreation.length; i++)
      if (limit == null || i < limit) byCreation[i].id,
  };
  final items = [
    for (final b in buddies) BuddyListItem(buddy: b, locked: !active.contains(b.id)),
  ]..sort((a, b) => b.buddy.activityAt.compareTo(a.buddy.activityAt));
  return items;
}

// ------------------------------------------------------------------ bloc

/// The Buddies tab: the user's Buddies (live) + plan usage + free replies.
class BuddiesListBloc extends Bloc<BuddiesListEvent, BuddiesListState> {
  BuddiesListBloc({required BuddiesRepository repository})
      : _repo = repository,
        super(const BuddiesListState()) {
    on<BuddiesListStarted>(_onStarted);
    on<BuddiesStatusRequested>(_onStatusRequested);
    on<_BuddiesStatusLoaded>(_onStatusLoaded);
  }

  final BuddiesRepository _repo;
  List<Buddy> _buddies = const <Buddy>[];

  Future<void> _onStarted(BuddiesListStarted event, Emitter<BuddiesListState> emit) async {
    emit(const BuddiesListState());
    add(const BuddiesStatusRequested());
    await emit.forEach<List<Buddy>>(
      _repo.watchBuddies(event.uid),
      onData: (buddies) {
        _buddies = buddies;
        return state.copyWith(
          loading: false,
          items: buddyListItems(buddies, state.status?.buddyLimit),
          error: () => null,
        );
      },
      onError: (e, _) => state.copyWith(loading: false, error: () => e),
    );
  }

  Future<void> _onStatusRequested(
      BuddiesStatusRequested event, Emitter<BuddiesListState> emit) async {
    try {
      final status = await _repo.getStatus();
      if (!isClosed) add(_BuddiesStatusLoaded(status));
    } catch (_) {
      // Status is informative only (usage line, locks); the server enforces.
    }
  }

  void _onStatusLoaded(_BuddiesStatusLoaded event, Emitter<BuddiesListState> emit) {
    emit(state.copyWith(
      status: event.status,
      items: buddyListItems(_buddies, event.status.buddyLimit),
    ));
  }
}
