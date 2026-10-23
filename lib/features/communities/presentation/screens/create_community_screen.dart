import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../media_library/presentation/image_source_picker.dart';
import '../../../../core/services/image_moderation_gate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/platform/web_media.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../utils/community_l10n.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../domain/community_id.dart';
import '../../domain/entities/community.dart';
import '../bloc/communities_bloc.dart';
import '../bloc/communities_event.dart';
import '../bloc/communities_state.dart';
import '../widgets/community_card.dart';
import '../widgets/sponsorship_editor_sheet.dart';
import '../widgets/sponsorship_gate.dart';
import 'community_detail_screen.dart';
import '../../../../core/media/cover_focus.dart';
import '../../../../core/widgets/cover_frames.dart';
import '../../../../core/widgets/cover_image_size_hint.dart';
import '../../../../core/widgets/cover_positioner.dart';
import '../../../../core/widgets/focal_cover_image.dart';
import '../widgets/community_text_warning.dart';
import '../../../../core/services/app_sound_service.dart';
import '../../../../core/services/sound_feedback.dart';

/// Create Community Screen
///
/// Form for creating a new community with name, description,
/// type, languages, tags, and privacy settings.
///
/// With [existing] the SAME form opens in EDIT mode (owner request
/// 2026-10-21: "who created a community can change the community info and
/// featured image"): prefilled, no preview step, Save dispatches
/// [UpdateCommunity]. Only the creator reaches it (detail screen menu; the
/// Firestore rules enforce the same).
class CreateCommunityScreen extends StatefulWidget {

  const CreateCommunityScreen({
    super.key,
    this.preselectedType,
    this.existing,
    this.currentUserId,
  });
  final CommunityType? preselectedType;

  /// The signed-in user's id; null = read it from FirebaseAuth (tests pass it).
  final String? currentUserId;

  /// The community being edited (null = create a new one).
  final Community? existing;

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _tagController = TextEditingController();

  CommunityType _selectedType = CommunityType.general;
  bool _isPublic = true;
  final List<String> _selectedLanguages = [];
  final List<String> _tags = [];
  bool _showPreview = false;

  // Hero/cover image (optional). Picked locally, uploaded to Storage on create.
  XFile? _coverImage;
  // A cover that is already a URL (no upload): a picture from My pictures, or
  // in edit mode the community's current cover.
  String? _coverLibraryUrl;

  // Where the cover sits in every frame (focal point + zoom), chosen in the
  // positioning step after a pick; centre by default.
  CoverFocus _coverFocus = CoverFocus.center;
  // Pixel size of a My pictures cover (for the small-image warning).
  Size? _coverLibrarySize;

  ImageProvider? get _coverProvider => _coverImage != null
      ? WebMedia.imageProviderFor(_coverImage!)
      : (_coverLibraryUrl != null ? NetworkImage(_coverLibraryUrl!) : null);
  bool _uploadingCover = false;
  // The URL of [_coverImage] once uploaded, so a retry never uploads it twice.
  XFile? _uploadedCoverFor;
  String? _uploadedCoverUrl;

  /// The new community's doc id, generated ONCE for this form: every tap on
  /// Create (or retry) writes the SAME `communities/{id}`, so a double submit
  /// can never produce two communities (owner bug 2026-10-21).
  /// In edit mode the edited community's id.
  late final String _communityId = widget.existing?.id ?? newCommunityId();

  bool get _isEdit => widget.existing != null;

  /// True from the first Create tap until the bloc answers (success navigates
  /// away; an error re-enables the buttons). Both Create buttons are disabled
  /// meanwhile.
  bool _submitting = false;

  // Sponsorship (Platinum-business feature).
  bool _isSponsored = false;
  PinnedPromo? _pinnedPromo;

