import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/security/viewer_watermark.dart';
import 'package:greengo_chat/core/widgets/zoom_photo_viewer.dart';

void main() {
  testWidgets('full-screen viewer: zoomable, GreenGo mark, page counter',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ZoomPhotoViewer(
        urls: ['https://example.invalid/a.jpg', 'https://example.invalid/b.jpg'],
        initialIndex: 1,
      ),
    ));
    await tester.pump();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byKey(const ValueKey('viewerWatermark')), findsOneWidget);
    expect(find.text(kWatermarkBrand), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
  });
}
