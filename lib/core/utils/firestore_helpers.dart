import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firestore Helpers for Cost Optimization
/// Includes pagination, batch writes, and query utilities
class FirestoreHelpers {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================================
  // PAGINATION HELPERS
  // ============================================================================

  /// Default page size for list queries
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// Paginated query result
  static Future<PaginatedResult<T>> paginatedQuery<T>({
    required Query query,
    required T Function(DocumentSnapshot doc) fromDoc,
    DocumentSnapshot? startAfter,
    int pageSize = defaultPageSize,
  }) async {
    Query paginatedQuery = query.limit(pageSize + 1); // +1 to check if more exists

    if (startAfter != null) {
      paginatedQuery = paginatedQuery.startAfterDocument(startAfter);
    }

    final snapshot = await paginatedQuery.get();
    final docs = snapshot.docs;

    final hasMore = docs.length > pageSize;
    final resultDocs = hasMore ? docs.take(pageSize).toList() : docs;

    final items = resultDocs.map((doc) => fromDoc(doc)).toList();
    final lastDoc = resultDocs.isNotEmpty ? resultDocs.last : null;

    return PaginatedResult<T>(
      items: items,
      lastDocument: lastDoc,
      hasMore: hasMore,
    );
  }

  /// Stream-based paginated query
  static Stream<PaginatedResult<T>> paginatedStream<T>({
    required Query query,
    required T Function(DocumentSnapshot doc) fromDoc,
    int pageSize = defaultPageSize,
  }) {
    return query.limit(pageSize).snapshots().map((snapshot) {
      final docs = snapshot.docs;
      final items = docs.map((doc) => fromDoc(doc)).toList();
      final lastDoc = docs.isNotEmpty ? docs.last : null;

      return PaginatedResult<T>(
        items: items,
        lastDocument: lastDoc,
        hasMore: docs.length >= pageSize,
      );
    });
  }

  // ============================================================================
  // BATCH WRITE HELPERS
  // ============================================================================

  /// Max operations per batch (Firestore limit is 500)
  static const int maxBatchSize = 450; // Leave some margin

  /// Execute batch writes efficiently
  /// Automatically splits into multiple batches if needed
  static Future<void> batchWrite(List<BatchOperation> operations) async {
    if (operations.isEmpty) return;

    final batches = <WriteBatch>[];
    WriteBatch currentBatch = _firestore.batch();
    int operationCount = 0;

    for (final op in operations) {
      switch (op.type) {
        case BatchOperationType.set:
          currentBatch.set(
            op.reference,
            op.data!,
            op.setOptions ?? SetOptions(merge: false),
          );
          break;
        case BatchOperationType.update:
          currentBatch.update(op.reference, op.data!);
          break;
        case BatchOperationType.delete:
          currentBatch.delete(op.reference);
          break;
      }

      operationCount++;

      // Start new batch if limit reached
      if (operationCount >= maxBatchSize) {
        batches.add(currentBatch);
        currentBatch = _firestore.batch();
        operationCount = 0;
      }
    }

    // Add final batch if not empty
    if (operationCount > 0) {
      batches.add(currentBatch);
    }

    // Execute all batches
    debugPrint('Executing ${batches.length} batch(es) with ${operations.length} operations');

    for (int i = 0; i < batches.length; i++) {
      await batches[i].commit();
      debugPrint('Batch ${i + 1}/${batches.length} committed');
    }
  }

  /// Create multiple documents in a batch
  static Future<void> batchCreate(
    String collection,
    List<Map<String, dynamic>> documents, {
    bool merge = false,
  }) async {
    final operations = documents.map((doc) {
      final docRef = _firestore.collection(collection).doc();
      return BatchOperation.set(
        docRef,
        {...doc, 'createdAt': FieldValue.serverTimestamp()},
        merge: merge,
      );
    }).toList();

    await batchWrite(operations);
  }

