import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../domain/entities/community.dart';
import '../bloc/communities_bloc.dart';
import '../bloc/communities_event.dart';
import '../bloc/communities_state.dart';
import '../widgets/community_card.dart';

/// Create Community Screen
///
/// Form for creating a new community with name, description,
/// type, languages, tags, and privacy settings
class CreateCommunityScreen extends StatefulWidget {
  final CommunityType? preselectedType;

  const CreateCommunityScreen({
    super.key,
    this.preselectedType,
  });

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
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Community',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _showPreview ? _createCommunity : null,
            child: Text(
              'Create',
              style: TextStyle(
                color: _showPreview
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
          if (state is CommunityCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Community created!'),
                backgroundColor: AppColors.successGreen,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is CommunitiesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.errorRed,
              ),
            );
          }
        },
        child: _showPreview ? _buildPreview() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            _buildSectionLabel('Community Name'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration('e.g., Spanish Learners NYC'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Description
            _buildSectionLabel('Description'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 4,
              decoration: _inputDecoration(
                'What is this community about?',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Type selector
            _buildSectionLabel('Community Type'),
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
                          type.displayName,
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
            _buildSectionLabel('Languages'),
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
                      lang['name']!,
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
            _buildSectionLabel('Tags'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Add a tag'),
                    onSubmitted: _addTag,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
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
              _buildSectionLabel('Location'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('City'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _countryController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Country'),
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
                          _isPublic ? 'Public' : 'Private',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _isPublic
                              ? 'Anyone can find and join'
                              : 'Invite only',
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
                    onChanged: (value) =>
                        setState(() => _isPublic = value),
                    activeColor: AppColors.richGold,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingXL),

            // Preview button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validateAndShowPreview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
                child: const Text(
                  'Preview',
                  style: TextStyle(
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
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This is how your community will appear to others.',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),

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
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _createCommunity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                  ),
                  child: const Text(
                    'Create Community',
                    style: TextStyle(
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

  Community _buildCommunityFromForm() {
    return Community(
      id: '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      createdByUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
      createdByName: _getCurrentUserName(),
      createdAt: DateTime.now(),
      memberCount: 1,
      languages: _selectedLanguages,
      tags: _tags,
      isPublic: _isPublic,
      city: _cityController.text.trim().isNotEmpty
          ? _cityController.text.trim()
          : null,
      country: _countryController.text.trim().isNotEmpty
          ? _countryController.text.trim()
          : null,
    );
  }

  String _getCurrentUserName() {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      return profileState.profile.displayName;
    }
    return 'Unknown';
  }

  void _createCommunity() {
    final community = _buildCommunityFromForm();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    context.read<CommunitiesBloc>().add(
          CreateCommunity(
            community: community,
            userId: userId,
            userName: _getCurrentUserName(),
          ),
        );

    HapticFeedback.heavyImpact();
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
