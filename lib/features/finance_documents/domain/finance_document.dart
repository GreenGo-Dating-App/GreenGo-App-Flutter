import 'package:equatable/equatable.dart';

/// Which list of the seller's finance documents.
enum FinanceDocKind { invoices, statements }

/// NFS-e (Brazil) state of an invoice, as shown to the seller.
class FinanceNfse extends Equatable {
  const FinanceNfse({this.status, this.number, this.url});

  final String? status;
  final String? number;
  final String? url;

  bool get isAuthorized => status == 'authorized';
  bool get isCancelled => status == 'cancelled';

  static FinanceNfse? fromMap(Object? raw) {
    if (raw is! Map) return null;
    return FinanceNfse(
      status: raw['status'] as String?,
      number: raw['number'] as String?,
      url: raw['url'] as String?,
    );
  }

  @override
  List<Object?> get props => [status, number, url];
}

/// One currency of a monthly statement.
class FinanceStatementLine extends Equatable {
  const FinanceStatementLine({
    required this.currency,
    required this.sales,
    required this.feesNet,
    required this.net,
    required this.orders,
  });

  final String currency;

  /// Minor units.
  final int sales;
  final int feesNet;
  final int net;
  final int orders;

  static FinanceStatementLine fromMap(Map raw) => FinanceStatementLine(
        currency: (raw['currency'] as String? ?? '').toLowerCase(),
        sales: _int(raw['sales']),
        feesNet: _int(raw['feesNet']),
        net: _int(raw['net']),
        orders: _int(raw['orders']),
      );

  @override
  List<Object?> get props => [currency, sales, feesNet, net, orders];
}

/// A GreenGo fee invoice / credit note issued to the seller, or a seller
/// monthly statement (callable `listMyFinanceDocuments`).
class FinanceDocument extends Equatable {
  const FinanceDocument({
    required this.id,
    required this.kind,
    required this.number,
    this.type,
    this.status,
    this.isTest = false,
    this.currency,
    this.total,
    this.month,
    this.issuedAt,
    this.nfse,
    this.lines = const <FinanceStatementLine>[],
  });

  final String id;
  final FinanceDocKind kind;
  final String number;

  /// 'invoice' | 'credit_note' (invoices only).
  final String? type;

  /// 'issued' | 'void' (invoices only).
  final String? status;
  final bool isTest;
  final String? currency;

  /// Minor units (invoices only; negative for credit notes).
  final int? total;

  /// 'YYYYMM' (monthly fee invoices and statements).
  final String? month;
  final DateTime? issuedAt;
  final FinanceNfse? nfse;
  final List<FinanceStatementLine> lines;

  bool get isCreditNote => type == 'credit_note';
  bool get isVoid => status == 'void';

  /// 'YYYYMM' -> 'MM/YYYY', null when absent / malformed.
  String? get period {
    final m = month;
    if (m == null || !RegExp(r'^\d{6}$').hasMatch(m)) return null;
    return '${m.substring(4)}/${m.substring(0, 4)}';
  }

  static FinanceDocument fromMap(Map raw) {
    final isStatement = raw['kind'] == 'statement';
    return FinanceDocument(
      id: raw['id'] as String? ?? '',
      kind: isStatement ? FinanceDocKind.statements : FinanceDocKind.invoices,
      number: raw['number'] as String? ?? '',
      type: raw['type'] as String?,
      status: raw['status'] as String?,
      isTest: raw['isTest'] == true,
      currency: (raw['currency'] as String?)?.toLowerCase(),
      total: raw['total'] == null ? null : _int(raw['total']),
      month: raw['month'] as String?,
      issuedAt: DateTime.tryParse('${raw['issuedAt'] ?? ''}'),
      nfse: FinanceNfse.fromMap(raw['nfse']),
      lines: [
        for (final l in (raw['lines'] as List? ?? const []))
          if (l is Map) FinanceStatementLine.fromMap(l),
      ],
    );
  }

  @override
  List<Object?> get props =>
      [id, kind, number, type, status, isTest, currency, total, month, issuedAt, nfse, lines];
}

/// One page of documents + the cursor for the next one (null = last page).
class FinanceDocumentsPage {
  const FinanceDocumentsPage(this.items, this.nextCursor);

  final List<FinanceDocument> items;
  final String? nextCursor;
}

int _int(Object? v) => v is num ? v.round() : int.tryParse('$v') ?? 0;
