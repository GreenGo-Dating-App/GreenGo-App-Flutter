import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/platform/web_media.dart';
import '../../../../core/utils/phone_verification_gate.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../safety/data/services/identity_details_service.dart';
import '../../../safety/presentation/widgets/identity_details_form.dart';

/// Business verification request — collects everything an admin needs to
/// verify a business, then writes it to `business_verification_requests/{uid}`.
///
/// Required (owner decision 2026-10-17): the ACCOUNT's verified phone (the
/// only identity requirement), the business name and the owner's full name.
/// Optional: the owner's ID document (deleted after review; its details can be
/// added encrypted), a website URL and free-text notes.
class BusinessVerificationRequestScreen extends StatefulWidget {
  const BusinessVerificationRequestScreen({required this.profile, super.key});

  final Profile profile;

  @override
  State<BusinessVerificationRequestScreen> createState() =>
      _BusinessVerificationRequestScreenState();
}

class _BusinessVerificationRequestScreenState
    extends State<BusinessVerificationRequestScreen> {
  final _businessNameController = TextEditingController();
  // The OWNER's full name, exactly as printed on the uploaded ID document.
  final _ownerNameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  // Owner ID document.
  String? _documentUrl;
  bool _uploadingDocument = false;

  // Owner decision 2026-10-17: the ONLY identity requirement for a business
  // is the ACCOUNT's verified phone (Firebase Auth phone credential, rules
  // phoneVerified()). No separate OTP here; the owner ID is optional.
  String? _accountPhone = _currentAccountPhone();

  static String? _currentAccountPhone() {
    try {
      final p = FirebaseAuth.instance.currentUser?.phoneNumber;
      return (p == null || p.isEmpty) ? null : p;
    } catch (_) {
      return null;
    }
  }

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _businessNameController.text =
        widget.profile.businessName ?? widget.profile.displayName;
    // NOTE: no per-keystroke setState here. Typing in the name fields used to
    // rebuild the WHOLE form (this screen), which tore down the sibling text
    // fields' IME connection — that's why the phone field couldn't be typed
    // into. Instead, ONLY the submit button reacts to the name controllers via
    // an AnimatedBuilder (see build), so keystrokes never rebuild any field.
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _accountPhone != null &&
      _businessNameController.text.trim().isNotEmpty &&
      _ownerNameController.text.trim().isNotEmpty;

  // ── Owner document upload ────────────────────────────────────────────────

  Future<void> _pickDocument() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _uploadingDocument = true);
      final ref = FirebaseStorage.instance.ref().child(
            'business_verification/${widget.profile.userId}/owner_document.jpg',
          );
      await WebMedia.uploadXFile(ref, picked);
      final url = await ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        _documentUrl = url;
        _uploadingDocument = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingDocument = false);
      final l10n = AppLocalizations.of(context)!;
      _snack(l10n.verifyDocumentUploadError, isError: true);
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canSubmit) {
      _snack(l10n.verifyMissingFields, isError: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance
          .collection('business_verification_requests')
          .doc(widget.profile.userId)
          .set({
        'status': 'pending',
        'businessName': _businessNameController.text.trim(),
        // Owner's full name (as on the ID). `legalName` kept as a mirror for
        // back-compat with any admin reader that still reads the old key.
        'ownerName': _ownerNameController.text.trim(),
        'legalName': _ownerNameController.text.trim(),
        'ownerDocumentUrl': _documentUrl,
        'phoneNumber': _accountPhone,
        'phoneVerified': true,
        'website': _websiteController.text.trim(),
        'note': _notesController.text.trim(),
        'submittedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _snack(l10n.requestVerificationSubmitted);
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(l10n.requestVerificationError, isError: true);
    }
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      showUserErrorMessage(context, message);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────

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
          onPressed: () => SafeNavigation.pop(context),
        ),
        title: Text(
          l10n.requestVerificationTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.requestVerificationMessage,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Business name (required)
            _label(l10n.verifyBusinessNameLabel, required: true),
            _field(_businessNameController,
                icon: Icons.storefront, fieldKey: 'businessName'),
            const SizedBox(height: 20),

            // Owner's full name — must match the uploaded ID document (required)
            _label(l10n.verifyOwnerNameLabel, required: true),
            _field(_ownerNameController,
                icon: Icons.person_outline,
                fieldKey: 'ownerName',
                hint: l10n.verifyOwnerNameHint),
            const SizedBox(height: 20),

            // The account's verified phone (required).
            _label(l10n.verifyPhoneLabel, required: true),
            _buildAccountPhoneSection(l10n),
            const SizedBox(height: 20),

            // Owner document (OPTIONAL since 2026-10-17; deleted after review)
            _label(l10n.phoneVerifyOwnerDocumentOptional),
            _buildDocumentSection(l10n),
            // Optional: the details printed on the owner document (encrypted).
            if (_documentUrl != null)
              const IdentityDetailsButton(source: IdentitySource.business),
            const SizedBox(height: 20),

            // Website (optional)
            _label(l10n.verifyWebsiteLabel),
            _field(_websiteController,
                icon: Icons.link,
                fieldKey: 'website',
                hint: l10n.verifyWebsiteHint,
                keyboardType: TextInputType.url),
            const SizedBox(height: 20),

            // Notes (optional)
            _label(l10n.verifyNotesLabel),
            _field(_notesController,
                icon: Icons.notes,
                fieldKey: 'notes',
                hint: l10n.requestVerificationNoteHint,
                maxLines: 3),
            const SizedBox(height: 32),

            // Only the submit button reacts to the name-field text (via the
            // controllers) — NOT the whole form — so typing never rebuilds any
            // TextField and the IME stays connected.
            SizedBox(
              width: double.infinity,
              child: AnimatedBuilder(
                animation: Listenable.merge(
                    [_businessNameController, _ownerNameController]),
                builder: (context, _) => ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    disabledBackgroundColor:
                        AppColors.richGold.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.deepBlack),
                          ),
                        )
                      : Text(
                          l10n.submit,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountPhoneSection(AppLocalizations l10n) {
    final phone = _accountPhone;
    if (phone != null) {
      final masked = phone.length > 4
          ? '${phone.substring(0, phone.length - 4).replaceAll(RegExp(r'\d'), '•')}${phone.substring(phone.length - 4)}'
          : phone;
      return Container(
        key: const ValueKey('business-verify-account-phone'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.successGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified, color: AppColors.successGreen, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${l10n.phoneVerifyAccountPhone}: $masked',
                  style: const TextStyle(color: AppColors.textPrimary)),
            ),
          ],
        ),
      );
    }
    return Column(
      key: const ValueKey('business-verify-phone-needed'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.phoneVerifyAccountPhoneNeeded,
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await PhoneVerificationGate.showSheet(context);
            if (ok && mounted) setState(() => _accountPhone = _currentAccountPhone());
          },
          icon: const Icon(Icons.phone_android, size: 18),
          label: Text(l10n.phoneVerifyBannerAction),
        ),
      ],
    );
  }

  Widget _buildDocumentSection(AppLocalizations l10n) {
    final uploaded = _documentUrl != null;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _uploadingDocument ? null : _pickDocument,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              uploaded ? AppColors.richGold : AppColors.textPrimary,
          side: BorderSide(
            color: uploaded ? AppColors.richGold : AppColors.divider,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: _uploadingDocument
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
                ),
              )
            : Icon(uploaded ? Icons.check_circle : Icons.upload_file, size: 18),
        label: Text(
          uploaded ? l10n.verifyDocumentUploaded : l10n.verifyUploadDocument,
        ),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.richGold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller, {
    required IconData icon,
    required String fieldKey,
    String? hint,
    int maxLines = 1,
    bool enabled = true,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextField(
      // A distinct, STABLE key per field so Flutter never re-maps one field's
      // IME connection onto another (which dropped keystrokes).
      key: ValueKey('verify_field_$fieldKey'),
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.richGold, size: 20),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
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
    );
  }
}
