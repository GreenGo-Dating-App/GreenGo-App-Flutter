import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_member.dart';
import '../../domain/entities/community_message.dart';
import '../../domain/repositories/communities_repository.dart';
import '../../data/datasources/communities_remote_datasource.dart';
import 'communities_event.dart';
import 'communities_state.dart';

/// Communities BLoC
///
/// Manages state for the communities feature including
/// interest groups, language circles, and local guide program
class CommunitiesBloc extends Bloc<CommunitiesEvent, CommunitiesState> {
  final CommunitiesRepository _repository;
  final CommunitiesRemoteDataSource _remoteDataSource;

  StreamSubscription? _messagesSubscription;

  CommunitiesBloc({
    required CommunitiesRepository repository,
    required CommunitiesRemoteDataSource remoteDataSource,
  })  : _repository = repository,
        _remoteDataSource = remoteDataSource,
        super(const CommunitiesInitial()) {
    on<LoadCommunities>(_onLoadCommunities);
    on<LoadUserCommunities>(_onLoadUserCommunities);
    on<LoadRecommendedCommunities>(_onLoadRecommendedCommunities);
    on<LoadCommunityDetail>(_onLoadCommunityDetail);
    on<CreateCommunity>(_onCreateCommunity);
    on<JoinCommunity>(_onJoinCommunity);
    on<LeaveCommunity>(_onLeaveCommunity);
    on<SendCommunityMessage>(_onSendMessage);
    on<SubscribeToCommunityMessages>(_onSubscribeToMessages);
    on<CommunityMessagesUpdated>(_onMessagesUpdated);
    on<SeedSampleCommunities>(_onSeedSampleCommunities);
  }

  Future<void> _onLoadCommunities(
    LoadCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    emit(const CommunitiesLoading());

    final result = await _repository.getCommunities(
      type: event.type,
      language: event.language,
      city: event.city,
      searchQuery: event.searchQuery,
    );

    result.fold(
      (failure) => emit(CommunitiesError(message: failure.message)),
      (communities) {
        // Separate language circles from other communities
        final languageCircles = communities
            .where((c) => c.type == CommunityType.languageCircle)
            .toList();

        emit(CommunitiesLoaded(
          communities: communities,
          languageCircles: languageCircles,
        ));
      },
    );
  }

  Future<void> _onLoadUserCommunities(
    LoadUserCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    // Preserve current state data if available
    final currentState = state;
    List<Community> allCommunities = [];
    List<Community> recommended = [];
    List<Community> languageCircles = [];

    if (currentState is CommunitiesLoaded) {
      allCommunities = currentState.communities;
      recommended = currentState.recommended;
      languageCircles = currentState.languageCircles;
    }

    emit(const CommunitiesLoading());

    final result = await _repository.getUserCommunities(event.userId);

    result.fold(
      (failure) => emit(CommunitiesError(message: failure.message)),
      (userCommunities) {
        emit(CommunitiesLoaded(
          communities: allCommunities,
          userCommunities: userCommunities,
          recommended: recommended,
          languageCircles: languageCircles,
        ));
      },
    );
  }

  Future<void> _onLoadRecommendedCommunities(
    LoadRecommendedCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    final currentState = state;
    List<Community> allCommunities = [];
    List<Community> userCommunities = [];
    List<Community> languageCircles = [];

    if (currentState is CommunitiesLoaded) {
      allCommunities = currentState.communities;
      userCommunities = currentState.userCommunities;
      languageCircles = currentState.languageCircles;
    }

    final result = await _repository.getRecommendedCommunities(
      userId: event.userId,
      languages: event.languages,
      interests: event.interests,
    );

    result.fold(
      (failure) => emit(CommunitiesError(message: failure.message)),
      (recommended) {
        emit(CommunitiesLoaded(
          communities: allCommunities,
          userCommunities: userCommunities,
          recommended: recommended,
          languageCircles: languageCircles,
        ));
      },
    );
  }

