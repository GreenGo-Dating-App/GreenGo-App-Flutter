import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../coins/domain/entities/coin_package.dart';
import '../../../coins/domain/entities/order.dart';
import '../../../coins/domain/entities/invoice.dart';
import '../../../coins/domain/entities/video_coin.dart';

/// Coin Management Screen
/// Admin interface for managing coin packages and user balances
class CoinManagementScreen extends StatefulWidget {
  final String adminId;

  const CoinManagementScreen({
    super.key,
    required this.adminId,
  });

  @override
  State<CoinManagementScreen> createState() => _CoinManagementScreenState();
}

class _CoinManagementScreenState extends State<CoinManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
          'Coin Management',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.textSecondary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Packages'),
            Tab(text: 'Video Coins'),
            Tab(text: 'User Balance'),
            Tab(text: 'Orders'),
            Tab(text: 'Invoices'),
            Tab(text: 'Spend Items'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PackagesTab(adminId: widget.adminId),
          _VideoCoinsTab(adminId: widget.adminId),
          _UserBalanceTab(adminId: widget.adminId),
          _OrdersTab(adminId: widget.adminId),
          _InvoicesTab(adminId: widget.adminId),
          _SpendItemsTab(adminId: widget.adminId),
        ],
      ),
    );
  }
}

/// Packages Tab - Manage coin packages
class _PackagesTab extends StatefulWidget {
  final String adminId;

  const _PackagesTab({required this.adminId});

  @override
  State<_PackagesTab> createState() => _PackagesTabState();
}

