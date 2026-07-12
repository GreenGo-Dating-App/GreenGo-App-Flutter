import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/bloc/profile_state.dart';

/// Storefront editor — lets a business account owner curate the public
/// storefront that visitors see in [BusinessStorefrontScreen].
///
/// Editable here:
///   * Gallery images — add/remove multiple, reusing the app's existing
///     image-pick + Firebase Storage upload path (the ProfileBloc
///     `ProfilePhotoUploadRequested` event → validated public upload →
///     `ProfilePhotoUploaded`). The returned URLs are stored in
///     `Profile.galleryImages` (kept separate from personal `photoUrls`).
///   * Opening hours — per-weekday open/close time pickers + "closed" toggle.
///   * Description (`storefrontBio`).
///   * Links (`storefrontLinks`) — arbitrary website/booking/menu URLs.
///   * Category (`businessCategory`).
///
/// Everything is persisted through the standard profile update path
/// (`ProfileUpdateRequested`), so no new repository/datasource wiring is needed.
///
/// Images are curated in three distinct roles:
///   * Featured/cover (hero) image → `Profile.coverImageUrl`
///   * Gallery → `Profile.galleryImages`
///   * Profile image/avatar → `Profile.photoUrls.first`
/// Uploads flow through a single bloc event that returns only a URL, so the
/// pending upload's target is tracked in [_pendingUploadTarget] before dispatch
/// and applied in the listener — this keeps the three uploads from mixing up.
enum _UploadTarget { featured, gallery, avatar }

class StorefrontEditorScreen extends StatefulWidget {
  const StorefrontEditorScreen({required this.profile, super.key});

  final Profile profile;

  @override
  State<StorefrontEditorScreen> createState() => _StorefrontEditorScreenState();
}

class _StorefrontEditorScreenState extends State<StorefrontEditorScreen> {
  final ImagePicker _picker = ImagePicker();

  late List<String> _galleryImages;
  late List<OpeningHours> _openingHours; // exactly 7, index 0 = Monday
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  late List<TextEditingController> _linkControllers;

  // Featured/cover (hero) image URL. Empty string is the "removed" sentinel so
  // the removal survives the copyWith(coverImageUrl:) null-coalescing on save.
  String? _coverImageUrl;
  // Profile image/avatar URL (mirrors photoUrls.first).
  String? _avatarUrl;

  // Which image slot the in-flight upload belongs to (null = no upload).
  _UploadTarget? _pendingUploadTarget;
  bool _saving = false;

  bool get _uploadingFeatured => _pendingUploadTarget == _UploadTarget.featured;
  bool get _uploadingGallery => _pendingUploadTarget == _UploadTarget.gallery;
  bool get _uploadingAvatar => _pendingUploadTarget == _UploadTarget.avatar;

  @override
  void initState() {
    super.initState();
    _galleryImages = List<String>.from(widget.profile.galleryImages);
    _coverImageUrl = widget.profile.coverImageUrl;
    _avatarUrl = widget.profile.photoUrls.isNotEmpty
        ? widget.profile.photoUrls.first
        : null;

    // Seed 7 weekday rows, hydrating from any saved entries.
    final saved = <int, OpeningHours>{
      for (final h in widget.profile.openingHours) h.weekday: h,
    };
    _openingHours = List<OpeningHours>.generate(
      7,
      (i) => saved[i + 1] ?? OpeningHours(weekday: i + 1, isClosed: true),
    );

    _descController = TextEditingController(
      text: widget.profile.storefrontBio ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.profile.businessCategory ?? '',
    );
    final links = widget.profile.storefrontLinks.isNotEmpty
        ? widget.profile.storefrontLinks
        : <String>[''];
    _linkControllers =
        links.map((l) => TextEditingController(text: l)).toList();
  }

