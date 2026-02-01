import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/virtual_gift_model.dart';

/// Virtual Gift Remote Data Source
abstract class VirtualGiftRemoteDataSource {
  Future<List<VirtualGiftModel>> getGiftCatalog();
  Future<List<VirtualGiftModel>> getGiftsByCategory(String category);
  Future<VirtualGiftModel> getGiftById(String giftId);
  Future<SentVirtualGiftModel> sendGift({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String giftId,
    String? message,
  });
  Future<List<SentVirtualGiftModel>> getReceivedGifts({
    required String userId,
    int limit = 20,
    String? lastGiftId,
  });
  Stream<List<SentVirtualGiftModel>> streamReceivedGifts(String userId);
  Future<List<SentVirtualGiftModel>> getSentGifts({
    required String userId,
    int limit = 20,
    String? lastGiftId,
  });
  Future<void> markGiftViewed(String giftId);
  Future<GiftStatsModel> getGiftStats(String userId);
  Future<int> getUnviewedGiftCount(String userId);
}

/// Implementation
class VirtualGiftRemoteDataSourceImpl implements VirtualGiftRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  // Cache for gift catalog
  List<VirtualGiftModel>? _catalogCache;
  DateTime? _catalogCacheTime;
  static const _cacheDuration = Duration(minutes: 30);

  VirtualGiftRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<List<VirtualGiftModel>> getGiftCatalog() async {
    // Check cache first
    if (_catalogCache != null &&
        _catalogCacheTime != null &&
        DateTime.now().difference(_catalogCacheTime!) < _cacheDuration) {
      return _catalogCache!;
    }

    final callable = _functions.httpsCallable('getGiftCatalog');
    final result = await callable.call<Map<String, dynamic>>();

    final gifts = result.data['gifts'] as List<dynamic>;
    _catalogCache = gifts.map((gift) {
      final giftMap = gift as Map<String, dynamic>;
      return VirtualGiftModel.fromMap(giftMap, giftMap['id'] as String);
    }).toList();
    _catalogCacheTime = DateTime.now();

    return _catalogCache!;
  }

  @override
  Future<List<VirtualGiftModel>> getGiftsByCategory(String category) async {
    final snapshot = await _firestore
        .collection('virtualGifts')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .map((doc) => VirtualGiftModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<VirtualGiftModel> getGiftById(String giftId) async {
    // Check cache first
    if (_catalogCache != null) {
      try {
        return _catalogCache!.firstWhere((g) => g.id == giftId);
      } catch (_) {
        // Not in cache, fetch from Firestore
      }
    }

    final doc = await _firestore.collection('virtualGifts').doc(giftId).get();
    if (!doc.exists) {
      throw Exception('Gift not found');
    }
    return VirtualGiftModel.fromFirestore(doc);
  }

  @override
  Future<SentVirtualGiftModel> sendGift({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String giftId,
    String? message,
  }) async {
    final callable = _functions.httpsCallable('sendGift');
    final result = await callable.call<Map<String, dynamic>>({
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'giftId': giftId,
      if (message != null) 'message': message,
    });

    final data = result.data;
    final gift = await getGiftById(giftId);

    return SentVirtualGiftModel(
      id: data['sentGiftId'] as String,
      giftId: giftId,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      receiverName: receiverName,
      message: message,
      sentAt: DateTime.now(),
      coinsCost: gift.price,
      gift: gift,
    );
  }

  @override
  Future<List<SentVirtualGiftModel>> getReceivedGifts({
    required String userId,
    int limit = 20,
    String? lastGiftId,
  }) async {
    final callable = _functions.httpsCallable('getReceivedGifts');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'limit': limit,
      if (lastGiftId != null) 'lastGiftId': lastGiftId,
    });

    final gifts = result.data['gifts'] as List<dynamic>;
    final giftModels = <SentVirtualGiftModel>[];

    for (final giftData in gifts) {
      final map = giftData as Map<String, dynamic>;
      VirtualGiftModel? giftDetails;
      try {
        giftDetails = await getGiftById(map['giftId'] as String);
      } catch (_) {}

      giftModels.add(SentVirtualGiftModel(
        id: map['id'] as String,
        giftId: map['giftId'] as String,
        senderId: map['senderId'] as String,
        senderName: map['senderName'] as String,
        receiverId: map['receiverId'] as String,
        receiverName: map['receiverName'] as String,
        message: map['message'] as String?,
        sentAt: DateTime.parse(map['sentAt'] as String),
        isViewed: map['isViewed'] as bool? ?? false,
        viewedAt: map['viewedAt'] != null
            ? DateTime.parse(map['viewedAt'] as String)
            : null,
        coinsCost: (map['coinsCost'] as num).toInt(),
        gift: giftDetails,
      ));
    }

    return giftModels;
  }

  @override
  Stream<List<SentVirtualGiftModel>> streamReceivedGifts(String userId) {
    return _firestore
        .collection('sentVirtualGifts')
        .where('receiverId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
      final giftModels = <SentVirtualGiftModel>[];

      for (final doc in snapshot.docs) {
        VirtualGiftModel? giftDetails;
        try {
          final data = doc.data();
          giftDetails = await getGiftById(data['giftId'] as String);
        } catch (_) {}

        giftModels.add(SentVirtualGiftModel.fromFirestore(doc, gift: giftDetails));
      }

      return giftModels;
    });
  }

  @override
  Future<List<SentVirtualGiftModel>> getSentGifts({
    required String userId,
    int limit = 20,
    String? lastGiftId,
  }) async {
    final callable = _functions.httpsCallable('getSentGifts');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'limit': limit,
      if (lastGiftId != null) 'lastGiftId': lastGiftId,
    });

    final gifts = result.data['gifts'] as List<dynamic>;
    final giftModels = <SentVirtualGiftModel>[];

    for (final giftData in gifts) {
      final map = giftData as Map<String, dynamic>;
      VirtualGiftModel? giftDetails;
      try {
        giftDetails = await getGiftById(map['giftId'] as String);
      } catch (_) {}

      giftModels.add(SentVirtualGiftModel(
        id: map['id'] as String,
        giftId: map['giftId'] as String,
        senderId: map['senderId'] as String,
        senderName: map['senderName'] as String,
        receiverId: map['receiverId'] as String,
        receiverName: map['receiverName'] as String,
        message: map['message'] as String?,
        sentAt: DateTime.parse(map['sentAt'] as String),
        isViewed: map['isViewed'] as bool? ?? false,
        viewedAt: map['viewedAt'] != null
            ? DateTime.parse(map['viewedAt'] as String)
            : null,
        coinsCost: (map['coinsCost'] as num).toInt(),
        gift: giftDetails,
      ));
    }

    return giftModels;
  }

  @override
  Future<void> markGiftViewed(String giftId) async {
    final callable = _functions.httpsCallable('markGiftViewed');
    await callable.call<Map<String, dynamic>>({
      'giftId': giftId,
    });
  }

  @override
  Future<GiftStatsModel> getGiftStats(String userId) async {
    final callable = _functions.httpsCallable('getGiftStats');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
    });

    final data = result.data;
    return GiftStatsModel(
      userId: userId,
      totalGiftsSent: (data['totalGiftsSent'] as num?)?.toInt() ?? 0,
      totalGiftsReceived: (data['totalGiftsReceived'] as num?)?.toInt() ?? 0,
      totalCoinsSpent: (data['totalCoinsSpent'] as num?)?.toInt() ?? 0,
      totalCoinsReceived: (data['totalCoinsReceived'] as num?)?.toInt() ?? 0,
      giftsSentByType:
          Map<String, int>.from(data['giftsSentByType'] as Map? ?? {}),
      giftsReceivedByType:
          Map<String, int>.from(data['giftsReceivedByType'] as Map? ?? {}),
      mostSentGiftId: data['mostSentGiftId'] as String?,
      mostReceivedGiftId: data['mostReceivedGiftId'] as String?,
    );
  }

  @override
  Future<int> getUnviewedGiftCount(String userId) async {
    final snapshot = await _firestore
        .collection('sentVirtualGifts')
        .where('receiverId', isEqualTo: userId)
        .where('isViewed', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}
