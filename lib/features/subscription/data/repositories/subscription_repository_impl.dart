import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/purchase.dart' as domain;
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_datasource.dart';
import '../models/subscription_model.dart';

/// Subscription Repository Implementation
/// Handles subscription and purchase operations
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remoteDataSource;

  SubscriptionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Subscription?>> getCurrentSubscription(String userId) async {
    try {
      final subscription = await remoteDataSource.getCurrentSubscription(userId);
      return Right(subscription?.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, Subscription?>> subscriptionStream(String userId) {
    return remoteDataSource.subscriptionStream(userId).map<
        Either<Failure, Subscription?>>(
      (subscription) => Right(subscription?.toEntity()),
    ).handleError(
      (error) => Left(ServerFailure(error.toString())),
    );
  }

  @override
  Future<Either<Failure, domain.Purchase>> purchaseSubscription({
    required String userId,
    required SubscriptionTier tier,
    required String platform,
  }) async {
    try {
      // Get available products
      final products = await remoteDataSource.getAvailableProducts();
      
      // Find the product for the requested tier
      final productId = _getProductIdForTier(tier);
      final product = products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found for tier: $tier'),
      );
      
      // Consumable products can always be re-purchased (no ownership check needed)
      // Attempt purchase (one-time membership)
      await remoteDataSource.purchaseMembership(
        product: product,
        userId: userId,
      );
      
      // Return a pending purchase - actual verification happens through stream
      return Right(domain.Purchase(
        purchaseId: 'pending',
        userId: userId,
        type: domain.PurchaseType.subscription,
        status: domain.PurchaseStatus.pending,
        productId: productId,
        productName: product.title,
        tier: tier,
        price: (product.price is num) ? (product.price as num).toDouble() : double.tryParse(product.price.toString()) ?? 0.0,
        currency: product.currencyCode,
        platform: platform,
        purchaseDate: DateTime.now(),
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<domain.Purchase>>> restorePurchases(String userId) async {
    try {
      await remoteDataSource.restorePurchases();
      
      // Get purchase history
      final history = await remoteDataSource.getPurchaseHistory(userId);
      
      final purchases = history.map((data) {
        return domain.Purchase(
          purchaseId: data['purchaseId'] as String,
          userId: userId,
          type: domain.PurchaseType.subscription,
          status: _stringToPurchaseStatus(data['status'] as String),
          productId: data['productId'] as String,
          productName: data['productName'] as String? ?? '',
          tier: SubscriptionTierExtension.fromString(data['tier'] as String),
          price: (data['price'] as num).toDouble(),
          currency: data['currency'] as String? ?? 'USD',
          platform: data['platform'] as String,
          purchaseToken: data['purchaseToken'] as String?,
          transactionId: data['transactionId'] as String?,
          purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
          verifiedAt: data['verifiedAt'] != null ? (data['verifiedAt'] as Timestamp).toDate() : null,
        );
      }).toList();
      
      return Right(purchases);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPurchase({
    required String purchaseToken,
    required String productId,
    required String platform,
  }) async {
    try {
      // This is handled by the data source through purchase stream
      // For direct verification, we'd need to implement it
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<domain.Purchase>>> getPurchaseHistory(String userId) async {
    try {
      final history = await remoteDataSource.getPurchaseHistory(userId);
      
      final purchases = history.map((data) {
        return domain.Purchase(
          purchaseId: data['purchaseId'] as String,
          userId: userId,
          type: domain.PurchaseType.subscription,
          status: _stringToPurchaseStatus(data['status'] as String),
          productId: data['productId'] as String,
          productName: data['productName'] as String? ?? '',
          tier: SubscriptionTierExtension.fromString(data['tier'] as String),
          price: (data['price'] as num).toDouble(),
          currency: data['currency'] as String? ?? 'USD',
          platform: data['platform'] as String,
          purchaseToken: data['purchaseToken'] as String?,
          transactionId: data['transactionId'] as String?,
          purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
          verifiedAt: data['verifiedAt'] != null ? (data['verifiedAt'] as Timestamp).toDate() : null,
        );
      }).toList();
      
      return Right(purchases);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> handleFailedPayment({
    required String subscriptionId,
  }) async {
    try {
      // Implement failed payment handling
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> endGracePeriod({
    required String subscriptionId,
  }) async {
    try {
      // Implement grace period ending
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasFeatureAccess({
    required String userId,
    required String featureName,
  }) async {
    try {
      return Right(await remoteDataSource.hasFeatureAccess(
        userId: userId,
        featureName: featureName,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getFeatureLimit({
    required String userId,
    required String featureName,
  }) async {
    try {
      return Right(await remoteDataSource.getFeatureLimit(
        userId: userId,
        featureName: featureName,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> adminUpdateSubscription({
    required String subscriptionId,
    required SubscriptionStatus status,
    String? note,
  }) async {
    try {
      // Implement admin update
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> adminRefund({
    required String purchaseId,
    required String reason,
  }) async {
    try {
      // Implement admin refund
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Helper methods
  String _getProductIdForTier(SubscriptionTier tier) {
    // For now, return monthly product ID
    // In the UI, users can choose between monthly and yearly
    switch (tier) {
      case SubscriptionTier.silver:
        return '1_month_silver';
      case SubscriptionTier.gold:
        return '1_month_gold';
      case SubscriptionTier.platinum:
        return '1_month_platinum';
      case SubscriptionTier.basic:
        return 'greengo_base_membership';
      case SubscriptionTier.test:
        throw Exception('Test tier is not purchasable');
    }
  }

  domain.PurchaseStatus _stringToPurchaseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return domain.PurchaseStatus.pending;
      case 'completed':
      case 'success':
        return domain.PurchaseStatus.completed;
      case 'failed':
        return domain.PurchaseStatus.failed;
      case 'refunded':
        return domain.PurchaseStatus.refunded;
      case 'cancelled':
      case 'canceled':
        return domain.PurchaseStatus.cancelled;
      default:
        return domain.PurchaseStatus.pending;
    }
  }
}