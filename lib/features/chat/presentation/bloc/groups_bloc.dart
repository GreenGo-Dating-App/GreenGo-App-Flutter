import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_user_groups.dart';
import 'groups_event.dart';
import 'groups_state.dart';

/// Groups BLoC
///
/// Streams the current user's group inbox (Culture Circles) from the per-user
/// `user_group_inbox` index — one paginated query per user, scales to millions.
class GroupsBloc extends Bloc<GroupsEvent, GroupsState> {
  GroupsBloc({required this.getUserGroups}) : super(const GroupsInitial()) {
    on<GroupsLoadRequested>(_onLoadRequested);
    on<GroupsRefreshRequested>(_onRefreshRequested);
  }

  final GetUserGroups getUserGroups;
  String? _userId;

  Future<void> _onLoadRequested(
    GroupsLoadRequested event,
    Emitter<GroupsState> emit,
  ) async {
    emit(const GroupsLoading());
    _userId = event.userId;

    await emit.forEach(
      getUserGroups(event.userId),
      onData: (result) => result.fold(
        (failure) => GroupsError(failure.message),
        (groups) =>
            groups.isEmpty ? const GroupsEmpty() : GroupsLoaded(groups: groups),
      ),
      onError: (error, _) => GroupsError('$error'),
    );
  }

  Future<void> _onRefreshRequested(
    GroupsRefreshRequested event,
    Emitter<GroupsState> emit,
  ) async {
    if (_userId != null) {
      add(GroupsLoadRequested(_userId!));
    }
  }
}
