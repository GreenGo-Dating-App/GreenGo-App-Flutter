import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../main/presentation/screens/main_navigation_screen.dart';

/// Screen shown after Stripe payment redirect.
/// Polls Firestore for the stripe_orders document to verify payment.
class PaymentResultScreen extends StatefulWidget {
  final bool success;
  final String? productId;

  const PaymentResultScreen({
    super.key,
    required this.success,
    this.productId,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  bool _verified = false;
  bool _verifying = true;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    if (widget.success) {
      _verifyPayment();
    } else {
      setState(() => _verifying = false);
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  Future<void> _verifyPayment() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _verifying = false;
        _verified = false;
      });
      return;
    }

    // Poll Firestore for up to 15 seconds to find the completed order
    int attempts = 0;
    while (attempts < 15 && mounted) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('stripe_orders')
            .where('userId', isEqualTo: uid)
            .where('status', isEqualTo: 'completed')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final order = query.docs.first.data();
          final createdAt = order['createdAt'] as Timestamp?;
          if (createdAt != null) {
            final age = DateTime.now().difference(createdAt.toDate());
            // Order was created within the last 5 minutes
            if (age.inMinutes < 5) {
              if (mounted) {
                setState(() {
                  _verified = true;
                  _verifying = false;
                });
              }
              return;
            }
          }
        }
      } catch (_) {}

      attempts++;
      await Future.delayed(const Duration(seconds: 1));
    }

    if (mounted) {
      setState(() {
        _verified = false;
        _verifying = false;
      });
    }
  }

  void _goHome() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainNavigationScreen(userId: uid),
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_verifying) ...[
                const CircularProgressIndicator(color: AppColors.richGold),
                const SizedBox(height: 24),
                Text(
                  l10n?.paymentVerifying ?? 'Verifying your payment...',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else if (widget.success && _verified) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 24),
                Text(
                  l10n?.paymentSuccess ?? 'Payment Successful!',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.paymentSuccessMessage ?? 'Your purchase has been credited to your account.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else if (widget.success && !_verified) ...[
                const Icon(Icons.hourglass_bottom, color: AppColors.richGold, size: 80),
                const SizedBox(height: 24),
                Text(
                  l10n?.paymentPending ?? 'Payment Processing',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.paymentPendingMessage ?? 'Your payment is being processed. It may take a few minutes to appear.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const Icon(Icons.cancel, color: AppColors.errorRed, size: 80),
                const SizedBox(height: 24),
                Text(
                  l10n?.paymentCancelled ?? 'Payment Cancelled',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.paymentCancelledMessage ?? 'Your payment was cancelled. No charges were made.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              if (!_verifying)
                ElevatedButton(
                  onPressed: _goHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n?.continueToApp ?? 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
