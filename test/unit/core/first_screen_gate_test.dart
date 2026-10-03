import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/first_screen_gate.dart';

/// An image whose load the test controls (complete / fail / never).
class _TestImage extends ImageProvider<_TestImage> {
  _TestImage(this.id);
  final String id;
  final Completer<ImageInfo> load = Completer<ImageInfo>();

  @override
  Future<_TestImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_TestImage>(this);

  @override
  ImageStreamCompleter loadImage(_TestImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(load.future);

  @override
  bool operator ==(Object other) => other is _TestImage && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

int _seq = 0;
_TestImage _image() => _TestImage('img${_seq++}');

Widget _host(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(400, 800)),
        child: child,
      ),
    );

const _loader = Text('loading');
const _content = Text('content');

Widget _gate({
  required bool ready,
  required List<ImageProvider> images,
  Duration cap = const Duration(seconds: 2),
}) =>
    _host(FirstScreenGate(
      ready: ready,
      images: (_, __) => images,
      placeholder: _loader,
      builder: (_) => _content,
      cap: cap,
    ));

void main() {
  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  group('waitAllCapped', () {
    testWidgets('resolves when every future is done', (tester) async {
      final a = Completer<void>(), b = Completer<void>();
      var done = false;
      unawaited(waitAllCapped([a.future, b.future], const Duration(seconds: 5))
          .then((_) => done = true));
      a.complete();
      await tester.pump(const Duration(milliseconds: 10));
      expect(done, isFalse);
      b.complete();
      await tester.pump(const Duration(milliseconds: 10));
      expect(done, isTrue);
    });

    testWidgets('resolves at the cap when a future never completes',
        (tester) async {
      var done = false;
      unawaited(
          waitAllCapped([Completer<void>().future], const Duration(seconds: 2))
              .then((_) => done = true));
      await tester.pump(const Duration(milliseconds: 1900));
      expect(done, isFalse);
      await tester.pump(const Duration(milliseconds: 200));
      expect(done, isTrue);
    });

    testWidgets('an error counts as done and never throws', (tester) async {
      var done = false;
      unawaited(waitAllCapped([Future<void>.error(StateError('boom'))],
              const Duration(seconds: 5))
          .then((_) => done = true));
      await tester.pump(const Duration(milliseconds: 10));
      expect(done, isTrue);
    });

    test('nothing to wait for resolves at once', () async {
      await waitAllCapped(const [], const Duration(seconds: 5));
    });
  });

  group('FirstScreenGate', () {
    testWidgets('holds the loader until data is ready', (tester) async {
      await tester.pumpWidget(_gate(ready: false, images: [_image()]));
      expect(find.text('loading'), findsOneWidget);
      expect(find.text('content'), findsNothing);
    });

    testWidgets('opens at once when the first screen has no images',
        (tester) async {
      await tester.pumpWidget(_gate(ready: true, images: const []));
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('opens when ALL first-screen images are decoded',
        (tester) async {
      final a = _image(), b = _image();
      await tester.pumpWidget(_gate(ready: true, images: [a, b]));
      await tester.pump();
      expect(find.text('loading'), findsOneWidget);

      final img =
          await tester.runAsync(() => createTestImage(width: 2, height: 2));
      a.load.complete(ImageInfo(image: img!.clone()));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();
      expect(find.text('loading'), findsOneWidget, reason: 'b still loading');

      b.load.complete(ImageInfo(image: img.clone()));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();
      expect(find.text('content'), findsOneWidget);
      img.dispose();
    });

    testWidgets('opens at the cap when an image never loads', (tester) async {
      await tester.pumpWidget(_gate(
          ready: true, images: [_image()], cap: const Duration(seconds: 2)));
      await tester.pump(const Duration(milliseconds: 1900));
      expect(find.text('loading'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('a failing image counts as done', (tester) async {
      final bad = _image();
      await tester.pumpWidget(_gate(ready: true, images: [bad]));
      await tester.pump();
      bad.load.completeError(StateError('404'));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();
      expect(find.text('content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens without a loader frame when images are cached',
        (tester) async {
      final a = _image();
      final img =
          await tester.runAsync(() => createTestImage(width: 2, height: 2));
      a.load.complete(ImageInfo(image: img!.clone()));
      // Warm the cache, as the background warm-up / a revisit does.
      await tester.pumpWidget(_host(Builder(builder: (context) {
        precacheImage(a, context);
        return const SizedBox();
      })));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();

      await tester.pumpWidget(_gate(ready: true, images: [a]));
      expect(find.text('content'), findsOneWidget);
      img.dispose();
    });

    testWidgets('stays open once shown (later changes never re-gate)',
        (tester) async {
      await tester.pumpWidget(_gate(ready: true, images: const []));
      expect(find.text('content'), findsOneWidget);
      await tester.pumpWidget(_gate(ready: false, images: [_image()]));
      expect(find.text('content'), findsOneWidget);
    });
  });

  group('first-screen geometry', () {
    test('gridCellWidth matches the grid delegate arithmetic', () {
      // 400 wide, padding 12, 3 columns, spacing 8: (376 - 16) / 3 = 120.
      expect(gridCellWidth(400, 3), 120);
    });

    test('firstScreenGridCount counts whole visible rows', () {
      // Cell 120 x (120 / 0.6 = 200); (800 - 12) / 208 = 3.8 -> 4 rows.
      expect(
          firstScreenGridCount(
              viewport: const Size(400, 800),
              columns: 3,
              childAspectRatio: 0.6),
          12);
    });

    test('firstScreenListCount counts partly visible rows', () {
      expect(firstScreenListCount(viewportHeight: 800, itemExtent: 300), 3);
    });

    test('cachedNetworkImageProvider mirrors CachedNetworkImage', () {
      final p = cachedNetworkImageProvider('https://x.test/a.jpg',
          memCacheWidth: 300);
      expect(p, isA<ResizeImage>());
      expect((p as ResizeImage).width, 300);
      expect(
          p.imageProvider, const CachedNetworkImageProvider('https://x.test/a.jpg'));
      expect(cachedNetworkImageProvider('https://x.test/a.jpg'),
          isA<CachedNetworkImageProvider>());
      // Equal providers -> the same ImageCache entry as the tile.
      expect(
          cachedNetworkImageProvider('https://x.test/a.jpg',
              memCacheWidth: 300),
          cachedNetworkImageProvider('https://x.test/a.jpg',
              memCacheWidth: 300));
    });
  });
}
