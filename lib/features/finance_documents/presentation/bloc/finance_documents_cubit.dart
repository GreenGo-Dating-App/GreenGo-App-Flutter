import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/finance_documents_repository.dart';
import '../../domain/finance_document.dart';

enum FinanceDocsStatus { loading, ready, failed }

class FinanceDocumentsState extends Equatable {
  const FinanceDocumentsState({
    this.status = FinanceDocsStatus.loading,
    this.items = const <FinanceDocument>[],
    this.nextCursor,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final FinanceDocsStatus status;
  final List<FinanceDocument> items;
  final String? nextCursor;
  final bool loadingMore;
  final bool loadMoreFailed;

  bool get hasMore => nextCursor != null;

  FinanceDocumentsState copyWith({
    FinanceDocsStatus? status,
    List<FinanceDocument>? items,
    String? Function()? nextCursor,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) =>
      FinanceDocumentsState(
        status: status ?? this.status,
        items: items ?? this.items,
        nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      );

  @override
  List<Object?> get props => [status, items, nextCursor, loadingMore, loadMoreFailed];
}

/// One list (invoices or statements) of the signed-in seller's documents,
/// cursor-paginated (20 per page).
class FinanceDocumentsCubit extends Cubit<FinanceDocumentsState> {
  FinanceDocumentsCubit(this._repo, this.kind) : super(const FinanceDocumentsState());

  final FinanceDocumentsRepository _repo;
  final FinanceDocKind kind;

  /// First page (initial load, retry and pull-to-refresh).
  Future<void> load() async {
    if (state.items.isEmpty) emit(const FinanceDocumentsState());
    try {
      final page = await _repo.list(kind);
      if (isClosed) return;
      emit(FinanceDocumentsState(status: FinanceDocsStatus.ready, items: page.items, nextCursor: page.nextCursor));
    } catch (e) {
      debugPrint('[FinanceDocs] list ${kind.name} failed: $e');
      if (isClosed) return;
      emit(state.copyWith(status: state.items.isEmpty ? FinanceDocsStatus.failed : FinanceDocsStatus.ready));
    }
  }

  /// Next page; no-op while one is loading or when there is none.
  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loadingMore || state.status != FinanceDocsStatus.ready) return;
    emit(state.copyWith(loadingMore: true, loadMoreFailed: false));
    try {
      final page = await _repo.list(kind, cursor: cursor);
      if (isClosed) return;
      final seen = state.items.map((d) => d.id).toSet();
      emit(state.copyWith(
        items: [...state.items, ...page.items.where((d) => !seen.contains(d.id))],
        nextCursor: () => page.nextCursor,
        loadingMore: false,
      ));
    } catch (e) {
      debugPrint('[FinanceDocs] loadMore ${kind.name} failed: $e');
      if (isClosed) return;
      emit(state.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }
}
