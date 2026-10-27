// Owner requests 2026-10-21:
//  1. "when creating a cover image or editing it, I have to let the user know
//     the dimensions of the cover image" - a localized recommended-size hint
//     next to every cover / main-photo picker, and a gentle non-blocking
//     warning after picking a picture that is small or a very different shape.
//  2. Users POSITION the cover in the frame (drag / zoom) with a live preview
//     of every real place it is shown; the focal point is stored next to the
//     URL and applied by every display.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/di/injection_container.dart' as di;
import 'package:greengo_chat/core/media/cover_focus.dart';
import 'package:greengo_chat/core/widgets/cover_frames.dart';
import 'package:greengo_chat/core/widgets/cover_image_size_hint.dart';
import 'package:greengo_chat/core/widgets/cover_positioner.dart';
import 'package:greengo_chat/core/widgets/focal_cover_image.dart';
import 'package:greengo_chat/features/business/presentation/screens/storefront_editor_screen.dart';
import 'package:greengo_chat/features/communities/domain/entities/community.dart';
import 'package:greengo_chat/features/communities/domain/repositories/communities_repository.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_bloc.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_event.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_state.dart';
import 'package:greengo_chat/features/communities/presentation/screens/create_community_screen.dart';
import 'package:greengo_chat/features/communities/presentation/widgets/community_card.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';
import 'package:greengo_chat/features/events/presentation/screens/events_screen.dart';
import 'package:greengo_chat/features/media_library/presentation/image_source_picker.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_event.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_state.dart';
import 'package:greengo_chat/features/user_experiences/data/models/user_experience_model.dart';
import 'package:greengo_chat/features/user_experiences/domain/repositories/user_experiences_repository.dart';
import 'package:greengo_chat/features/user_experiences/presentation/screens/experience_editor_screen.dart';
import 'package:greengo_chat/features/user_experiences/presentation/widgets/experience_widgets.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../support/profile_fixtures.dart';

class _MockCommunitiesBloc extends Mock implements CommunitiesBloc {}

class _MockProfileBloc extends Mock implements ProfileBloc {}

class _MockCommunitiesRepo extends Mock implements CommunitiesRepository {}

class _MockExperiencesRepo extends Mock implements UserExperiencesRepository {}

/// 1 x 1 transparent PNG.
final Uint8List _png1x1 = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// A real w x h PNG (encoded by the engine; call inside runAsync).
Future<Uint8List> _png(int w, int h) async {
  final rec = ui.PictureRecorder();
  ui.Canvas(rec).drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..color = const Color(0xFF3366CC));
  final img = await rec.endRecording().toImage(w, h);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return data!.buffer.asUint8List();
}

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

