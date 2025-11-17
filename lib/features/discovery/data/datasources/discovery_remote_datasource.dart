import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../matching/data/datasources/matching_remote_datasource.dart';
import '../../../matching/domain/entities/match_candidate.dart';
import '../../../matching/domain/entities/match_preferences.dart' as matching;
import '../../domain/entities/match_preferences.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/swipe_action.dart';
import '../models/match_model.dart';
import '../models/swipe_action_model.dart';

/// Discovery Remote Data Source Interface
abstract class DiscoveryRemoteDataSource {
  Future<List<MatchCandidate>> getDiscoveryStack({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
  });

  Future<SwipeAction> recordSwipe({
    required String userId,
    required String targetUserId,
    required SwipeActionType actionType,
  });

  Future<Match?> checkForMatch({
    required String userId,
    required String targetUserId,
  });

  Future<List<Match>> getMatches({
    required String userId,
    bool activeOnly = true,
  });

  Future<(Match, Profile)> getMatchWithProfile({
    required String matchId,
    required String currentUserId,
  });

  Future<void> markMatchAsSeen({
    required String matchId,
    required String userId,
  });

  Future<void> unmatch({
    required String matchId,
    required String userId,
  });

  Future<List<String>> getUserLikes(String userId);

  Future<List<Profile>> getWhoLikedMe(String userId);

  Future<bool> hasSwipedOn({
    required String userId,
    required String targetUserId,
  });
}

/// Discovery Remote Data Source Implementation
class DiscoveryRemoteDataSourceImpl implements DiscoveryRemoteDataSource {
  final FirebaseFirestore firestore;
  final MatchingRemoteDataSource matchingDataSource;

  DiscoveryRemoteDataSourceImpl({
    required this.firestore,
    required this.matchingDataSource,
  });

  @override
  Future<List<MatchCandidate>> getDiscoveryStack({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
  }) async {
    // Get candidates from matching datasource
    final candidates = await matchingDataSource.getMatchCandidates(
      userId: userId,
      preferences: matching.MatchPreferences(userId: preferences.userId, minAge: preferences.minAge, maxAge: preferences.maxAge, maxDistance: (preferences.maxDistanceKm ?? 50).toDouble(), updatedAt: DateTime.now()),
      limit: limit * 2, // Get more for filtering
    );

    // Get user's already swiped profiles
    final swipedUserIds = await _getSwipedUserIds(userId);

    // Filter out already swiped profiles
    final filteredCandidates = candidates
        .where((candidate) => !swipedUserIds.contains(candidate.profile.userId))
        .take(limit)
        .toList();

    return filteredCandidates;
  }

  @override
  Future<SwipeAction> recordSwipe({
    required String userId,
    required String targetUserId,
    required SwipeActionType actionType,
  }) async {
    // Create swipe action
    final action = SwipeAction(
      userId: userId,
      targetUserId: targetUserId,
      actionType: actionType,
      timestamp: DateTime.now(),
      createdMatch: false,
    );

    // Save to Firestore
    final model = SwipeActionModel.fromEntity(action);
    await firestore.collection('swipes').add(model.toFirestore());

    // If it's a like or super like, check for match
    if (action.isPositive) {
      final match = await checkForMatch(
        userId: userId,
        targetUserId: targetUserId,
      );

      if (match != null) {
        return action.copyWith(createdMatch: true);
      }
    }

    return action;
  }

  @override
  Future<Match?> checkForMatch({
    required String userId,
    required String targetUserId,
  }) async {
    // Check if target user has also liked current user
    final querySnapshot = await firestore
        .collection('swipes')
        .where('userId', isEqualTo: targetUserId)
        .where('targetUserId', isEqualTo: userId)
        .where('actionType', whereIn: ['like', 'superLike']).get();

    if (querySnapshot.docs.isEmpty) {
      // No mutual like yet
      return null;
    }

    // Check if match already exists
    final existingMatch = await _findExistingMatch(userId, targetUserId);
    if (existingMatch != null) {
      return existingMatch;
    }

    // Create new match
    final match = Match(
      matchId: '', // Will be set by Firestore
      userId1: userId,
      userId2: targetUserId,
      matchedAt: DateTime.now(),
      isActive: true,
      user1Seen: false,
      user2Seen: false,
    );

    final model = MatchModel.fromEntity(match);
    final docRef = await firestore.collection('matches').add(model.toFirestore());

    return match.copyWith(matchId: docRef.id);
  }

  @override
  Future<List<Match>> getMatches({
    required String userId,
    bool activeOnly = true,
  }) async {
    // Query matches where user is userId1
    Query query1 = firestore
        .collection('matches')
        .where('userId1', isEqualTo: userId);

    // Query matches where user is userId2
    Query query2 = firestore
        .collection('matches')
        .where('userId2', isEqualTo: userId);

    if (activeOnly) {
      query1 = query1.where('isActive', isEqualTo: true);
      query2 = query2.where('isActive', isEqualTo: true);
    }

    // Execute both queries
    final results1 = await query1.orderBy('matchedAt', descending: true).get();
    final results2 = await query2.orderBy('matchedAt', descending: true).get();

    // Combine and convert
    final matches = <Match>[];

    for (final doc in results1.docs) {
      matches.add(MatchModel.fromFirestore(doc));
    }

    for (final doc in results2.docs) {
      matches.add(MatchModel.fromFirestore(doc));
    }

    // Sort by match date (most recent first)
    matches.sort((a, b) => b.matchedAt.compareTo(a.matchedAt));

    return matches;
  }

