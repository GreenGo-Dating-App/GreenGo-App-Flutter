import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';

/// Recommended size + shape of a cover-style picture (community cover,
/// storefront featured image / logo, event and experience main photo, group
/// photo). One place so every picker tells users the same numbers.
///
/// The shapes follow how the pictures are actually DISPLAYED:
///   * [banner] 16:9 - community cover (16:9 editor, 140 px full-width
///     header), storefront featured image (220 px hero), event main photo
///     (150 px card, 250 px header), experience main photo (170 px card,
///     280 px header), sponsored promo (16:9). All BoxFit.cover, so wider or
///     taller pictures are cropped at the edges.
///   * [square] 1:1 - storefront logo (circle) and group photo (circle
///     avatar).
class CoverImageSpec {
  const CoverImageSpec({
    required this.width,
    required this.height,
    required this.minWidth,
    required this.minHeight,
    this.circular = false,
  });

  /// Recommended pixel size.
  final int width;
  final int height;

  /// Below this a picked picture gets the gentle "small image" warning.
  final int minWidth;
  final int minHeight;

  /// Displayed in a circle (logo / group avatar).
  final bool circular;

  double get aspectRatio => width / height;

  /// '16:9' / '1:1' (language neutral).
  String get ratioLabel {
    int gcd(int a, int b) => b == 0 ? a : gcd(b, a % b);
    final g = gcd(width, height);
    return '${width ~/ g}:${height ~/ g}';
  }

  /// 16:9 cover / banner / main photo.
  static const banner = CoverImageSpec(
    width: 1920,
    height: 1080,
    minWidth: 1200,
    minHeight: 600,
  );

  /// Square logo / group photo, shown in a circle.
  static const square = CoverImageSpec(
    width: 1080,
    height: 1080,
    minWidth: 600,
    minHeight: 600,
    circular: true,
  );

  /// Upload ceiling enforced by storage.rules `validUpload()` for the paths
  /// these pictures go to (communities/{owner}/..., profiles/{uid}/...).
  /// Pictures are also resized / re-encoded on the device before upload, so
  /// this is a ceiling, never the size that ends up stored.
  static const int maxUploadMb = 50;

  /// A picture whose aspect ratio differs from the display shape by more than
  /// this factor is "very different" (e.g. portrait on a 16:9 banner, 16:9 on
  /// a square). 4:3 on 16:9 (1.33x) is still fine.
  static const double shapeTolerance = 1.5;

  /// What is wrong with a picture of [size] for this spec (null = fine).
  CoverImageIssue? evaluate(Size size) {
    if (size.width <= 0 || size.height <= 0) return null;
    final small = size.width < minWidth || size.height < minHeight;
    final r = size.width / size.height;
    final t = aspectRatio;
    final factor = r > t ? r / t : t / r;
    final badShape = factor > shapeTolerance;
    if (!small && !badShape) return null;
    return CoverImageIssue(size: size, small: small, badShape: badShape);
  }
}

/// Result of [CoverImageSpec.evaluate].
class CoverImageIssue {
  const CoverImageIssue({
    required this.size,
    required this.small,
    required this.badShape,
  });

  final Size size;
  final bool small;
  final bool badShape;
}

/// Reads a picture's pixel size from its encoded bytes (header only when the
/// platform supports it, else one decode). Null when it cannot be read.
Future<Size?> readImagePixelSize(Uint8List bytes) async {
  try {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size =
          Size(descriptor.width.toDouble(), descriptor.height.toDouble());
      descriptor.dispose();
      return size;
    } finally {
      buffer.dispose();
    }
  } catch (_) {
    // Web engines without ImageDescriptor.encoded: decode once.
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size =
          Size(frame.image.width.toDouble(), frame.image.height.toDouble());
      frame.image.dispose();
      codec.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }
}

/// Short localized hint: recommended size, shape, formats and upload limit.
class CoverImageSizeHint extends StatelessWidget {
  const CoverImageSizeHint({
    super.key,
    this.spec = CoverImageSpec.banner,
    this.textAlign = TextAlign.start,
  });

  final CoverImageSpec spec;
  final TextAlign textAlign;

  static String textFor(AppLocalizations l10n, CoverImageSpec spec) => spec
          .circular
      ? l10n.coverImageHintSquare(
          '${spec.width}', '${spec.height}', '${CoverImageSpec.maxUploadMb}')
      : l10n.coverImageHintBanner('${spec.width}', '${spec.height}',
          spec.ratioLabel, '${CoverImageSpec.maxUploadMb}');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      key: const Key('cover_image_size_hint'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child:
              Icon(Icons.info_outline, size: 14, color: AppColors.textTertiary),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            textFor(l10n, spec),
            textAlign: textAlign,
            style: const TextStyle(
                color: AppColors.textTertiary, fontSize: 11.5, height: 1.3),
          ),
        ),
      ],
    );
  }
}

