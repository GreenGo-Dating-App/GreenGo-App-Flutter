import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/media_library/data/media_library_repository.dart';
import 'package:greengo_chat/features/media_library/domain/media_library_item.dart';
import 'package:greengo_chat/features/media_library/presentation/image_source_picker.dart';
import 'package:greengo_chat/features/media_library/presentation/my_pictures_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:network_image_mock/network_image_mock.dart';

/// "My pictures": paged library screen, the "Choose from My pictures" picker
/// used by every image picker, and "Ask for a review" on a held picture.

MediaLibraryItem _approved(int i) => MediaLibraryItem(
      id: 'profiles~u~photos~$i.jpg',
      path: 'profiles/u/photos/$i.jpg',
      status: 'approved',
      url: 'https://firebasestorage.googleapis.com/v0/b/b/o/p$i.jpg?alt=media&token=t$i',
      hasFace: true,
    );

const _held = MediaLibraryItem(
  id: 'profiles~u~photos~held.jpg',
  path: 'profiles/u/photos/held.jpg',
  status: 'held',
  reasons: ['no_face'],
  reviewable: true,
);

const _rejected = MediaLibraryItem(
  id: 'profiles~u~photos~gone.jpg',
  path: 'profiles/u/photos/gone.jpg',
  status: 'rejected',
);

class _FakeRepo implements MediaLibraryRepository {
  _FakeRepo(this.all);

  final List<MediaLibraryItem> all;
  final List<({bool approvedOnly, Object? cursor, int limit})> fetches = [];
  final List<({String id, String? note})> reviews = [];
  final List<String> removed = [];
  ReviewRequestError? failWith;

  @override
  Future<MediaLibraryPage> fetchPage({
    required bool approvedOnly,
    Object? cursor,
    int limit = 30,
  }) async {
    fetches.add((approvedOnly: approvedOnly, cursor: cursor, limit: limit));
    final source = approvedOnly ? all.where((i) => i.isApproved).toList() : all;
    final start = (cursor as int?) ?? 0;
    final end = (start + limit).clamp(0, source.length);
    return MediaLibraryPage(
      source.sublist(start, end),
      end,
      hasMore: end < source.length,
    );
  }

  @override
  Future<void> remove(String itemId) async => removed.add(itemId);

  @override
  Future<void> requestReview(String itemId, {String? note}) async {
    if (failWith != null) throw ReviewRequestException(failWith!);
    reviews.add((id: itemId, note: note));
  }
}

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

