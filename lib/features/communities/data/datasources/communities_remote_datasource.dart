import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_member.dart';
import '../models/community_model.dart';
import '../models/community_member_model.dart';
import '../models/community_message_model.dart';

/// Communities Remote Data Source
///
/// Handles Firestore operations for the communities feature
abstract class CommunitiesRemoteDataSource {
  /// Get all communities with optional filters
  Future<List<CommunityModel>> getCommunities({
    CommunityType? type,
    String? language,
    String? city,
    String? searchQuery,
  });

  /// Get a community by ID
  Future<CommunityModel> getCommunityById(String communityId);

  /// Create a new community
  Future<CommunityModel> createCommunity(CommunityModel community);

  /// Update an existing community
  Future<void> updateCommunity(CommunityModel community);

  /// Delete a community
  Future<void> deleteCommunity(String communityId);

  /// Join a community
  Future<void> joinCommunity({
    required String communityId,
    required CommunityMemberModel member,
  });

  /// Leave a community
  Future<void> leaveCommunity({
    required String communityId,
    required String userId,
  });

  /// Get members of a community
  Future<List<CommunityMemberModel>> getCommunityMembers(String communityId);

  /// Stream of messages for a community (real-time)
  Stream<List<CommunityMessageModel>> getCommunityMessages(
    String communityId, {
    int? limit,
  });

  /// Send a message to a community
  Future<CommunityMessageModel> sendMessage({
    required String communityId,
    required CommunityMessageModel message,
  });

  /// Get communities the user has joined
  Future<List<CommunityModel>> getUserCommunities(String userId);

  /// Get recommended communities based on user preferences
  Future<List<CommunityModel>> getRecommendedCommunities({
    required String userId,
    required List<String> languages,
    List<String> interests,
  });

  /// Check if user is a member
  Future<bool> isMember({
    required String communityId,
    required String userId,
  });

  /// Update member role
  Future<void> updateMemberRole({
    required String communityId,
    required String userId,
    required CommunityRole newRole,
  });

  /// Seed sample communities (for development)
  Future<void> seedSampleCommunities();
}

/// Implementation of CommunitiesRemoteDataSource
class CommunitiesRemoteDataSourceImpl implements CommunitiesRemoteDataSource {
  final FirebaseFirestore _firestore;

  CommunitiesRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reference to communities collection
  CollectionReference get _communitiesRef =>
      _firestore.collection('communities');

  /// Reference to members subcollection
  CollectionReference _membersRef(String communityId) =>
      _communitiesRef.doc(communityId).collection('members');

  /// Reference to messages subcollection
  CollectionReference _messagesRef(String communityId) =>
      _communitiesRef.doc(communityId).collection('messages');

  @override
  Future<List<CommunityModel>> getCommunities({
    CommunityType? type,
    String? language,
    String? city,
    String? searchQuery,
  }) async {
    try {
      Query query = _communitiesRef.where('isPublic', isEqualTo: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.value);
      }

      if (language != null && language.isNotEmpty) {
        query = query.where('languages', arrayContains: language);
      }

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      query = query.orderBy('lastActivityAt', descending: true);

      final snapshot = await query.limit(50).get();

      List<CommunityModel> communities = snapshot.docs
          .map((doc) => CommunityModel.fromFirestore(doc))
          .toList();

      // Client-side search filter if query provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        communities = communities
            .where((c) =>
                c.name.toLowerCase().contains(lowerQuery) ||
                c.description.toLowerCase().contains(lowerQuery) ||
                c.tags.any((t) => t.toLowerCase().contains(lowerQuery)))
            .toList();
      }