/// Gentle, NON-blocking warning shown after a picture is picked when it is
/// much smaller than recommended or a very different shape, with a preview at
/// the real display crop. Renders nothing when the picture is fine or its
/// size cannot be read. Pass [file] for a new pick or [knownSize] when the
/// size is already known (e.g. a My pictures item).
class CoverImagePickWarning extends StatefulWidget {
  const CoverImagePickWarning({
    super.key,
    this.file,
    this.knownSize,
    this.spec = CoverImageSpec.banner,
    this.showPreview = true,
  });

  final XFile? file;
  final Size? knownSize;
  final CoverImageSpec spec;
  final bool showPreview;

  @override
  State<CoverImagePickWarning> createState() => _CoverImagePickWarningState();
}

class _CoverImagePickWarningState extends State<CoverImagePickWarning> {
  Size? _size;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(CoverImagePickWarning old) {
    super.didUpdateWidget(old);
    if (old.file != widget.file || old.knownSize != widget.knownSize) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final token = ++_token;
    if (widget.knownSize != null) {
      setState(() => _size = widget.knownSize);
      return;
    }
    _size = null;
    final file = widget.file;
    if (file == null) return;
    Size? size;
    try {
      size = await readImagePixelSize(await file.readAsBytes());
    } catch (_) {
      size = null;
    }
    if (!mounted || token != _token) return;
    setState(() => _size = size);
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;
    if (size == null) return const SizedBox.shrink();
    final issue = widget.spec.evaluate(size);
    if (issue == null) return const SizedBox.shrink();
    return CoverImageIssueCard(
      issue: issue,
      spec: widget.spec,
      preview: widget.showPreview && widget.file != null
          ? Image(
              image: ResizeImage(_XFileImage(widget.file!), width: 400),
              fit: BoxFit.cover)
          : null,
    );
  }
}

/// The warning card itself (message + optional crop preview).
class CoverImageIssueCard extends StatelessWidget {
  const CoverImageIssueCard({
    super.key,
    required this.issue,
    required this.spec,
    this.preview,
  });

  final CoverImageIssue issue;
  final CoverImageSpec spec;
  final Widget? preview;

  static String messageFor(
      AppLocalizations l10n, CoverImageIssue issue, CoverImageSpec spec) {
    final lines = <String>[
      if (issue.small)
        l10n.coverImageWarnSmall('${issue.size.width.round()}',
            '${issue.size.height.round()}', '${spec.minWidth}'),
      if (issue.badShape) l10n.coverImageWarnShape(spec.ratioLabel),
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = preview;
    return Container(
      key: const Key('cover_image_pick_warning'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.warningAmber.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 16, color: AppColors.warningAmber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  messageFor(l10n, issue, spec),
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.3),
                ),
              ),
            ],
          ),
          if (p != null) ...[
            const SizedBox(height: 8),
            Text(l10n.coverImageWarnPreview,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 11)),
            const SizedBox(height: 4),
            SizedBox(
              key: const Key('cover_image_crop_preview'),
              width: spec.circular ? 72 : 176,
              child: AspectRatio(
                aspectRatio: spec.aspectRatio,
                child: spec.circular
                    ? ClipOval(child: p)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(6), child: p),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// XFile image provider reading the picked bytes (works on mobile, web and
/// for in-memory XFile.fromData); wrapped in a ResizeImage for the preview.
class _XFileImage extends ImageProvider<_XFileImage> {
  const _XFileImage(this.file);
  final XFile file;

  @override
  Future<_XFileImage> obtainKey(ImageConfiguration configuration) =>
      Future.value(this);

  @override
  ImageStreamCompleter loadImage(
          _XFileImage key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(
        codec: () async {
          final bytes = await key.file.readAsBytes();
          final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
          return decode(buffer);
        }(),
        scale: 1.0,
      );

  @override
  bool operator ==(Object other) =>
      other is _XFileImage && other.file.path == file.path;

  @override
  int get hashCode => file.path.hashCode;
}

/// What every cover / main-photo picker shows under the picture: an "Adjust
/// position" button (when there is a picture), the recommended size hint and
/// the small / odd-shape warning for a freshly picked one.
class CoverPhotoGuide extends StatelessWidget {
  const CoverPhotoGuide({
    super.key,
    required this.hasImage,
    this.onAdjust,
    this.file,
    this.knownSize,
    this.spec = CoverImageSpec.banner,
    this.adjustKey,
  });

  final bool hasImage;
  final VoidCallback? onAdjust;
  final XFile? file;
  final Size? knownSize;
  final CoverImageSpec spec;
  final Key? adjustKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage && onAdjust != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: adjustKey,
              onPressed: onAdjust,
              icon: const Icon(Icons.open_with,
                  size: 16, color: AppColors.richGold),
              label: Text(l10n.coverPositionAdjust,
                  style: const TextStyle(color: AppColors.richGold)),
            ),
          ),
        CoverImageSizeHint(spec: spec),
        if (file != null || knownSize != null)
          CoverImagePickWarning(
            file: file,
            knownSize: file == null ? knownSize : null,
            spec: spec,
          ),
      ],
    );
  }
}