void _bigView(WidgetTester t) {
  t.view.physicalSize = const Size(1200, 6000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

AppLocalizations _l(WidgetTester t, Type screen) =>
    AppLocalizations.of(t.element(find.byType(screen)))!;

const _bannerHint =
    'Recommended: 1920 × 1080 px (16:9), JPG or PNG, max 50 MB. '
    'Keep the main subject centred: edges may be cropped on smaller cards.';

void main() {
  group('hint + warning widgets', () {
    testWidgets('banner hint states size, shape, formats and the 50 MB limit',
        (t) async {
      await t.pumpWidget(_app(const Scaffold(body: CoverImageSizeHint())));
      expect(find.text(_bannerHint), findsOneWidget);
      await t.pumpWidget(_app(const Scaffold(
          body: CoverImageSizeHint(spec: CoverImageSpec.square))));
      expect(
          find.textContaining('1080 × 1080 px (square, 1:1)'), findsOneWidget);
    });

    testWidgets('every locale has the hint text', (t) async {
      for (final loc in AppLocalizations.supportedLocales) {
        final l = await AppLocalizations.delegate.load(loc);
        final s = CoverImageSizeHint.textFor(l, CoverImageSpec.banner);
        expect(s, contains('1920'), reason: '$loc');
        expect(s, contains('16:9'), reason: '$loc');
        expect(s, contains('50'), reason: '$loc');
      }
    });

    testWidgets('small-image warning: 600 x 400 warns, 1920 x 1080 does not',
        (t) async {
      await t.pumpWidget(_app(const Scaffold(
          body: CoverImagePickWarning(knownSize: Size(600, 400)))));
      expect(find.byKey(const Key('cover_image_pick_warning')), findsOneWidget);
      expect(find.textContaining('600 × 400 px'), findsOneWidget);
      await t.pumpWidget(_app(const Scaffold(
          body: CoverImagePickWarning(knownSize: Size(1920, 1080)))));
      expect(find.byKey(const Key('cover_image_pick_warning')), findsNothing);
    });

    testWidgets(
        'picked FILES are measured: 600 x 400 warns (with crop preview), '
        '1920 x 1080 does not', (t) async {
      Future<void> pumpFile(int w, int h) async {
        final bytes = (await t.runAsync(() => _png(w, h)))!;
        await t.pumpWidget(_app(Scaffold(
            body: SingleChildScrollView(
          child: CoverImagePickWarning(
              key: ValueKey('$w'), file: XFile.fromData(bytes, name: 'p.png')),
        ))));
        for (var i = 0; i < 5; i++) {
          await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 50)));
          await t.pump();
        }
      }

      await pumpFile(600, 400);
      expect(find.byKey(const Key('cover_image_pick_warning')), findsOneWidget);
      expect(find.byKey(const Key('cover_image_crop_preview')), findsOneWidget);
      await pumpFile(1920, 1080);
      expect(find.byKey(const Key('cover_image_pick_warning')), findsNothing);
    });

    testWidgets('portrait picture on a 16:9 cover gets the shape warning',
        (t) async {
      await t.pumpWidget(_app(const Scaffold(
          body: CoverImagePickWarning(knownSize: Size(3024, 4032)))));
      expect(find.textContaining('very different from 16:9'), findsOneWidget);
    });

    testWidgets('the source sheet shows the hint when opened from a cover',
        (t) async {
      await t.pumpWidget(_app(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                showImageSourceSheet(context, hint: const CoverImageSizeHint()),
            child: const Text('open'),
          ),
        ),
      )));
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(find.text(_bannerHint), findsOneWidget);
      expect(find.byKey(const Key('image_source_library')), findsOneWidget);
    });
  });

  group('positioning step', () {
    Future<List<CoverFocus?>> openPositioner(WidgetTester t,
        {Size imageSize = const Size(1000, 2000)}) async {
      _bigView(t);
      final out = <CoverFocus?>[];
      await t.pumpWidget(_app(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final l = AppLocalizations.of(context)!;
              out.add(await Navigator.of(context).push<CoverFocus>(
                MaterialPageRoute(
                  builder: (_) => CoverPositionerScreen(
                    image: MemoryImage(_png1x1),
                    imageSize: imageSize,
                    frames: CoverFrames.event(l),
                    title: 'Sunset walk',
                  ),
                ),
              ));
            },
            child: const Text('open'),
          ),
        ),
      )));
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      return out;
    }

    testWidgets('drag moves the focal point; Done returns it', (t) async {
      final out = await openPositioner(t);
      // Tall picture in a 16:9 frame: dragging up shows its lower part.
      await t.drag(
          find.byKey(const Key('cover_position_frame')), const Offset(0, -80));
      await t.pumpAndSettle();
      final img = t.widget<FocalCoverImage>(find.descendant(
          of: find.byKey(const Key('cover_position_frame')),
          matching: find.byType(FocalCoverImage)));
      expect(img.focus.y, greaterThan(0));
      expect(img.focus.x, 0);
      await t.tap(find.byKey(const Key('cover_position_done')));
      await t.pumpAndSettle();
      expect(out.single!.y, greaterThan(0));
    });

    testWidgets('the zoom slider zooms; reset centres', (t) async {
      final out = await openPositioner(t);
      await t.drag(
          find.byKey(const Key('cover_position_zoom')), const Offset(200, 0));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('cover_position_done')));
      await t.pumpAndSettle();
      expect(out.single!.zoom, greaterThan(1));
    });

    testWidgets(
        'live preview shows every real frame with the title, all '
        'positioned like the editor', (t) async {
      await openPositioner(t);
      await t.drag(
          find.byKey(const Key('cover_position_frame')), const Offset(0, -80));
      await t.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        final frame = find.byKey(Key('cover_preview_frame_$i'));
        expect(frame, findsOneWidget);
        final img = t.widget<FocalCoverImage>(
            find.descendant(of: frame, matching: find.byType(FocalCoverImage)));
        expect(img.focus.y, greaterThan(0));
      }
      expect(find.text('Sunset walk'), findsNWidgets(4));
      // Real aspect ratios: Explore card 320x230, events card x150, header x250.
      final explore = t.getSize(find.descendant(
          of: find.byKey(const Key('cover_preview_frame_0')),
          matching: find.byType(FocalCoverImage)));
      expect(explore.width / explore.height, closeTo(320 / 230, 0.01));
      final header = t.getSize(find.descendant(
          of: find.byKey(const Key('cover_preview_frame_3')),
          matching: find.byType(FocalCoverImage)));
      expect(header.width / header.height, closeTo(390 / 250, 0.01));
    });
  });

  group('displays apply the stored position', () {
    testWidgets('community list card + experience image use the alignment',
        (t) async {
      await mockNetworkImagesFor(() async {
        const f = CoverFocus(x: -0.8, y: 0.4, zoom: 1.5);
        await t.pumpWidget(_app(Scaffold(
          body: Column(children: [
            CommunityCard(
              community: Community(
                id: 'c',
                name: 'Porto Coffee',
                description: 'd',
                type: CommunityType.general,
                imageUrl: 'https://example.test/c.jpg',
                createdByUserId: 'u',
                createdByName: 'U',
                createdAt: DateTime(2026, 10, 1),
                coverFocus: f,
              ),
            ),
            const SizedBox(
                width: 200,
                height: 120,
                child: ExperienceImage(
                    url: 'https://example.test/x.jpg', height: 120, focus: f)),
          ]),
        )));
        final images = t
            .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .toList();
        expect(images, hasLength(2));
        for (final i in images) {
          expect(i.alignment, const Alignment(-0.8, 0.4));
        }
        // Zoom 1.5 about the focal point.
        final scales = t
            .widgetList<Transform>(find.byType(Transform))
            .where((w) => (w.transform.getMaxScaleOnAxis() - 1.5).abs() < 1e-6);
        expect(scales.length, greaterThanOrEqualTo(2));
      });
    });
  });

  group('community create + edit', () {
    late _MockCommunitiesBloc bloc;
    late _MockProfileBloc profile;
    final existing = Community(
      id: 'c_edit',
      name: 'Porto Coffee Club',
      description: 'Coffee lovers meeting in Porto',
      type: CommunityType.general,
      imageUrl: 'https://example.test/old-cover.jpg',
      createdByUserId: 'creator',
      createdByName: 'Creator',
      createdAt: DateTime(2026, 10, 1),
      coverFocus: const CoverFocus(x: 0.5, y: -0.25),
    );

    setUpAll(() => registerFallbackValue(UpdateCommunity(community: existing)));

    setUp(() {
      bloc = _MockCommunitiesBloc();
      profile = _MockProfileBloc();
      when(() => profile.state).thenReturn(const ProfileInitial());
      when(() => profile.stream).thenAnswer((_) => const Stream.empty());
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => bloc.state).thenReturn(const CommunitiesInitial());
      when(() => bloc.add(any())).thenReturn(null);
      when(() => bloc.close()).thenAnswer((_) async {});
    });

    Widget host(Widget child) => MultiBlocProvider(
          providers: [
            BlocProvider<CommunitiesBloc>.value(value: bloc),
            BlocProvider<ProfileBloc>.value(value: profile),
          ],
          child: _app(child),
        );

    testWidgets('create: the empty cover picker + the form show the size hint',
        (t) async {
      _bigView(t);
      await mockNetworkImagesFor(() async {
        await t
            .pumpWidget(host(const CreateCommunityScreen(currentUserId: 'u')));
        await t.pump();
        expect(find.byKey(const Key('cover_image_size_hint')), findsOneWidget);
        expect(find.text(_bannerHint), findsOneWidget);
        expect(find.byKey(const Key('communityCoverAdjust')), findsNothing);
      });
    });

    testWidgets(
        'edit: hint + stored position shown; Adjust -> zoom -> Save '
        'carries the focal fields', (t) async {
      _bigView(t);
      await mockNetworkImagesFor(() async {
        await t.pumpWidget(host(CreateCommunityScreen(
            existing: existing, currentUserId: 'creator')));
        await t.pump();
        expect(find.text(_bannerHint), findsOneWidget);
        final shown = t.widget<FocalCoverImage>(
            find.byKey(const Key('communityCoverImage')));
        expect(shown.focus, const CoverFocus(x: 0.5, y: -0.25));

        await t.tap(find.byKey(const Key('communityCoverAdjust')));
        await t.pumpAndSettle();
        // Live preview: Explore card, page header, list row.
        for (var i = 0; i < 3; i++) {
          expect(find.byKey(Key('cover_preview_frame_$i')), findsOneWidget);
        }
        await t.drag(
            find.byKey(const Key('cover_position_zoom')), const Offset(200, 0));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('cover_position_done')));
        await t.pumpAndSettle();

        await t.tap(find.byKey(const Key('editCommunitySaveAppBarAction')));
        await t.pump();
        final update = verify(() => bloc.add(captureAny()))
            .captured
            .whereType<UpdateCommunity>()
            .single;
        expect(update.community.coverFocus.x, 0.5);
        expect(update.community.coverFocus.y, -0.25);
        expect(update.community.coverFocus.zoom, greaterThan(1));
      });
    });

    testWidgets('removing the cover resets the position', (t) async {
      _bigView(t);
      await mockNetworkImagesFor(() async {
        await t.pumpWidget(host(CreateCommunityScreen(
            existing: existing, currentUserId: 'creator')));
        await t.pump();
        await t.tap(find.byKey(const Key('communityCoverRemove')));
        await t.pump();
        await t.tap(find.byKey(const Key('editCommunitySaveAppBarAction')));
        await t.pump();
        final update = verify(() => bloc.add(captureAny()))
            .captured
            .whereType<UpdateCommunity>()
            .single;
        expect(update.community.imageUrl, isNull);
        expect(update.community.coverFocus, CoverFocus.center);
      });
    });
  });

  group('storefront editor', () {
    testWidgets('featured + logo hints; stored position shown and saved',
        (t) async {
      _bigView(t);
      final business = buildBusinessProfile().copyWith(
        businessLogoUrl: 'https://example.com/logo.jpg',
        coverFocus: const CoverFocus(x: -0.4, y: 0.6, zoom: 1.2),
      );
      registerFallbackValue(ProfileUpdateRequested(profile: business));
      final bloc = _MockProfileBloc();
      when(() => bloc.state).thenReturn(const ProfileInitial());
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
      await mockNetworkImagesFor(() async {
        await t.pumpWidget(_app(BlocProvider<ProfileBloc>.value(
            value: bloc, child: StorefrontEditorScreen(profile: business))));
        await t.pump();
        expect(find.text(_bannerHint), findsOneWidget);
        expect(find.textContaining('1080 × 1080 px (square, 1:1)'),
            findsOneWidget);
        expect(find.byKey(const Key('storefront_featured_adjust')),
            findsOneWidget);
        final shown = t.widget<FocalCoverImage>(
            find.byKey(const Key('storefront_featured_image')));
        expect(shown.focus, business.coverFocus);
        final l = _l(t, StorefrontEditorScreen);
        final save = find.widgetWithText(ElevatedButton, l.save);
        await t.ensureVisible(save);
        await t.tap(save);
        await t.pump();
        final ev = verify(() => bloc.add(captureAny())).captured.single
            as ProfileUpdateRequested;
        expect(ev.profile.coverFocus, business.coverFocus);
      });
    });
  });

  group('event + experience main photo', () {
    setUp(() async {
      await di.sl.reset();
      final communities = _MockCommunitiesRepo();
      di.sl.registerSingleton<CommunitiesRepository>(communities);
      di.sl
          .registerSingleton<UserExperiencesRepository>(_MockExperiencesRepo());
    });
    tearDown(() => di.sl.reset());

    testWidgets('event editor shows the hint and Adjust for the main photo',
        (t) async {
      _bigView(t);
      final event = Event(
        id: 'e1',
        organizerId: 'u',
        organizerName: 'U',
        title: 'Sunset walk',
        description: 'A walk along the river at sunset',
        category: EventCategory.values.first,
        startDate: DateTime.now().add(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 3, hours: 2)),
        locationName: 'Porto',
        maxAttendees: 10,
        status: EventStatus.values.first,
        createdAt: DateTime(2026, 10, 1),
        imageUrl: 'https://example.test/e.jpg',
        coverFocus: const CoverFocus(y: 0.5),
      );
      await mockNetworkImagesFor(() async {
        await t.pumpWidget(_app(CreateEventScreen(
          currentUserId: 'u',
          existing: event,
          lockCommunity: true,
          onEventCreated: (_) {},
          onEventDeleted: () {},
        )));
        await t.pump();
        // Save changes: a save icon in the AppBar, right of the bin.
        final bar = find.byType(AppBar);
        final save = find.descendant(of: bar, matching: find.byKey(const ValueKey('event-save-top')));
        expect(save, findsOneWidget);
        expect(find.byTooltip('Save changes'), findsOneWidget);
        expect(t.getTopLeft(save).dx,
            greaterThan(t.getTopLeft(find.descendant(of: bar, matching: find.byIcon(Icons.delete_outline))).dx));
        // Edit mode opens on the overview: open the first step (photos).
        await t.tap(find.byKey(const ValueKey('wizard-edit-0')));
        await t.pump(const Duration(milliseconds: 500));
        // Still there on a step.
        expect(find.byKey(const ValueKey('event-save-top')), findsOneWidget);
        expect(find.text(_bannerHint), findsOneWidget);
        expect(
            find.byKey(const Key('event_main_photo_adjust')), findsOneWidget);
      });
    });

    testWidgets(
        'experience editor shows the hint and Adjust for the main photo',
        (t) async {
      _bigView(t);
      final x = UserExperienceModel.fromMap('x1', const {
        'hostId': 'u',
        'title': 'Port wine tasting',
        'description': 'Taste three port wines with a local guide downtown.',
        'category': 'foodDrink',
        'mainPhotoUrl': 'https://example.test/x.jpg',
        'included': ['Wine'],
        'locationName': 'Porto',
        'durationMinutes': 90,
        'languages': ['en'],
        'maxGroupSize': 6,
        'isFree': true,
        'status': 'draft',
        'coverFocalX': 0.2,
      });
      await mockNetworkImagesFor(() async {
        await t.pumpWidget(
            _app(ExperienceEditorScreen(currentUserId: 'u', existing: x)));
        await t.pump();
        await t.pump();
        expect(find.descendant(of: find.byType(AppBar), matching: find.byKey(const ValueKey('experience-save-top'))),
            findsOneWidget);
        // Edit mode opens on the overview: open the first step (photos).
        await t.tap(find.byKey(const ValueKey('wizard-edit-0')));
        await t.pump(const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('experience-save-top')), findsOneWidget);
        expect(find.text(_bannerHint), findsOneWidget);
        expect(find.byKey(const Key('experience_main_photo_adjust')),
            findsOneWidget);
      });
    });
  });
}