  Future<void> _onLoadCommunityDetail(
    LoadCommunityDetail event,
    Emitter<CommunitiesState> emit,
  ) async {
    emit(const CommunitiesLoading());

    final communityResult =
        await _repository.getCommunityById(event.communityId);

    await communityResult.fold(
      (failure) async =>
          emit(CommunitiesError(message: failure.message)),
      (community) async {
        final membersResult =
            await _repository.getCommunityMembers(event.communityId);

        final members = membersResult.fold(
          (failure) => <CommunityMember>[],
          (members) => members,
        );

        emit(CommunityDetailLoaded(
          community: community,
          members: members,
          messages: const [],
          isMember: false,
        ));
      },
    );
  }

  Future<void> _onCreateCommunity(
    CreateCommunity event,
    Emitter<CommunitiesState> emit,
  ) async {
    emit(const CommunitiesLoading());

    final result = await _repository.createCommunity(event.community);

    result.fold(
      (failure) => emit(CommunitiesError(message: failure.message)),
      (community) async {
        // Auto-join the creator as owner
        final member = CommunityMember(
          userId: event.userId,
          displayName: event.userName,
          role: CommunityRole.owner,
          joinedAt: DateTime.now(),
        );

        await _repository.joinCommunity(
          communityId: community.id,
          member: member,
        );

        emit(CommunityCreated(community: community));
      },
    );
  }

  Future<void> _onJoinCommunity(
    JoinCommunity event,
    Emitter<CommunitiesState> emit,
  ) async {
    final member = CommunityMember(
      userId: event.userId,
      displayName: event.displayName,
      photoUrl: event.photoUrl,
      role: CommunityRole.member,
      joinedAt: DateTime.now(),
      languages: event.languages,
      isLocalGuide: event.isLocalGuide,
    );

    final result = await _repository.joinCommunity(
      communityId: event.communityId,
      member: member,
    );

    result.fold(
      (failure) => emit(CommunitiesError(message: failure.message)),
      (_) {
        emit(CommunityJoined(communityId: event.communityId));

        // Refresh detail if currently viewing this community
        add(LoadCommunityDetail(communityId: event.communityId));
      },
    );
  }

  Future<void> _onLeaveCommunity(
    LeaveCommunity event,
    Emitter<CommunitiesState> emit,
  ) async {
    final result = await _repository.leaveCommunity(
      communityId: event.communityId,
      userId: event.userId,
    );

    result.fold(
      (failure) => emit(CommunitiesError(message: failure.message)),
      (_) => emit(CommunityLeft(communityId: event.communityId)),
    );
  }

  Future<void> _onSendMessage(
    SendCommunityMessage event,
    Emitter<CommunitiesState> emit,
  ) async {
    final currentState = state;
    if (currentState is CommunityDetailLoaded) {
      emit(currentState.copyWith(isSending: true));
    }

    final message = CommunityMessage(
      id: '',
      communityId: event.communityId,
      senderId: event.senderId,
      senderName: event.senderName,
      senderPhotoUrl: event.senderPhotoUrl,
      content: event.content,
      sentAt: DateTime.now(),
      type: event.type,
    );

    final result = await _repository.sendMessage(
      communityId: event.communityId,
      message: message,
    );

    result.fold(
      (failure) => emit(CommunitiesError(message: failure.message)),
      (sentMessage) {
        if (currentState is CommunityDetailLoaded) {
          emit(currentState.copyWith(isSending: false));
        }
      },
    );
  }

  void _onSubscribeToMessages(
    SubscribeToCommunityMessages event,
    Emitter<CommunitiesState> emit,
  ) {
    _messagesSubscription?.cancel();

    _messagesSubscription = _repository
        .getCommunityMessages(event.communityId)
        .listen(
      (result) {
        result.fold(
          (failure) {
            debugPrint('Message stream error: ${failure.message}');
          },
          (messages) {
            add(CommunityMessagesUpdated(messages: messages));
          },
        );
      },
      onError: (error) {
        debugPrint('Message stream error: $error');
      },
    );
  }

  void _onMessagesUpdated(
    CommunityMessagesUpdated event,
    Emitter<CommunitiesState> emit,
  ) {
    final currentState = state;
    if (currentState is CommunityDetailLoaded) {
      emit(currentState.copyWith(messages: event.messages));
    }
  }

  Future<void> _onSeedSampleCommunities(
    SeedSampleCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    try {
      await _remoteDataSource.seedSampleCommunities();
    } catch (e) {
      debugPrint('Error seeding communities: $e');
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
