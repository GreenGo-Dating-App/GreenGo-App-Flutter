import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/vibe_tag.dart';
import '../../domain/usecases/vibe_tag_usecases.dart';
import 'vibe_tag_event.dart';
import 'vibe_tag_state.dart';

/// Vibe Tag BLoC
/// Manages vibe tag selection and display
class VibeTagBloc extends Bloc<VibeTagEvent, VibeTagState> {
  final GetVibeTags getVibeTags;
  final GetVibeTagsByCategory getVibeTagsByCategory;
  final GetUserVibeTags getUserVibeTags;
  final UpdateUserVibeTags updateUserVibeTags;
  final SetTemporaryVibeTag setTemporaryVibeTag;
  final RemoveVibeTag removeVibeTag;
  final SearchUsersByVibeTags searchUsersByVibeTags;

  // Cache for tags
  List<VibeTag> _cachedTags = [];
  UserVibeTags? _cachedUserTags;
  bool _isPremium = false;

  VibeTagBloc({
    required this.getVibeTags,
    required this.getVibeTagsByCategory,
    required this.getUserVibeTags,
    required this.updateUserVibeTags,
    required this.setTemporaryVibeTag,
    required this.removeVibeTag,
    required this.searchUsersByVibeTags,
  }) : super(const VibeTagInitial()) {
    on<LoadVibeTags>(_onLoadVibeTags);
    on<LoadVibeTagsByCategory>(_onLoadVibeTagsByCategory);
    on<LoadUserVibeTags>(_onLoadUserVibeTags);
    on<SubscribeToUserVibeTags>(_onSubscribeToUserVibeTags);
    on<UpdateUserVibeTagsEvent>(_onUpdateUserVibeTags);
    on<AddVibeTag>(_onAddVibeTag);
    on<RemoveVibeTagEvent>(_onRemoveVibeTag);
    on<SetTemporaryVibeTagEvent>(_onSetTemporaryVibeTag);
    on<SearchByVibeTags>(_onSearchByVibeTags);
    on<ToggleVibeTag>(_onToggleVibeTag);
  }

  /// Set premium status (should be called from auth/subscription)
  void setPremiumStatus(bool isPremium) {
    _isPremium = isPremium;
  }

  int get _tagLimit => VibeTagLimits.getTagLimit(_isPremium);

  /// Load all available vibe tags
  Future<void> _onLoadVibeTags(
    LoadVibeTags event,
    Emitter<VibeTagState> emit,
  ) async {
    emit(const VibeTagLoading());

    final result = await getVibeTags();

    result.fold(
      (failure) => emit(VibeTagError(failure.toString())),
      (tags) {
        _cachedTags = tags;
        emit(VibeTagsLoaded(tags: tags));
      },
    );
  }

  /// Load vibe tags by category
  Future<void> _onLoadVibeTagsByCategory(
    LoadVibeTagsByCategory event,
    Emitter<VibeTagState> emit,
  ) async {
    emit(const VibeTagLoading());

    final result = await getVibeTagsByCategory(event.category);

    result.fold(
      (failure) => emit(VibeTagError(failure.toString())),
      (tags) => emit(VibeTagsLoaded(tags: tags)),
    );
  }

  /// Load user's selected vibe tags
  Future<void> _onLoadUserVibeTags(
    LoadUserVibeTags event,
    Emitter<VibeTagState> emit,
  ) async {
    emit(const VibeTagLoading());

    // Load both all tags and user tags
    final tagsResult = await getVibeTags();
    final userTagsResult = await getUserVibeTags(event.userId);

    tagsResult.fold(
      (failure) => emit(VibeTagError(failure.toString())),
      (tags) {
        _cachedTags = tags;
        userTagsResult.fold(
          (failure) => emit(VibeTagError(failure.toString())),
          (userTags) {
            _cachedUserTags = userTags;
            _emitSelectionState(emit);
          },
        );
      },
    );
  }

  /// Subscribe to user's vibe tags stream
  Future<void> _onSubscribeToUserVibeTags(
    SubscribeToUserVibeTags event,
    Emitter<VibeTagState> emit,
  ) async {
    // First load all tags if not cached
    if (_cachedTags.isEmpty) {
      final tagsResult = await getVibeTags();
      tagsResult.fold(
        (failure) => emit(VibeTagError(failure.toString())),
        (tags) => _cachedTags = tags,
      );
    }

    // Then subscribe to user tags stream
    await emit.forEach(
      getUserVibeTags.stream(event.userId),
      onData: (result) {
        return result.fold(
          (failure) => VibeTagError(failure.toString()),
          (userTags) {
            _cachedUserTags = userTags;
            return _createSelectionState();
          },
        );
      },
    );
  }

