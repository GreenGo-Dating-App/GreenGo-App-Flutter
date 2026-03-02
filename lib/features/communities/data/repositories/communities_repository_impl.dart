import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_member.dart';
import '../../domain/entities/community_message.dart';
import '../../domain/repositories/communities_repository.dart';
import '../datasources/communities_remote_datasource.dart';
import '../models/community_model.dart';
import '../models/community_member_model.dart';
import '../models/community_message_model.dart';

/// Communities Repository Implementation
class CommunitiesRepositoryImpl implements CommunitiesRepository {
  final CommunitiesRemoteDataSource remoteDataSource;

  CommunitiesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Community>>> getCommunities({
    CommunityType? type,
    String? language,
    String? city,
    String? searchQuery,
  }) async {
    try {
      final communities = await remoteDataSource.getCommunities(
        type: type,
        language: language,
        city: city,
        searchQuery: searchQuery,
      );
      return Right(communities.map((c) => c.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Community>> getCommunityById(
    String communityId,
  ) async {
    try {
      final community = await remoteDataSource.getCommunityById(communityId);
      return Right(community.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Community>> createCommunity(
    Community community,
  ) async {
    try {
      final model = CommunityModel.fromEntity(community);
      final created = await remoteDataSource.createCommunity(model);
      return Right(created.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCommunity(Community community) async {
    try {
      final model = CommunityModel.fromEntity(community);
      await remoteDataSource.updateCommunity(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCommunity(String communityId) async {
    try {
      await remoteDataSource.deleteCommunity(communityId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> joinCommunity({
    required String communityId,
    required CommunityMember member,
  }) async {
    try {
      final model = CommunityMemberModel.fromEntity(member);
      await remoteDataSource.joinCommunity(
        communityId: communityId,
        member: model,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> leaveCommunity({
    required String communityId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.leaveCommunity(
        communityId: communityId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CommunityMember>>> getCommunityMembers(
    String communityId,
  ) async {
    try {
      final members =
          await remoteDataSource.getCommunityMembers(communityId);
      return Right(members.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<CommunityMessage>>> getCommunityMessages(
    String communityId, {
    int? limit,
  }) {
    try {
      return remoteDataSource
          .getCommunityMessages(communityId, limit: limit)
          .map((messages) => Right<Failure, List<CommunityMessage>>(
                messages.map((m) => m.toEntity()).toList(),
              ))
          .handleError((error) {
        return Left<Failure, List<CommunityMessage>>(
          ServerFailure(error.toString()),
        );
      });
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, CommunityMessage>> sendMessage({
    required String communityId,
    required CommunityMessage message,
  }) async {
    try {
      final model = CommunityMessageModel.fromEntity(message);
      final sent = await remoteDataSource.sendMessage(
        communityId: communityId,
        message: model,
      );
      return Right(sent.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Community>>> getUserCommunities(
    String userId,
  ) async {
    try {
      final communities = await remoteDataSource.getUserCommunities(userId);
      return Right(communities.map((c) => c.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Community>>> getRecommendedCommunities({
    required String userId,
    required List<String> languages,
    List<String> interests = const [],
  }) async {
    try {
      final communities = await remoteDataSource.getRecommendedCommunities(
        userId: userId,
        languages: languages,
        interests: interests,
      );
      return Right(communities.map((c) => c.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isMember({
    required String communityId,
    required String userId,
  }) async {
    try {
      final result = await remoteDataSource.isMember(
        communityId: communityId,
        userId: userId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMemberRole({
    required String communityId,
    required String userId,
    required CommunityRole newRole,
  }) async {
    try {
      await remoteDataSource.updateMemberRole(
        communityId: communityId,
        userId: userId,
        newRole: newRole,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
