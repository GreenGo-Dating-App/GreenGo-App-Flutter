import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/payment_links.dart';
import 'payment_methods_section.dart';

/// Inline editor for the user's OWN external payment methods (Pix, PayPal, …)
/// so others can pay them directly; also the methods offered for manually
/// confirmed tickets. GreenGo stores only the handle/key/link.
///
/// Embedded in Settings > Get paid (one page for every way to get paid).
/// [onSave] persists the normalized links and returns whether it succeeded.
class PaymentMethodsEditor extends StatefulWidget {
  const PaymentMethodsEditor({
    required this.initial,
    required this.onSave,
    super.key,
  });

  final PaymentLinks? initial;
  final Future<bool> Function(PaymentLinks links) onSave;

  @override
  State<PaymentMethodsEditor> createState() => _PaymentMethodsEditorState();
}

class _PaymentMethodsEditorState extends State<PaymentMethodsEditor> {
  late PaymentLinks? _saved = widget.initial;
  late final Map<PaymentMethod, TextEditingController> _controllers = {
    for (final m in PaymentMethod.values)
      m: TextEditingController(text: widget.initial?.valueOf(m) ?? ''),
  };

  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final c in _controllers.values) {
      c.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c
        ..removeListener(_onFieldChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() {
    final hasChanges = PaymentMethod.values.any(
      (m) => _controllers[m]!.text.trim() != (_saved?.valueOf(m) ?? ''),
    );
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  String _hint(AppLocalizations l10n, PaymentMethod m) {
    switch (m) {
      case PaymentMethod.pix:
        return l10n.paymentLinksHintPix;
      case PaymentMethod.mercadoPago:
      case PaymentMethod.stripe:
        return l10n.paymentLinksHintLink;
      default:
        return l10n.paymentLinksHintHandle;
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;

    final values = <PaymentMethod, String>{};
    for (final m in PaymentMethod.values) {
      final raw = _controllers[m]!.text.trim();
      if (raw.isEmpty) continue;
      final normalized = m.normalize(raw);
      if (normalized == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.paymentLinkInvalid(m.label)),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }
      values[m] = normalized;
    }

    setState(() => _isSaving = true);
    final links = PaymentLinks(values);
    final ok = await widget.onSave(links);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (ok) {
        _saved = links;
        _hasChanges = false;
        for (final m in PaymentMethod.values) {
          final v = links.valueOf(m) ?? '';
          if (_controllers[m]!.text != v) _controllers[m]!.text = v;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoCard(
          icon: Icons.payments,
          color: AppColors.richGold,
          title: l10n.paymentLinksInfoTitle,
          body: l10n.paymentLinksInfoBody,
        ),
        const SizedBox(height: 16),
        for (final m in PaymentMethod.values)
          _buildInput(
            controller: _controllers[m]!,
            method: m,
            hint: _hint(l10n, m),
          ),
        _InfoCard(
          icon: Icons.info_outline,
          color: AppColors.textSecondary,
          body: l10n.paymentLinksRules,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const ValueKey('payment-methods-save'),
            onPressed: _hasChanges && !_isSaving ? _save : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.backgroundDark,
              disabledBackgroundColor: AppColors.backgroundCard,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(l10n.save),
          ),
        ),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required PaymentMethod method,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType:
            method.opensLink ? TextInputType.url : TextInputType.emailAddress,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText: method.label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textTertiary),
          filled: true,
          fillColor: AppColors.backgroundCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: BorderSide(color: method.color, width: 2),
          ),
          prefixIcon: Icon(method.icon, color: method.color),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.body,
    this.title,
  });

  final IconData icon;
  final Color color;
  final String? title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
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
