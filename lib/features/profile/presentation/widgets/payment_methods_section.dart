import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/payment_links.dart';
import '../../domain/pix_br_code.dart';

/// Brand icon/colour per provider (readable on the dark theme).
extension PaymentMethodStyle on PaymentMethod {
  IconData get icon {
    switch (this) {
      case PaymentMethod.pix:
        return Icons.pix;
      case PaymentMethod.paypal:
        return Icons.paypal;
      case PaymentMethod.cashApp:
        return Icons.attach_money;
      case PaymentMethod.wise:
        return Icons.currency_exchange;
      case PaymentMethod.kofi:
        return Icons.coffee;
      case PaymentMethod.stripe:
        return Icons.credit_card;
      case PaymentMethod.mercadoPago:
        return Icons.handshake;
      case PaymentMethod.picPay:
      case PaymentMethod.venmo:
      case PaymentMethod.revolut:
      case PaymentMethod.monzo:
        return Icons.account_balance_wallet;
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethod.pix:
        return const Color(0xFF32BCAD);
      case PaymentMethod.mercadoPago:
        return const Color(0xFF00B1EA);
      case PaymentMethod.picPay:
        return const Color(0xFF21C25E);
      case PaymentMethod.paypal:
        return const Color(0xFF3C8DFF);
      case PaymentMethod.venmo:
        return const Color(0xFF3D95CE);
      case PaymentMethod.cashApp:
        return const Color(0xFF00D64F);
      case PaymentMethod.revolut:
        return const Color(0xFF8E9BFF);
      case PaymentMethod.wise:
        return const Color(0xFF9FE870);
      case PaymentMethod.monzo:
        return const Color(0xFFFF4F40);
      case PaymentMethod.kofi:
        return const Color(0xFF29ABE0);
      case PaymentMethod.stripe:
        return const Color(0xFF8B85FF);
    }
  }
}

/// "Pay directly" section on someone's profile: one chip per provider they
/// listed. Tapping shows a disclaimer (GreenGo is not part of the payment),
/// then opens the provider's own link — which the OS routes to the provider's
/// app when installed — or, for Pix, a sheet with the key, a Copia e Cola
/// code and its QR to use in the payer's bank app.
class PaymentMethodsSection extends StatelessWidget {
  const PaymentMethodsSection({
    required this.links,
    required this.receiverName,
    this.receiverCity = '',
    super.key,
  });

  final PaymentLinks links;
  final String receiverName;
  final String receiverCity;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final method in links.methods)
          _PaymentChip(
            method: method,
            onTap: () => _onTap(context, method),
          ),
      ],
    );
  }

  Future<void> _onTap(BuildContext context, PaymentMethod method) async {
    final value = links.valueOf(method);
    if (value == null) return;
    final proceed = await _confirm(context, method);
    if (!proceed || !context.mounted) return;

    if (!method.opensLink) {
      await _showPixSheet(context, value);
      return;
    }
    final uri = Uri.tryParse(method.url(value));
    final opened = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showUserErrorMessage(
          context, AppLocalizations.of(context)!.couldNotOpenLink);
    }
  }

  Future<bool> _confirm(BuildContext context, PaymentMethod method) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.paymentDisclaimerTitle(receiverName),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.paymentDisclaimerBody(receiverName, method.label),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.paymentContinueTo(method.label),
              style: const TextStyle(
                  color: AppColors.richGold, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showPixSheet(BuildContext context, String pixKey) {
    final l10n = AppLocalizations.of(context)!;
    final code = pixCopiaECola(
      pixKey: pixKey,
      receiverName: receiverName,
      receiverCity: receiverCity,
    );

    Future<void> copy(BuildContext ctx, String text) async {
      await Clipboard.setData(ClipboardData(text: text));
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text(l10n.pixCopied)));
      }
    }

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(PaymentMethod.pix.icon, color: PaymentMethod.pix.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.paymentDisclaimerTitle(receiverName),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: QrImageView(data: code, size: 200),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.pixInstructions,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                '${l10n.pixKeyLabel}: $pixKey',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PaymentMethod.pix.color,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => copy(ctx, code),
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.pixCopyCode),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PaymentMethod.pix.color,
                    side: BorderSide(color: PaymentMethod.pix.color),
                  ),
                  onPressed: () => copy(ctx, pixKey),
                  icon: const Icon(Icons.key),
                  label: Text(l10n.pixCopyKey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({required this.method, required this.onTap});

  final PaymentMethod method;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = method.color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(method.icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                method.label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