  final List<Map<String, String>> _availableLanguages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'de', 'name': 'German'},
    {'code': 'it', 'name': 'Italian'},
    {'code': 'pt', 'name': 'Portuguese'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'ko', 'name': 'Korean'},
    {'code': 'zh', 'name': 'Mandarin'},
    {'code': 'ar', 'name': 'Arabic'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'ru', 'name': 'Russian'},
    {'code': 'tr', 'name': 'Turkish'},
    {'code': 'nl', 'name': 'Dutch'},
    {'code': 'sv', 'name': 'Swedish'},
    {'code': 'pl', 'name': 'Polish'},
    {'code': 'th', 'name': 'Thai'},
    {'code': 'vi', 'name': 'Vietnamese'},
    {'code': 'ca', 'name': 'Catalan'},
    {'code': 'he', 'name': 'Hebrew'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedType != null) {
      _selectedType = widget.preselectedType!;
    }
    final c = widget.existing;
    if (c != null) {
      _nameController.text = c.name;
      _descriptionController.text = c.description;
      _cityController.text = c.city ?? '';
      _countryController.text = c.country ?? '';
      _selectedType = c.type;
      _isPublic = c.isPublic;
      _selectedLanguages.addAll(c.languages);
      _tags.addAll(c.tags);
      final image = c.imageUrl ?? '';
      _coverLibraryUrl = image.isEmpty ? null : image;
      _coverFocus = c.coverFocus;
      _isSponsored = c.isSponsored;
      _pinnedPromo = c.pinnedPromo;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEdit
              ? AppLocalizations.of(context)!.communitiesEditCommunity
              : AppLocalizations.of(context)!.communitiesCreateCommunity,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isEdit)
            TextButton(
              key: const Key('editCommunitySaveAppBarAction'),
              onPressed: _submitting ? null : _saveEdits,
              child: Text(
                AppLocalizations.of(context)!.communitiesSaveLabel,
                style: TextStyle(
                  color: _submitting
                      ? AppColors.textTertiary
                      : AppColors.richGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
          TextButton(
            key: const Key('createCommunityAppBarAction'),
            onPressed: _showPreview && !_submitting ? _createCommunity : null,
            child: Text(
              AppLocalizations.of(context)!.communitiesCreateAction,
              style: TextStyle(
                color: _showPreview && !_submitting
                    ? AppColors.richGold
                    : AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<CommunitiesBloc, CommunitiesState>(
        listener: (context, state) {
          if (_isEdit) {
            if (state is CommunityInfoUpdated &&
                state.community.id == _communityId &&
                _submitting) {
              _submitting = false;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.communitiesUpdatedSuccess,
                  ),
                  backgroundColor: AppColors.successGreen,
                ),
              );
              Navigator.of(context).pop(state.community);
            } else if (state is CommunitiesError && _submitting) {
              setState(() => _submitting = false);
              showUserError(context, state.message);
            }
            return;
          }
          if (state is CommunityCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.communitiesCreatedManageHint,
                ),
                backgroundColor: AppColors.successGreen,
                duration: const Duration(seconds: 4),
              ),
            );
            // Land the creator INSIDE the new community so they can immediately
            // add members and grant tip / announcement rights (Members sheet →
            // moderation). pushReplacement so Back doesn't return to the form.
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: context.read<CommunitiesBloc>()),
                    BlocProvider.value(value: context.read<ProfileBloc>()),
                  ],
                  child: CommunityDetailScreen(community: state.community),
                ),
              ),
            );
          } else if (state is CommunitiesError) {
            if (_submitting) setState(() => _submitting = false);
            showUserError(context, state.message);
          }
        },
        child: _showPreview ? _buildPreview() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover / hero image (optional)
            _buildCoverPicker(),
            const SizedBox(height: AppDimensions.paddingL),

            // Name
            _buildSectionLabel(AppLocalizations.of(context)!.communitiesCommunityName),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration(AppLocalizations.of(context)!.communitiesNameHint),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.communitiesNameRequired;
                }
                if (value.trim().length < 3) {
                  return AppLocalizations.of(context)!.communitiesNameMinLength;
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Description
            _buildSectionLabel(AppLocalizations.of(context)!.communitiesDescriptionLabel),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 4,
              decoration: _inputDecoration(
                AppLocalizations.of(context)!.communitiesDescriptionHint,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.communitiesDescriptionRequired;
                }
                if (value.trim().length < 10) {
                  return AppLocalizations.of(context)!.communitiesDescriptionMinLength;
                }
                return null;
              },
            ),
            // Apple 4.3(b): gentle note on dating wording (never blocks).
            CommunityTextWarning(
              controllers: [_nameController, _descriptionController],
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Type selector
            _buildSectionLabel(AppLocalizations.of(context)!.communitiesCommunityType),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CommunityType.values.map((type) {
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedType = type);
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.richGold.withValues(alpha: 0.15)
                          : AppColors.backgroundCard,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.richGold
                            : AppColors.divider,
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTypeIcon(type),
                          size: 18,
                          color: isSelected
                              ? AppColors.richGold
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          communityTypeLabel(AppLocalizations.of(context)!, type),
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.richGold
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Languages (multi-select)
            _buildSectionLabel(AppLocalizations.of(context)!.communitiesLanguagesLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableLanguages.map((lang) {
                final isSelected =
                    _selectedLanguages.contains(lang['code']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedLanguages.remove(lang['code']);
                      } else {
                        _selectedLanguages.add(lang['code']!);
                      }
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.infoBlue.withValues(alpha: 0.15)
                          : AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.infoBlue
                            : AppColors.divider,
                        width: isSelected ? 1 : 0.5,
                      ),
                    ),
                    child: Text(
                      communityLanguageName(AppLocalizations.of(context)!, lang['code']!),
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.infoBlue
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Tags
            _buildSectionLabel(AppLocalizations.of(context)!.communitiesTagsLabel),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration(AppLocalizations.of(context)!.communitiesAddTag),
                    onSubmitted: _addTag,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(tooltip: AppLocalizations.of(context)!.xplTipAddTag,
                  onPressed: () => _addTag(_tagController.text),
                  icon: const Icon(Icons.add_circle,
                      color: AppColors.richGold),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: AppColors.richGold.withValues(alpha: 0.1),
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    onDeleted: () {
                      setState(() => _tags.remove(tag));
                    },
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: AppDimensions.paddingL),

            // City / Country (for local guides or travel groups)
            if (_selectedType == CommunityType.localGuides ||
                _selectedType == CommunityType.travelGroup) ...[
              _buildSectionLabel(AppLocalizations.of(context)!.communitiesLocationLabel),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(AppLocalizations.of(context)!.communitiesCityLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _countryController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(AppLocalizations.of(context)!.communitiesCountryLabel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingL),
            ],

            // Public/Private toggle
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPublic ? Icons.public : Icons.lock_outline,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPublic ? AppLocalizations.of(context)!.communitiesPublic : AppLocalizations.of(context)!.communitiesPrivate,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _isPublic
                              ? AppLocalizations.of(context)!.communitiesAnyoneCanJoin
                              : AppLocalizations.of(context)!.communitiesInviteOnly,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isPublic,
                    onChanged: withToggleSound((value) =>
                        setState(() => _isPublic = value)),
                    activeThumbColor: AppColors.richGold,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Sponsorship (Platinum-business feature). In edit mode it stays
            // in the detail screen's own sponsorship editor.
            if (!_isEdit) ...[
              _buildSponsorshipSection(),
              const SizedBox(height: AppDimensions.paddingXL),
            ],

            // Preview button (create) / Save button (edit)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: _isEdit ? const Key('editCommunitySaveButton') : null,
                onPressed: _isEdit
                    ? (_submitting ? null : _saveEdits)
                    : _validateAndShowPreview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
                child: _isEdit && _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.deepBlack,
                        ),
                      )
                    : Text(
                        _isEdit
                            ? AppLocalizations.of(context)!.communitiesSaveLabel
                            : AppLocalizations.of(context)!.communitiesPreview,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final previewCommunity = _buildCommunityFromForm();

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.communitiesPreview,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.communitiesPreviewSubtitle,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),

          // Featured/cover image hero (the picked image isn't uploaded yet, so
          // preview it from the local file).
          if (_coverProvider != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: FocalCoverImage(
                    image: _coverProvider!, focus: _coverFocus),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
          ],

          // Preview card
          CommunityCard(community: previewCommunity),
          const SizedBox(height: AppDimensions.paddingXL),

          // Details preview
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  previewCommunity.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  previewCommunity.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                if (previewCommunity.languages.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    children: previewCommunity.languages.map((lang) {
                      return Chip(
                        label: Text(
                          lang.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: AppColors.backgroundInput,
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                if (previewCommunity.tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: previewCommunity.tags.map((tag) {
                      return Text(
                        '#$tag',
                        style: const TextStyle(
                          color: AppColors.richGold,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),

          // Edit / Create buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showPreview = false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.communitiesEditLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  key: const Key('createCommunitySubmitButton'),
                  onPressed: _submitting ? null : _createCommunity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.deepBlack,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!
                              .communitiesCreateCommunityAction,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingXL),
        ],
      ),
    );
  }

  /// Optional cover image picker (16:9 banner).
  Widget _buildCoverPicker() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(l10n.communitiesCoverImageLabel),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickCoverImage,
          child: AspectRatio(
            aspectRatio: CoverImageSpec.banner.aspectRatio,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: _coverProvider != null
                  ? Stack(fit: StackFit.expand, children: [
                      FocalCoverImage(
                        key: const Key('communityCoverImage'),
                        image: _coverProvider!,
                        focus: _coverFocus,
                      ),
                      Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            key: const Key('communityCoverRemove'),
                            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                            padding: EdgeInsets.zero,
                            iconSize: 18,
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() {
                              _coverImage = null;
                              _coverLibraryUrl = null;
                              _coverLibrarySize = null;
                              _coverFocus = CoverFocus.center;
                            }),
                          ),
                        ),
                      ),
                    ),
                    ])
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            color: AppColors.textTertiary, size: 32),
                        const SizedBox(height: 6),
                        Text(
                          l10n.communitiesCoverImageHint,
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        CoverPhotoGuide(
          hasImage: _coverProvider != null,
          onAdjust: _positionCover,
          adjustKey: const Key('communityCoverAdjust'),
          file: _coverImage,
          knownSize: _coverLibrarySize,
        ),
      ],
    );
  }

  /// Positioning step: drag / zoom the cover inside the real frame with a
  /// live preview of every place it is shown.
  Future<void> _positionCover() async {
    final provider = _coverProvider;
    if (provider == null) return;
    final l10n = AppLocalizations.of(context)!;
    final focus = await showCoverPositioner(
      context,
      image: provider,
      initial: _coverFocus,
      frames: CoverFrames.community(l10n),
      title: _nameController.text.trim(),
      file: _coverImage,
      knownSize: _coverImage == null ? _coverLibrarySize : null,
    );
    if (focus != null && mounted) setState(() => _coverFocus = focus);
  }

  Future<void> _pickCoverImage() async {
    HapticFeedback.selectionClick();
    final picked = await pickImageWithLibrary(
      context,
      maxWidth: 1600,
      imageQuality: 82,
      hint: const CoverImageSizeHint(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      // A new picture starts centred; the positioning step moves it.
      _coverFocus = CoverFocus.center;
      if (picked.isLibrary) {
        _coverImage = null;
        _coverLibraryUrl = picked.url;
        _coverLibrarySize = picked.librarySize;
      } else {
        _coverImage = picked.file;
        _coverLibraryUrl = null;
        _coverLibrarySize = null;
      }
    });
    await _positionCover();
  }

  /// Upload the picked cover image to Storage; returns its download URL or null.
  Future<String?> _uploadCoverImage(String communityOwnerId) async {
    if (_coverImage == null) return _coverLibraryUrl;
    try {
      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final objectPath = 'communities/$communityOwnerId/$fileName';
      final ref = FirebaseStorage.instance.ref().child(objectPath);
      final task = await WebMedia.uploadXFile(ref, _coverImage!);
      // Never store a URL before the server check passed: a held picture is
      // moved out of reach and must not end up on the community doc.
      await ImageModerationGate().awaitVerdict(objectPath);
      return task.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Cover image upload failed: $e');
      return null;
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim().toLowerCase().replaceAll(' ', '-');
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
        _tagController.clear();
      });
    }
  }

  void _validateAndShowPreview() {
    if (_formKey.currentState!.validate()) {
      setState(() => _showPreview = true);
      HapticFeedback.mediumImpact();
    }
  }

  /// EDIT mode: the edited community with the form's info fields applied.
  /// Everything else (creator, createdAt, member count, sponsorship, rules,
  /// resources) is carried over unchanged.
  Community _buildEditedCommunity({String? imageUrl}) {
    final city = _cityController.text.trim();
    final country = _countryController.text.trim();
    return widget.existing!.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      imageUrl: imageUrl,
      clearImageUrl: imageUrl == null,
      coverFocus: imageUrl == null ? CoverFocus.center : _coverFocus,
      languages: List<String>.of(_selectedLanguages),
      tags: List<String>.of(_tags),
      isPublic: _isPublic,
      city: city.isEmpty ? null : city,
      clearCity: city.isEmpty,
      country: country.isEmpty ? null : country,
      clearCountry: country.isEmpty,
    );
  }

  /// EDIT mode: validate, upload a newly picked cover (same moderation wait
  /// as create), then save via [UpdateCommunity]. The previous cover's
  /// Storage object is left in place: it may be a My pictures item or still
  /// referenced elsewhere.
  Future<void> _saveEdits() async {
    if (_submitting || _uploadingCover) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final userId =
        widget.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    setState(() => _submitting = true);

    String? imageUrl = _coverLibraryUrl;
    if (_coverImage != null) {
      if (_uploadedCoverFor == _coverImage && _uploadedCoverUrl != null) {
        imageUrl = _uploadedCoverUrl;
      } else {
        setState(() => _uploadingCover = true);
        imageUrl = await _uploadCoverImage(userId);
        if (!mounted) return;
        setState(() => _uploadingCover = false);
        if (imageUrl == null) {
          // Upload failed or the picture was held by moderation: never drop
          // the current cover silently.
          setState(() => _submitting = false);
          showUserError(context,
              AppLocalizations.of(context)!.communitiesCoverUploadFailed);
          return;
        }
        _uploadedCoverFor = _coverImage;
        _uploadedCoverUrl = imageUrl;
      }
    }
    if (!mounted) return;
    context.read<CommunitiesBloc>().add(
          UpdateCommunity(community: _buildEditedCommunity(imageUrl: imageUrl)),
        );
    HapticFeedback.mediumImpact();
  }

  Community _buildCommunityFromForm({String? imageUrl}) {
    return Community(
      id: _communityId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      createdByUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
      createdByName: _getCurrentUserName(),
      createdAt: DateTime.now(),
      memberCount: 1,
      imageUrl: imageUrl,
      coverFocus: imageUrl == null ? CoverFocus.center : _coverFocus,
      languages: _selectedLanguages,
      tags: _tags,
      isPublic: _isPublic,
      city: _cityController.text.trim().isNotEmpty
          ? _cityController.text.trim()
          : null,
      country: _countryController.text.trim().isNotEmpty
          ? _countryController.text.trim()
          : null,
      // Sponsorship: only persisted when the eligible business enabled it.
      sponsorId: _isSponsored
          ? (FirebaseAuth.instance.currentUser?.uid ?? '')
          : null,
      isSponsored: _isSponsored,
      pinnedPromo: _isSponsored ? _pinnedPromo : null,
    );
  }

  String _getCurrentUserName() {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      return profileState.profile.displayName;
    }
    return 'Unknown';
  }

  Future<void> _createCommunity() async {
    // Re-entrancy guard: a second tap while the first create is still in
    // flight (cover upload + Firestore writes can take several seconds) used
    // to create a SECOND identical community.
    if (_submitting || _uploadingCover) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    setState(() => _submitting = true);

    // Upload the cover image (if any) BEFORE creating the community so its URL
    // is stored on the doc. Reused on a retry so it is uploaded only once;
    // a picture chosen from My pictures is used as-is (no upload).
    String? imageUrl = _coverLibraryUrl;
    if (_coverImage != null) {
      if (_uploadedCoverFor == _coverImage && _uploadedCoverUrl != null) {
        imageUrl = _uploadedCoverUrl;
      } else {
        setState(() => _uploadingCover = true);
        imageUrl = await _uploadCoverImage(userId);
        if (!mounted) return;
        setState(() => _uploadingCover = false);
        if (imageUrl != null) {
          _uploadedCoverFor = _coverImage;
          _uploadedCoverUrl = imageUrl;
        }
      }
    }

    final community = _buildCommunityFromForm(imageUrl: imageUrl);
    if (!mounted) return;
    context.read<CommunitiesBloc>().add(
          CreateCommunity(
            community: community,
            userId: userId,
            userName: _getCurrentUserName(),
          ),
        );

    AppSoundService().play(AppSound.communityJoin);
    HapticFeedback.heavyImpact();
  }

  Widget _buildSponsorshipSection() {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: _openSponsorshipEditor,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.richGold.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: AppColors.richGold.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium,
                color: AppColors.richGold, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.communitiesSponsorThisCommunity,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isSponsored && _pinnedPromo != null
                        ? _pinnedPromo!.title
                        : l10n.communitiesSponsorSubtitle,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              _isSponsored ? Icons.edit_outlined : Icons.chevron_right,
              color: AppColors.richGold,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSponsorshipEditor() async {
    HapticFeedback.selectionClick();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (!SponsorshipGate.canSponsor(
      isBusiness: _isBusiness,
      tier: _membershipTier,
    )) {
      await SponsorshipGate.showGate(
        context,
        currentTier: _membershipTier,
        userId: userId,
      );
      return;
    }

    final result = await SponsorshipEditorSheet.show(
      context,
      initialSponsored: _isSponsored,
      initialPromo: _pinnedPromo,
    );
    if (result != null) {
      setState(() {
        _isSponsored = result.isSponsored;
        _pinnedPromo = result.pinnedPromo;
      });
    }
  }

  bool get _isBusiness {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      return profileState.profile.isBusiness;
    }
    return false;
  }

  MembershipTier get _membershipTier {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      return profileState.profile.effectiveTier;
    }
    return MembershipTier.free;
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textTertiary),
      filled: true,
      fillColor: AppColors.backgroundInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingM,
      ),
      errorStyle: const TextStyle(color: AppColors.errorRed),
    );
  }

  IconData _getTypeIcon(CommunityType type) {
    switch (type) {
      case CommunityType.languageCircle:
        return Icons.translate;
      case CommunityType.culturalInterest:
        return Icons.public;
      case CommunityType.travelGroup:
        return Icons.flight;
      case CommunityType.localGuides:
        return Icons.location_on;
      case CommunityType.studyGroup:
        return Icons.menu_book;
      case CommunityType.general:
        return Icons.chat_bubble_outline;
    }
  }
}
