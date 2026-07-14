import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/business_categories.dart';
import '../../../../core/services/tier_entitlements.dart';
import '../../../../core/services/tier_gate.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../core/widgets/limit_reached_dialog.dart';
import '../../../../generated/app_localizations.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import 'business_verification_request_screen.dart';

/// Business / venue account screen.
///
/// Lets a user turn their personal account into a business/venue account so
/// they can publish and feature events. Writes ride along on the existing
/// `profiles/{uid}` document (isBusiness / businessName / businessCategory).
/// The verified badge (`businessVerified`) is admin-granted and stays read-only
/// here.
class BusinessAccountScreen extends StatefulWidget {
  const BusinessAccountScreen({required this.profile, super.key});

  final Profile profile;

  @override
  State<BusinessAccountScreen> createState() => _BusinessAccountScreenState();
}

class _BusinessAccountScreenState extends State<BusinessAccountScreen> {
  // Storefront display name (what people see) and the registered legal
  // company name (used for verification / invoicing).
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _legalNameController = TextEditingController();

  late bool _isBusiness;
  String? _category;
  bool _isSaving = false;

  // Verification-request state (a pending or approved request disables the
  // "Request verification" action).
  bool _verificationPending = false;
  bool _loadingVerification = true;
  final bool _submittingVerification = false;

