import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';

/// Standalone screen shown when admin requests a better verification photo.
/// User takes a new selfie, it uploads to Storage, updates the profile doc
/// with the new URL and sets verificationStatus back to 'pending'.
class ReverificationScreen extends StatefulWidget {
  final String userId;
  final String? rejectionReason;

  const ReverificationScreen({
    super.key,
    required this.userId,
    this.rejectionReason,
  });

  @override
  State<ReverificationScreen> createState() => _ReverificationScreenState();
}

class _ReverificationScreenState extends State<ReverificationScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _capturedPhoto;
  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (image != null && mounted) {
        setState(() {
          _capturedPhoto = File(image.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _errorMessage = '${l10n.reverificationCameraError}: $e';
        });
      }
    }
  }

  Future<void> _submitPhoto() async {
    if (_capturedPhoto == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Upload to Firebase Storage
      final fileName =
          '${widget.userId}_reverify_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('verifications')
          .child(widget.userId)
          .child(fileName);

      await ref.putFile(_capturedPhoto!);
      final downloadUrl = await ref.getDownloadURL();

      // Update Firestore profile: new photo, status → pending
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.userId)
          .update({
        'verificationPhotoUrl': downloadUrl,
        'verificationStatus': 'pending',
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
        'verificationRejectionReason': null,
      });

      // Also reset approvalStatus in users collection so access gate shows pending
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'approvalStatus': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop(true); // Return true = success
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isUploading = false;
          _errorMessage = l10n.reverificationUploadFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.reverificationTitle,
          style: const TextStyle(color: AppColors.richGold, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.richGold,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                l10n.reverificationHeading,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                l10n.reverificationDescription,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Rejection reason if present
              if (widget.rejectionReason != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.errorRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.errorRed, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.reverificationReasonLabel,
                              style: const TextStyle(
                                color: AppColors.errorRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.rejectionReason!,
                              style: TextStyle(
                                color: AppColors.errorRed.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tips
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: AppColors.richGold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.reverificationPhotoTips,
                          style: const TextStyle(
                            color: AppColors.richGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _tip(l10n.reverificationTipLighting),
                    _tip(l10n.reverificationTipCamera),
                    _tip(l10n.reverificationTipNoAccessories),
                    _tip(l10n.reverificationTipFullFace),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Photo preview or take-photo card
              if (_capturedPhoto != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 260,
                    height: 340,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.successGreen, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.file(
                        _capturedPhoto!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _isUploading ? null : _takePhoto,
                  icon: const Icon(Icons.refresh, color: AppColors.richGold),
                  label: Text(
                    l10n.reverificationRetakePhoto,
                    style: const TextStyle(color: AppColors.richGold),
                  ),
                ),
              ] else ...[
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    width: 260,
                    height: 340,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.richGold, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            color: AppColors.richGold, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          l10n.reverificationTapToSelfie,
                          style: const TextStyle(
                            color: AppColors.richGold,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.errorRed, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      (_capturedPhoto != null && !_isUploading) ? _submitPhoto : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        AppColors.richGold.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          l10n.reverificationSubmit,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Info text
              Text(
                l10n.reverificationInfoText,
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.successGreen, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