class _PackagesTabState extends State<_PackagesTab> {
  List<CoinPackage> _packages = CoinPackages.standardPackages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with add button
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Coin Packages',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddPackageDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Package'),
              ),
            ],
          ),
        ),

        // Packages list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
            ),
            itemCount: _packages.length,
            itemBuilder: (context, index) {
              final package = _packages[index];
              return _PackageCard(
                package: package,
                onEdit: () => _showEditPackageDialog(package),
                onDelete: () => _confirmDeletePackage(package),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddPackageDialog() {
    showDialog(
      context: context,
      builder: (context) => _PackageEditDialog(
        onSave: (package) {
          setState(() {
            _packages = [..._packages, package];
          });
        },
      ),
    );
  }

  void _showEditPackageDialog(CoinPackage package) {
    showDialog(
      context: context,
      builder: (context) => _PackageEditDialog(
        package: package,
        onSave: (updatedPackage) {
          setState(() {
            final index = _packages.indexWhere(
              (p) => p.packageId == package.packageId,
            );
            if (index != -1) {
              _packages = List.from(_packages)..[index] = updatedPackage;
            }
          });
        },
      ),
    );
  }

  void _confirmDeletePackage(CoinPackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Delete Package?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${package.coinAmount} Coins" package?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _packages = _packages
                    .where((p) => p.packageId != package.packageId)
                    .toList();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final CoinPackage package;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PackageCard({
    required this.package,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monetization_on,
                color: Colors.white,
              ),
            ),
            title: Text(
              '${package.coinAmount} Coins',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.displayPrice,
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (package.bonusCoins != null && package.bonusCoins! > 0)
                  Text(
                    '+${package.bonusCoins} bonus coins',
                    style: const TextStyle(
                      color: AppColors.successGreen,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${package.coinsPerDollar.toStringAsFixed(0)}/\$',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.textSecondary),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.errorRed),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          if (package.isPromotional)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              decoration: BoxDecoration(
                color: AppColors.warningAmber.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppDimensions.radiusM),
                  bottomRight: Radius.circular(AppDimensions.radiusM),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: AppColors.warningAmber,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    package.promotionLabel ?? 'Promotional',
                    style: const TextStyle(
                      color: AppColors.warningAmber,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PackageEditDialog extends StatefulWidget {
  final CoinPackage? package;
  final Function(CoinPackage) onSave;

  const _PackageEditDialog({
    this.package,
    required this.onSave,
  });

  @override
  State<_PackageEditDialog> createState() => _PackageEditDialogState();
}

class _PackageEditDialogState extends State<_PackageEditDialog> {
  late TextEditingController _coinsController;
  late TextEditingController _priceController;
  late TextEditingController _bonusController;
  late TextEditingController _productIdController;
  bool _isPromotional = false;

  @override
  void initState() {
    super.initState();
    _coinsController = TextEditingController(
      text: widget.package?.coinAmount.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.package?.price.toStringAsFixed(2) ?? '',
    );
    _bonusController = TextEditingController(
      text: widget.package?.bonusCoins?.toString() ?? '0',
    );
    _productIdController = TextEditingController(
      text: widget.package?.productId ?? '',
    );
    _isPromotional = widget.package?.isPromotional ?? false;
  }

  @override
  void dispose() {
    _coinsController.dispose();
    _priceController.dispose();
    _bonusController.dispose();
    _productIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: Text(
        widget.package == null ? 'Add Package' : 'Edit Package',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: _coinsController,
              label: 'Coin Amount',
              icon: Icons.monetization_on,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            _buildTextField(
              controller: _priceController,
              label: 'Price (USD)',
              icon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            _buildTextField(
              controller: _bonusController,
              label: 'Bonus Coins',
              icon: Icons.card_giftcard,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            _buildTextField(
              controller: _productIdController,
              label: 'Product ID (for IAP)',
              icon: Icons.inventory,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            SwitchListTile(
              title: const Text(
                'Promotional Package',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: _isPromotional,
              activeColor: AppColors.warningAmber,
              onChanged: (value) => setState(() => _isPromotional = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.richGold,
            foregroundColor: Colors.black,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.richGold),
        ),
      ),
    );
  }

  void _save() {
    final coins = int.tryParse(_coinsController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final bonus = int.tryParse(_bonusController.text) ?? 0;

    if (coins <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid coin amount and price'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final package = CoinPackage(
      packageId: widget.package?.packageId ?? 'pkg_${DateTime.now().millisecondsSinceEpoch}',
      productId: _productIdController.text.isNotEmpty
          ? _productIdController.text
          : 'greengo_coins_$coins',
      coinAmount: coins,
      price: price,
      bonusCoins: bonus > 0 ? bonus : null,
      isPromotional: _isPromotional,
    );

    widget.onSave(package);
    Navigator.pop(context);
  }
}

/// User Balance Tab - Adjust user coin balances
class _UserBalanceTab extends StatefulWidget {
  final String adminId;

  const _UserBalanceTab({required this.adminId});

  @override
  State<_UserBalanceTab> createState() => _UserBalanceTabState();
}

class _UserBalanceTabState extends State<_UserBalanceTab> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedUserId;
  int _currentBalance = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by user ID or email',
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _selectedUserId = null);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: const BorderSide(color: AppColors.richGold),
              ),
              filled: true,
              fillColor: AppColors.backgroundCard,
            ),
            onSubmitted: (value) {
              // TODO: Search for user
              setState(() {
                _selectedUserId = value;
                _currentBalance = 500; // Mock value
              });
            },
          ),
          const SizedBox(height: AppDimensions.paddingL),

          // User info and balance adjustment
          if (_selectedUserId != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.richGold.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: AppColors.richGold),
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User ID: $_selectedUserId',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'user@example.com',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: AppDimensions.paddingM),

                  // Current balance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Current Balance',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: AppColors.richGold,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currentBalance.toString(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingL),

                  // Adjustment buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAdjustmentDialog(isAdd: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Coins'),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAdjustmentDialog(isAdd: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.errorRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.remove),
                          label: const Text('Remove Coins'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Empty state
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 64,
                      color: AppColors.textTertiary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    const Text(
                      'Search for a user to manage their coin balance',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAdjustmentDialog({required bool isAdd}) {
    final controller = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          isAdd ? 'Add Coins' : 'Remove Coins',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: const TextStyle(color: AppColors.textTertiary),
                prefixIcon: const Icon(
                  Icons.monetization_on,
                  color: AppColors.richGold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Reason (required)',
                labelStyle: const TextStyle(color: AppColors.textTertiary),
                prefixIcon: const Icon(
                  Icons.notes,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
                return;
              }
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              setState(() {
                _currentBalance = isAdd
                    ? _currentBalance + amount
                    : (_currentBalance - amount).clamp(0, double.infinity).toInt();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAdd
                        ? 'Added $amount coins to user'
                        : 'Removed $amount coins from user',
                  ),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdd ? AppColors.successGreen : AppColors.errorRed,
            ),
            child: Text(isAdd ? 'Add' : 'Remove'),
          ),
        ],
      ),
    );
  }
}

/// Spend Items Tab - Configure what coins can be spent on
class _SpendItemsTab extends StatelessWidget {
  final String adminId;

  const _SpendItemsTab({required this.adminId});

  @override
  Widget build(BuildContext context) {
    final categories = CoinSpendCategory.values;

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final items = CoinSpendItems.getByCategory(category);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingS,
              ),
              child: Text(
                category.displayName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...items.map((item) => _SpendItemCard(item: item)),
            const SizedBox(height: AppDimensions.paddingM),
          ],
        );
      },
    );
  }
}

