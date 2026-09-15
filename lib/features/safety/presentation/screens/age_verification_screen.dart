import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/services/age_verification_service.dart';

/// Age verification flow.
///
/// Apple Guideline 2.3.6 draws a hard line between a *declared* age and an
/// *assured* one; 1.2.1 and 4.7.5 then require an age-restriction mechanism
/// before someone can publish content other people will see. This screen is
/// that mechanism.
///
/// The design goal is that it never feels like surveillance: the user is told
/// plainly why it is being asked, what is read, and that the photo is deleted
/// straight away — which is literally what `submitAgeDocument` does.
class AgeVerificationScreen extends StatefulWidget {
  const AgeVerificationScreen({
    super.key,
    this.reason = AgeVerificationReason.publishing,
  });

  /// Why the user arrived here, which changes only the explanatory line.
  final AgeVerificationReason reason;

  static Future<bool?> push(
    BuildContext context, {
    AgeVerificationReason reason = AgeVerificationReason.publishing,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AgeVerificationScreen(reason: reason),
      ),
    );
  }

  @override
  State<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

enum AgeVerificationReason { publishing, phoneAccount }

class _AgeVerificationScreenState extends State<AgeVerificationScreen> {
  final _service = AgeVerificationService();
  final _picker = ImagePicker();

  AgeVerificationState _state = const AgeVerificationState.unknown();
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = await _service.loadState();
    if (!mounted) return;
    setState(() {
      _state = state;
      _loading = false;
    });
  }

  Future<void> _pickAndSubmit(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      // A document photo needs to be legible, not large. Capping here keeps the
      // upload short, which matters because the file is deleted seconds later.
      maxWidth: 2000,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    setState(() => _submitting = true);
    final status = await _service.submitDocument(documentFile: picked);
    if (!mounted) return;

    setState(() {
      _submitting = false;
      _state = AgeVerificationState(
        status: status,
        documentRequired: _state.documentRequired,
        canPublishToCommunities: status == AgeVerificationStatus.verified,
        rejectionReason: _state.rejectionReason,
      );
    });

    if (status == AgeVerificationStatus.verified && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(l10n.ageVerifyTitle),
      ),
      body: SafeArea(
        child: Center(
          // Capped width so the page reads as a designed layout on an iPad
          // rather than a stretched phone screen.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildBody(l10n),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    switch (_state.status) {
      case AgeVerificationStatus.verified:
        return _statusPanel(
          icon: Icons.verified_user,
          color: AppColors.successGreen,
          message: l10n.ageVerifyVerified,
        );
      case AgeVerificationStatus.pending:
        return _statusPanel(
          icon: Icons.hourglass_top,
          color: AppColors.richGold,
          message: l10n.ageVerifyPending,
        );
      case AgeVerificationStatus.rejected:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _statusPanel(
              icon: Icons.error_outline,
              color: AppColors.errorRed,
              message: _rejectionMessage(l10n),
            ),
            const SizedBox(height: 24),
            ..._actions(l10n),
          ],
        );
      case AgeVerificationStatus.none:
      case AgeVerificationStatus.declared:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.badge_outlined,
                size: 56, color: AppColors.richGold),
            const SizedBox(height: 20),
            Text(
              widget.reason == AgeVerificationReason.phoneAccount
                  ? l10n.ageVerifyWhyPhone
                  : l10n.ageVerifyWhyPublish,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            // The privacy promise is deliberately as prominent as the ask.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.ageVerifyPrivacyNote,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            ..._actions(l10n),
          ],
        );
    }
  }

  List<Widget> _actions(AppLocalizations l10n) {
    if (_submitting) {
      return [
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 12),
        Center(
          child: Text(
            l10n.ageVerifyChecking,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ];
    }
    return [
      ElevatedButton.icon(
        onPressed: () => _pickAndSubmit(ImageSource.camera),
        icon: const Icon(Icons.camera_alt_outlined),
        label: Text(l10n.ageVerifyTakePhoto),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.richGold,
          foregroundColor: AppColors.deepBlack,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: () => _pickAndSubmit(ImageSource.gallery),
        icon: const Icon(Icons.photo_library_outlined),
        label: Text(l10n.ageVerifyChooseImage),
        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
      ),
    ];
  }

  String _rejectionMessage(AppLocalizations l10n) {
    switch (_state.rejectionReason) {
      case 'underage':
        return l10n.ageVerifyRejectedUnderage;
      case 'documentAlreadyUsed':
        return l10n.ageVerifyRejectedReused;
      default:
        return l10n.ageVerifyRejected;
    }
  }

  Widget _statusPanel({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Column(
      children: [
        Icon(icon, size: 56, color: color),
        const SizedBox(height: 20),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