      return communities;
    } catch (e) {
      debugPrint('Error getting communities: $e');
      rethrow;
    }
  }

  @override
  Future<CommunityModel> getCommunityById(String communityId) async {
    try {
      final doc = await _communitiesRef.doc(communityId).get();
      if (!doc.exists) {
        throw Exception('Community not found');
      }
      return CommunityModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting community by ID: $e');
      rethrow;
    }
  }

  @override
  Future<CommunityModel> createCommunity(CommunityModel community) async {
    try {
      final docRef = await _communitiesRef.add(community.toFirestore());
      final newDoc = await docRef.get();
      return CommunityModel.fromFirestore(newDoc);
    } catch (e) {
      debugPrint('Error creating community: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateCommunity(CommunityModel community) async {
    try {
      await _communitiesRef.doc(community.id).update(community.toFirestore());
    } catch (e) {
      debugPrint('Error updating community: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteCommunity(String communityId) async {
    try {
      // Delete all messages
      final messagesSnapshot = await _messagesRef(communityId).get();
      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all members
      final membersSnapshot = await _membersRef(communityId).get();
      for (final doc in membersSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the community
      await _communitiesRef.doc(communityId).delete();
    } catch (e) {
      debugPrint('Error deleting community: $e');
      rethrow;
    }
  }

  @override
  Future<void> joinCommunity({
    required String communityId,
    required CommunityMemberModel member,
  }) async {
    try {
      final batch = _firestore.batch();

      // Add member to subcollection
      batch.set(
        _membersRef(communityId).doc(member.userId),
        member.toFirestore(),
      );

      // Increment member count
      batch.update(
        _communitiesRef.doc(communityId),
        {'memberCount': FieldValue.increment(1)},
      );

      await batch.commit();
    } catch (e) {
      debugPrint('Error joining community: $e');
      rethrow;
    }
  }

  @override
  Future<void> leaveCommunity({
    required String communityId,
    required String userId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Remove member from subcollection
      batch.delete(_membersRef(communityId).doc(userId));

      // Decrement member count
      batch.update(
        _communitiesRef.doc(communityId),
        {'memberCount': FieldValue.increment(-1)},
      );

      await batch.commit();
    } catch (e) {
      debugPrint('Error leaving community: $e');
      rethrow;
    }
  }

  @override
  Future<List<CommunityMemberModel>> getCommunityMembers(
    String communityId,
  ) async {
    try {
      final snapshot = await _membersRef(communityId)
          .orderBy('joinedAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => CommunityMemberModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting community members: $e');
      rethrow;
    }
  }

  @override
  Stream<List<CommunityMessageModel>> getCommunityMessages(
    String communityId, {
    int? limit,
  }) {
    try {
      Query query = _messagesRef(communityId)
          .orderBy('sentAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      } else {
        query = query.limit(100);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => CommunityMessageModel.fromFirestore(
                  doc,
                  communityId: communityId,
                ))
            .toList();
      });
    } catch (e) {
      debugPrint('Error streaming community messages: $e');
      rethrow;
    }
  }

  @override
  Future<CommunityMessageModel> sendMessage({
    required String communityId,
    required CommunityMessageModel message,
  }) async {
    try {
      final batch = _firestore.batch();

      // Add message to subcollection
      final msgRef = _messagesRef(communityId).doc();
      batch.set(msgRef, message.toFirestore());

      // Update community last activity
      batch.update(_communitiesRef.doc(communityId), {
        'lastMessagePreview': message.content.length > 100
            ? '${message.content.substring(0, 100)}...'
            : message.content,
        'lastActivityAt': Timestamp.fromDate(message.sentAt),
      });

      await batch.commit();

      // Return message with generated ID
      final newDoc = await msgRef.get();
      return CommunityMessageModel.fromFirestore(
        newDoc,
        communityId: communityId,
      );
    } catch (e) {
      debugPrint('Error sending community message: $e');
      rethrow;
    }
  }

  @override
  Future<List<CommunityModel>> getUserCommunities(String userId) async {
    try {
      // Query all communities where user is a member
      // We use collectionGroup to find user across all member subcollections
      final memberDocs = await _firestore
          .collectionGroup('members')
          .where(FieldPath.documentId, isEqualTo: userId)
          .get();

      final communityIds = memberDocs.docs
          .map((doc) => doc.reference.parent.parent?.id)
          .where((id) => id != null)
          .cast<String>()
          .toList();

      if (communityIds.isEmpty) return [];

      // Fetch communities in batches of 10 (Firestore whereIn limit)
      final communities = <CommunityModel>[];
      for (var i = 0; i < communityIds.length; i += 10) {
        final batchIds = communityIds.sublist(
          i,
          i + 10 > communityIds.length ? communityIds.length : i + 10,
        );

        final snapshot = await _communitiesRef
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        communities.addAll(
          snapshot.docs.map((doc) => CommunityModel.fromFirestore(doc)),
        );
      }

      // Sort by last activity
      communities.sort((a, b) {
        final aTime = a.lastActivityAt ?? a.createdAt;
        final bTime = b.lastActivityAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      return communities;
    } catch (e) {
      debugPrint('Error getting user communities: $e');
      rethrow;
    }
  }

  @override
  Future<List<CommunityModel>> getRecommendedCommunities({
    required String userId,
    required List<String> languages,
    List<String> interests = const [],
  }) async {
    try {
      final recommended = <CommunityModel>[];

      // Get communities matching user's languages
      if (languages.isNotEmpty) {
        for (final lang in languages.take(3)) {
          final snapshot = await _communitiesRef
              .where('isPublic', isEqualTo: true)
              .where('languages', arrayContains: lang)
              .limit(10)
              .get();

          for (final doc in snapshot.docs) {
            final community = CommunityModel.fromFirestore(doc);
            if (!recommended.any((c) => c.id == community.id)) {
              recommended.add(community);
            }
          }
        }
      }

      // Get popular communities if not enough recommendations
      if (recommended.length < 10) {
        final snapshot = await _communitiesRef
            .where('isPublic', isEqualTo: true)
            .orderBy('memberCount', descending: true)
            .limit(10)
            .get();

        for (final doc in snapshot.docs) {
          final community = CommunityModel.fromFirestore(doc);
          if (!recommended.any((c) => c.id == community.id)) {
            recommended.add(community);
          }
        }
      }

      // Filter out communities user has already joined
      final userCommunityIds = <String>{};
      final memberDocs = await _firestore
          .collectionGroup('members')
          .where(FieldPath.documentId, isEqualTo: userId)
          .get();

      for (final doc in memberDocs.docs) {
        final parentId = doc.reference.parent.parent?.id;
        if (parentId != null) userCommunityIds.add(parentId);
      }

      return recommended
          .where((c) => !userCommunityIds.contains(c.id))
          .take(15)
          .toList();
    } catch (e) {
      debugPrint('Error getting recommended communities: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isMember({
    required String communityId,
    required String userId,
  }) async {
    try {
      final doc = await _membersRef(communityId).doc(userId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking membership: $e');
      return false;
    }
  }

  @override
  Future<void> updateMemberRole({
    required String communityId,
    required String userId,
    required CommunityRole newRole,
  }) async {
    try {
      await _membersRef(communityId).doc(userId).update({
        'role': newRole.value,
      });
    } catch (e) {
      debugPrint('Error updating member role: $e');
      rethrow;
    }
  }

  @override
  Future<void> seedSampleCommunities() async {
    try {
      // Check if communities already exist
      final existing = await _communitiesRef.limit(1).get();
      if (existing.docs.isNotEmpty) {
        debugPrint('Communities already seeded, skipping');
        return;
      }

      final now = DateTime.now();
      final sampleCommunities = [
        CommunityModel(
          id: '',
          name: 'Spanish Learners Worldwide',
          description:
              'A global community for Spanish language learners. Practice conversation, share resources, and connect with native speakers.',
          type: CommunityType.languageCircle,
          createdByUserId: 'system',
          createdByName: 'GreenGo',
          createdAt: now.subtract(const Duration(days: 90)),
          memberCount: 245,
          languages: ['es', 'en'],
          tags: ['spanish', 'language-learning', 'conversation'],
          isPublic: true,
          lastMessagePreview: 'Hola! Anyone want to practice this weekend?',
          lastActivityAt: now.subtract(const Duration(hours: 2)),
        ),
        CommunityModel(
          id: '',
          name: 'Japanese Culture Explorers',
          description:
              'Discover the richness of Japanese culture, traditions, food, and language. From anime to tea ceremonies.',
          type: CommunityType.culturalInterest,
          createdByUserId: 'system',
          createdByName: 'GreenGo',
          createdAt: now.subtract(const Duration(days: 75)),
          memberCount: 189,
          languages: ['ja', 'en'],
          tags: ['japan', 'culture', 'anime', 'food', 'traditions'],
          isPublic: true,
          lastMessagePreview: 'Just visited Kyoto temples, amazing!',
          lastActivityAt: now.subtract(const Duration(hours: 5)),
        ),
        CommunityModel(
          id: '',
          name: 'Travel to France',
          description:
              'Planning a trip to France? Share tips, itineraries, hidden gems, and connect with fellow travelers and locals.',
          type: CommunityType.travelGroup,
          createdByUserId: 'system',
          createdByName: 'GreenGo',
          createdAt: now.subtract(const Duration(days: 60)),
          memberCount: 312,
          languages: ['fr', 'en'],
          tags: ['france', 'travel', 'paris', 'food', 'wine'],
          isPublic: true,
          country: 'France',
          lastMessagePreview: 'Best croissants in Lyon?',
          lastActivityAt: now.subtract(const Duration(hours: 1)),
        ),
        CommunityModel(
          id: '',
          name: 'Local Guides - Tokyo',
          description:
              'Local guides sharing the best of Tokyo. Restaurant recommendations, hidden spots, events, and cultural tips from people who live here.',
          type: CommunityType.localGuides,
          createdByUserId: 'system',
          createdByName: 'GreenGo',
          createdAt: now.subtract(const Duration(days: 120)),
          memberCount: 156,
          languages: ['ja', 'en'],
          tags: ['tokyo', 'local-guide', 'restaurants', 'nightlife'],
          isPublic: true,
          city: 'Tokyo',
          country: 'Japan',
          lastMessagePreview: 'New ramen spot opened in Shibuya!',
          lastActivityAt: now.subtract(const Duration(minutes: 30)),
        ),
        CommunityModel(
          id: '',
          name: 'Local Guides - Paris',
          description:
              'Your insider guide to Paris. Local recommendations for restaurants, activities, nightlife, and dating spots.',
          type: CommunityType.localGuides,
          createdByUserId: 'system',
          createdByName: 'GreenGo',
          createdAt: now.subtract(const Duration(days: 110)),
          memberCount: 203,
          languages: ['fr', 'en'],
          tags: ['paris', 'local-guide', 'dating-spots', 'restaurants'],
          isPublic: true,
          city: 'Paris',
          country: 'France',
          lastMessagePreview: 'Hidden rooftop bar in Le Marais',
          lastActivityAt: now.subtract(const Duration(hours: 3)),
        ),
        CommunityModel(
          id: '',
          name: 'Korean Study Group',
          description:
              'Studying Korean together! Share study materials, practice writing, and discuss K-dramas in Korean.',
          type: CommunityType.studyGroup,
          createdByUserId: 'system',
          createdByName: 'GreenGo',
          createdAt: now.subtract(const Duration(days: 45)),
          memberCount: 134,
          languages: ['ko', 'en'],
          tags: ['korean', 'study', 'k-drama', 'language-learning'],
          isPublic: true,
          lastMessagePreview: 'TOPIK exam tips anyone?',
          lastActivityAt: now.subtract(const Duration(hours: 8)),
        ),
        CommunityModel(
          id: '',
          name: 'Arabic & Culture',
          description:
              'Learn Arabic and explore the rich cultural heritage of the Arab world. All dialects welcome!',
          type: CommunityType.languageCircle,
          createdByUserId: 'system',
          createdByName: 'GreenGo',
          createdAt: now.subtract(const Duration(days: 80)),
          memberCount: 98,
          languages: ['ar', 'en'],
          tags: ['arabic', 'culture', 'middle-east', 'calligraphy'],
          isPublic: true,
          lastMessagePreview: 'MSA vs dialect discussion thread',
          lastActivityAt: now.subtract(const Duration(hours: 12)),
        ),
        CommunityModel(
          id: '',
          name: 'Backpackers United',
          description:
              'For the adventurous souls! Share travel stories, budget tips, hostel recommendations, and find travel buddies.',
          type: CommunityType.travelGroup,
          createdByUserId: 'system',
          createdByName: 'GreenGo',
          createdAt: now.subtract(const Duration(days: 100)),
          memberCount: 421,
          languages: ['en'],
          tags: ['backpacking', 'budget-travel', 'adventure', 'hostels'],
          isPublic: true,
          lastMessagePreview: 'Southeast Asia route recommendations?',
          lastActivityAt: now.subtract(const Duration(minutes: 45)),
        ),
        CommunityModel(
          id: '',
          name: 'Local Guides - Barcelona',
          description:
              'Explore Barcelona like a local! Tapas bars, hidden beaches, cultural events, and the best dating spots in the city.',
          type: CommunityType.localGuides,
          createdByUserId: 'system',
          createdByName: 'GreenGo',
          createdAt: now.subtract(const Duration(days: 85)),
          memberCount: 167,
          languages: ['es', 'ca', 'en'],
          tags: ['barcelona', 'local-guide', 'tapas', 'beach', 'gaudi'],
          isPublic: true,
          city: 'Barcelona',
          country: 'Spain',
          lastMessagePreview: 'Best paella near the beach?',
          lastActivityAt: now.subtract(const Duration(hours: 4)),
        ),
        CommunityModel(
          id: '',
          name: 'Mandarin Practice',
          description:
              'Daily Mandarin practice group. Share characters, pronunciation tips, and have conversations in Chinese.',
          type: CommunityType.languageCircle,
          createdByUserId: 'system',
          createdByName: 'GreenGo',
          createdAt: now.subtract(const Duration(days: 55)),
          memberCount: 176,
          languages: ['zh', 'en'],
          tags: ['mandarin', 'chinese', 'characters', 'pronunciation'],
          isPublic: true,
          lastMessagePreview: 'Today\'s character challenge: ...',
          lastActivityAt: now.subtract(const Duration(hours: 6)),
        ),
        CommunityModel(
          id: '',
          name: 'International Foodies',
          description:
              'Share recipes, restaurant finds, and food culture from around the world. Taste the diversity!',
          type: CommunityType.culturalInterest,
          createdByUserId: 'system',
          createdByName: 'GreenGo',
          createdAt: now.subtract(const Duration(days: 70)),
          memberCount: 289,
          languages: ['en'],
          tags: ['food', 'cooking', 'restaurants', 'recipes', 'culture'],
          isPublic: true,
          lastMessagePreview: 'Best street food cities ranking!',
          lastActivityAt: now.subtract(const Duration(hours: 1)),
        ),
        CommunityModel(
          id: '',
          name: 'Portuguese & Brazilian Vibes',
          description:
              'Connect over Portuguese language and Brazilian/Portuguese culture. Music, food, language exchange!',
          type: CommunityType.languageCircle,
          createdByUserId: 'system',
          createdByName: 'GreenGo',
          createdAt: now.subtract(const Duration(days: 40)),
          memberCount: 112,
          languages: ['pt', 'en'],
          tags: ['portuguese', 'brazilian', 'music', 'samba', 'fado'],
          isPublic: true,
          lastMessagePreview: 'Bossa nova playlist recommendations!',
          lastActivityAt: now.subtract(const Duration(hours: 10)),
        ),
      ];

      for (final community in sampleCommunities) {
        await _communitiesRef.add(community.toFirestore());
      }

      debugPrint('Seeded ${sampleCommunities.length} sample communities');
    } catch (e) {
      debugPrint('Error seeding communities: $e');
      rethrow;
    }
  }
}