class _SpendItemCard extends StatelessWidget {
  final CoinSpendItem item;

  const _SpendItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: item.isActive ? AppColors.divider : AppColors.errorRed.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.richGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            _getIconForItem(item.itemId),
            color: AppColors.richGold,
          ),
        ),
        title: Row(
          children: [
            Text(
              item.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!item.isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Disabled',
                  style: TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          item.description,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.richGold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on,
                color: AppColors.richGold,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                item.coinCost.toString(),
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        onTap: () => _showEditDialog(context, item),
      ),
    );
  }

  IconData _getIconForItem(String itemId) {
    switch (itemId) {
      case 'super_like':
        return Icons.favorite;
      case 'profile_boost':
        return Icons.rocket_launch;
      case 'undo_swipe':
        return Icons.undo;
      case 'see_who_liked':
        return Icons.visibility;
      case 'read_receipts_day':
        return Icons.done_all;
      case 'gift_rose':
        return Icons.local_florist;
      case 'gift_teddy':
        return Icons.pets;
      case 'gift_diamond':
        return Icons.diamond;
      default:
        return Icons.stars;
    }
  }

  void _showEditDialog(BuildContext context, CoinSpendItem item) {
    final costController = TextEditingController(text: item.coinCost.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          'Edit ${item.name}',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Coin Cost',
                labelStyle: const TextStyle(color: AppColors.textTertiary),
                prefixIcon: const Icon(
                  Icons.monetization_on,
                  color: AppColors.richGold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Save changes to Firestore
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Changes saved'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Video Coins Tab - Manage video coin packages
class _VideoCoinsTab extends StatelessWidget {
  final String adminId;

  const _VideoCoinsTab({required this.adminId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      children: [
        const Text(
          'Video Coin Packages',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        ...VideoCoinPackages.all.map((pkg) => _VideoCoinPackageCard(package: pkg)),
        const SizedBox(height: AppDimensions.paddingL),
        const Text(
          'Statistics',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('videoCoinBalances')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            int totalMinutes = 0;
            int usedMinutes = 0;
            for (final doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              totalMinutes += (data['totalVideoCoins'] as num?)?.toInt() ?? 0;
              usedMinutes += (data['usedVideoCoins'] as num?)?.toInt() ?? 0;
            }
            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Minutes',
                    value: totalMinutes.toString(),
                    icon: Icons.videocam,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: _StatCard(
                    title: 'Used Minutes',
                    value: usedMinutes.toString(),
                    icon: Icons.phone_in_talk,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: _StatCard(
                    title: 'Available',
                    value: (totalMinutes - usedMinutes).toString(),
                    icon: Icons.timer,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _VideoCoinPackageCard extends StatelessWidget {
  final VideoCoinPackage package;

  const _VideoCoinPackageCard({required this.package});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: package.isPopular ? AppColors.richGold : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: const Icon(Icons.videocam, color: AppColors.richGold),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${package.videoMinutes} Minutes',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (package.bonusMinutes != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${package.bonusMinutes} bonus',
                          style: const TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  package.displayPrice,
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (package.badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warningAmber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                package.badge!,
                style: const TextStyle(
                  color: AppColors.warningAmber,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.richGold, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Orders Tab - View and manage orders
class _OrdersTab extends StatefulWidget {
  final String adminId;

  const _OrdersTab({required this.adminId});

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  OrderStatus? _filterStatus;
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search orders...',
                    hintStyle: const TextStyle(color: AppColors.textTertiary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundCard,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<OrderStatus?>(
                    value: _filterStatus,
                    hint: const Text(
                      'Status',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                    dropdownColor: AppColors.backgroundCard,
                    items: [
                      const DropdownMenuItem<OrderStatus?>(
                        value: null,
                        child: Text('All', style: TextStyle(color: AppColors.textPrimary)),
                      ),
                      ...OrderStatus.values.map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.displayName,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      )),
                    ],
                    onChanged: (value) => setState(() => _filterStatus = value),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Orders list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildOrdersQuery(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No orders found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _OrderCard(orderId: doc.id, data: data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _buildOrdersQuery() {
    Query query = FirebaseFirestore.instance
        .collection('coinOrders')
        .orderBy('createdAt', descending: true);

    if (_filterStatus != null) {
      query = query.where('status', isEqualTo: _filterStatus!.name);
    }

    return query.limit(50).snapshots();
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const _OrderCard({required this.orderId, required this.data});

  @override
  Widget build(BuildContext context) {
    final status = OrderStatus.values.firstWhere(
      (s) => s.name == data['status'],
      orElse: () => OrderStatus.pending,
    );
    final type = OrderType.values.firstWhere(
      (t) => t.name == data['type'],
      orElse: () => OrderType.coins,
    );
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final total = (data['total'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getStatusColor(status).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTypeIcon(type),
            color: _getStatusColor(status),
          ),
        ),
        title: Text(
          '${type.displayName} - \$${total.toStringAsFixed(2)}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User: ${(data['userId'] as String).substring(0, 8)}...',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            if (createdAt != null)
              Text(
                '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status.displayName,
            style: TextStyle(
              color: _getStatusColor(status),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => _showOrderDetails(context),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed:
        return AppColors.successGreen;
      case OrderStatus.failed:
      case OrderStatus.cancelled:
        return AppColors.errorRed;
      case OrderStatus.pending:
      case OrderStatus.processing:
        return AppColors.warningAmber;
      case OrderStatus.refunded:
        return AppColors.textSecondary;
    }
  }

  IconData _getTypeIcon(OrderType type) {
    switch (type) {
      case OrderType.coins:
        return Icons.monetization_on;
      case OrderType.videoCoins:
        return Icons.videocam;
      case OrderType.subscription:
        return Icons.star;
      case OrderType.gift:
        return Icons.card_giftcard;
    }
  }

  void _showOrderDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Order Details',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('Order ID', orderId.substring(0, 8)),
            _DetailRow('User ID', (data['userId'] as String).substring(0, 8)),
            _DetailRow('Type', (data['type'] ?? 'Unknown').toString()),
            _DetailRow('Status', (data['status'] ?? 'Unknown').toString()),
            _DetailRow('Amount', '\$${((data['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}'),
            _DetailRow('Payment', (data['paymentMethod'] ?? 'Unknown').toString()),
          ],
        ),
        actions: [
          if (data['status'] == 'completed')
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('coinOrders')
                    .doc(orderId)
                    .update({
                  'status': 'refunded',
                  'refundedAt': FieldValue.serverTimestamp(),
                  'refundReason': 'Admin refund',
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order refunded'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              },
              child: const Text('Refund', style: TextStyle(color: AppColors.errorRed)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

/// Invoices Tab - View and manage invoices
class _InvoicesTab extends StatefulWidget {
  final String adminId;

  const _InvoicesTab({required this.adminId});

  @override
  State<_InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<_InvoicesTab> {
  InvoiceStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Invoices',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<InvoiceStatus?>(
                    value: _filterStatus,
                    hint: const Text(
                      'Status',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                    dropdownColor: AppColors.backgroundCard,
                    items: [
                      const DropdownMenuItem<InvoiceStatus?>(
                        value: null,
                        child: Text('All', style: TextStyle(color: AppColors.textPrimary)),
                      ),
                      ...InvoiceStatus.values.map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.displayName,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      )),
                    ],
                    onChanged: (value) => setState(() => _filterStatus = value),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Invoices list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildInvoicesQuery(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No invoices found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _InvoiceCard(invoiceId: doc.id, data: data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _buildInvoicesQuery() {
    Query query = FirebaseFirestore.instance
        .collection('invoices')
        .orderBy('issueDate', descending: true);

    if (_filterStatus != null) {
      query = query.where('status', isEqualTo: _filterStatus!.name);
    }

    return query.limit(50).snapshots();
  }
}

class _InvoiceCard extends StatelessWidget {
  final String invoiceId;
  final Map<String, dynamic> data;

  const _InvoiceCard({required this.invoiceId, required this.data});

  @override
  Widget build(BuildContext context) {
    final status = InvoiceStatus.values.firstWhere(
      (s) => s.name == data['status'],
      orElse: () => InvoiceStatus.draft,
    );
    final issueDate = (data['issueDate'] as Timestamp?)?.toDate();
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final invoiceNumber = data['invoiceNumber'] as String? ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getStatusColor(status).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.receipt_long,
            color: _getStatusColor(status),
          ),
        ),
        title: Text(
          invoiceNumber,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.richGold,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (issueDate != null)
              Text(
                '${issueDate.day}/${issueDate.month}/${issueDate.year}',
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status.displayName,
            style: TextStyle(
              color: _getStatusColor(status),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return AppColors.successGreen;
      case InvoiceStatus.cancelled:
      case InvoiceStatus.overdue:
        return AppColors.errorRed;
      case InvoiceStatus.draft:
      case InvoiceStatus.issued:
        return AppColors.warningAmber;
      case InvoiceStatus.refunded:
        return AppColors.textSecondary;
    }
  }
}
