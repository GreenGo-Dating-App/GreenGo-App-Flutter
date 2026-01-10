import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/coupon_code.dart';
import '../../data/models/coupon_code_model.dart';
import '../../data/models/membership_model.dart';
import '../../data/datasources/membership_remote_datasource.dart';

class MembershipAdminScreen extends StatefulWidget {
  final String adminId;

  const MembershipAdminScreen({
    super.key,
    required this.adminId,
  });

  @override
  State<MembershipAdminScreen> createState() => _MembershipAdminScreenState();
}

class _MembershipAdminScreenState extends State<MembershipAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MembershipRemoteDataSourceImpl _dataSource;

  List<CouponCodeModel> _couponCodes = [];
  Map<MembershipTier, MembershipRulesModel?> _tierRules = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _dataSource = MembershipRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final coupons = await _dataSource.getAllCouponCodes();

      // Load tier rules
      final Map<MembershipTier, MembershipRulesModel?> rules = {};
      for (final tier in MembershipTier.values) {
        rules[tier] = await _dataSource.getTierRulesConfig(tier);
      }

      if (mounted) {
        setState(() {
          _couponCodes = coupons;
          _tierRules = rules;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
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
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Membership Management',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Coupons (${_couponCodes.length})'),
            const Tab(text: 'Tier Rules'),
            const Tab(text: 'Redemptions'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCouponsTab(),
                _buildTierRulesTab(),
                _buildRedemptionsTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showCreateCouponDialog,
              backgroundColor: AppColors.richGold,
              child: const Icon(Icons.add, color: AppColors.deepBlack),
            )
          : null,
    );
  }

  Widget _buildCouponsTab() {
    if (_couponCodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.card_giftcard,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No coupon codes yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCreateCouponDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Coupon'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.richGold,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _couponCodes.length,
        itemBuilder: (context, index) {
          return _buildCouponCard(_couponCodes[index]);
        },
      ),
    );
  }

  Widget _buildCouponCard(CouponCodeModel coupon) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final isExpired = coupon.validUntil != null &&
        DateTime.now().isAfter(coupon.validUntil!);
    final isMaxedOut = coupon.maxUses != null &&
        coupon.currentUses >= coupon.maxUses!;

    Color statusColor = AppColors.successGreen;
    String statusText = 'Active';

    if (!coupon.isActive) {
      statusColor = AppColors.textSecondary;
      statusText = 'Inactive';
    } else if (isExpired) {
      statusColor = AppColors.errorRed;
      statusText = 'Expired';
    } else if (isMaxedOut) {
      statusColor = Colors.orange;
      statusText = 'Maxed Out';
    }

    return Card(
      color: AppColors.backgroundCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getTierColor(coupon.tier).withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        coupon.code,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTierColor(coupon.tier).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        coupon.tier.displayName,
                        style: TextStyle(
                          color: _getTierColor(coupon.tier),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (coupon.name.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                coupon.name,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                _buildStatItem(
                  icon: Icons.people,
                  label: 'Uses',
                  value: coupon.maxUses != null
                      ? '${coupon.currentUses}/${coupon.maxUses}'
                      : '${coupon.currentUses}/∞',
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  icon: Icons.access_time,
                  label: 'Duration',
                  value: coupon.durationDays != null
                      ? '${coupon.durationDays} days'
                      : 'Lifetime',
                ),
                const SizedBox(width: 16),
                if (coupon.validUntil != null)
                  _buildStatItem(
                    icon: Icons.event,
                    label: 'Expires',
                    value: dateFormatter.format(coupon.validUntil!),
                  ),
              ],
            ),

            if (coupon.notes != null && coupon.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${coupon.notes}',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showRedemptionsForCoupon(coupon.code),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('History'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showEditCouponDialog(coupon),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.richGold,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDeleteCoupon(coupon),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTierRulesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: MembershipTier.values.map((tier) {
        return _buildTierRulesCard(tier);
      }).toList(),
    );
  }

  Widget _buildTierRulesCard(MembershipTier tier) {
    final rules = _tierRules[tier] ?? MembershipRulesModel.fromEntity(MembershipRules.getDefaultsForTier(tier));

    return Card(
      color: AppColors.backgroundCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getTierColor(tier).withOpacity(0.5),
        ),
      ),
      child: ExpansionTile(
        leading: Icon(
          _getTierIcon(tier),
          color: _getTierColor(tier),
        ),
        title: Text(
          tier.displayName,
          style: TextStyle(
            color: _getTierColor(tier),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _tierRules[tier] != null ? 'Custom rules' : 'Default rules',
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColors.richGold),
          onPressed: () => _showEditTierRulesDialog(tier, rules),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRuleRow('Daily Messages',
                    rules.dailyMessageLimit == -1 ? 'Unlimited' : '${rules.dailyMessageLimit}'),
                _buildRuleRow('Daily Swipes',
                    rules.dailySwipeLimit == -1 ? 'Unlimited' : '${rules.dailySwipeLimit}'),
                _buildRuleRow('Super Likes/Day',
                    rules.dailySuperLikeLimit == -1 ? 'Unlimited' : '${rules.dailySuperLikeLimit}'),
                _buildRuleRow('Monthly Boosts', '${rules.monthlyFreeBoosts}'),
                _buildRuleRow('See Who Liked', rules.canSeeWhoLiked ? 'Yes' : 'No'),
                _buildRuleRow('Advanced Filters', rules.canUseAdvancedFilters ? 'Yes' : 'No'),
                _buildRuleRow('Match Priority', '${rules.matchPriority}'),
                _buildRuleRow('Read Receipts', rules.canSeeReadReceipts ? 'Yes' : 'No'),
                _buildRuleRow('Profile Boost', rules.canBoostProfile ? 'Yes' : 'No'),
                _buildRuleRow('Undo Last Swipe', rules.canUndoSwipe ? 'Yes' : 'No'),
                _buildRuleRow('Send Media', rules.canSendMedia ? 'Yes' : 'No'),
                _buildRuleRow('Incognito Mode', rules.canUseIncognitoMode ? 'Yes' : 'No'),
                _buildRuleRow('Profile Visitors', rules.canSeeProfileVisitors ? 'Yes' : 'No'),
                _buildRuleRow('Video Chat', rules.canUseVideoChat ? 'Yes' : 'No'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: value == 'Yes' || value == 'Unlimited'
                  ? AppColors.successGreen
                  : value == 'No'
                      ? AppColors.textTertiary
                      : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionsTab() {
    return FutureBuilder<List<CouponRedemptionModel>>(
      future: _loadAllRedemptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.richGold),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: AppColors.errorRed),
            ),
          );
        }

        final redemptions = snapshot.data ?? [];

        if (redemptions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                SizedBox(height: 16),
                Text(
                  'No redemptions yet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: redemptions.length,
          itemBuilder: (context, index) {
            return _buildRedemptionCard(redemptions[index]);
          },
        );
      },
    );
  }

  Future<List<CouponRedemptionModel>> _loadAllRedemptions() async {
    final List<CouponRedemptionModel> allRedemptions = [];
    for (final coupon in _couponCodes) {
      final redemptions = await _dataSource.getCouponRedemptions(coupon.code);
      allRedemptions.addAll(redemptions);
    }
    allRedemptions.sort((a, b) => b.redeemedAt.compareTo(a.redeemedAt));
    return allRedemptions;
  }

  Widget _buildRedemptionCard(CouponRedemptionModel redemption) {
    final dateFormatter = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      color: AppColors.backgroundCard,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.richGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.redeem,
            color: AppColors.richGold,
          ),
        ),
        title: Text(
          'Code: ${redemption.couponCode}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User: ${redemption.userId.substring(0, 8)}...',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              dateFormatter.format(redemption.redeemedAt),
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCouponDialog() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final maxUsesController = TextEditingController();
    final durationController = TextEditingController();
    final notesController = TextEditingController();
    MembershipTier selectedTier = MembershipTier.silver;
    DateTime? validUntil;
    bool isActive = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text(
            'Create Coupon Code',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Coupon Code *',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintText: 'e.g., GOLD2024',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Name/Description',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MembershipTier>(
                  value: selectedTier,
                  dropdownColor: AppColors.backgroundCard,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Membership Tier *',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  items: MembershipTier.values.where((t) => t != MembershipTier.free).map((tier) {
                    return DropdownMenuItem(
                      value: tier,
                      child: Text(tier.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedTier = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Duration (days)',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintText: 'Leave empty for lifetime',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxUsesController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Max Uses',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintText: 'Leave empty for unlimited',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Valid Until',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  subtitle: Text(
                    validUntil != null
                        ? DateFormat('MMM dd, yyyy').format(validUntil!)
                        : 'No expiration',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today, color: AppColors.richGold),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (date != null) {
                        setDialogState(() => validUntil = date);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text(
                    'Active',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  value: isActive,
                  activeColor: AppColors.richGold,
                  onChanged: (value) {
                    setDialogState(() => isActive = value);
                  },
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
              onPressed: () async {
                if (codeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a coupon code'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                  return;
                }

                try {
                  final coupon = CouponCodeModel(
                    code: codeController.text.trim().toUpperCase(),
                    name: nameController.text.trim(),
                    tier: selectedTier,
                    durationDays: durationController.text.isNotEmpty
                        ? int.tryParse(durationController.text)
                        : null,
                    maxUses: maxUsesController.text.isNotEmpty
                        ? int.tryParse(maxUsesController.text)
                        : null,
                    currentUses: 0,
                    validFrom: DateTime.now(),
                    validUntil: validUntil,
                    isActive: isActive,
                    createdBy: widget.adminId,
                    createdAt: DateTime.now(),
                    notes: notesController.text.trim().isNotEmpty
                        ? notesController.text.trim()
                        : null,
                  );

                  await _dataSource.createCouponCode(coupon);
                  Navigator.pop(context);
                  _loadData();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Coupon created successfully'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCouponDialog(CouponCodeModel coupon) {
    final nameController = TextEditingController(text: coupon.name);
    final maxUsesController = TextEditingController(
      text: coupon.maxUses?.toString() ?? '',
    );
    final notesController = TextEditingController(text: coupon.notes ?? '');
    bool isActive = coupon.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: Text(
            'Edit: ${coupon.code}',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Name/Description',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxUsesController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Max Uses',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintText: 'Leave empty for unlimited',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text(
                    'Active',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  value: isActive,
                  activeColor: AppColors.richGold,
                  onChanged: (value) {
                    setDialogState(() => isActive = value);
                  },
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
              onPressed: () async {
                try {
                  final updatedCoupon = CouponCodeModel(
                    code: coupon.code,
                    name: nameController.text.trim(),
                    tier: coupon.tier,
                    durationDays: coupon.durationDays,
                    maxUses: maxUsesController.text.isNotEmpty
                        ? int.tryParse(maxUsesController.text)
                        : null,
                    currentUses: coupon.currentUses,
                    validFrom: coupon.validFrom,
                    validUntil: coupon.validUntil,
                    isActive: isActive,
                    customRules: coupon.customRules,
                    createdBy: coupon.createdBy,
                    createdAt: coupon.createdAt,
                    notes: notesController.text.trim().isNotEmpty
                        ? notesController.text.trim()
                        : null,
                  );

                  await _dataSource.updateCouponCode(updatedCoupon);
                  Navigator.pop(context);
                  _loadData();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Coupon updated successfully'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTierRulesDialog(MembershipTier tier, MembershipRulesModel rules) {
    final dailyMessagesController = TextEditingController(
      text: rules.dailyMessageLimit == -1 ? '' : rules.dailyMessageLimit.toString(),
    );
    final dailySwipesController = TextEditingController(
      text: rules.dailySwipeLimit == -1 ? '' : rules.dailySwipeLimit.toString(),
    );
    final superLikesController = TextEditingController(
      text: rules.dailySuperLikeLimit == -1 ? '' : rules.dailySuperLikeLimit.toString(),
    );
    final monthlyBoostsController = TextEditingController(
      text: rules.monthlyFreeBoosts.toString(),
    );

    bool canSeeWhoLiked = rules.canSeeWhoLiked;
    bool canUseAdvancedFilters = rules.canUseAdvancedFilters;
    bool canBoostProfile = rules.canBoostProfile;
    bool canSeeReadReceipts = rules.canSeeReadReceipts;
    bool canUndoSwipe = rules.canUndoSwipe;
    bool canSendMedia = rules.canSendMedia;
    bool canUseIncognitoMode = rules.canUseIncognitoMode;
    bool canSeeProfileVisitors = rules.canSeeProfileVisitors;
    bool canUseVideoChat = rules.canUseVideoChat;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: Text(
            'Edit ${tier.displayName} Rules',
            style: TextStyle(color: _getTierColor(tier)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: dailyMessagesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Daily Messages (empty = unlimited)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dailySwipesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Daily Swipes (empty = unlimited)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: superLikesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Super Likes/Day (empty = unlimited)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: monthlyBoostsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Monthly Free Boosts',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Divider(height: 24),
                  _buildSwitchTile('See Who Liked', canSeeWhoLiked, (v) {
                    setDialogState(() => canSeeWhoLiked = v);
                  }),
                  _buildSwitchTile('Advanced Filters', canUseAdvancedFilters, (v) {
                    setDialogState(() => canUseAdvancedFilters = v);
                  }),
                  _buildSwitchTile('Profile Boost', canBoostProfile, (v) {
                    setDialogState(() => canBoostProfile = v);
                  }),
                  _buildSwitchTile('Read Receipts', canSeeReadReceipts, (v) {
                    setDialogState(() => canSeeReadReceipts = v);
                  }),
                  _buildSwitchTile('Undo Last Swipe', canUndoSwipe, (v) {
                    setDialogState(() => canUndoSwipe = v);
                  }),
                  _buildSwitchTile('Send Media', canSendMedia, (v) {
                    setDialogState(() => canSendMedia = v);
                  }),
                  _buildSwitchTile('Incognito Mode', canUseIncognitoMode, (v) {
                    setDialogState(() => canUseIncognitoMode = v);
                  }),
                  _buildSwitchTile('Profile Visitors', canSeeProfileVisitors, (v) {
                    setDialogState(() => canSeeProfileVisitors = v);
                  }),
                  _buildSwitchTile('Video Chat', canUseVideoChat, (v) {
                    setDialogState(() => canUseVideoChat = v);
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final newRules = MembershipRulesModel(
                    dailyMessageLimit: dailyMessagesController.text.isNotEmpty
                        ? int.tryParse(dailyMessagesController.text) ?? 10
                        : -1,
                    dailySwipeLimit: dailySwipesController.text.isNotEmpty
                        ? int.tryParse(dailySwipesController.text) ?? 20
                        : -1,
                    dailySuperLikeLimit: superLikesController.text.isNotEmpty
                        ? int.tryParse(superLikesController.text) ?? 0
                        : -1,
                    monthlyFreeBoosts: int.tryParse(monthlyBoostsController.text) ?? 0,
                    canSeeWhoLiked: canSeeWhoLiked,
                    canUseAdvancedFilters: canUseAdvancedFilters,
                    canBoostProfile: canBoostProfile,
                    canSeeReadReceipts: canSeeReadReceipts,
                    canUndoSwipe: canUndoSwipe,
                    canSendMedia: canSendMedia,
                    canUseIncognitoMode: canUseIncognitoMode,
                    canSeeProfileVisitors: canSeeProfileVisitors,
                    canUseVideoChat: canUseVideoChat,
                  );

                  await _dataSource.updateTierRulesConfig(tier, newRules);
                  Navigator.pop(context);
                  _loadData();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${tier.displayName} rules updated'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      value: value,
      activeColor: AppColors.richGold,
      dense: true,
      onChanged: onChanged,
    );
  }

  void _showRedemptionsForCoupon(String couponCode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      ),
    );

    try {
      final redemptions = await _dataSource.getCouponRedemptions(couponCode);
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: Text(
            'Redemptions: $couponCode',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: redemptions.isEmpty
                ? const Center(
                    child: Text(
                      'No redemptions yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: redemptions.length,
                    itemBuilder: (context, index) {
                      return _buildRedemptionCard(redemptions[index]);
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _confirmDeleteCoupon(CouponCodeModel coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Delete Coupon',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete coupon "${coupon.code}"?\n\nThis action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _dataSource.deleteCouponCode(coupon.code);
                Navigator.pop(context);
                _loadData();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Coupon deleted'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
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

  Color _getTierColor(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return AppColors.textSecondary;
      case MembershipTier.silver:
        return Colors.grey[400]!;
      case MembershipTier.gold:
        return AppColors.richGold;
      case MembershipTier.platinum:
        return Colors.blueGrey[300]!;
    }
  }

  IconData _getTierIcon(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return Icons.person_outline;
      case MembershipTier.silver:
        return Icons.star_half;
      case MembershipTier.gold:
        return Icons.star;
      case MembershipTier.platinum:
        return Icons.workspace_premium;
    }
  }
}