  @override
  void dispose() {
    _descController.dispose();
    _categoryController.dispose();
    for (final c in _linkControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Shared image picker + upload dispatch ──────────────────────────────
  /// Picks an image and dispatches it through the shared validated upload path.
  /// [target] disambiguates which slot the returned URL belongs to (applied in
  /// the bloc listener). [isMainPhoto] gates the validation: the avatar (main)
  /// requires a face + no NSFW; featured/gallery only run the NSFW check.
  Future<void> _pickAndUpload(_UploadTarget target,
      {required bool isMainPhoto}) async {
    if (_pendingUploadTarget != null) return; // one upload at a time
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;
      setState(() => _pendingUploadTarget = target);
      context.read<ProfileBloc>().add(
            ProfilePhotoUploadRequested(
              userId: widget.profile.userId,
              photo: File(image.path),
              isMainPhoto: isMainPhoto,
              isPrivate: false,
            ),
          );
    } catch (_) {
      if (mounted) setState(() => _pendingUploadTarget = null);
    }
  }

  // ─── Featured / cover image ─────────────────────────────────────────────
  Future<void> _pickFeaturedImage() =>
      _pickAndUpload(_UploadTarget.featured, isMainPhoto: false);

  void _removeFeaturedImage() {
    // Empty-string sentinel: survives copyWith(coverImageUrl:) so removal
    // actually persists (the display treats empty as "no cover").
    setState(() => _coverImageUrl = '');
  }

  // ─── Profile image / avatar ─────────────────────────────────────────────
  Future<void> _pickAvatarImage() =>
      _pickAndUpload(_UploadTarget.avatar, isMainPhoto: true);

  // ─── Gallery ────────────────────────────────────────────────────────────
  Future<void> _addGalleryImage() async {
    final l10n = AppLocalizations.of(context)!;
    if (_galleryImages.length >= 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.photoMaxPublic),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }
    // Reuse the existing validated upload path (no face required for a
    // non-main public photo — only the NSFW check runs).
    await _pickAndUpload(_UploadTarget.gallery, isMainPhoto: false);
  }

  void _removeGalleryImage(int index) {
    setState(() => _galleryImages.removeAt(index));
  }

