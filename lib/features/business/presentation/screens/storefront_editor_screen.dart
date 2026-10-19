import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/place_search_service.dart';
import '../../../../core/widgets/info_button.dart';
import '../../../../core/widgets/location_picker.dart';
import '../../../profile/domain/entities/business_address.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/business_categories.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/domain/entities/location.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/screens/edit_location_screen.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../domain/business_name.dart';
import '../../../../core/widgets/locked_reason_sheet.dart';

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
///   * Business profile picture → `Profile.businessLogoUrl` (REQUIRED, owner
///     2026-10-19: the business tile photo in Discover, the storefront avatar
///     and the business chat avatar)
///   * Featured/cover (hero) image → `Profile.coverImageUrl` (optional: the
///     top of the storefront)
///   * Gallery → `Profile.galleryImages` (optional)
/// The storefront NEVER touches the owner's personal avatar (`photoUrls`).
/// Uploads flow through a single bloc event that returns only a URL, so the
/// pending upload's target is tracked in [_pendingUploadTarget] before dispatch
/// and applied in the listener — this keeps the uploads from mixing up.
enum _UploadTarget { logo, featured, gallery }

class StorefrontEditorScreen extends StatefulWidget {
  const StorefrontEditorScreen({required this.profile, super.key});

  final Profile profile;

  /// Business accounts must have a BUSINESS PROFILE PICTURE
  /// (`businessLogoUrl`, owner 2026-10-19): the business's tile photo in
  /// Discover, its storefront avatar and chat avatar. The featured (cover)
  /// image is optional. Empty string counts as missing.
  static bool hasRequiredLogo(String? businessLogoUrl) =>
      (businessLogoUrl ?? '').trim().isNotEmpty;

  @override
  State<StorefrontEditorScreen> createState() => _StorefrontEditorScreenState();
}

class _StorefrontEditorScreenState extends State<StorefrontEditorScreen> {
  final ImagePicker _picker = ImagePicker();

  late List<String> _galleryImages;
  late List<OpeningHours> _openingHours; // exactly 7, index 0 = Monday
  // Business PROFILE name (profiles/{uid}.businessName) - the same field the
  // Business account screen edits; validated by [BusinessName].
  late TextEditingController _businessNameController;
  bool _businessNameError = false;
  late TextEditingController _descController;
  late TextEditingController _whatsappController;
  String? _category;
  String? _categoryGroup;
  late List<TextEditingController> _linkControllers;

  // Latest location/languages the owner edited via the Location & Languages
  // tile (null until they open it this session; falls back to widget.profile).
  Location? _location;
  BusinessAddress? _businessAddress;
  List<String>? _languages;

  // Featured/cover (hero) image URL. Empty string is the "removed" sentinel so
  // the removal survives the copyWith(coverImageUrl:) null-coalescing on save.
  String? _coverImageUrl;

  // Business profile picture URL (required; never the personal photoUrls).
  String? _businessLogoUrl;

  // Which image slot the in-flight upload belongs to (null = no upload).
  _UploadTarget? _pendingUploadTarget;
  bool _saving = false;
  // Inline "add a business profile picture" error under that section (set on
  // a save attempt without one, cleared as soon as one is uploaded).
  bool _logoRequiredError = false;

  bool get _uploadingLogo => _pendingUploadTarget == _UploadTarget.logo;
  bool get _uploadingFeatured => _pendingUploadTarget == _UploadTarget.featured;
  bool get _uploadingGallery => _pendingUploadTarget == _UploadTarget.gallery;