void main() {
  testWidgets('My pictures: pages newest-first items as the grid scrolls',
      (tester) async {
    await mockNetworkImagesFor(() async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = _FakeRepo([for (var i = 0; i < 45; i++) _approved(i)]);

      await tester.pumpWidget(
          _host(MyPicturesScreen(repository: repo, pageSize: 20)));
      await tester.pump();
      await tester.pump();

      expect(repo.fetches.first.approvedOnly, isFalse);
      expect(repo.fetches.first.cursor, isNull);
      expect(find.byKey(Key('my_pictures_tile_${_approved(0).id}')),
          findsOneWidget);

      // Scroll to the end until every page is loaded.
      for (var n = 0; n < 10 && repo.fetches.length < 3; n++) {
        await tester.drag(
            find.byKey(const Key('my_pictures_grid')), const Offset(0, -3000));
        await tester.pump();
        await tester.pump();
      }
      expect(repo.fetches.length, 3);
      expect(repo.fetches[1].cursor, 20);
      expect(repo.fetches[2].cursor, 40);
      await tester.drag(
          find.byKey(const Key('my_pictures_grid')), const Offset(0, -6000));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('my_pictures_tile_${_approved(44).id}')),
          findsOneWidget);
      // Last page reached: no further fetch.
      expect(repo.fetches.length, 3);
    });
  });

  testWidgets('empty library shows the empty state', (tester) async {
    await tester.pumpWidget(_host(MyPicturesScreen(repository: _FakeRepo([]))));
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.myPicturesEmpty), findsOneWidget);
  });

  testWidgets(
      'picker: "Choose from My pictures" returns the approved URL (no upload)',
      (tester) async {
    await mockNetworkImagesFor(() async {
      final repo = _FakeRepo([_held, _approved(1), _approved(2)]);
      PickedImage? result;
      await tester.pumpWidget(_host(Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await pickImageWithLibrary(context, repository: repo);
              },
              child: const Text('pick'),
            ),
          ),
        ),
      )));

      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      // Next to Gallery (and Camera where the surface allows it).
      expect(find.text(l10n.myPicturesGallery), findsOneWidget);
      await tester.tap(find.text(l10n.myPicturesChoose));
      await tester.pumpAndSettle();

      // Picker lists approved pictures only.
      expect(repo.fetches.single.approvedOnly, isTrue);
      expect(find.byKey(Key('my_pictures_tile_${_held.id}')), findsNothing);
      await tester.tap(find.byKey(Key('my_pictures_tile_${_approved(2).id}')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.isLibrary, isTrue);
      expect(result!.file, isNull);
      expect(result!.url, _approved(2).url);
    });
  });

  testWidgets('"Ask for a review" on a held picture sends the request',
      (tester) async {
    await mockNetworkImagesFor(() async {
      final repo = _FakeRepo([_held, _approved(1), _rejected]);
      await tester.pumpWidget(_host(MyPicturesScreen(repository: repo)));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      // Held: badge + button. Approved and final-rejected: no button.
      expect(find.text(l10n.myPicturesNotVisibleHeld), findsOneWidget);
      expect(find.byKey(Key('my_pictures_ask_review_${_held.id}')),
          findsOneWidget);
      expect(find.byKey(Key('my_pictures_ask_review_${_approved(1).id}')),
          findsNothing);
      expect(find.byKey(Key('my_pictures_ask_review_${_rejected.id}')),
          findsNothing);
      expect(find.text(l10n.myPicturesNotVisibleRejected), findsOneWidget);

      await tester.tap(find.byKey(Key('my_pictures_ask_review_${_held.id}')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.myPicturesReviewSla), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('my_pictures_review_note')), 'It is me.');
      await tester.tap(find.byKey(const Key('my_pictures_review_send')));
      await tester.pumpAndSettle();

      expect(repo.reviews.single.id, _held.id);
      expect(repo.reviews.single.note, 'It is me.');
      expect(find.text(l10n.myPicturesReviewSent), findsOneWidget);
      // Now pending: badge changes, no second request possible.
      expect(find.text(l10n.myPicturesNotVisibleReview), findsOneWidget);
      expect(find.byKey(Key('my_pictures_ask_review_${_held.id}')),
          findsNothing);
    });
  });

  testWidgets('rate-limited review request shows the limit message',
      (tester) async {
    await mockNetworkImagesFor(() async {
      final repo = _FakeRepo([_held])..failWith = ReviewRequestError.rateLimited;
      await tester.pumpWidget(_host(MyPicturesScreen(repository: repo)));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.byKey(Key('my_pictures_ask_review_${_held.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('my_pictures_review_send')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.myPicturesReviewRateLimited), findsOneWidget);
      expect(find.byKey(Key('my_pictures_ask_review_${_held.id}')),
          findsOneWidget);
    });
  });

  testWidgets('remove asks first, then drops only the library entry',
      (tester) async {
    await mockNetworkImagesFor(() async {
      final repo = _FakeRepo([_approved(1)]);
      await tester.pumpWidget(_host(MyPicturesScreen(repository: repo)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('my_pictures_remove_${_approved(1).id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('my_pictures_remove_confirm')));
      await tester.pumpAndSettle();
      expect(repo.removed, [_approved(1).id]);
      expect(find.byKey(Key('my_pictures_tile_${_approved(1).id}')),
          findsNothing);
    });
  });
}
