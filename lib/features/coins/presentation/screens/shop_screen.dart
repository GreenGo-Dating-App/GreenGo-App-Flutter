import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/coin_package.dart';
import '../../domain/entities/video_coin.dart';
import '../../domain/entities/coin_gift.dart';

/// Shop Screen with tabs for Coins, Video Coins, and Gifts
class ShopScreen extends StatefulWidget {
  final String userId;

  const ShopScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _coinBalance = 0;
  int _videoCoinBalance = 0;

  // Check if video calls feature is enabled
  bool get _showVideoCoins => AppConfig.enableVideoCalls;

  @override
  void initState() {
    super.initState();
    // 2 tabs (Coins, Gifts) if video calls disabled, 3 tabs if enabled
    _tabController = TabController(length: _showVideoCoins ? 3 : 2, vsync: this);
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    try {
      final balanceDoc = await FirebaseFirestore.instance
          .collection('coinBalances')
          .doc(widget.userId)
          .get();

      if (balanceDoc.exists && mounted) {
        setState(() {
          _coinBalance = (balanceDoc.data()?['totalCoins'] as num?)?.toInt() ?? 0;
        });
      }

      final videoBalanceDoc = await FirebaseFirestore.instance
          .collection('videoCoinBalances')
          .doc(widget.userId)
          .get();

      if (videoBalanceDoc.exists && mounted) {
        final total = (videoBalanceDoc.data()?['totalVideoCoins'] as num?)?.toInt() ?? 0;
        final used = (videoBalanceDoc.data()?['usedVideoCoins'] as num?)?.toInt() ?? 0;
        setState(() {
          _videoCoinBalance = total - used;
        });
      }
    } catch (e) {
      debugPrint('Error loading balances: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'Shop',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Transaction History
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => _showTransactionHistory(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Balance display
              _buildBalanceHeader(),
              // Tab bar
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.richGold,
                labelColor: AppColors.richGold,
                unselectedLabelColor: AppColors.textTertiary,
                tabs: [
                  const Tab(text: 'Coins'),
                  if (_showVideoCoins) const Tab(text: 'Video Coins'),
                  const Tab(text: 'Gifts'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CoinsTab(
            userId: widget.userId,
            onPurchase: _handleCoinPurchase,
          ),
          if (_showVideoCoins)
            _VideoCoinsTab(
              userId: widget.userId,
              onPurchase: _handleVideoCoinPurchase,
            ),
          _GiftsTab(
            userId: widget.userId,
            coinBalance: _coinBalance,
            onSendGift: _handleSendGift,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Coin balance
          _BalanceChip(
            icon: Icons.monetization_on,
            iconColor: AppColors.richGold,
            label: 'Coins',
            value: _coinBalance.toString(),
          ),
          // Video coin balance - only show if video calls enabled
          if (_showVideoCoins)
            _BalanceChip(
              icon: Icons.videocam,
              iconColor: Colors.blueAccent,
              label: 'Video Min',
              value: _videoCoinBalance.toString(),
            ),
        ],
      ),
    );
  }

  void _showTransactionHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _TransactionHistoryScreen(userId: widget.userId),
      ),
    );
  }

  Future<void> _handleCoinPurchase(CoinPackage package) async {
    // Show purchase confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Confirm Purchase', style: TextStyle(color: Colors.white)),
        content: Text(
          'Purchase ${package.totalCoins} coins for ${package.displayPrice}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Purchase', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Simulate purchase (in production, use IAP)
      await _processCoinPurchase(package);
    }
  }