  @override
  void initState() {
    super.initState();
    _galleryImages = List<String>.from(widget.profile.galleryImages);
    _coverImageUrl = widget.profile.coverImageUrl;
    _businessLogoUrl = widget.profile.businessLogoUrl;

    // Seed 7 weekday rows, hydrating from any saved entries.
    final saved = <int, OpeningHours>{
      for (final h in widget.profile.openingHours) h.weekday: h,
    };
    _openingHours = List<OpeningHours>.generate(
      7,
      (i) => saved[i + 1] ?? OpeningHours(weekday: i + 1, isClosed: true),
    );

    _businessNameController = TextEditingController(
      text: widget.profile.businessName ?? '',
    );
    _descController = TextEditingController(
      text: widget.profile.storefrontBio ?? '',
    );
    _whatsappController = TextEditingController(
      text: widget.profile.businessWhatsapp ?? '',
    );
    _location = widget.profile.location;
    _businessAddress = widget.profile.businessAddress;
    _languages = List<String>.from(widget.profile.languages);
    _category = widget.profile.businessCategory;
    final links = widget.profile.storefrontLinks.isNotEmpty
        ? widget.profile.storefrontLinks
        : <String>[''];
    _linkControllers =
        links.map((l) => TextEditingController(text: l)).toList();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descController.dispose();
    _whatsappController.dispose();
    for (final c in _linkControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Shared image picker + upload dispatch ──────────────────────────────
  /// Picks an image and dispatches it through the shared validated upload path.
  /// [target] disambiguates which slot the returned URL belongs to (applied in
  /// the bloc listener). [isMainPhoto] gates the validation (face + NSFW);
  /// storefront images are never the main photo, so only NSFW runs.
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
              photo: image,
              isMainPhoto: isMainPhoto,
              isPrivate: false,
            ),
          );
    } catch (_) {
      if (mounted) setState(() => _pendingUploadTarget = null);
    }
  }

  // ─── Business profile picture ───────────────────────────────────────────
  // Same validated public upload as the featured/gallery images (NSFW check,
  // no face requirement): a logo or shop photo need not show a face.
  Future<void> _pickLogoImage() =>
      _pickAndUpload(_UploadTarget.logo, isMainPhoto: false);

  // ─── Featured / cover image ─────────────────────────────────────────────
  Future<void> _pickFeaturedImage() =>
      _pickAndUpload(_UploadTarget.featured, isMainPhoto: false);

  void _removeFeaturedImage() {
    // Empty-string sentinel: survives copyWith(coverImageUrl:) so removal
    // actually persists (the display treats empty as "no cover").
    setState(() => _coverImageUrl = '');
  }

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
  /// Build the profile reflecting ALL current storefront edits (so a nested
  /// save, e.g. Location & Languages, doesn't clobber unsaved changes here).
  Profile _buildDraft() {
    final links = _linkControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final businessName =
        BusinessName.normalize(_businessNameController.text);
    return widget.profile.copyWith(
      // Empty (only in a nested, not-yet-validated draft) keeps the stored one.
      businessName: businessName.isNotEmpty ? businessName : null,
      // photoUrls (the owner's personal avatar) is deliberately NOT touched.
      galleryImages: _galleryImages,
      // '' sentinel persists a removal; a URL persists the new cover; null
      // leaves the existing value untouched via copyWith's null-coalescing.
      coverImageUrl: _coverImageUrl,
      // The business profile picture (separate from personal photoUrls).
      businessLogoUrl: _businessLogoUrl,
      openingHours: _openingHours,
      storefrontBio: _descController.text.trim(),
      storefrontLinks: links,
      businessCategory: _category ?? widget.profile.businessCategory,
      // Empty string persists a cleared WhatsApp (hides the button); a value
      // persists the number.
      businessWhatsapp: _whatsappController.text.trim(),
      location: _location ?? widget.profile.location,
      businessAddress: _businessAddress,
      clearBusinessAddress: _businessAddress == null,
      languages: _languages ?? widget.profile.languages,
      updatedAt: DateTime.now(),
    );
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    final nameOk = BusinessName.isValid(_businessNameController.text);
    final logoOk = StorefrontEditorScreen.hasRequiredLogo(_businessLogoUrl);
    if (!nameOk || !logoOk) {
      setState(() {
        _businessNameError = !nameOk;
        _logoRequiredError = !logoOk;
      });
      LockedReasonSheet.show(
        context,
        title: l10n.xplLockedStorefrontTitle,
        reason: !logoOk
            ? l10n.storefrontLogoRequiredError
            : l10n.businessProfileNameRequiredError,
        bullets: [if (!logoOk) l10n.xplInfoPicturesBusiness],
        icon: Icons.storefront,
      );
      return;
    }
    setState(() => _saving = true);
    context
        .read<ProfileBloc>()
        .add(ProfileUpdateRequested(profile: _buildDraft()));
  }

  /// Open the shared Location & Languages editor (business accounts edit these
  /// here since their personal "Edit profile" menu is hidden). It self-saves the
  /// draft via ProfileBloc and pops the updated profile; sync it back locally.
  Future<void> _openLocationLanguages() async {
    final result = await Navigator.of(context).push<Profile>(
      MaterialPageRoute<Profile>(
        builder: (_) => BlocProvider.value(
          value: context.read<ProfileBloc>(),
          child: EditLocationScreen(profile: _buildDraft()),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _location = result.location;
        _languages = List<String>.from(result.languages);
      });
    }
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
        leading: IconButton(tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
                case _UploadTarget.logo:
                  _businessLogoUrl = state.photoUrl;
                  _logoRequiredError = false;
                  break;
                case _UploadTarget.featured:
                  _coverImageUrl = state.photoUrl;
                  break;
                case _UploadTarget.gallery:
                  _galleryImages.add(state.photoUrl);
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
            // Image rejected (NSFW) — clear the spinner.
            if (_pendingUploadTarget != null && mounted) {
              setState(() => _pendingUploadTarget = null);
            }
          } else if (state is ProfileError) {
            _saving = false;
            _pendingUploadTarget = null;
            if (mounted) setState(() {});
            showUserError(context, state.message);
          }
        },
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          children: [
            // Business profile picture (required, owner 2026-10-19) - the
            // business's own picture, next to its name at the top.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _sectionHeader('${l10n.storefrontLogoTitle} *',
                      l10n.storefrontLogoSubtitle),
                ),
                InfoButton(
                  title: l10n.xplInfoPicturesTitle,
                  message: l10n.xplInfoPicturesBody,
                  bullets: [
                    l10n.xplInfoPicturesPersonal,
                    l10n.xplInfoPicturesBusiness,
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _logoPicker(l10n),
            if (_logoRequiredError &&
                !StorefrontEditorScreen.hasRequiredLogo(_businessLogoUrl)) ...[
              const SizedBox(height: 8),
              Row(
                key: const Key('storefront_logo_required_error'),
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.errorRed, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.storefrontLogoRequiredError,
                      style: const TextStyle(
                          color: AppColors.errorRed, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),

            // Business profile name (required) - shown in Discover and on
            // the storefront.
            _sectionHeader('${l10n.businessProfileNameLabel} *',
                l10n.businessProfileNameHint),
            const SizedBox(height: 12),
            _glassField(
              key: const ValueKey('storefront-business-name'),
              controller: _businessNameController,
              hint: l10n.businessProfileNameLabel,
              errorText:
                  _businessNameError ? l10n.businessProfileNameRequiredError : null,
              onChanged: (v) {
                if (_businessNameError && BusinessName.isValid(v)) {
                  setState(() => _businessNameError = false);
                }
              },
            ),
            const SizedBox(height: 28),

            // Featured / cover (hero) image (optional)
            _sectionHeader(l10n.storefrontFeaturedImage,
                l10n.storefrontFeaturedImageSubtitle),
            const SizedBox(height: 12),
            _featuredImagePicker(l10n),
            const SizedBox(height: 28),

            // Gallery (optional)
            _sectionHeader(
                l10n.businessGallery, l10n.storefrontGallerySubtitle),
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

            // Category — two select boxes: type of business, then category.
            _sectionHeader(l10n.categoryName, null),
            const SizedBox(height: 8),
            _buildCategoryGroups(),
            const SizedBox(height: 28),

            // Public business address: search + map, like events.
            _sectionHeader(l10n.storefrontAddressTitle, l10n.storefrontAddressSubtitle),
            const SizedBox(height: 8),
            _businessAddressTile(l10n),
            const SizedBox(height: 28),

            // Location & Languages (business accounts edit these here).
            _sectionHeader(l10n.locationLanguagesLabel,
                l10n.storefrontLocationLanguagesSubtitle),
            const SizedBox(height: 8),
            _locationLanguagesTile(l10n),
            const SizedBox(height: 28),

            // WhatsApp contact — visitors tap to open wa.me/<number>.
            _sectionHeader(l10n.businessWhatsappLabel,
                l10n.businessWhatsappSubtitle),
            const SizedBox(height: 12),
            _glassField(
              controller: _whatsappController,
              hint: l10n.businessWhatsappHint,
              keyboardType: TextInputType.phone,
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
                        IconButton(tooltip: AppLocalizations.of(context)!.xplTipRemove,
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

  /// Opens the shared search + map picker (the one events use) for the
  /// storefront's public address.
  Future<void> _pickBusinessAddress() async {
    final l10n = AppLocalizations.of(context)!;
    final a = _businessAddress;
    final picked = await Navigator.of(context).push<PickedPlace>(LocationPickerScreen.route(
      initialLat: a?.latitude,
      initialLng: a?.longitude,
      initialAddress: a?.address,
      title: l10n.storefrontAddressTitle,
    ));
    if (picked != null && mounted) {
      setState(() => _businessAddress = BusinessAddress.fromPicked(picked));
    }
  }

  Widget _businessAddressTile(AppLocalizations l10n) {
    final a = _businessAddress;
    return InkWell(
      key: const ValueKey('storefront-address-tile'),
      onTap: _pickBusinessAddress,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined, color: AppColors.richGold),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                a == null ? l10n.storefrontAddressNotSet : a.summary,
                style: TextStyle(
                  color: a == null ? AppColors.textTertiary : AppColors.textPrimary,
                  fontWeight: a == null ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ),
            if (a != null)
              IconButton(
                key: const ValueKey('storefront-address-clear'),
                tooltip: l10n.storefrontAddressRemove,
                icon: const Icon(Icons.close, color: AppColors.textTertiary, size: 20),
                onPressed: () => setState(() => _businessAddress = null),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  /// Tappable summary tile that opens the shared Location & Languages editor.
  Widget _locationLanguagesTile(AppLocalizations l10n) {
    final loc = _location;
    final langs = _languages ?? const <String>[];
    final parts = <String>[
      if (loc != null && loc.city.isNotEmpty) loc.city,
      if (loc != null && loc.country.isNotEmpty) loc.country,
    ];
    final place = parts.isEmpty ? l10n.storefrontLocationNotSet : parts.join(', ');
    final languagesText =
        langs.isEmpty ? '' : langs.map((c) => c.toUpperCase()).join(' · ');

    return InkWell(
      onTap: _openLocationLanguages,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: AppColors.richGold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                  if (languagesText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      languagesText,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  /// Two select boxes (owner, 2026-10-17): first the type of business
  /// ([BusinessCategories.grouped] section), then the category inside it.
  /// Changing the type clears a category that doesn't belong to it.
  Widget _buildCategoryGroups() {
    final l10n = AppLocalizations.of(context)!;
    final group = _categoryGroup ?? BusinessCategories.groupOf(_category);
    final inGroup = group == null
        ? const <String>[]
        : (BusinessCategories.grouped[group] ?? const <String>[]);
    final category = inGroup.contains(_category) ? _category : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _selectBox<String>(
          key: const ValueKey('storefront-category-group'),
          label: l10n.storefrontCategoryGroupLabel,
          hint: l10n.storefrontCategoryGroupHint,
          value: group,
          items: [
            for (final g in BusinessCategories.grouped.keys)
              DropdownMenuItem(
                value: g,
                child: Text(localizedBusinessCategoryGroup(l10n, g),
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (g) => setState(() {
            _categoryGroup = g;
            if (BusinessCategories.groupOf(_category) != g) _category = null;
          }),
        ),
        const SizedBox(height: 12),
        _selectBox<String>(
          key: const ValueKey('storefront-category'),
          label: l10n.categoryName,
          hint: l10n.storefrontCategoryHint,
          value: category,
          items: [
            for (final c in inGroup)
              DropdownMenuItem(
                value: c,
                child: Text(localizedBusinessCategory(l10n, c),
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: group == null
              ? null
              : (c) => setState(() => _category = c),
        ),
      ],
    );
  }

  Widget _selectBox<T>({
    required Key key,
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide(color: c),
        );
    return DropdownButtonFormField<T>(
      key: key,
      value: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      dropdownColor: AppColors.backgroundCard,
      iconEnabledColor: AppColors.richGold,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      hint: Text(hint, style: const TextStyle(color: AppColors.textTertiary)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.backgroundCard,
        border: border(AppColors.divider),
        enabledBorder: border(AppColors.divider),
        disabledBorder: border(AppColors.divider),
        focusedBorder: border(AppColors.richGold),
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

  // ─── Business profile picture picker ────────────────────────────────────
  Widget _logoPicker(AppLocalizations l10n) {
    final url = (_businessLogoUrl ?? '').trim();
    final hasLogo = url.isNotEmpty;
    const size = 96.0;
    return Row(
      children: [
        GestureDetector(
          key: const Key('storefront_logo_picker'),
          onTap: _pendingUploadTarget != null ? null : _pickLogoImage,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundCard,
                    border: Border.all(
                      color: _logoRequiredError && !hasLogo
                          ? AppColors.errorRed
                          : AppColors.richGold.withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                  child: hasLogo
                      ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.storefront,
                              color: AppColors.richGold,
                              size: 36),
                        )
                      : const Icon(Icons.add_a_photo_outlined,
                          color: AppColors.richGold, size: 32),
                ),
                if (_uploadingLogo)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.deepBlack.withOpacity(0.5),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.richGold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('storefront_logo_button'),
              onPressed: _pendingUploadTarget != null ? null : _pickLogoImage,
              icon: Icon(hasLogo ? Icons.edit : Icons.add_photo_alternate,
                  color: AppColors.richGold, size: 18),
              label: Text(
                hasLogo ? l10n.storefrontLogoChange : l10n.storefrontLogoAdd,
                style: const TextStyle(color: AppColors.richGold),
              ),
            ),
          ),
        ),
      ],
    );
  }

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
    Key? key,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      key: key,
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        errorText: errorText,
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
