import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/nickname_generator.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class EditNicknameScreen extends StatefulWidget {
  final Profile profile;

  const EditNicknameScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditNicknameScreen> createState() => _EditNicknameScreenState();
}

class _EditNicknameScreenState extends State<EditNicknameScreen> {
  late TextEditingController _nicknameController;
  String? _validationError;
  bool _isChecking = false;
  bool _isAvailable = false;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.profile.nickname);
    _suggestions = NicknameGenerator.generateSuggestions(count: 5);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _validateNickname(String nickname) {
    final result = NicknameGenerator.validate(nickname);
    setState(() {
      _validationError = result.error;
      _isAvailable = false;
    });

    if (result.isValid && nickname != widget.profile.nickname) {
      _checkAvailability(nickname);
    }
  }

  Future<void> _checkAvailability(String nickname) async {
    setState(() {
      _isChecking = true;
    });

    try {
      // Real-time Firestore uniqueness check
      final querySnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .where('nickname', isEqualTo: nickname.toLowerCase())
          .limit(1)
          .get();

      if (mounted) {
        final isTaken = querySnapshot.docs.isNotEmpty &&
            querySnapshot.docs.first.id != widget.profile.userId;

        setState(() {
          _isChecking = false;
          _isAvailable = !isTaken;
          if (isTaken) {
            _validationError = 'This nickname is already taken';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isAvailable = false;
          _validationError = 'Error checking availability';
        });
      }
    }
  }

  void _selectSuggestion(String suggestion) {
    _nicknameController.text = suggestion;
    _validateNickname(suggestion);
  }

  void _regenerateSuggestions() {
    setState(() {
      _suggestions = NicknameGenerator.generateSuggestions(count: 5);
    });
  }

  void _saveNickname() {
    final nickname = _nicknameController.text.trim();
    final validation = NicknameGenerator.validate(nickname);

    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.error ?? 'Invalid nickname'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    context.read<ProfileBloc>().add(
          ProfileNicknameUpdateRequested(
            userId: widget.profile.userId,
            nickname: nickname,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Nickname',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              return TextButton(
                onPressed: state is ProfileLoading ? null : _saveNickname,
                child: state is ProfileLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.richGold,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: AppColors.richGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nickname updated successfully'),
                backgroundColor: AppColors.successGreen,
              ),
            );
            Navigator.of(context).pop(state.profile);
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.errorRed,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.richGold,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your nickname is unique and can be used to find you. Others can search for you using @${widget.profile.nickname}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Nickname input
              const Text(
                'Nickname',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nicknameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  prefixText: '@',
                  prefixStyle: const TextStyle(
                    color: AppColors.richGold,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: 'Enter nickname',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.backgroundCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: const BorderSide(color: AppColors.richGold),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: const BorderSide(color: AppColors.errorRed),
                  ),
                  errorText: _validationError,
                  suffixIcon: _isChecking
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.richGold,
                            ),
                          ),
                        )
                      : _validationError == null &&
                              _nicknameController.text.isNotEmpty
                          ? Icon(
                              _isAvailable ? Icons.check_circle : Icons.error,
                              color: _isAvailable
                                  ? AppColors.successGreen
                                  : AppColors.errorRed,
                            )
                          : null,
                ),
                onChanged: _validateNickname,
              ),

              const SizedBox(height: 8),
              const Text(
                '3-20 characters. Letters, numbers, and underscores only.',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 32),

              // Suggestions section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Suggestions',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _regenerateSuggestions,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.richGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((suggestion) {
                  return ActionChip(
                    label: Text('@$suggestion'),
                    labelStyle: const TextStyle(color: AppColors.textPrimary),
                    backgroundColor: AppColors.backgroundCard,
                    side: BorderSide(
                      color: _nicknameController.text == suggestion
                          ? AppColors.richGold
                          : AppColors.divider,
                    ),
                    onPressed: () => _selectSuggestion(suggestion),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Rules
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nickname Rules',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRule('Must be 3-20 characters'),
                    _buildRule('Start with a letter'),
                    _buildRule('Only letters, numbers, and underscores'),
                    _buildRule('No consecutive underscores'),
                    _buildRule('Cannot contain reserved words'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRule(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.textTertiary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
