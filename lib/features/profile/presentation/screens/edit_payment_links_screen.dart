import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../core/widgets/action_success_dialog.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/payment_links.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/payment_methods_section.dart';

/// Lets a user list their OWN external payment methods (Pix, PayPal, …) so
/// others can pay them directly. GreenGo stores only the handle/key/link.
class EditPaymentLinksScreen extends StatefulWidget {
  const EditPaymentLinksScreen({
    required this.profile,
    super.key,
  });
  final Profile profile;

  @override
  State<EditPaymentLinksScreen> createState() => _EditPaymentLinksScreenState();
}

class _EditPaymentLinksScreenState extends State<EditPaymentLinksScreen> {
  late final Map<PaymentMethod, TextEditingController> _controllers = {
    for (final m in PaymentMethod.values)
      m: TextEditingController(
          text: widget.profile.paymentLinks?.valueOf(m) ?? ''),
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
    final original = widget.profile.paymentLinks;
    final hasChanges = PaymentMethod.values.any(
      (m) => _controllers[m]!.text.trim() != (original?.valueOf(m) ?? ''),
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

  void _save() {
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
    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(
            profile: widget.profile.copyWith(
              paymentLinks: PaymentLinks(values),
              updatedAt: DateTime.now(),
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) async {
        if (!_isSaving) return;
        if (state is ProfileUpdated) {
          await ActionSuccessDialog.showPaymentLinksUpdated(context);
          if (context.mounted) Navigator.of(context).pop(state.profile);
        } else if (state is ProfileError) {
          setState(() => _isSaving = false);
          showUserError(context, state.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => SafeNavigation.pop(context),
            ),
            title: Text(
              l10n.paymentLinksTitle,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            actions: [
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.richGold),
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: _hasChanges ? _save : null,
                  child: Text(
                    l10n.save,
                    style: TextStyle(
                      color: _hasChanges
                          ? AppColors.richGold
                          : AppColors.textTertiary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoCard(
                  icon: Icons.payments,
                  color: AppColors.richGold,
                  title: l10n.paymentLinksInfoTitle,
                  body: l10n.paymentLinksInfoBody,
                ),
                const SizedBox(height: 24),
                for (final m in PaymentMethod.values)
                  _buildInput(
                    controller: _controllers[m]!,
                    method: m,
                    hint: _hint(l10n, m),
                  ),
                const SizedBox(height: 8),
                _InfoCard(
                  icon: Icons.info_outline,
                  color: AppColors.textSecondary,
                  body: l10n.paymentLinksRules,
                ),
              ],
            ),
          ),
        );
      },
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
        keyboardType: method.opensLink
            ? TextInputType.url
            : TextInputType.emailAddress,
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