  /// Update user's selected vibe tags
  Future<void> _onUpdateUserVibeTags(
    UpdateUserVibeTagsEvent event,
    Emitter<VibeTagState> emit,
  ) async {
    emit(const VibeTagLoading());

    final result = await updateUserVibeTags(
      userId: event.userId,
      tagIds: event.tagIds,
    );

    result.fold(
      (failure) => emit(VibeTagError(failure.toString())),
      (userTags) {
        _cachedUserTags = userTags;
        emit(UserVibeTagsUpdated(userTags));
        _emitSelectionState(emit);
      },
    );
  }

  /// Add a vibe tag to user's selection
  Future<void> _onAddVibeTag(
    AddVibeTag event,
    Emitter<VibeTagState> emit,
  ) async {
    final currentTags = _cachedUserTags?.selectedTagIds ?? [];

    // Check limit
    if (currentTags.length >= _tagLimit) {
      emit(VibeTagLimitReached(
        currentCount: currentTags.length,
        limit: _tagLimit,
        isPremium: _isPremium,
      ));
      return;
    }

    // Don't add duplicates
    if (currentTags.contains(event.tagId)) {
      return;
    }

    final newTags = [...currentTags, event.tagId];
    add(UpdateUserVibeTagsEvent(userId: event.userId, tagIds: newTags));
  }

  /// Remove a vibe tag from user's selection
  Future<void> _onRemoveVibeTag(
    RemoveVibeTagEvent event,
    Emitter<VibeTagState> emit,
  ) async {
    emit(const VibeTagLoading());

    final result = await removeVibeTag(
      userId: event.userId,
      tagId: event.tagId,
    );

    result.fold(
      (failure) => emit(VibeTagError(failure.toString())),
      (userTags) {
        _cachedUserTags = userTags;
        emit(VibeTagRemoved(tagId: event.tagId, userTags: userTags));
        _emitSelectionState(emit);
      },
    );
  }

  /// Set a temporary vibe tag (24 hours)
  Future<void> _onSetTemporaryVibeTag(
    SetTemporaryVibeTagEvent event,
    Emitter<VibeTagState> emit,
  ) async {
    emit(const VibeTagLoading());

    final result = await setTemporaryVibeTag(
      userId: event.userId,
      tagId: event.tagId,
    );

    result.fold(
      (failure) => emit(VibeTagError(failure.toString())),
      (userTags) {
        _cachedUserTags = userTags;
        emit(TemporaryVibeTagSet(
          userTags: userTags,
          expiresAt: userTags.temporaryTagExpiresAt ?? DateTime.now(),
        ));
        _emitSelectionState(emit);
      },
    );
  }

  /// Search users by vibe tags
  Future<void> _onSearchByVibeTags(
    SearchByVibeTags event,
    Emitter<VibeTagState> emit,
  ) async {
    emit(const VibeTagLoading());

    final result = await searchUsersByVibeTags(
      tagIds: event.tagIds,
      limit: event.limit,
      lastUserId: event.lastUserId,
    );

    result.fold(
      (failure) => emit(VibeTagError(failure.toString())),
      (userIds) => emit(VibeTagSearchResults(
        userIds: userIds,
        searchedTagIds: event.tagIds,
        hasMore: userIds.length >= event.limit,
      )),
    );
  }

  /// Toggle a vibe tag selection
  Future<void> _onToggleVibeTag(
    ToggleVibeTag event,
    Emitter<VibeTagState> emit,
  ) async {
    final currentTags = _cachedUserTags?.selectedTagIds ?? [];

    if (currentTags.contains(event.tagId)) {
      // Remove tag
      add(RemoveVibeTagEvent(userId: event.userId, tagId: event.tagId));
    } else {
      // Add tag
      add(AddVibeTag(userId: event.userId, tagId: event.tagId));
    }
  }

  /// Create selection state from cached data
  VibeTagSelectionState _createSelectionState() {
    final tagsByCategory = <String, List<VibeTag>>{};
    for (final tag in _cachedTags) {
      if (!tagsByCategory.containsKey(tag.category)) {
        tagsByCategory[tag.category] = [];
      }
      tagsByCategory[tag.category]!.add(tag);
    }

    return VibeTagSelectionState(
      allTags: _cachedTags,
      tagsByCategory: tagsByCategory,
      userTags: _cachedUserTags ??
          UserVibeTags(
            userId: '',
            selectedTagIds: [],
            updatedAt: DateTime.now(),
          ),
      tagLimit: _tagLimit,
      isPremium: _isPremium,
    );
  }

  /// Emit selection state
  void _emitSelectionState(Emitter<VibeTagState> emit) {
    emit(_createSelectionState());
  }
}
