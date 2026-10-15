import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/finance_documents/data/finance_documents_repository.dart';
import 'package:greengo_chat/features/finance_documents/domain/finance_document.dart';
import 'package:greengo_chat/features/finance_documents/presentation/bloc/finance_documents_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements FinanceDocumentsRepository {}

FinanceDocument _inv(String id) => FinanceDocument(id: id, kind: FinanceDocKind.invoices, number: 'GG-2026-$id');

void main() {
  group('FinanceDocument.fromMap', () {
    test('invoice with NFS-e, month and credit-note flags', () {
      final d = FinanceDocument.fromMap({
        'id': 'mfee_org1_202610_brl', 'kind': 'invoice', 'type': 'credit_note', 'number': 'GGCN-2026-000002',
        'status': 'issued', 'isTest': true, 'currency': 'BRL', 'total': -1500, 'month': '202610',
        'issuedAt': '2026-11-02T06:00:00.000Z',
        'nfse': {'status': 'authorized', 'number': '77', 'url': 'https://nfse.example/77'},
      });
      expect(d.kind, FinanceDocKind.invoices);
      expect(d.isCreditNote, isTrue);
      expect(d.isTest, isTrue);
      expect(d.currency, 'brl');
      expect(d.total, -1500);
      expect(d.period, '10/2026');
      expect(d.issuedAt, DateTime.utc(2026, 11, 2, 6));
      expect(d.nfse!.isAuthorized, isTrue);
    });

    test('statement lines; missing / malformed fields are tolerated', () {
      final s = FinanceDocument.fromMap({
        'id': 'org1_202610', 'kind': 'statement', 'number': 'ST-202610-ORG1', 'month': '2026-10',
        'lines': [
          {'currency': 'usd', 'sales': 12000, 'feesNet': 2000, 'net': 10000, 'orders': 1},
          'garbage',
        ],
      });
      expect(s.kind, FinanceDocKind.statements);
      expect(s.period, isNull);
      expect(s.lines.single.net, 10000);
      expect(s.nfse, isNull);
    });
  });

  group('FinanceDocumentsCubit', () {
    late _Repo repo;
    setUp(() => repo = _Repo());

    test('loads the first page, then appends the next one without duplicates', () async {
      when(() => repo.list(FinanceDocKind.invoices))
          .thenAnswer((_) async => FinanceDocumentsPage([_inv('1'), _inv('2')], 'c2'));
      when(() => repo.list(FinanceDocKind.invoices, cursor: 'c2'))
          .thenAnswer((_) async => FinanceDocumentsPage([_inv('2'), _inv('3')], null));
      final cubit = FinanceDocumentsCubit(repo, FinanceDocKind.invoices);
      await cubit.load();
      expect(cubit.state.status, FinanceDocsStatus.ready);
      expect(cubit.state.hasMore, isTrue);
      await cubit.loadMore();
      expect(cubit.state.items.map((d) => d.id), ['1', '2', '3']);
      expect(cubit.state.hasMore, isFalse);
      await cubit.loadMore(); // no-op on the last page
      verify(() => repo.list(FinanceDocKind.invoices, cursor: 'c2')).called(1);
      await cubit.close();
    });

    test('first-page error -> failed; retry recovers', () async {
      var calls = 0;
      when(() => repo.list(FinanceDocKind.statements)).thenAnswer((_) async {
        if (calls++ == 0) throw Exception('offline');
        return const FinanceDocumentsPage(<FinanceDocument>[], null);
      });
      final cubit = FinanceDocumentsCubit(repo, FinanceDocKind.statements);
      await cubit.load();
      expect(cubit.state.status, FinanceDocsStatus.failed);
      await cubit.load();
      expect(cubit.state.status, FinanceDocsStatus.ready);
      expect(cubit.state.items, isEmpty);
      await cubit.close();
    });

    test('next-page error keeps the list and flags loadMoreFailed', () async {
      when(() => repo.list(FinanceDocKind.invoices))
          .thenAnswer((_) async => FinanceDocumentsPage([_inv('1')], 'c2'));
      when(() => repo.list(FinanceDocKind.invoices, cursor: 'c2')).thenThrow(Exception('boom'));
      final cubit = FinanceDocumentsCubit(repo, FinanceDocKind.invoices);
      await cubit.load();
      await cubit.loadMore();
      expect(cubit.state.items, hasLength(1));
      expect(cubit.state.loadMoreFailed, isTrue);
      expect(cubit.state.loadingMore, isFalse);
      await cubit.close();
    });
  });
}