  // ─── Opening hours ──────────────────────────────────────────────────────
  String _fmtTod(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay _parseTod(String? v, {required int fallbackHour}) {
    if (v != null && v.contains(':')) {
      final parts = v.split(':');
      final h = int.tryParse(parts[0]) ?? fallbackHour;
      final m = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
    }
    return TimeOfDay(hour: fallbackHour, minute: 0);
  }

  Future<void> _pickTime(int index, {required bool isOpen}) async {
    final current = _openingHours[index];
    final initial = _parseTod(
      isOpen ? current.open : current.close,
      fallbackHour: isOpen ? 9 : 18,
    );
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      _openingHours[index] = current.copyWith(
        isClosed: false,
        open: isOpen ? _fmtTod(picked) : current.open,
        close: isOpen ? current.close : _fmtTod(picked),
      );
    });
  }

  void _toggleClosed(int index, bool closed) {
    setState(() {
      _openingHours[index] = _openingHours[index].copyWith(isClosed: closed);
    });
  }

  // ─── Links ──────────────────────────────────────────────────────────────
  void _addLinkField() {
    setState(() => _linkControllers.add(TextEditingController()));
  }

  void _removeLinkField(int index) {
    setState(() {
      _linkControllers.removeAt(index).dispose();
      if (_linkControllers.isEmpty) {
        _linkControllers.add(TextEditingController());
      }
    });
  }

  // ─── Save ───────────────────────────────────────────────────────────────
  void _save() {
    final links = _linkControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    // Apply the (optionally replaced) avatar into slot 0 of photoUrls, which is
    // what the storefront and discovery surfaces read as the business avatar.
    final photoUrls = List<String>.from(widget.profile.photoUrls);
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      if (photoUrls.isEmpty) {
        photoUrls.add(_avatarUrl!);
      } else {
        photoUrls[0] = _avatarUrl!;
      }
    }

    final updated = widget.profile.copyWith(
      photoUrls: photoUrls,
      galleryImages: _galleryImages,
      // '' sentinel persists a removal; a URL persists the new cover; null
      // leaves the existing value untouched via copyWith's null-coalescing.
      coverImageUrl: _coverImageUrl,
      openingHours: _openingHours,
      storefrontBio: _descController.text.trim(),
      storefrontLinks: links,
      businessCategory: _categoryController.text.trim().isEmpty
          ? widget.profile.businessCategory
          : _categoryController.text.trim(),
      updatedAt: DateTime.now(),
    );

    setState(() => _saving = true);
    context.read<ProfileBloc>().add(ProfileUpdateRequested(profile: updated));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();

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
          l10n.editStorefront,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfilePhotoUploaded && _pendingUploadTarget != null) {
            final target = _pendingUploadTarget;
            _pendingUploadTarget = null;
            setState(() {
              switch (target!) {
                case _UploadTarget.featured:
                  _coverImageUrl = state.photoUrl;
                  break;
                case _UploadTarget.gallery:
                  _galleryImages.add(state.photoUrl);
                  break;
                case _UploadTarget.avatar:
                  _avatarUrl = state.photoUrl;
                  break;
              }
            });
          } else if (state is ProfileUpdated && _saving) {
            _saving = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.storefrontSaved),
                backgroundColor: AppColors.successGreen,
              ),
            );
            SafeNavigation.pop(context);
          } else if (state is ProfilePhotoValidationFailed) {
            // Image rejected (NSFW / no face for avatar) — clear the spinner.
            if (_pendingUploadTarget != null && mounted) {
              setState(() => _pendingUploadTarget = null);
            }
          } else if (state is ProfileError) {
            _saving = false;
            _pendingUploadTarget = null;
            if (mounted) setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.errorRed,
              ),
            );
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          children: [
            // Featured / cover (hero) image
            _sectionHeader(
                l10n.storefrontFeaturedImage, l10n.storefrontFeaturedImageSubtitle),
            const SizedBox(height: 12),
            _featuredImagePicker(l10n),
            const SizedBox(height: 28),

            // Profile image / avatar
            _sectionHeader(
                l10n.storefrontProfileImage, l10n.storefrontProfileImageSubtitle),
            const SizedBox(height: 12),
            _avatarPicker(l10n),
            const SizedBox(height: 28),

            // Gallery
            _sectionHeader(l10n.businessGallery, l10n.storefrontGallerySubtitle),
            const SizedBox(height: 12),
            _galleryGrid(l10n),
            const SizedBox(height: 28),

            // Opening hours
            _sectionHeader(
                l10n.businessOpeningHours, l10n.storefrontOpeningHoursSubtitle),
            const SizedBox(height: 8),
            ...List.generate(7, (i) => _dayRow(i, locale, l10n)),
            const SizedBox(height: 28),

            // Description
            _sectionHeader(l10n.communitiesDescriptionLabel, null),
            const SizedBox(height: 12),
            _glassField(
              controller: _descController,
              hint: l10n.storefrontDescriptionHint,
              maxLines: 4,
            ),
            const SizedBox(height: 28),

            // Category
            _sectionHeader(l10n.categoryName, null),
            const SizedBox(height: 12),
            _glassField(
              controller: _categoryController,
              hint: l10n.storefrontCategoryHint,
            ),
            const SizedBox(height: 28),

            // Links
            _sectionHeader(l10n.businessLinks, null),
            const SizedBox(height: 12),
            ..._linkControllers.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _glassField(
                            controller: e.value,
                            hint: l10n.storefrontLinkHint,
                            keyboardType: TextInputType.url,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.textTertiary),
                          onPressed: () => _removeLinkField(e.key),
                        ),
                      ],
                    ),
                  ),
                ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addLinkField,
                icon: const Icon(Icons.add, color: AppColors.richGold, size: 18),
                label: Text(
                  l10n.storefrontAddLink,
                  style: const TextStyle(color: AppColors.richGold),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save CTA (gold)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.deepBlack),
                      )
                    : Text(
                        l10n.save,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String? subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      );

  // ─── Featured / cover image picker ──────────────────────────────────────
  Widget _featuredImagePicker(AppLocalizations l10n) {
    final hasCover = _coverImageUrl != null && _coverImageUrl!.isNotEmpty;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasCover)
              Image.network(
                _coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _featuredPlaceholder(l10n),
              )
            else
              _featuredPlaceholder(l10n),
            if (_uploadingFeatured)
              Container(
                color: AppColors.deepBlack.withOpacity(0.5),
                child: const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.richGold),
                  ),
                ),
              )
            else if (hasCover)
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    _overlayButton(
                      icon: Icons.edit,
                      onTap: _pickFeaturedImage,
                    ),
                    const SizedBox(width: 8),
                    _overlayButton(
                      icon: Icons.delete_outline,
                      onTap: _removeFeaturedImage,
                      danger: true,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _featuredPlaceholder(AppLocalizations l10n) => GestureDetector(
        onTap: _pendingUploadTarget != null ? null : _pickFeaturedImage,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.richGold.withOpacity(0.18),
                AppColors.backgroundCard,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.richGold.withOpacity(0.4)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_photo_alternate,
                    color: AppColors.richGold, size: 34),
                const SizedBox(height: 6),
                Text(
                  l10n.storefrontAddFeaturedImage,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _overlayButton({
    required IconData icon,
    required VoidCallback onTap,
    bool danger = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (danger ? AppColors.errorRed : AppColors.deepBlack)
                .withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );

  // ─── Profile image / avatar picker ──────────────────────────────────────
  Widget _avatarPicker(AppLocalizations l10n) {
    final hasAvatar = _avatarUrl != null && _avatarUrl!.isNotEmpty;
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.backgroundCard,
                border: Border.all(
                    color: AppColors.richGold.withOpacity(0.5), width: 2),
                image: hasAvatar
                    ? DecorationImage(
                        image: NetworkImage(_avatarUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: _uploadingAvatar
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.richGold),
                      ),
                    )
                  : (hasAvatar
                      ? null
                      : const Icon(Icons.storefront,
                          color: AppColors.richGold, size: 36)),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pendingUploadTarget != null ? null : _pickAvatarImage,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.richGold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit,
                      color: AppColors.deepBlack, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextButton.icon(
            onPressed: _pendingUploadTarget != null ? null : _pickAvatarImage,
            icon: const Icon(Icons.add_photo_alternate,
                color: AppColors.richGold, size: 18),
            label: Text(
              hasAvatar
                  ? l10n.storefrontReplaceProfileImage
                  : l10n.storefrontAddProfileImage,
              style: const TextStyle(color: AppColors.richGold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _galleryGrid(AppLocalizations l10n) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._galleryImages.asMap().entries.map(
              (e) => Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusM),
                    child: Image.network(
                      e.value,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: AppColors.backgroundCard,
                        child: const Icon(Icons.broken_image,
                            color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeGalleryImage(e.key),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.errorRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        // Add tile
        GestureDetector(
          onTap: _pendingUploadTarget != null ? null : _addGalleryImage,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.richGold.withOpacity(0.4),
              ),
            ),
            child: _uploadingGallery
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.richGold),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate,
                          color: AppColors.richGold, size: 28),
                      const SizedBox(height: 4),
                      Text(
                        l10n.storefrontAddImage,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _dayRow(int index, String locale, AppLocalizations l10n) {
    final day = _openingHours[index];
    final dayName =
        DateFormat.EEEE(locale).format(DateTime(2024, 1, index + 1));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              dayName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (day.isClosed)
            Expanded(
              flex: 5,
              child: Text(
                l10n.adminClosed,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            )
          else
            Expanded(
              flex: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _timeChip(day.open ?? '09:00',
                      () => _pickTime(index, isOpen: true)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('–',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  _timeChip(day.close ?? '18:00',
                      () => _pickTime(index, isOpen: false)),
                ],
              ),
            ),
          // Closed toggle
          Switch(
            value: !day.isClosed,
            activeColor: AppColors.richGold,
            onChanged: (open) => _toggleClosed(index, !open),
          ),
        ],
      ),
    );
  }

  Widget _timeChip(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.richGold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.richGold,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.backgroundCard,
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
          borderSide: const BorderSide(color: AppColors.richGold),
        ),
      ),
    );
  }
}