  @override
  Future<(Match, Profile)> getMatchWithProfile({
    required String matchId,
    required String currentUserId,
  }) async {
    // Get match document
    final matchDoc = await firestore.collection('matches').doc(matchId).get();

    if (!matchDoc.exists) {
      throw Exception('Match not found');
    }

    final match = MatchModel.fromFirestore(matchDoc);

    // Get other user's profile
    final otherUserId = match.getOtherUserId(currentUserId);
    final profileDoc =
        await firestore.collection('profiles').doc(otherUserId).get();

    if (!profileDoc.exists) {
      throw Exception('Profile not found');
    }

    final profile = ProfileModel.fromFirestore(profileDoc);

    return (match, profile);
  }

  @override
  Future<void> markMatchAsSeen({
    required String matchId,
    required String userId,
  }) async {
    final matchDoc = await firestore.collection('matches').doc(matchId).get();

    if (!matchDoc.exists) return;

    final match = MatchModel.fromFirestore(matchDoc);

    // Update the appropriate seen field
    final updateData = userId == match.userId1
        ? {'user1Seen': true}
        : {'user2Seen': true};

    await firestore.collection('matches').doc(matchId).update(updateData);
  }

  @override
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {
    await firestore.collection('matches').doc(matchId).update({
      'isActive': false,
      'unmatchedAt': FieldValue.serverTimestamp(),
      'unmatchedBy': userId,
    });
  }

  @override
  Future<List<String>> getUserLikes(String userId) async {
    final querySnapshot = await firestore
        .collection('swipes')
        .where('userId', isEqualTo: userId)
        .where('actionType', whereIn: ['like', 'superLike']).get();

    return querySnapshot.docs
        .map((doc) => doc.data()['targetUserId'] as String)
        .toList();
  }

  @override
  Future<List<Profile>> getWhoLikedMe(String userId) async {
    // Get all users who liked current user
    final querySnapshot = await firestore
        .collection('swipes')
        .where('targetUserId', isEqualTo: userId)
        .where('actionType', whereIn: ['like', 'superLike']).get();

    final likerIds = querySnapshot.docs
        .map((doc) => doc.data()['userId'] as String)
        .toSet()
        .toList();

    if (likerIds.isEmpty) return [];

    // Get profiles for these users
    final profiles = <Profile>[];
    for (final likerId in likerIds) {
      try {
        final profileDoc =
            await firestore.collection('profiles').doc(likerId).get();
        if (profileDoc.exists) {
          profiles.add(ProfileModel.fromFirestore(profileDoc));
        }
      } catch (e) {
        // Skip invalid profiles
        continue;
      }
    }

    return profiles;
  }

  @override
  Future<bool> hasSwipedOn({
    required String userId,
    required String targetUserId,
  }) async {
    final querySnapshot = await firestore
        .collection('swipes')
        .where('userId', isEqualTo: userId)
        .where('targetUserId', isEqualTo: targetUserId)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  // Helper methods

  Future<Set<String>> _getSwipedUserIds(String userId) async {
    final querySnapshot = await firestore
        .collection('swipes')
        .where('userId', isEqualTo: userId)
        .get();

    return querySnapshot.docs
        .map((doc) => doc.data()['targetUserId'] as String)
        .toSet();
  }

  Future<Match?> _findExistingMatch(String userId1, String userId2) async {
    // Try both user orders
    final query1 = await firestore
        .collection('matches')
        .where('userId1', isEqualTo: userId1)
        .where('userId2', isEqualTo: userId2)
        .limit(1)
        .get();

    if (query1.docs.isNotEmpty) {
      return MatchModel.fromFirestore(query1.docs.first);
    }

    final query2 = await firestore
        .collection('matches')
        .where('userId1', isEqualTo: userId2)
        .where('userId2', isEqualTo: userId1)
        .limit(1)
        .get();

    if (query2.docs.isNotEmpty) {
      return MatchModel.fromFirestore(query2.docs.first);
    }

    return null;
  }
}

/// Extension for SwipeAction to add copyWith
extension SwipeActionCopyWith on SwipeAction {
  SwipeAction copyWith({bool? createdMatch}) {
    return SwipeAction(
      userId: userId,
      targetUserId: targetUserId,
      actionType: actionType,
      timestamp: timestamp,
      createdMatch: createdMatch ?? this.createdMatch,
    );
  }
}

/// Extension for Match to add copyWith for matchId
extension MatchCopyWith on Match {
  Match copyWith({String? matchId}) {
    return Match(
      matchId: matchId ?? this.matchId,
      userId1: userId1,
      userId2: userId2,
      matchedAt: matchedAt,
      isActive: isActive,
      lastMessageAt: lastMessageAt,
      lastMessage: lastMessage,
      unreadCount: unreadCount,
      user1Seen: user1Seen,
      user2Seen: user2Seen,
    );
  }
}
