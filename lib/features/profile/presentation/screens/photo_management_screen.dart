import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/action_success_dialog.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class PhotoManagementScreen extends StatefulWidget {
  final Profile profile;

  const PhotoManagementScreen({
    super.key,
    required this.profile,
  });

  @override
  State<PhotoManagementScreen> createState() => _PhotoManagementScreenState();
}

class _PhotoManagementScreenState extends State<PhotoManagementScreen> {
  final ImagePicker _picker = ImagePicker();
  List<String> _photoUrls = [];

  @override
  void initState() {
    super.initState();
    _photoUrls = List.from(widget.profile.photoUrls);
  }

  Future<void> _addPhoto() async {
    if (_photoUrls.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 6 photos allowed'),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        if (!mounted) return;

        // Upload photo
        context.read<ProfileBloc>().add(
              ProfilePhotoUploadRequested(
                userId: widget.profile.userId,
                photo: file,
              ),
            );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _deletePhoto(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Delete Photo',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this photo?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _photoUrls.removeAt(index);
              });
              _updateProfile();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final photo = _photoUrls.removeAt(oldIndex);
      _photoUrls.insert(newIndex, photo);
    });
    _updateProfile();
  }

  void _updateProfile() {
    final updatedProfile = widget.profile.copyWith(
      photoUrls: _photoUrls,
      updatedAt: DateTime.now(),
    );

    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(profile: updatedProfile),
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
            'Manage Photos',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            if (_photoUrls.length < 6)
              IconButton(
                icon: const Icon(Icons.add_photo_alternate, color: AppColors.richGold),
                onPressed: _addPhoto,
              ),
          ],
        ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) async {
            if (state is ProfilePhotoUploaded) {
              setState(() {
                _photoUrls.add(state.photoUrl);
              });
              _updateProfile();

              // Show success dialog for photo upload
              await ActionSuccessDialog.showImageUploaded(context);
            } else if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            } else if (state is ProfileUpdated) {
              // Show success dialog for photos updated (reorder/delete)
              await ActionSuccessDialog.showPhotosUpdated(context);
            }
          },
          builder: (context, state) {
            final isLoading = state is ProfileLoading;

            if (_photoUrls.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 80,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No photos yet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add photos to complete your profile',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _addPhoto,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.deepBlack,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Info Banner
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.richGold,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_photoUrls.length}/6 photos',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Long press and drag to reorder',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Photo Grid
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    onReorder: _reorderPhotos,
                    itemCount: _photoUrls.length,
                    itemBuilder: (context, index) {
                      return _PhotoCard(
                        key: ValueKey(_photoUrls[index]),
                        photoUrl: _photoUrls[index],
                        index: index,
                        onDelete: () => _deletePhoto(index),
                        isPrimary: index == 0,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
  }
}

class _PhotoCard extends StatelessWidget {
  final String photoUrl;
  final int index;
  final VoidCallback onDelete;
  final bool isPrimary;

  const _PhotoCard({
    required Key key,
    required this.photoUrl,
    required this.index,
    required this.onDelete,
    required this.isPrimary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: isPrimary ? AppColors.richGold : AppColors.divider,
                width: isPrimary ? 3 : 1,
              ),
              image: DecorationImage(
                image: NetworkImage(photoUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (isPrimary)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.richGold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PRIMARY',
                  style: TextStyle(
                    color: AppColors.deepBlack,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.errorRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.deepBlack.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.drag_handle,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
