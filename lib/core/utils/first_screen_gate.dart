import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// "Render the first screen in one go": keep the loader up until the first
/// page's data AND the images of the items visible in the first viewport are
/// decoded, then paint everything at once — never longer than a cap.
///
/// The precache only pays off when the [ImageProvider] built here is EQUAL
/// to the one the tile paints (same URL, same resize, same provider type):
/// use [cachedNetworkImageProvider] with exactly the arguments the tile's
/// `CachedNetworkImage` gets.

/// Longest wait for the first screen's images once its data is in hand.
/// On timeout the screen renders anyway (tiles show their placeholders).
const Duration kFirstScreenImageCap = Duration(milliseconds: 2500);

/// Completes when every future in [futures] has completed — an error counts
/// as completed — or after [cap], whichever comes first. Never throws.
Future<void> waitAllCapped(Iterable<Future<void>> futures, Duration cap) {
  final all = <Future<void>>[
    for (final f in futures) f.then<void>((_) {}).catchError((Object _) {}),
  ];
  if (all.isEmpty) return Future<void>.value();
  final done = Completer<void>();
  final timer = Timer(cap, () {
    if (!done.isCompleted) done.complete();
  });
  Future.wait(all).whenComplete(() {
    timer.cancel();
    if (!done.isCompleted) done.complete();
  });
  return done.future;
}

/// Decodes [images] in parallel into the ImageCache (so the tiles that use
/// the same providers paint on their first frame). Failed images count as
/// done; the whole call is bounded by [cap]. Never throws.
Future<void> precacheFirstScreen(
  BuildContext context,
  Iterable<ImageProvider> images, {
  Duration cap = kFirstScreenImageCap,
}) {
  if (!context.mounted) return Future<void>.value();
  final unique = <ImageProvider>{...images};
  final waits = <Future<void>>[];
  for (final p in unique) {
    try {
      waits.add(precacheImage(p, context,
          onError: (Object _, StackTrace? __) {/* tile shows its fallback */}));
    } catch (_) {/* counts as done */}
  }
  return waitAllCapped(waits, cap);
}

/// True when every one of [images] is already decoded in the ImageCache
/// (e.g. a revisit, or the background warm-up got there first), checked
/// synchronously so a warm first screen opens without a loader frame.
bool firstScreenImagesCached(
    BuildContext context, Iterable<ImageProvider> images) {
  final cache = PaintingBinding.instance.imageCache;
  final config = createLocalImageConfiguration(context);
  for (final p in images) {
    Object? key;
    var sync = false;
    try {
      p.obtainKey(config).then((Object k) {
        key = k;
        sync = true;
      });
    } catch (_) {
      return false;
    }
    if (!sync || key == null) return false;
    final status = cache.statusForKey(key!);
    if (!(status.keepAlive || (status.live && !status.pending))) return false;
  }
  return true;
}

/// The provider a `CachedNetworkImage(imageUrl: url, memCacheWidth: …,
/// memCacheHeight: …, maxWidthDiskCache: …, maxHeightDiskCache: …)` paints:
/// a [CachedNetworkImageProvider] wrapped in [ResizeImage] when a memory
/// size is given (what `OctoImage` does internally).
ImageProvider cachedNetworkImageProvider(
  String url, {
  int? memCacheWidth,
  int? memCacheHeight,
  int? maxWidthDiskCache,
  int? maxHeightDiskCache,
}) =>
    ResizeImage.resizeIfNeeded(
      memCacheWidth,
      memCacheHeight,
      CachedNetworkImageProvider(url,
          maxWidth: maxWidthDiskCache, maxHeight: maxHeightDiskCache),
    );

/// Width of one cell of a `GridView` with `padding: EdgeInsets.all(padding)`
/// and a `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:
/// columns, crossAxisSpacing: spacing)` laid out [boxWidth] wide — the same
/// arithmetic as the delegate.
double gridCellWidth(double boxWidth, int columns,
    {double padding = 12, double spacing = 8}) {
  final cross = math.max(0.0, boxWidth - 2 * padding);
  final usable = math.max(0.0, cross - spacing * (columns - 1));
  return usable / columns;
}

