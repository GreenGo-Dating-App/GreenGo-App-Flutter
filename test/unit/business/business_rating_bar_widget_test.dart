import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:greengo_chat/features/business/data/services/rating_service.dart';
import 'package:greengo_chat/features/business/presentation/widgets/business_rating.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

/// Master Test Plan — Business/Storefront. BusinessRatingBar regression:
/// the "Rate this business" control is HIDDEN (SizedBox.shrink) when
///   (a) the viewer already rated (myRating > 0), or
///   (b) the viewer IS the business (self, raterId == businessId).
/// RatingService is resolved via di.sl — a mock is registered in GetIt.
class _MockRatingService extends Mock implements RatingService {}

Widget _host(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  late _MockRatingService service;

  setUp(() {
    service = _MockRatingService();
    GetIt.I.registerSingleton<RatingService>(service);
  });

  tearDown(() => GetIt.I.reset());

  Finder rateLabel() => find.text('Rate this business');

  testWidgets('shows the rating control when viewer has not rated (mine == 0)',
      (tester) async {
    when(() => service.myRating(
          businessId: any(named: 'businessId'),
          raterId: any(named: 'raterId'),
        )).thenAnswer((_) => Stream<int?>.value(0));

    await tester.pumpWidget(_host(
      const BusinessRatingBar(businessId: 'biz', raterId: 'ava'),
    ));
    await tester.pump();

    expect(rateLabel(), findsOneWidget);
    // Five interactive star buttons rendered.
    expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(5));
  });

  testWidgets('HIDDEN once the viewer has already rated (mine > 0)',
      (tester) async {
    when(() => service.myRating(
          businessId: any(named: 'businessId'),
          raterId: any(named: 'raterId'),
        )).thenAnswer((_) => Stream<int?>.value(4));

    await tester.pumpWidget(_host(
      const BusinessRatingBar(businessId: 'biz', raterId: 'ava'),
    ));
    await tester.pump();

    expect(rateLabel(), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.byType(SizedBox), findsWidgets); // shrink placeholder
  });

  testWidgets('HIDDEN when the viewer IS the business (self)', (tester) async {
    // Self path returns SizedBox.shrink before touching the stream.
    await tester.pumpWidget(_host(
      const BusinessRatingBar(businessId: 'biz', raterId: 'biz'),
    ));
    await tester.pump();

    expect(rateLabel(), findsNothing);
    verifyNever(() => service.myRating(
          businessId: any(named: 'businessId'),
          raterId: any(named: 'raterId'),
        ));
  });

  testWidgets('null rating (never rated) also shows the control',
      (tester) async {
    when(() => service.myRating(
          businessId: any(named: 'businessId'),
          raterId: any(named: 'raterId'),
        )).thenAnswer((_) => Stream<int?>.value(null));

    await tester.pumpWidget(_host(
      const BusinessRatingBar(businessId: 'biz', raterId: 'ava'),
    ));
    await tester.pump();

    expect(rateLabel(), findsOneWidget);
  });
}
