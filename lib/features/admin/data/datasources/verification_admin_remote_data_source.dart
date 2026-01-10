import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/exceptions.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/domain/entities/profile.dart';

abstract class VerificationAdminRemoteDataSource {
  Future<List<ProfileModel>> getPendingVerifications();
  Future<List<ProfileModel>> getVerificationHistory({int limit = 50});
  Future<void> approveVerification(String userId, String adminId);
  Future<void> rejectVerification(String userId, String adminId, String reason);
  Future<void> requestBetterPhoto(String userId, String adminId, String reason);
}

class VerificationAdminRemoteDataSourceImpl implements VerificationAdminRemoteDataSource {
  final FirebaseFirestore firestore;

  VerificationAdminRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<ProfileModel>> getPendingVerifications() async {
    try {
      final snapshot = await firestore
          .collection('profiles')
          .where('verificationStatus', isEqualTo: 'pending')
          .orderBy('verificationSubmittedAt', descending: false)
          .get();

      return snapshot.docs.map((doc) => ProfileModel.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to get pending verifications');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ProfileModel>> getVerificationHistory({int limit = 50}) async {
    try {
      final snapshot = await firestore
          .collection('profiles')
          .where('verificationStatus', whereIn: ['approved', 'rejected'])
          .orderBy('verificationReviewedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => ProfileModel.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to get verification history');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> approveVerification(String userId, String adminId) async {
    try {
      await firestore.collection('profiles').doc(userId).update({
        'verificationStatus': VerificationStatus.approved.name,
        'verificationReviewedAt': FieldValue.serverTimestamp(),
        'verificationReviewedBy': adminId,
        'verificationRejectionReason': null,
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to approve verification');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> rejectVerification(String userId, String adminId, String reason) async {
    try {
      await firestore.collection('profiles').doc(userId).update({
        'verificationStatus': VerificationStatus.rejected.name,
        'verificationReviewedAt': FieldValue.serverTimestamp(),
        'verificationReviewedBy': adminId,
        'verificationRejectionReason': reason,
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to reject verification');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> requestBetterPhoto(String userId, String adminId, String reason) async {
    try {
      await firestore.collection('profiles').doc(userId).update({
        'verificationStatus': VerificationStatus.needsResubmission.name,
        'verificationReviewedAt': FieldValue.serverTimestamp(),
        'verificationReviewedBy': adminId,
        'verificationRejectionReason': reason,
        'verificationPhotoUrl': null, // Clear the old photo so user can submit new one
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to request better photo');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