/// How many grid cells are (at least partly) visible in a [viewport]-sized
/// grid: whole rows × [columns].
int firstScreenGridCount({
  required Size viewport,
  required int columns,
  required double childAspectRatio,
  double padding = 12,
  double spacing = 8,
}) {
  final cellW = gridCellWidth(viewport.width, columns,
      padding: padding, spacing: spacing);
  if (cellW <= 0 || childAspectRatio <= 0) return columns;
  final cellH = cellW / childAspectRatio;
  final rows =
      ((viewport.height - padding) / (cellH + spacing)).ceil().clamp(1, 50);
  return rows * columns;
}

/// How many list rows of roughly [itemExtent] px are (at least partly)
/// visible in a list [viewportHeight] tall.
int firstScreenListCount({
  required double viewportHeight,
  required double itemExtent,
  double padding = 12,
}) {
  if (itemExtent <= 0) return 1;
  return ((viewportHeight - padding) / itemExtent).ceil().clamp(1, 50);
}

/// Holds [placeholder] until [ready] (the first page's data is in hand) AND
/// the [images] of the first viewport are decoded — or [cap] after [ready],
/// whichever is first — then shows [builder] for good (later data changes
/// never bring the placeholder back; re-key the gate to re-arm it).
///
/// [images] receives the gate's own viewport (its layout constraints), so a
/// tile whose decode width depends on its cell can be matched exactly. While
/// pending, a changed image list (e.g. the server page replacing a cached
/// one) is decoded instead; the cap still counts from the first [ready].
class FirstScreenGate extends StatefulWidget {
  const FirstScreenGate({
    super.key,
    required this.ready,
    required this.images,
    required this.placeholder,
    required this.builder,
    this.cap = kFirstScreenImageCap,
  });

  final bool ready;
  final List<ImageProvider> Function(BuildContext context, Size viewport)
      images;
  final Widget placeholder;
  final WidgetBuilder builder;
  final Duration cap;

  @override
  State<FirstScreenGate> createState() => _FirstScreenGateState();
}

class _FirstScreenGateState extends State<FirstScreenGate> {
  bool _open = false;
  int _batch = 0;
  List<ImageProvider> _pending = const [];
  Timer? _capTimer;

  @override
  void dispose() {
    _capTimer?.cancel();
    super.dispose();
  }

  void _openNow() {
    _capTimer?.cancel();
    if (_open || !mounted) return;
    setState(() => _open = true);
  }

  @override
  Widget build(BuildContext context) {
    // Always the same LayoutBuilder, so opening never remounts the content.
    return LayoutBuilder(builder: (context, box) {
      if (_open) return widget.builder(context);
      if (!widget.ready) return widget.placeholder;
      final mq = MediaQuery.maybeSizeOf(context) ?? Size.zero;
      final viewport = Size(
        box.maxWidth.isFinite ? box.maxWidth : mq.width,
        box.maxHeight.isFinite ? box.maxHeight : mq.height,
      );
      List<ImageProvider> images;
      try {
        images = widget.images(context, viewport);
      } catch (_) {
        images = const [];
      }
      if (images.isEmpty || firstScreenImagesCached(context, images)) {
        _capTimer?.cancel();
        _open = true; // assigned in build: no re-entrant setState
        return widget.builder(context);
      }
      _capTimer ??= Timer(widget.cap, _openNow);
      if (!listEquals(images, _pending)) {
        _pending = images;
        final batch = ++_batch;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _open || batch != _batch) return;
          precacheFirstScreen(this.context, images, cap: widget.cap).then((_) {
            if (batch == _batch) _openNow();
          });
        });
      }
      return widget.placeholder;
    });
  }
}