  /// Update multiple documents in a batch
  static Future<void> batchUpdate(
    String collection,
    Map<String, Map<String, dynamic>> updates, // docId -> data
  ) async {
    final operations = updates.entries.map((entry) {
      final docRef = _firestore.collection(collection).doc(entry.key);
      return BatchOperation.update(docRef, {
        ...entry.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }).toList();

    await batchWrite(operations);
  }

  /// Delete multiple documents in a batch
  static Future<void> batchDelete(
    String collection,
    List<String> documentIds,
  ) async {
    final operations = documentIds.map((docId) {
      final docRef = _firestore.collection(collection).doc(docId);
      return BatchOperation.delete(docRef);
    }).toList();

    await batchWrite(operations);
  }

  // ============================================================================
  // QUERY OPTIMIZATION HELPERS
  // ============================================================================

  /// Get document with caching check
  static Future<DocumentSnapshot?> getDocument(
    DocumentReference ref, {
    Source source = Source.serverAndCache,
  }) async {
    try {
      return await ref.get(GetOptions(source: source));
    } catch (e) {
      debugPrint('Document fetch error: $e');
      // Try cache if server fails
      if (source == Source.server) {
        try {
          return await ref.get(GetOptions(source: Source.cache));
        } catch (_) {}
      }
      return null;
    }
  }

  /// Get collection with limit
  static Future<List<DocumentSnapshot>> getCollection(
    String collection, {
    int limit = defaultPageSize,
    List<QueryCondition>? conditions,
    String? orderBy,
    bool descending = false,
  }) async {
    Query query = _firestore.collection(collection);

    // Apply conditions
    if (conditions != null) {
      for (final condition in conditions) {
        query = condition.apply(query);
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs;
  }

  /// Count documents (uses aggregation for efficiency)
  static Future<int> countDocuments(
    String collection, {
    List<QueryCondition>? conditions,
  }) async {
    Query query = _firestore.collection(collection);

    if (conditions != null) {
      for (final condition in conditions) {
        query = condition.apply(query);
      }
    }

    final countQuery = query.count();
    final snapshot = await countQuery.get();
    return snapshot.count ?? 0;
  }

  // ============================================================================
  // TRANSACTION HELPERS
  // ============================================================================

  /// Run a transaction with retry
  static Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) handler, {
    int maxAttempts = 3,
  }) async {
    return await _firestore.runTransaction(handler, maxAttempts: maxAttempts);
  }

  /// Increment a field atomically
  static Future<void> incrementField(
    DocumentReference ref,
    String field,
    num value,
  ) async {
    await ref.update({
      field: FieldValue.increment(value),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add to array atomically
  static Future<void> arrayUnion(
    DocumentReference ref,
    String field,
    List<dynamic> values,
  ) async {
    await ref.update({
      field: FieldValue.arrayUnion(values),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove from array atomically
  static Future<void> arrayRemove(
    DocumentReference ref,
    String field,
    List<dynamic> values,
  ) async {
    await ref.update({
      field: FieldValue.arrayRemove(values),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

// ============================================================================
// SUPPORTING CLASSES
// ============================================================================

/// Result of a paginated query
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedResult({
    required this.items,
    this.lastDocument,
    this.hasMore = false,
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;
}

/// Batch operation types
enum BatchOperationType { set, update, delete }

/// Batch operation wrapper
class BatchOperation {
  final BatchOperationType type;
  final DocumentReference reference;
  final Map<String, dynamic>? data;
  final SetOptions? setOptions;

  BatchOperation._({
    required this.type,
    required this.reference,
    this.data,
    this.setOptions,
  });

  factory BatchOperation.set(
    DocumentReference ref,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    return BatchOperation._(
      type: BatchOperationType.set,
      reference: ref,
      data: data,
      setOptions: SetOptions(merge: merge),
    );
  }

  factory BatchOperation.update(
    DocumentReference ref,
    Map<String, dynamic> data,
  ) {
    return BatchOperation._(
      type: BatchOperationType.update,
      reference: ref,
      data: data,
    );
  }

  factory BatchOperation.delete(DocumentReference ref) {
    return BatchOperation._(
      type: BatchOperationType.delete,
      reference: ref,
    );
  }
}

/// Query condition for building queries
class QueryCondition {
  final String field;
  final dynamic operator;
  final dynamic value;

  QueryCondition.equals(this.field, this.value) : operator = '==';
  QueryCondition.notEquals(this.field, this.value) : operator = '!=';
  QueryCondition.lessThan(this.field, this.value) : operator = '<';
  QueryCondition.lessThanOrEqual(this.field, this.value) : operator = '<=';
  QueryCondition.greaterThan(this.field, this.value) : operator = '>';
  QueryCondition.greaterThanOrEqual(this.field, this.value) : operator = '>=';
  QueryCondition.whereIn(this.field, this.value) : operator = 'in';
  QueryCondition.arrayContains(this.field, this.value) : operator = 'array-contains';

  Query apply(Query query) {
    switch (operator) {
      case '==':
        return query.where(field, isEqualTo: value);
      case '!=':
        return query.where(field, isNotEqualTo: value);
      case '<':
        return query.where(field, isLessThan: value);
      case '<=':
        return query.where(field, isLessThanOrEqualTo: value);
      case '>':
        return query.where(field, isGreaterThan: value);
      case '>=':
        return query.where(field, isGreaterThanOrEqualTo: value);
      case 'in':
        return query.where(field, whereIn: value);
      case 'array-contains':
        return query.where(field, arrayContains: value);
      default:
        return query;
    }
  }
}
