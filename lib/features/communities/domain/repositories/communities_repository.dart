import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/community.dart';
import '../entities/community_member.dart';
import '../entities/community_message.dart';

/// Communities Repository
///
/// Contract for community data operations
abstract class CommunitiesRepository {
  /// Get all communities with optional filter
  Future<Either<Failure, List<Community>>> getCommunities({
    CommunityType? type,
    String? language,
    String? city,
    String? searchQuery,
  });

  /// Get a community by ID
  Future<Either<Failure, Community>> getCommunityById(String communityId);

  /// Create a new community
  Future<Either<Failure, Community>> createCommunity(Community community);

  /// Update an existing community
  Future<Either<Failure, void>> updateCommunity(Community community);

  /// Delete a community (owner only)
  Future<Either<Failure, void>> deleteCommunity(String communityId);

  /// Join a community
  Future<Either<Failure, void>> joinCommunity({
    required String communityId,
    required CommunityMember member,
  });

  /// Leave a community
  Future<Either<Failure, void>> leaveCommunity({
    required String communityId,
    required String userId,
  });

  /// Get members of a community
  Future<Either<Failure, List<CommunityMember>>> getCommunityMembers(
    String communityId,
  );

  /// Stream of messages for a community (real-time)
  Stream<Either<Failure, List<CommunityMessage>>> getCommunityMessages(
    String communityId, {
    int? limit,
  });

  /// Send a message to a community
  Future<Either<Failure, CommunityMessage>> sendMessage({
    required String communityId,
    required CommunityMessage message,
  });

  /// Get communities the user has joined
  Future<Either<Failure, List<Community>>> getUserCommunities(String userId);

  /// Get recommended communities for a user based on languages and interests
  Future<Either<Failure, List<Community>>> getRecommendedCommunities({
    required String userId,
    required List<String> languages,
    List<String> interests,
  });

  /// Check if user is a member of a community
  Future<Either<Failure, bool>> isMember({
    required String communityId,
    required String userId,
  });

  /// Update member role (admin/owner only)
  Future<Either<Failure, void>> updateMemberRole({
    required String communityId,
    required String userId,
    required CommunityRole newRole,
  });
}
