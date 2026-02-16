import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
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

class _PhotoManagementScreenState extends State<PhotoManagementScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  List<String> _photoUrls = [];
  List<String> _privatePhotoUrls = [];
  late TabController _tabController;
  bool _uploadingToPrivate = false;
  bool _skipNextUpdateDialog = false;

  @override
  void initState() {
    super.initState();
    _photoUrls = List.from(widget.profile.photoUrls);
    _privatePhotoUrls = List.from(widget.profile.privatePhotoUrls);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto({bool isPrivate = false}) async {
    final targetList = isPrivate ? _privatePhotoUrls : _photoUrls;
    if (targetList.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 6 ${isPrivate ? "private" : "public"} photos allowed'),
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

        _uploadingToPrivate = isPrivate;
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

  void _deletePhoto(int index, {bool isPrivate = false}) {
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
                if (isPrivate) {
                  _privatePhotoUrls.removeAt(index);
                } else {
                  _photoUrls.removeAt(index);
                }
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

  void _copyToOther(String photoUrl, {required bool toPrivate}) {
    final targetList = toPrivate ? _privatePhotoUrls : _photoUrls;
    if (targetList.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 6 ${toPrivate ? "private" : "public"} photos'),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }
    if (targetList.contains(photoUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo already exists in target album'),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }
    setState(() {
      targetList.add(photoUrl);
    });
    _updateProfile();
  }

  void _reorderPhotos(int oldIndex, int newIndex, {bool isPrivate = false}) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final list = isPrivate ? _privatePhotoUrls : _photoUrls;
      final photo = list.removeAt(oldIndex);
      list.insert(newIndex, photo);
    });
    _updateProfile();
  }

  void _updateProfile() {
    final updatedProfile = widget.profile.copyWith(
      photoUrls: _photoUrls,
      privatePhotoUrls: _privatePhotoUrls,
      updatedAt: DateTime.now(),
    );

    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(profile: updatedProfile),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.richGold,
            labelColor: AppColors.richGold,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(
                icon: const Icon(Icons.public, size: 18),
                text: '${l10n?.publicAlbum ?? "Public"} (${_photoUrls.length}/6)',
              ),
              Tab(
                icon: const Icon(Icons.lock, size: 18),
                text: '${l10n?.privateAlbum ?? "Private"} (${_privatePhotoUrls.length}/6)',
              ),
            ],
          ),
        ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) async {
            if (state is ProfilePhotoUploaded) {
              setState(() {
                if (_uploadingToPrivate) {
                  _privatePhotoUrls.add(state.photoUrl);
                } else {
                  _photoUrls.add(state.photoUrl);
                }
              });
              _skipNextUpdateDialog = true;
              _updateProfile();
              await ActionSuccessDialog.showImageUploaded(context);
            } else if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            } else if (state is ProfileUpdated) {
              if (_skipNextUpdateDialog) {
                _skipNextUpdateDialog = false;
              } else {
                await ActionSuccessDialog.showPhotosUpdated(context);
              }
            }
          },
          builder: (context, state) {
            final isLoading = state is ProfileLoading;

            return Column(
              children: [
                // Upload progress bar
                if (isLoading)
                  const LinearProgressIndicator(
                    color: AppColors.richGold,
                    backgroundColor: AppColors.backgroundCard,
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPhotoList(
                        photos: _photoUrls,
                        isPrivate: false,
                        isLoading: isLoading,
                      ),
                      _buildPhotoList(
                        photos: _privatePhotoUrls,
                        isPrivate: true,
                        isLoading: isLoading,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
  }

  Widget _buildPhotoList({
    required List<String> photos,
    required bool isPrivate,
    required bool isLoading,
  }) {
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPrivate ? Icons.lock_outline : Icons.photo_library_outlined,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              isPrivate ? 'No private photos yet' : 'No photos yet',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPrivate
                  ? 'Add private photos that you can share in chat'
                  : 'Add photos to complete your profile',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isLoading ? null : () => _addPhoto(isPrivate: isPrivate),
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
              Icon(
                isPrivate ? Icons.lock : Icons.info_outline,
                color: AppColors.richGold,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${photos.length}/6 photos',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPrivate
                          ? 'Private photos can be shared in chat'
                          : 'Long press and drag to reorder',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (photos.length < 6)
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate, color: AppColors.richGold),
                  onPressed: () => _addPhoto(isPrivate: isPrivate),
                ),
            ],
          ),
        ),

        // Photo Grid
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            onReorder: (oldIndex, newIndex) =>
                _reorderPhotos(oldIndex, newIndex, isPrivate: isPrivate),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return _PhotoCard(
                key: ValueKey('${isPrivate ? "priv" : "pub"}_${photos[index]}'),
                photoUrl: photos[index],
                index: index,
                onDelete: () => _deletePhoto(index, isPrivate: isPrivate),
                isPrimary: !isPrivate && index == 0,
                isPrivate: isPrivate,
                onCopyToOther: () => _copyToOther(
                  photos[index],
                  toPrivate: !isPrivate,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final String photoUrl;
  final int index;
  final VoidCallback onDelete;
  final bool isPrimary;
  final bool isPrivate;
  final VoidCallback? onCopyToOther;

  const _PhotoCard({
    required Key key,
    required this.photoUrl,
    required this.index,
    required this.onDelete,
    required this.isPrimary,
    this.isPrivate = false,
    this.onCopyToOther,
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
          // Copy to other album button
          if (onCopyToOther != null)
            Positioned(
              top: 8,
              right: 44,
              child: GestureDetector(
                onTap: onCopyToOther,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.deepBlack.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPrivate ? Icons.public : Icons.lock,
                    color: Colors.white,
                    size: 20,
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
