import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

import '../domain/finance_document.dart';

/// A downloaded PDF.
class FinancePdf {
  const FinancePdf(this.filename, this.bytes);

  final String filename;
  final Uint8List bytes;
}

/// Client of the seller finance callables (`listMyFinanceDocuments`,
/// `getMyFinanceDocumentPdf`). The server checks ownership; documents are
/// server-only in Firestore, so there is no direct read path.
class FinanceDocumentsRepository {
  FinanceDocumentsRepository({FirebaseFunctions? functions}) : _functions = functions;

  final FirebaseFunctions? _functions;

  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instance;

  static const int pageSize = 20;

  Future<FinanceDocumentsPage> list(FinanceDocKind kind, {String? cursor}) async {
    final res = await _fn.httpsCallable('listMyFinanceDocuments').call<Map<String, dynamic>>({
      'kind': kind == FinanceDocKind.statements ? 'statements' : 'invoices',
      'pageSize': pageSize,
      if (cursor != null) 'cursor': cursor,
    });
    final data = Map<String, dynamic>.from(res.data);
    final items = [
      for (final raw in (data['items'] as List? ?? const []))
        if (raw is Map) FinanceDocument.fromMap(raw),
    ];
    return FinanceDocumentsPage(items, data['nextCursor'] as String?);
  }

  Future<FinancePdf> pdf(FinanceDocument doc) async {
    final res = await _fn.httpsCallable('getMyFinanceDocumentPdf').call<Map<String, dynamic>>({
      'kind': doc.kind == FinanceDocKind.statements ? 'statement' : 'invoice',
      'id': doc.id,
    });
    final data = Map<String, dynamic>.from(res.data);
    final name = (data['filename'] as String?)?.trim();
    return FinancePdf(
      name == null || name.isEmpty ? '${doc.number}.pdf' : name,
      base64Decode(data['base64'] as String? ?? ''),
    );
  }
}
