import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../generated/app_localizations.dart';
import '../data/media_library_repository.dart';
import '../domain/media_library_item.dart';
import 'my_pictures_screen.dart';
import '../../../core/services/app_sound_service.dart';

/// Where a picture comes from.
enum ImageSourceChoice { camera, gallery, library }

/// The result of [pickImageWithLibrary]: a NEW file to upload (camera /
/// gallery) or an already-approved library picture to reuse as is.
class PickedImage {
  const PickedImage.file(XFile this.file) : libraryItem = null;
  const PickedImage.library(MediaLibraryItem this.libraryItem) : file = null;

  final XFile? file;
  final MediaLibraryItem? libraryItem;

  bool get isLibrary => libraryItem != null;

  /// Reused picture: its reduced approved copy (no upload, no re-moderation).
  String? get url => libraryItem?.reuseUrl;

  /// Pixel size of a reused library picture when recorded, else null.
  Size? get librarySize {
    final w = libraryItem?.reuseWidth;
    final h = libraryItem?.reuseHeight;
    return (w != null && h != null && w > 0 && h > 0)
        ? Size(w.toDouble(), h.toDouble())
        : null;
  }
}

/// Bottom sheet: Camera (optional) / Gallery / Choose from My pictures.
/// [hint] (e.g. a CoverImageSizeHint) is shown under the title.
Future<ImageSourceChoice?> showImageSourceSheet(
  BuildContext context, {
  bool allowCamera = true,
  Widget? hint,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<ImageSourceChoice>(
    context: context,
    backgroundColor: AppColors.backgroundCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.myPicturesAddPictureTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: hint,
            ),
          if (allowCamera)
            ListTile(
              key: const Key('image_source_camera'),
              leading: const Icon(Icons.camera_alt, color: AppColors.richGold),
              title: Text(l10n.myPicturesCamera,
                  style: const TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.of(ctx).pop(ImageSourceChoice.camera),
            ),
          ListTile(
            key: const Key('image_source_gallery'),
            leading: const Icon(Icons.photo_library, color: AppColors.richGold),
            title: Text(l10n.myPicturesGallery,
                style: const TextStyle(color: AppColors.textPrimary)),
            onTap: () => Navigator.of(ctx).pop(ImageSourceChoice.gallery),
          ),
          ListTile(
            key: const Key('image_source_library'),
            leading: const Icon(Icons.collections_bookmark_outlined,
                color: AppColors.richGold),
            title: Text(l10n.myPicturesChoose,
                style: const TextStyle(color: AppColors.textPrimary)),
            onTap: () => Navigator.of(ctx).pop(ImageSourceChoice.library),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Every image picker in the app: Camera / Gallery / Choose from My pictures.
///
/// Camera and gallery return a new [XFile] that goes through the surface's
/// usual upload (+ server moderation). A library pick returns the approved
/// picture: the caller stores its [PickedImage.url] directly. The personal
/// main-photo face rule still runs server-side on the profile write
/// (mainPhotoFaceRule.ts reads the item's hasFace).
Future<PickedImage?> pickImageWithLibrary(
  BuildContext context, {
  ImagePicker? picker,
  bool allowCamera = false,
  double? maxWidth,
  double? maxHeight,
  int? imageQuality,
  MediaLibraryRepository? repository,
  Widget? hint,
}) async {
  final choice = await showImageSourceSheet(context,
      allowCamera: allowCamera, hint: hint);
  if (choice == null || !context.mounted) return null;
  if (choice == ImageSourceChoice.library) {
    final item = await MyPicturesScreen.pick(context,
        repository: repository, pickHint: hint);
    return (item != null && item.isApproved) ? PickedImage.library(item) : null;
  }
  final file = await (picker ?? ImagePicker()).pickImage(
    source: choice == ImageSourceChoice.camera
        ? ImageSource.camera
        : ImageSource.gallery,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    imageQuality: imageQuality,
  );
  if (file != null && choice == ImageSourceChoice.camera) {
    AppSoundService().play(AppSound.photoCapture);
  }
  return file == null ? null : PickedImage.file(file);
}
