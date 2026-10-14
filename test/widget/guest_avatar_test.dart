import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/widgets/guest_avatar.dart';
import 'package:greengo_chat/features/experience_bookings/presentation/widgets/booking_widgets.dart';
import 'package:greengo_chat/features/user_experiences/presentation/widgets/experience_widgets.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

/// Shared-link guests (no GreenGo account) show as "Name Surname" with the
/// guest avatar and a "Guest" label, never as a tappable profile.
void main() {
  final guestKey = 'guest_${'0f' * 20}';

  testWidgets('GuestNameAvatar: name + Guest label, falls back to "Guest"',
      (tester) async {
    await tester.pumpWidget(_app(const GuestNameAvatar(name: 'Ana Souza')));
    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);

    await tester.pumpWidget(_app(const GuestNameAvatar(name: '  ')));
    expect(find.text('Guest'), findsNWidgets(2));
  });

  testWidgets('localized label', (tester) async {
    await tester.pumpWidget(_app(const GuestNameAvatar(name: 'Ana'),
        locale: const Locale('it')));
    expect(find.text('Ospite'), findsOneWidget);
  });

  testWidgets('UserNameAvatar with a guest key: guest row, no tap target',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(UserNameAvatar(
        uid: guestKey, fallbackName: 'Ana Souza', onTap: () => taps++)));
    expect(find.byType(GuestNameAvatar), findsOneWidget);
    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
    await tester.tap(find.text('Ana Souza'));
    expect(taps, 0);
  });

  testWidgets('BookingPartyRow for a guest booking', (tester) async {
    await tester.pumpWidget(_app(BookingPartyRow(
        uid: guestKey, guestName: 'Ana Souza', showGuestRating: true)));
    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget);
  });
}
