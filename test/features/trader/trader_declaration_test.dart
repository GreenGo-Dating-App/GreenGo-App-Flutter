// Terms 12.4 / DSA art. 30: trader declaration form, wire format and the
// seller information guests see.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/finance_documents/data/billing_profile_repository.dart';
import 'package:greengo_chat/features/finance_documents/domain/billing_profile.dart';
import 'package:greengo_chat/features/trader/data/trader_repository.dart';
import 'package:greengo_chat/features/trader/domain/trader_declaration.dart';
import 'package:greengo_chat/features/trader/presentation/screens/trader_declaration_screen.dart';
import 'package:greengo_chat/features/trader/presentation/widgets/seller_trader_info.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

class _Repo extends TraderRepository {
  _Repo(this.status, {this.reject});
  final TraderStatus status;
  final BillingFieldError? reject;
  final saved = <TraderDraft>[];

  @override
  Future<TraderStatus> get() async => status;

  @override
  Future<TraderDeclaration?> save(TraderDraft draft) async {
    saved.add(draft);
    if (reject != null) throw BillingValidationException(reject!);
    return TraderDeclaration(isTrader: draft.isTrader);
  }
}

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  group('wire format', () {
    test('non-trader sends only the answer', () {
      expect(const TraderDraft(isTrader: false, name: 'x').toMap(), {'isTrader': false});
    });

    test('trader sends trimmed fields, country, and omits empty optional ones', () {
      final m = const TraderDraft(
        isTrader: true,
        name: ' Bar do Zé ',
        address: BillingAddress(street: 'Via Roma', number: '1', city: 'Roma', postalCode: '00100', country: 'IT'),
        phone: '+39 06 123456',
        email: 'ze@example.com',
        selfCertified: true,
      ).toMap();
      expect(m['isTrader'], isTrue);
      expect(m['name'], 'Bar do Zé');
      expect((m['address'] as Map)['country'], 'IT');
      expect(m.containsKey('idNumber'), isFalse);
      expect(m.containsKey('tradeRegister'), isFalse);
      expect(m['selfCertified'], isTrue);
    });

    test('public info parses trader and non-trader docs; anything else is null', () {
      expect(TraderPublicInfo.fromMap({'isTrader': false})!.isTrader, isFalse);
      final t = TraderPublicInfo.fromMap({'isTrader': true, 'name': 'Ze', 'address': 'Via Roma 1', 'email': 'a@b.c'})!;
      expect(t.name, 'Ze');
      expect(TraderPublicInfo.fromMap(null), isNull);
      expect(TraderPublicInfo.fromMap({'name': 'x'}), isNull);
    });
  });

  group('seller information for guests', () {
    testWidgets('trader: name, address, contact and register', (tester) async {
      await tester.pumpWidget(_app(const SellerTraderInfo(
        sellerId: 'h1',
        info: TraderPublicInfo(
          isTrader: true, name: 'Bar do Zé Srl', address: 'Via Roma 1, 00100 Roma, IT', phone: '+39 06 1',
          email: 'ze@example.com', tradeRegister: 'Registro Imprese Roma', tradeRegisterNumber: 'RM-123'),
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('seller-trader-info')), findsOneWidget);
      expect(find.text('Bar do Zé Srl'), findsOneWidget);
      expect(find.text('Via Roma 1, 00100 Roma, IT'), findsOneWidget);
      expect(find.text('Registro Imprese Roma: RM-123'), findsOneWidget);
    });

    testWidgets('non-trader notice', (tester) async {
      await tester.pumpWidget(_app(const SellerTraderInfo(sellerId: 'h1', info: TraderPublicInfo(isTrader: false))));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('seller-non-trader')), findsOneWidget);
    });

    testWidgets('not declared / unreadable: nothing', (tester) async {
      await tester.pumpWidget(_app(const SellerTraderInfo(sellerId: 'h1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('seller-trader-info')), findsNothing);
      expect(find.byKey(const ValueKey('seller-non-trader')), findsNothing);
    });
  });

  group('declaration form', () {
    Future<void> pump(WidgetTester tester, _Repo repo) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => TraderDeclarationScreen(repository: repo))),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('trader: prefilled from invoice details, self-certification required, saved', (tester) async {
      final repo = _Repo(const TraderStatus(
        billing: TraderBillingPrefill(
          legalName: 'Bar do Zé Srl',
          address: BillingAddress(street: 'Via Roma', number: '1', city: 'Roma', postalCode: '00100', country: 'IT'),
          email: 'ze@example.com',
          phone: '+39 06 123456',
          hasTaxId: true,
          taxIdMasked: '••••5678',
        ),
      ));
      await pump(tester, repo);
      final saveBtn = find.byKey(const ValueKey('trader-save'));
      expect(tester.widget<ElevatedButton>(saveBtn).onPressed, isNull, reason: 'no answer yet');
      await tester.tap(find.byKey(const ValueKey('trader-yes')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byKey(const ValueKey('trader-name'))).controller!.text, 'Bar do Zé Srl');
      expect(tester.widget<ElevatedButton>(saveBtn).onPressed, isNull, reason: 'not self-certified');
      await tester.enterText(find.byKey(const ValueKey('trader-tradeRegister')), 'Registro Imprese Roma');
      await tester.enterText(find.byKey(const ValueKey('trader-tradeRegisterNumber')), 'RM-123');
      await tester.tap(find.byKey(const ValueKey('trader-self-certify')));
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      final d = repo.saved.single;
      expect(d.isTrader, isTrue);
      expect(d.selfCertified, isTrue);
      expect(d.address.country, 'IT');
      expect(d.toMap()['tradeRegisterNumber'], 'RM-123');
      expect(d.toMap().containsKey('idNumber'), isFalse, reason: 'server reuses the billing tax id');
      expect(find.byType(TraderDeclarationScreen), findsNothing, reason: 'closes after saving');
    });

    testWidgets('non-trader saves without details', (tester) async {
      final repo = _Repo(const TraderStatus());
      await pump(tester, repo);
      await tester.tap(find.byKey(const ValueKey('trader-no')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('trader-name')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('trader-save')));
      await tester.pumpAndSettle();
      expect(repo.saved.single.toMap(), {'isTrader': false});
    });

    testWidgets('a server field error is shown on the field and the form stays', (tester) async {
      final repo = _Repo(
        const TraderStatus(declaration: TraderDeclaration(isTrader: true, name: 'Ze', selfCertified: true)),
        reject: const BillingFieldError('phone', BillingErrorCode.required),
      );
      await pump(tester, repo);
      await tester.tap(find.byKey(const ValueKey('trader-save')));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(TraderDeclarationScreen)))!;
      expect(find.byType(TraderDeclarationScreen), findsOneWidget);
      expect(find.text(l10n.financeBillingErrorRequired), findsOneWidget);
    });
  });
}