  Future<void> _processCoinPurchase(CoinPackage package) async {
    try {
      // Create order
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'userId': widget.userId,
        'type': 'coins',
        'packageId': package.packageId,
        'amount': package.totalCoins,
        'price': package.price,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update balance
      await FirebaseFirestore.instance
          .collection('coinBalances')
          .doc(widget.userId)
          .set({
        'userId': widget.userId,
        'totalCoins': FieldValue.increment(package.totalCoins),
        'purchasedCoins': FieldValue.increment(package.totalCoins),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Create invoice
      await _createInvoice(orderId, 'coins', package.totalCoins, package.price);

      await _loadBalances();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully purchased ${package.totalCoins} coins!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleVideoCoinPurchase(VideoCoinPackage package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Confirm Purchase', style: TextStyle(color: Colors.white)),
        content: Text(
          'Purchase ${package.totalMinutes} video minutes for ${package.displayPrice}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Purchase', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _processVideoCoinPurchase(package);
    }
  }

  Future<void> _processVideoCoinPurchase(VideoCoinPackage package) async {
    try {
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'userId': widget.userId,
        'type': 'videoCoins',
        'packageId': package.packageId,
        'amount': package.totalMinutes,
        'price': package.price,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('videoCoinBalances')
          .doc(widget.userId)
          .set({
        'userId': widget.userId,
        'totalVideoCoins': FieldValue.increment(package.totalMinutes),
        'usedVideoCoins': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _createInvoice(orderId, 'videoCoins', package.totalMinutes, package.price);

      await _loadBalances();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully purchased ${package.totalMinutes} video minutes!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createInvoice(String orderId, String type, int amount, double price) async {
    final invoiceNumber = 'INV-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-$orderId';

    await FirebaseFirestore.instance.collection('invoices').doc(orderId).set({
      'invoiceId': orderId,
      'invoiceNumber': invoiceNumber,
      'orderId': orderId,
      'userId': widget.userId,
      'status': 'paid',
      'issueDate': FieldValue.serverTimestamp(),
      'paidDate': FieldValue.serverTimestamp(),
      'lineItems': [
        {
          'itemId': type,
          'description': type == 'coins' ? 'GreenGoCoins Purchase' : 'Video Minutes Purchase',
          'quantity': amount,
          'unitPrice': price / amount,
          'totalPrice': price,
        }
      ],
      'subtotal': price,
      'taxRate': 0.0,
      'taxAmount': 0.0,
      'total': price,
      'currency': 'USD',
      'paymentMethod': 'googlePlay',
    });
  }

  Future<void> _handleSendGift(String receiverId, int amount, String? message) async {
    if (_coinBalance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient coins'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final giftId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create gift
      await FirebaseFirestore.instance.collection('coinGifts').doc(giftId).set({
        'giftId': giftId,
        'senderId': widget.userId,
        'receiverId': receiverId,
        'amount': amount,
        'message': message,
        'status': 'pending',
        'sentAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
      });

      // Deduct from sender
      await FirebaseFirestore.instance
          .collection('coinBalances')
          .doc(widget.userId)
          .update({
        'totalCoins': FieldValue.increment(-amount),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await _loadBalances();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gift of $amount coins sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send gift: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Balance chip widget
class _BalanceChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _BalanceChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Coins Tab
class _CoinsTab extends StatelessWidget {
  final String userId;
  final Function(CoinPackage) onPurchase;

  const _CoinsTab({
    required this.userId,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final packages = CoinPackages.standardPackages;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.monetization_on, size: 48, color: Colors.white),
              const SizedBox(height: 8),
              const Text(
                'GreenGoCoins',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Unlock premium features',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Package list
        ...packages.map((package) => _CoinPackageCard(
              package: package,
              isPopular: package.packageId == 'popular_500',
              onTap: () => onPurchase(package),
            )),
      ],
    );
  }
}

/// Coin Package Card
class _CoinPackageCard extends StatelessWidget {
  final CoinPackage package;
  final bool isPopular;
  final VoidCallback onTap;

  const _CoinPackageCard({
    required this.package,
    this.isPopular = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.backgroundCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPopular
            ? const BorderSide(color: AppColors.richGold, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (isPopular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.richGold,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                      ),
                    ),
                    child: const Icon(Icons.monetization_on, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${package.coinAmount}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (package.bonusCoins != null && package.bonusCoins! > 0)
                              Text(
                                ' +${package.bonusCoins}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            const Text(
                              ' Coins',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${package.coinsPerDollar.toStringAsFixed(0)} coins/\$',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.richGold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      package.displayPrice,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Video Coins Tab
class _VideoCoinsTab extends StatelessWidget {
  final String userId;
  final Function(VideoCoinPackage) onPurchase;

  const _VideoCoinsTab({
    required this.userId,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final packages = VideoCoinPackages.all;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.videocam, size: 48, color: Colors.white),
              const SizedBox(height: 8),
              const Text(
                'Video Minutes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Video call with your matches',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Info box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '1 Video Coin = 1 minute of video call',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Package list
        ...packages.map((package) => _VideoCoinPackageCard(
              package: package,
              onTap: () => onPurchase(package),
            )),
      ],
    );
  }
}

/// Video Coin Package Card
class _VideoCoinPackageCard extends StatelessWidget {
  final VideoCoinPackage package;
  final VoidCallback onTap;

  const _VideoCoinPackageCard({
    required this.package,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.backgroundCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: package.isPopular
            ? const BorderSide(color: Colors.blueAccent, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (package.badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    package.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.blueAccent, Colors.blue],
                      ),
                    ),
                    child: const Icon(Icons.videocam, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${package.videoMinutes}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (package.bonusMinutes != null && package.bonusMinutes! > 0)
                              Text(
                                ' +${package.bonusMinutes}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            const Text(
                              ' mins',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '\$${package.pricePerMinute.toStringAsFixed(2)}/min',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      package.displayPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gifts Tab
class _GiftsTab extends StatefulWidget {
  final String userId;
  final int coinBalance;
  final Function(String, int, String?) onSendGift;

  const _GiftsTab({
    required this.userId,
    required this.coinBalance,
    required this.onSendGift,
  });

  @override
  State<_GiftsTab> createState() => _GiftsTabState();
}

class _GiftsTabState extends State<_GiftsTab> {
  int _selectedAmount = 50;
  final _receiverController = TextEditingController();
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _pendingGifts = [];

  @override
  void initState() {
    super.initState();
    _loadPendingGifts();
  }

  Future<void> _loadPendingGifts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('coinGifts')
          .where('receiverId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('sentAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _pendingGifts = snapshot.docs
              .map((doc) => {...doc.data(), 'giftId': doc.id})
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading gifts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Pending gifts to receive
        if (_pendingGifts.isNotEmpty) ...[
          const Text(
            'Pending Gifts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ..._pendingGifts.map((gift) => _PendingGiftCard(
                gift: gift,
                onAccept: () => _acceptGift(gift),
                onDecline: () => _declineGift(gift),
              )),
          const SizedBox(height: 24),
        ],

        // Send gift section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.pinkAccent, Colors.pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.card_giftcard, size: 48, color: Colors.white),
              const SizedBox(height: 8),
              const Text(
                'Send Gift',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Share coins with someone special',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Amount selection
        const Text(
          'Select Amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CoinGiftConstraints.suggestedAmounts.map((amount) {
            final isSelected = _selectedAmount == amount;
            return ChoiceChip(
              label: Text('$amount'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedAmount = amount);
              },
              selectedColor: AppColors.richGold,
              backgroundColor: AppColors.backgroundCard,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Receiver input (simplified - in production, use user search)
        TextField(
          controller: _receiverController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Receiver User ID',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.backgroundCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.person, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 12),

        // Message input
        TextField(
          controller: _messageController,
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Message (optional)',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.backgroundCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.message, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 16),

        // Send button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: widget.coinBalance >= _selectedAmount
                ? () {
                    final receiverId = _receiverController.text.trim();
                    if (receiverId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter receiver ID')),
                      );
                      return;
                    }
                    widget.onSendGift(
                      receiverId,
                      _selectedAmount,
                      _messageController.text.trim().isEmpty
                          ? null
                          : _messageController.text.trim(),
                    );
                  }
                : null,
            child: Text(
              'Send $_selectedAmount Coins',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _acceptGift(Map<String, dynamic> gift) async {
    try {
      await FirebaseFirestore.instance
          .collection('coinGifts')
          .doc(gift['giftId'])
          .update({
        'status': 'accepted',
        'receivedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('coinBalances')
          .doc(widget.userId)
          .set({
        'userId': widget.userId,
        'totalCoins': FieldValue.increment(gift['amount']),
        'giftedCoins': FieldValue.increment(gift['amount']),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _loadPendingGifts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accepted ${gift['amount']} coins!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _declineGift(Map<String, dynamic> gift) async {
    try {
      await FirebaseFirestore.instance
          .collection('coinGifts')
          .doc(gift['giftId'])
          .update({'status': 'declined'});

      // Refund sender
      await FirebaseFirestore.instance
          .collection('coinBalances')
          .doc(gift['senderId'])
          .update({
        'totalCoins': FieldValue.increment(gift['amount']),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await _loadPendingGifts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gift declined'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

/// Pending Gift Card
class _PendingGiftCard extends StatelessWidget {
  final Map<String, dynamic> gift;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _PendingGiftCard({
    required this.gift,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.backgroundCard,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard, color: Colors.pinkAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${gift['amount']} Coins',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (gift['message'] != null)
                    Text(
                      gift['message'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: onAccept,
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: onDecline,
            ),
          ],
        ),
      ),
    );
  }
}

/// Transaction History Screen
class _TransactionHistoryScreen extends StatelessWidget {
  final String userId;

  const _TransactionHistoryScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Transaction History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No transactions yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                color: AppColors.backgroundCard,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    data['type'] == 'coins'
                        ? Icons.monetization_on
                        : Icons.videocam,
                    color: data['type'] == 'coins'
                        ? AppColors.richGold
                        : Colors.blueAccent,
                  ),
                  title: Text(
                    data['type'] == 'coins'
                        ? '${data['amount']} Coins'
                        : '${data['amount']} Video Minutes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '\$${(data['price'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: data['status'] == 'completed'
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      data['status'] ?? 'pending',
                      style: TextStyle(
                        color: data['status'] == 'completed'
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
