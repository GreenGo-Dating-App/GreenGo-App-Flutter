import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/domain/entities/community_message.dart';
import 'package:greengo_chat/features/communities/presentation/widgets/community_message_bubble.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Terms 17.3: community owners and moderators can remove posts. The bubble
/// offers "Remove post" on long-press only when the screen passes onRemove
/// (owner/admin), and keeps the direct report for everyone else.
void main() {
  final msg = CommunityMessage(
    id: 'm1',
    communityId: 'c1',
    senderId: 'other',
    senderName: 'Other',
    content: 'hello community',
    sentAt: DateTime(2026, 10, 16, 12),
  );

  Widget app(Widget child) => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('member: long-press reports directly, no remove action',
      (tester) async {
    var reported = 0;
    await tester.pumpWidget(app(CommunityMessageBubble(
      message: msg,
      isCurrentUser: false,
      onReport: () => reported++,
    )));
    await tester.longPress(find.text('hello community'));
    await tester.pumpAndSettle();
    expect(reported, 1);
    expect(find.byKey(const ValueKey('community-post-remove')), findsNothing);
  });

  testWidgets('moderator: long-press offers Remove post and Report',
      (tester) async {
    var removed = 0;
    var reported = 0;
    await tester.pumpWidget(app(CommunityMessageBubble(
      message: msg,
      isCurrentUser: false,
      onReport: () => reported++,
      onRemove: () => removed++,
    )));
    await tester.longPress(find.text('hello community'));
    await tester.pumpAndSettle();
    expect(find.text('Remove post'), findsOneWidget);
    expect(find.byKey(const ValueKey('community-post-report')), findsOneWidget);
    await tester.tap(find.text('Remove post'));
    await tester.pumpAndSettle();
    expect(removed, 1);
    expect(reported, 0);
  });

  testWidgets('moderator on own post: Remove post only', (tester) async {
    var removed = 0;
    await tester.pumpWidget(app(CommunityMessageBubble(
      message: msg,
      isCurrentUser: true,
      onRemove: () => removed++,
    )));
    await tester.longPress(find.text('hello community'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('community-post-report')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('community-post-remove')));
    await tester.pumpAndSettle();
    expect(removed, 1);
  });
}
