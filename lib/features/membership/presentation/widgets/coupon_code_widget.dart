import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/membership.dart';
import '../../data/datasources/membership_remote_datasource.dart';

class CouponCodeWidget extends StatefulWidget {
  final String userId;
  final MembershipTier currentTier;
  final DateTime? membershipEndDate;
  final VoidCallback? onRedemptionSuccess;

  const CouponCodeWidget({
    super.key,
    required this.userId,
    required this.currentTier,
    this.membershipEndDate,
    this.onRedemptionSuccess,
  });

  @override
  State<CouponCodeWidget> createState() => _CouponCodeWidgetState();
}

class _CouponCodeWidgetState extends State<CouponCodeWidget> {
  final TextEditingController _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final MembershipRemoteDataSourceImpl _dataSource;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _dataSource = MembershipRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeemCoupon() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final membership = await _dataSource.redeemCouponCode(
        userId: widget.userId,
        couponCode: _codeController.text.trim(),
      );

      setState(() {
        _successMessage = 'Congratulations! You are now a ${membership.tier.displayName} member!';
        _codeController.clear();
      });

      widget.onRedemptionSuccess?.call();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: AppColors.richGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Redeem Coupon Code',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Enter your coupon code to upgrade',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Current membership info
          _buildCurrentMembershipInfo(),

          const SizedBox(height: 20),

          // Coupon input form
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _codeController,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code',
                    hintStyle: const TextStyle(
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.richGold,
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.confirmation_number_outlined,
                      color: AppColors.textTertiary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a coupon code';
                    }
                    if (value.trim().length < 4) {
                      return 'Coupon code is too short';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.errorRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.errorRed,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Success message
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.successGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(
                              color: AppColors.successGreen,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_errorMessage != null || _successMessage != null)
                  const SizedBox(height: 16),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _redeemCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: AppColors.richGold.withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.deepBlack,
                              ),
                            ),
                          )
                        : const Text(
                            'Redeem Coupon',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMembershipInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getMembershipColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getMembershipColor().withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getMembershipIcon(),
            color: _getMembershipColor(),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current: ${widget.currentTier.displayName}',
                  style: TextStyle(
                    color: _getMembershipColor(),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.membershipEndDate != null)
                  Text(
                    'Expires: ${_formatDate(widget.membershipEndDate!)}',
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
    );
  }

  Color _getMembershipColor() {
    switch (widget.currentTier) {
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

  IconData _getMembershipIcon() {
    switch (widget.currentTier) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
