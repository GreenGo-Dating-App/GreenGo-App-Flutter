import 'dart:async';
import 'dart:io' show File;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'cover_focus.dart';

/// Source rectangle (image pixels) that a frame of [aspect] shows of an image
/// of [imageSize] with BoxFit.cover positioned at [focus] - the exact maths
/// [FocalCoverImage] applies on screen.
Rect coverSourceRect(Size imageSize, double aspect, CoverFocus focus) {
  final f = focus.clamped();
  final iw = imageSize.width;
  final ih = imageSize.height;
  double fw, fh;
  if (iw / ih > aspect) {
    fh = ih;
    fw = ih * aspect;
  } else {
    fw = iw;
    fh = iw / aspect;
  }
  final w = fw / f.zoom;
  final h = fh / f.zoom;
  final left = (1 + f.x) / 2 * (iw - w);
  final top = (1 + f.y) / 2 * (ih - h);
  return Rect.fromLTWH(left, top, w, h);
}

/// Client-side crop (used for the storefront LOGO, which is shown as an
/// avatar in many places, so it is stored already square): renders the part
/// of [image] a frame of [aspect] shows at [focus], at most [maxSide] px on
/// its longer side, as PNG. Returns an [XFile] ready for the usual upload, or
/// null when the picture cannot be read.
Future<XFile?> cropImageToFocus(
  ImageProvider image,
  CoverFocus focus, {
  double aspect = 1,
  int maxSide = 1080,
}) async {
  ui.Image? src;
  try {
    src = await _resolve(image);
    if (src == null) return null;
    final rect = coverSourceRect(
        Size(src.width.toDouble(), src.height.toDouble()), aspect, focus);
    final scale = rect.longestSide > maxSide ? maxSide / rect.longestSide : 1.0;
    final ow = (rect.width * scale).round().clamp(1, 1 << 14);
    final oh = (rect.height * scale).round().clamp(1, 1 << 14);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      src,
      rect,
      Rect.fromLTWH(0, 0, ow.toDouble(), oh.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    final out = await recorder.endRecording().toImage(ow, oh);
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    out.dispose();
    if (data == null) return null;
    final bytes = data.buffer.asUint8List();
    final name = 'cover_${DateTime.now().millisecondsSinceEpoch}.png';
    if (kIsWeb) {
      return XFile.fromData(bytes, mimeType: 'image/png', name: name);
    }
    // Mobile uploads read the file path (compression + putFile).
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return XFile(file.path, mimeType: 'image/png', name: name);
  } catch (e) {
    debugPrint('cropImageToFocus failed: $e');
    return null;
  } finally {
    src?.dispose();
  }
}

Future<ui.Image?> _resolve(ImageProvider provider) {
  final completer = Completer<ui.Image?>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener((info, _) {
    if (!completer.isCompleted) completer.complete(info.image.clone());
    stream.removeListener(listener);
  }, onError: (e, __) {
    if (!completer.isCompleted) completer.complete(null);
    stream.removeListener(listener);
  });
  stream.addListener(listener);
  return completer.future;
}