  @override
  void initState() {
    super.initState();
    _isBusiness = widget.profile.isBusiness;
    _category = widget.profile.businessCategory;
    _nameController.text = widget.profile.businessName ?? '';
    _legalNameController.text = widget.profile.businessLegalName ?? '';
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('business_verification_requests')
          .doc(widget.profile.userId)
          .get();
      final status = doc.data()?['status'] as String?;
      if (mounted) {
        setState(() {
          _verificationPending = status == 'pending';
          _loadingVerification = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingVerification = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _legalNameController.dispose();
    super.dispose();
  }

  /// A section field label styled like the rest of the screen.
  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );

  /// A single-line text field with a leading gold icon and a hint.
  Widget _nameField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, color: AppColors.richGold, size: 20),
        filled: true,
        fillColor: AppColors.backgroundInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.richGold, width: 2),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  /// Grouped, tappable category chips — one labelled section per
  /// [BusinessCategories.grouped] entry (easier than a 50-item dropdown).
  Widget _buildCategoryGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in BusinessCategories.grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(
              entry.key,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final c in entry.value) _categoryChip(c)],
          ),
        ],
      ],
    );
  }

  Widget _categoryChip(String c) {
    final selected = _category == c;
    return GestureDetector(
      onTap: () => setState(() => _category = c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.richGold : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.richGold : AppColors.divider,
          ),
        ),
        child: Text(
          c,
          style: TextStyle(
            color: selected ? AppColors.deepBlack : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  bool get _isValid {
    if (!_isBusiness) return true; // turning it off is always valid
    return _nameController.text.trim().isNotEmpty && _category != null;
  }

  void _save() {
    if (!_isValid || _isSaving) return;
    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final legalName = _legalNameController.text.trim();
    final updated = widget.profile.copyWith(
      isBusiness: _isBusiness,
      businessName: _isBusiness && name.isNotEmpty ? name : null,
      businessLegalName:
          _isBusiness && legalName.isNotEmpty ? legalName : null,
      businessCategory: _isBusiness ? _category : null,
      updatedAt: DateTime.now(),
    );

    context.read<ProfileBloc>().add(ProfileUpdateRequested(profile: updated));
  }

  /// One-time, IRREVERSIBLE switch to a business account.
  ///
  /// Gated on [TierEntitlements.canBecomeBusiness] (Platinum only): non-Platinum
  /// users get the upgrade dialog (mirroring [TierGate]'s upsell path) and are
  /// blocked. Platinum users confirm a permanent one-time dialog, after which
  /// `profiles/{uid}.isBusiness` is set true with a `businessSince` timestamp.
  Future<void> _handleBecomeBusiness() async {
    if (_isBusiness || _isSaving) return;
    final uid = widget.profile.userId;
    final tier = widget.profile.membershipTier;
    final l10n = AppLocalizations.of(context)!;

    // Gate: Platinum-only. Surface the marketplace upsell on deny.
    if (!TierEntitlements.canBecomeBusiness(tier)) {
      final r = await FeatureNotAvailableDialog.show(
        context: context,
        featureName: l10n.becomeBusiness,
        description: l10n.businessRequiresPlatinum,
        currentTier: tier,
        requiredTier: MembershipTier.platinum,
        userId: uid,
        icon: Icons.storefront,
      );
      if (mounted && r?.action == LimitDialogAction.upgrade) {
        TierGate().openMembershipUpgrade(context, currentUserId: uid);
      }
      return;
    }

    // One-time permanent confirmation.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        title: Text(
          l10n.becomeBusinessConfirmTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.becomeBusinessConfirmMessage,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textTertiary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.becomeBusinessConfirmAction,
              style: const TextStyle(
                color: AppColors.richGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('profiles').doc(uid).set({
        'isBusiness': true,
        'businessSince': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _isBusiness = true;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.becomeBusinessSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.becomeBusinessError),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  /// Opens the full verification-request form (phone OTP, business & legal name,
  /// owner ID document, optional website, notes). On a successful submission the
  /// request becomes pending. Admin approval happens elsewhere. Disabled when
  /// already verified or a request is already pending.
  Future<void> _requestVerification() async {
    if (_submittingVerification ||
        _verificationPending ||
        widget.profile.businessVerified) {
      return;
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            BusinessVerificationRequestScreen(profile: widget.profile),
      ),
    );
    if (result == true && mounted) {
      setState(() => _verificationPending = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdated) {
          if (context.mounted) Navigator.of(context).pop(state.profile);
        } else if (state is ProfileError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => SafeNavigation.pop(context),
          ),
          title: Text(
            l10n.businessAccountTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.richGold),
                  ),
                ),
              )
            else
              TextButton(
                onPressed: _isValid ? _save : null,
                child: Text(
                  l10n.save,
                  style: TextStyle(
                    color:
                        _isValid ? AppColors.richGold : AppColors.textTertiary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Become-a-business — ONE-TIME, Platinum-gated, irreversible.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: _isBusiness
                        ? AppColors.richGold.withOpacity(0.5)
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.richGold.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: const Icon(Icons.storefront,
                          color: AppColors.richGold, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.becomeBusiness,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isBusiness
                                ? l10n.businessAccountActive
                                : l10n.becomeBusinessPermanentHint,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_isBusiness)
                      // Permanent: one-time = irreversible, no toggle-off.
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: AppColors.richGold, size: 20),
                        ],
                      )
                    else
                      TextButton(
                        onPressed: _isSaving ? null : _handleBecomeBusiness,
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: AppColors.deepBlack,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          l10n.becomeBusinessAction,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // "View storefront" and "View analytics" tiles removed here — both
              // are duplicated in the Business hub (View storefront / Analytics
              // tiles). This screen now owns only the one-time become-a-business
              // conversion + status and the verification request below.
              if (_isBusiness) ...[
                const SizedBox(height: 24),
                // Business PROFILE name — the storefront display name.
                _fieldLabel(l10n.businessProfileNameLabel),
                const SizedBox(height: 8),
                _nameField(
                  controller: _nameController,
                  icon: Icons.storefront_outlined,
                  hint: l10n.businessProfileNameHint,
                ),
                const SizedBox(height: 24),
                // LEGAL business name — the registered company name.
                _fieldLabel(l10n.businessLegalNameLabel),
                const SizedBox(height: 8),
                _nameField(
                  controller: _legalNameController,
                  icon: Icons.badge_outlined,
                  hint: l10n.businessLegalNameHint,
                ),
                const SizedBox(height: 24),
                // Category — grouped, tappable chips (easier than a 50-item
                // dropdown), mirroring the storefront editor.
                _fieldLabel(l10n.businessCategoryLabel),
                const SizedBox(height: 4),
                _buildCategoryGroups(),
                const SizedBox(height: 24),
                // Verified status (badge is admin-granted; user can REQUEST it).
                Row(
                  children: [
                    Icon(
                      widget.profile.businessVerified
                          ? Icons.verified
                          : Icons.verified_outlined,
                      color: widget.profile.businessVerified
                          ? AppColors.richGold
                          : AppColors.textTertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.businessVerifiedLabel,
                        style: TextStyle(
                          color: widget.profile.businessVerified
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!widget.profile.businessVerified)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: (_loadingVerification ||
                              _verificationPending ||
                              _submittingVerification)
                          ? null
                          : _requestVerification,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.richGold,
                        side: BorderSide(
                          color: _verificationPending
                              ? AppColors.textTertiary
                              : AppColors.richGold,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusM),
                        ),
                      ),
                      icon: _submittingVerification
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.richGold),
                              ),
                            )
                          : Icon(
                              _verificationPending
                                  ? Icons.hourglass_top
                                  : Icons.verified_user,
                              size: 18,
                            ),
                      label: Text(
                        _verificationPending
                            ? l10n.requestVerificationPending
                            : l10n.requestVerification,
                        style: TextStyle(
                          color: _verificationPending
                              ? AppColors.textTertiary
                              : AppColors.richGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
