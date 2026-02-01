import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Utility class to ensure admin users have all required fields populated
/// This prevents null errors when admin users access the app
class AdminDataUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Default admin profile data
  static Map<String, dynamic> get _defaultAdminProfileData => {
    'displayName': 'Admin User',
    'dateOfBirth': Timestamp.fromDate(DateTime(1990, 1, 1)),
    'gender': 'Other',
    'photoUrls': ['https://ui-avatars.com/api/?name=Admin&background=D4AF37&color=000&size=400'],
    'bio': 'GreenGo Administrator',
    'interests': ['Technology', 'Management', 'Community'],
    'location': {
      'latitude': 41.9028,
      'longitude': 12.4964,
      'city': 'Rome',
      'country': 'Italy',
      'displayAddress': 'Rome, Italy',
    },
    'languages': ['English', 'Italian'],
    'voiceRecordingUrl': null,
    'personalityTraits': {
      'openness': 80,
      'conscientiousness': 90,
      'extraversion': 70,
      'agreeableness': 85,
      'neuroticism': 20,
    },
    'education': 'System Administrator',
    'occupation': 'Administrator',
    'lookingFor': null,
    'height': 175,
    'isComplete': true,
    'verificationStatus': 'approved',
    'verificationPhotoUrl': null,
    'verificationRejectionReason': null,
    'verificationSubmittedAt': null,
    'verificationReviewedAt': null,
    'verificationReviewedBy': null,
    'isAdmin': true,
    'socialLinks': null,
    'membershipTier': 'GOLD',
    'membershipStartDate': null,
    'membershipEndDate': null,
  };

  /// Default admin user access control data
  static Map<String, dynamic> get _defaultAdminAccessData => {
    'approvalStatus': 'approved',
    'approvedAt': Timestamp.now(),
    'approvedBy': 'system',
    'accessDate': Timestamp.fromDate(DateTime(2020, 1, 1)), // Past date = immediate access
    'membershipTier': 'gold',
    'notificationsEnabled': true,
    'hasEarlyAccess': true,
    'isAdmin': true,
  };

  /// Check if current user is admin and ensure all required data exists
  static Future<bool> ensureAdminDataComplete() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Check profiles collection
      final profileDoc = await _firestore.collection('profiles').doc(user.uid).get();

      if (!profileDoc.exists) {
        // Create complete admin profile
        debugPrint('📝 Creating admin profile for ${user.email}...');
        await _createAdminProfile(user.uid, user.email);
        return true;
      }

      final profileData = profileDoc.data()!;
      final isAdmin = profileData['isAdmin'] as bool? ?? false;

      if (!isAdmin) {
        debugPrint('⚠️ User ${user.email} is not an admin');
        return false;
      }

      // Check and fill missing fields for admin
      await _ensureProfileFieldsComplete(user.uid, profileData);

      // Check and ensure users collection has required data
      await _ensureUserAccessDataComplete(user.uid);

      debugPrint('✅ Admin data complete for ${user.email}');
      return true;
    } catch (e) {
      debugPrint('❌ Error ensuring admin data: $e');
      return false;
    }
  }

  /// Create a complete admin profile
  static Future<void> _createAdminProfile(String userId, String? email) async {
    final now = Timestamp.now();
    final profileData = {
      ..._defaultAdminProfileData,
      'userId': userId,
      'displayName': email?.split('@').first ?? 'Admin',
      'createdAt': now,
      'updatedAt': now,
    };

    await _firestore.collection('profiles').doc(userId).set(profileData);
    debugPrint('✅ Created admin profile for $userId');
  }

  /// Ensure all profile fields exist with defaults for missing ones
  static Future<void> _ensureProfileFieldsComplete(
    String userId,
    Map<String, dynamic> existingData,
  ) async {
    final updates = <String, dynamic>{};
    final defaults = _defaultAdminProfileData;

    // Check each required field
    for (final entry in defaults.entries) {
      final key = entry.key;
      final defaultValue = entry.value;

      // Skip userId as it should exist
      if (key == 'userId') continue;

      // If field is missing or null (for required fields), use default
      if (!existingData.containsKey(key) ||
          (existingData[key] == null && _isRequiredField(key))) {
        updates[key] = defaultValue;
        debugPrint('  📝 Setting default for missing field: $key');
      }
    }

    // Always ensure isAdmin is true and verification is approved
    if (existingData['isAdmin'] != true) {
      updates['isAdmin'] = true;
    }
    if (existingData['verificationStatus'] != 'approved') {
      updates['verificationStatus'] = 'approved';
    }
    if (existingData['isComplete'] != true) {
      updates['isComplete'] = true;
    }

    // Update timestamps
    updates['updatedAt'] = Timestamp.now();

    if (updates.isNotEmpty) {
      await _firestore.collection('profiles').doc(userId).update(updates);
      debugPrint('✅ Updated ${updates.length} fields for admin profile');
    }
  }

  /// Check if a field is required (non-nullable)
  static bool _isRequiredField(String fieldName) {
    const requiredFields = {
      'displayName',
      'dateOfBirth',
      'gender',
      'photoUrls',
      'bio',
      'interests',
      'location',
      'languages',
      'createdAt',
      'updatedAt',
      'isComplete',
    };
    return requiredFields.contains(fieldName);
  }

  /// Ensure user access control data is complete
  static Future<void> _ensureUserAccessDataComplete(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      // Create user access data
      final accessData = {
        ..._defaultAdminAccessData,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };
      await _firestore.collection('users').doc(userId).set(accessData);
      debugPrint('✅ Created admin access data in users collection');
    } else {
      // Update missing fields
      final existingData = userDoc.data()!;
      final updates = <String, dynamic>{};

      for (final entry in _defaultAdminAccessData.entries) {
        if (!existingData.containsKey(entry.key) || existingData[entry.key] == null) {
          updates[entry.key] = entry.value;
        }
      }

      // Always ensure admin fields
      if (existingData['isAdmin'] != true) {
        updates['isAdmin'] = true;
      }
      if (existingData['approvalStatus'] != 'approved') {
        updates['approvalStatus'] = 'approved';
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = Timestamp.now();
        await _firestore.collection('users').doc(userId).update(updates);
        debugPrint('✅ Updated admin access data in users collection');
      }
    }
  }

  /// Initialize admin user by email (call this to set up a new admin)
  static Future<void> initializeAdminByEmail(String email) async {
    try {
      // Find user by email
      final usersQuery = await _firestore
          .collection('profiles')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        debugPrint('❌ User not found');
        return;
      }

      final userId = usersQuery.docs.first.id;

      // Update to admin
      await _firestore.collection('profiles').doc(userId).update({
        'isAdmin': true,
        'verificationStatus': 'approved',
        'isComplete': true,
        'membershipTier': 'GOLD',
        'updatedAt': Timestamp.now(),
      });

      await _ensureUserAccessDataComplete(userId);

      debugPrint('✅ User $email is now an admin');
    } catch (e) {
      debugPrint('❌ Error initializing admin: $e');
    }
  }

  /// Set a user as admin by their UID
  static Future<void> setUserAsAdmin(String userId) async {
    try {
      final now = Timestamp.now();

      // Update profiles collection
      await _firestore.collection('profiles').doc(userId).set({
        ..._defaultAdminProfileData,
        'userId': userId,
        'updatedAt': now,
      }, SetOptions(merge: true));

      // Update users collection
      await _firestore.collection('users').doc(userId).set({
        ..._defaultAdminAccessData,
        'updatedAt': now,
      }, SetOptions(merge: true));

      debugPrint('✅ User $userId set as admin with complete data');
    } catch (e) {
      debugPrint('❌ Error setting user as admin: $e');
    }
  }
}
