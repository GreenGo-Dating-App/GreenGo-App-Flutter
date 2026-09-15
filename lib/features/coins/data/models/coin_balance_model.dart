import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/coin_balance.dart';

/// Coin Balance Model for Firestore serialization
class CoinBalanceModel extends CoinBalance {
  const CoinBalanceModel({
    required super.userId,
    required super.totalCoins,
    required super.earnedCoins,
    required super.purchasedCoins,
    required super.giftedCoins,
    required super.spentCoins,
    required super.lastUpdated,
    super.coinBatches,
  });

  /// Create empty balance
  factory CoinBalanceModel.empty(String userId) {
    return CoinBalanceModel(
      userId: userId,
      totalCoins: 0,
      earnedCoins: 0,
      purchasedCoins: 0,
      giftedCoins: 0,
      spentCoins: 0,
      lastUpdated: DateTime.now(),
      coinBatches: const [],
    );
  }

  /// Create from Firestore document
  factory CoinBalanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CoinBalanceModel(
      userId: data['userId'] as String,
      totalCoins: (data['totalCoins'] as num?)?.toInt() ?? 0,
      earnedCoins: (data['earnedCoins'] as num?)?.toInt() ?? 0,
      purchasedCoins: (data['purchasedCoins'] as num?)?.toInt() ?? 0,
      giftedCoins: (data['giftedCoins'] as num?)?.toInt() ?? 0,
      spentCoins: (data['spentCoins'] as num?)?.toInt() ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      coinBatches: _parseCoinBatches(data['coinBatches'] as List<dynamic>?),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalCoins': totalCoins,
      'earnedCoins': earnedCoins,
      'purchasedCoins': purchasedCoins,
      'giftedCoins': giftedCoins,
      'spentCoins': spentCoins,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'coinBatches': coinBatches.map(_batchToMap).toList(),
    };
  }

  /// Parse coin batches from Firestore.
  ///
  /// One malformed entry used to throw straight out of `fromFirestore`, which
  /// discarded the WHOLE balance and showed the user zero coins. Skip what
  /// cannot be read; never lose the rest. Legacy `expirationDate` values are
  /// read and discarded — coins never expire (Guideline 3.1.1).
  static List<CoinBatch> _parseCoinBatches(List<dynamic>? data) {
    if (data == null) return [];

    final batches = <CoinBatch>[];
    for (final item in data) {
      try {
        final map = Map<String, dynamic>.from(item as Map);
        batches.add(CoinBatch(
          batchId: map['batchId'] as String,
          initialCoins: (map['initialCoins'] as num).toInt(),
          remainingCoins: (map['remainingCoins'] as num).toInt(),
          source: CoinSourceExtension.fromString(
              (map['source'] as String?) ?? 'reward'),
          acquiredDate:
              (map['acquiredDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ));
      } catch (_) {
        // Unreadable batch — the unbatched fallback in
        // CoinBalance.availableCoins still counts these coins via totalCoins.
      }
    }
    return batches;
  }

  /// Convert coin batch to map
  static Map<String, dynamic> _batchToMap(CoinBatch batch) {
    return {
      'batchId': batch.batchId,
      'initialCoins': batch.initialCoins,
      'remainingCoins': batch.remainingCoins,
      'source': batch.source.name,
      'acquiredDate': Timestamp.fromDate(batch.acquiredDate),
    };
  }
}
