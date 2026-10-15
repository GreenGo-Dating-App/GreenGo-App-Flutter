import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/finance_documents/data/billing_profile_repository.dart';
import 'package:greengo_chat/features/finance_documents/domain/billing_profile.dart';
import 'package:greengo_chat/features/finance_documents/presentation/bloc/billing_profile_cubit.dart';
import 'package:greengo_chat/features/finance_documents/presentation/screens/invoice_details_screen.dart';
import 'package:greengo_chat/features/finance_documents/presentation/widgets/billing_status.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Fake callable client: records saves, returns [status] / throws [saveError].
class _FakeRepo implements BillingProfileRepository {
  _FakeRepo(this.status);

  BillingStatus status;
  Object? loadError;
  Object? saveError;
  final saves = <BillingDraft>[];

  @override
  Future<BillingStatus> get() async {
    if (loadError != null) throw loadError!;
    return status;
  }

  @override
  Future<BillingStatus> save(BillingDraft draft) async {
    saves.add(draft);
    if (saveError != null) throw saveError!;
    status = const BillingStatus(complete: true, profile: BillingProfile(type: BillingType.private, country: 'BR', hasTaxId: true, taxIdMasked: '•••••••4725'));
    return status;
  }
}

const _savedMap = {
  'profile': {
    'type': 'company', 'country': 'br', 'legalName': 'Zé Bar Ltda', 'tradeName': 'Bar do Zé', 'contactPerson': 'José',
    'taxIdMasked': '••••••••0182', 'taxIdKind': 'cnpj', 'hasTaxId': true, 'inscricaoMunicipal': '12345678', 'inscricaoEstadual': '',
    'address': {'street': 'Av. Paulista', 'number': '1000', 'complement': '', 'district': 'Bela Vista', 'city': 'São Paulo',
      'region': 'SP', 'postalCode': '01310-100', 'country': 'BR'},
    'email': 'fiscal@ze.example', 'phone': '', 'updatedAt': '2026-10-15T01:00:00.000Z',
  },
  'missing': <String>[],
  'complete': true,
};

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  group('BillingStatus.fromMap', () {
    test('saved company profile, masked tax id, normalized country', () {
      final s = BillingStatus.fromMap(_savedMap);
      expect(s.complete, isTrue);
      final p = s.profile!;
      expect(p.type, BillingType.company);
      expect(p.country, 'BR');
      expect(p.taxIdMasked, '••••••••0182');
      expect(p.hasTaxId, isTrue);
      expect(p.address!.postalCode, '01310-100');
      expect(p.updatedAt, DateTime.utc(2026, 10, 15, 1));
    });

    test('no profile yet / malformed', () {
      final s = BillingStatus.fromMap(const {'profile': null, 'missing': ['profile', 3], 'complete': false});
      expect(s.profile, isNull);
      expect(s.missing, ['profile']);
      expect(BillingStatus.fromMap(const {}).complete, isFalse);
    });
  });

  group('BillingFieldError.fromDetails', () {
    test('maps server details', () {
      expect(BillingFieldError.fromDetails({'field': 'taxId', 'code': 'invalid'}), const BillingFieldError('taxId', BillingErrorCode.invalid));
      expect(BillingFieldError.fromDetails({'field': 'address.city', 'code': 'required'})!.code, BillingErrorCode.required);
      expect(BillingFieldError.fromDetails({'field': 'legalName', 'code': 'tooLong'})!.code, BillingErrorCode.tooLong);
      expect(BillingFieldError.fromDetails({'field': 'x', 'code': 'weird'})!.code, BillingErrorCode.invalid);
      expect(BillingFieldError.fromDetails({'code': 'invalid'}), isNull);
      expect(BillingFieldError.fromDetails('nope'), isNull);
    });
  });

  group('BillingDraft.toMap', () {
    const addr = BillingAddress(street: ' Rua A ', number: '1', district: 'Centro', city: 'Rio', region: 'RJ', postalCode: '20000-000', country: 'BR');
    test('blank tax id is NOT sent (keeps the stored one); company-only fields only for companies', () {
      final m = const BillingDraft(type: BillingType.private, country: 'BR', legalName: ' Ana ', address: addr, email: 'a@b.co',
          tradeName: 'ignored', contactPerson: 'ignored', inscricaoMunicipal: '9').toMap();
      expect(m.containsKey('taxId'), isFalse);
      expect(m.containsKey('tradeName'), isFalse);
      expect(m.containsKey('inscricaoMunicipal'), isFalse);
      expect(m['legalName'], 'Ana');
      expect((m['address'] as Map)['street'], 'Rua A');
    });
    test('company BR sends registrations + tax id', () {
      final m = const BillingDraft(type: BillingType.company, country: 'BR', legalName: 'X Ltda', address: addr, email: 'a@b.co',
          taxId: '40.486.663/0001-82', contactPerson: 'José', inscricaoMunicipal: '123').toMap();
      expect(m['type'], 'company');
      expect(m['taxId'], '40.486.663/0001-82');
      expect(m['inscricaoMunicipal'], '123');
      expect(m['contactPerson'], 'José');
    });
  });

  group('labels and rules', () {
    test('tax id label per country and type', () {
      expect(taxIdLabelFor('BR', BillingType.private), TaxIdLabel.cpf);
      expect(taxIdLabelFor('BR', BillingType.company), TaxIdLabel.cnpj);
      expect(taxIdLabelFor('IT', BillingType.private), TaxIdLabel.codiceFiscale);
      expect(taxIdLabelFor('ES', BillingType.company), TaxIdLabel.cifNif);
      expect(taxIdLabelFor('US', BillingType.private), TaxIdLabel.ssnItin);
      expect(taxIdLabelFor('NL', BillingType.company), TaxIdLabel.vat);
      expect(taxIdLabelFor('JP', BillingType.company), TaxIdLabel.genericCompany);
      expect(taxIdLabelFor('JP', BillingType.private), TaxIdLabel.generic);
      expect(taxIdOptional('US', BillingType.private), isTrue);
      expect(taxIdOptional('US', BillingType.company), isFalse);
      expect(regionRequired('BR') && regionRequired('US') && !regionRequired('IT'), isTrue);
      expect(postalCodeHint('PT'), '0000-000');
      expect(postalCodeHint('JP'), isNull);
    });
  });

  group('BillingProfileCubit', () {
    test('load -> ready; save success counts; field error kept until edited', () async {
      final repo = _FakeRepo(const BillingStatus(missing: ['profile']));
      final cubit = BillingProfileCubit(repo);
      await cubit.load();
      expect(cubit.state.status, BillingLoadStatus.ready);
      expect(cubit.state.complete, isFalse);

      repo.saveError = const BillingValidationException(BillingFieldError('taxId', BillingErrorCode.invalid));
      const draft = BillingDraft(type: BillingType.private, country: 'BR', legalName: 'A', address: BillingAddress(), email: 'a@b.co');
      expect(await cubit.save(draft), isFalse);
      expect(cubit.state.fieldError, const BillingFieldError('taxId', BillingErrorCode.invalid));
      cubit.clearFieldError('email');
      expect(cubit.state.fieldError, isNotNull);
      cubit.clearFieldError('taxId');
      expect(cubit.state.fieldError, isNull);

      repo.saveError = Exception('network');
      expect(await cubit.save(draft), isFalse);
      expect(cubit.state.saveFailed, isTrue);

      repo.saveError = null;
      expect(await cubit.save(draft), isTrue);
      expect(cubit.state.complete, isTrue);
      expect(cubit.state.savedCount, 1);
      await cubit.close();
    });

    test('load failure -> failed (retryable)', () async {
      final repo = _FakeRepo(const BillingStatus())..loadError = Exception('offline');
      final cubit = BillingProfileCubit(repo);
      await cubit.load();
      expect(cubit.state.status, BillingLoadStatus.failed);
      repo.loadError = null;
      await cubit.load();
      expect(cubit.state.status, BillingLoadStatus.ready);
      await cubit.close();
    });
  });

  group('InvoiceDetailsScreen', () {
    Future<void> tall(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('prefills a saved profile, tax id masked; Change reveals an empty input', (tester) async {
      await tall(tester);
      final repo = _FakeRepo(BillingStatus.fromMap(_savedMap));
      await tester.pumpWidget(_app(InvoiceDetailsScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Zé Bar Ltda'), findsOneWidget);
      expect(find.text('Saved: ••••••••0182'), findsOneWidget);
      expect(find.byKey(const ValueKey('billing-taxId')), findsNothing);
      expect(find.text('Inscrição municipal (optional)'), findsOneWidget);

      // Save without touching the tax id: none is sent.
      await tester.tap(find.byKey(const ValueKey('billing-save')));
      await tester.pumpAndSettle();
      expect(repo.saves.single.taxId, '');
      expect(repo.saves.single.type, BillingType.company);
      expect(find.text('Invoice details saved'), findsOneWidget);
    });

    testWidgets('new private profile: server field error is shown under the field', (tester) async {
      await tall(tester);
      final repo = _FakeRepo(const BillingStatus(missing: ['profile']))
        ..saveError = const BillingValidationException(BillingFieldError('taxId', BillingErrorCode.invalid));
      await tester.pumpWidget(_app(InvoiceDetailsScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('CPF'), findsOneWidget); // default country BR, private
      await tester.enterText(find.byKey(const ValueKey('billing-taxId')), '111.111.111-11');
      await tester.tap(find.byKey(const ValueKey('billing-save')));
      await tester.pumpAndSettle();
      expect(repo.saves.single.taxId, '111.111.111-11');
      expect(find.text('This number is not valid for the selected country'), findsOneWidget);
      // Editing the field clears its error.
      await tester.enterText(find.byKey(const ValueKey('billing-taxId')), '529.982.247-25');
      await tester.pump();
      expect(find.text('This number is not valid for the selected country'), findsNothing);
    });

    testWidgets('company switch shows contact person + CNPJ label', (tester) async {
      await tall(tester);
      final repo = _FakeRepo(const BillingStatus(missing: ['profile']));
      await tester.pumpWidget(_app(InvoiceDetailsScreen(repository: repo)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Company'));
      await tester.pumpAndSettle();
      expect(find.text('CNPJ'), findsOneWidget);
      expect(find.text('Contact person'), findsOneWidget);
    });
  });

  group('hub status widgets', () {
    testWidgets('banner only when known incomplete; tile subtitle reflects status', (tester) async {
      final repo = _FakeRepo(const BillingStatus(missing: ['profile']));
      await tester.pumpWidget(_app(Scaffold(
        body: BillingStatusScope(repository: repo, child: const Column(children: [BillingRequiredBanner(), InvoiceDetailsTile()])),
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('billing-required-banner')), findsOneWidget);
      expect(find.text('Missing — required for your fee invoices'), findsOneWidget);

      final done = _FakeRepo(BillingStatus.fromMap(_savedMap));
      await tester.pumpWidget(_app(Scaffold(
        body: BillingStatusScope(key: const ValueKey('b'), repository: done, child: const Column(children: [BillingRequiredBanner(), InvoiceDetailsTile()])),
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('billing-required-banner')), findsNothing);
      expect(find.text('Ready for your GreenGo fee invoices'), findsOneWidget);
    });

    testWidgets('no banner on a load error', (tester) async {
      final repo = _FakeRepo(const BillingStatus())..loadError = Exception('offline');
      await tester.pumpWidget(_app(Scaffold(body: BillingStatusScope(repository: repo, child: const BillingRequiredBanner()))));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('billing-required-banner')), findsNothing);
    });
  });
}
