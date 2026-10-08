import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/user_experience.dart';
import '../experience_l10n.dart';

/// Guest consent before paying a host: GreenGo does not process, guarantee or
/// refund the payment. Shows the cancellation policy summary and
/// method-specific guidance (PIX MED, PayPal Goods & Services, card disputes,
/// cash precautions). When the listing accepts both cash and the link, the
/// guest picks one here. Returns the chosen method, or null when cancelled.
///
/// Text version recorded with the consent: [version]. Bump it when the
/// wording changes materially (LEGAL TEXT: DRAFT FOR LAWYER REVIEW).
class BookingConsentDialog extends StatefulWidget {
  const BookingConsentDialog({super.key, required this.experience, this.only});

  final UserExperience experience;

  /// The method the guest already picked (booking flow): no choice shown.
  final PaymentMethod? only;

  static const int version = 1;

  static Future<PaymentMethod?> show(
          BuildContext context, UserExperience experience,
          {PaymentMethod? only}) =>
      showDialog<PaymentMethod>(
        context: context,
        builder: (_) => BookingConsentDialog(experience: experience, only: only),
      );

  /// Methods the guest can choose from, link first (pure, unit-tested).
  static List<PaymentMethod> methodsOf(UserExperience e) => [
        if (e.acceptsOnline) PaymentMethod.online,
        if (e.acceptsLink) PaymentMethod.link,
        if (e.acceptsCash) PaymentMethod.cash,
      ];

  /// Guidance lines for [method] (pure, unit-tested).
  static List<String> guidance(
      AppLocalizations l, UserExperience e, PaymentMethod method) {
    if (method == PaymentMethod.cash) return [l.uexpGuideCash];
    if (method == PaymentMethod.online) {
      return [e.paymentProvider == 'link' ? l.tpConsentGuideManual : l.tpConsentGuideInstant];
    }
    final type = e.paymentLink?.type ?? PaymentLinkType.other;
    return switch (type) {
      PaymentLinkType.pix => [l.uexpGuidePix],
      PaymentLinkType.paypal => [l.uexpGuidePaypal],
      PaymentLinkType.venmo => [l.uexpGuideVenmo],
      PaymentLinkType.stripe || PaymentLinkType.other => [l.uexpGuideCard],
    };
  }

  @override
  State<BookingConsentDialog> createState() => _BookingConsentDialogState();
}

class _BookingConsentDialogState extends State<BookingConsentDialog> {
  late final List<PaymentMethod> _methods = widget.only != null
      ? [widget.only!]
      : BookingConsentDialog.methodsOf(widget.experience);
  late PaymentMethod? _method = _methods.length == 1 ? _methods.first : null;
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final e = widget.experience;
    final m = _method;
    const body = TextStyle(
        color: AppColors.textSecondary, fontSize: 13, height: 1.4);
    return AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      icon: const Icon(Icons.shield_outlined,
          color: AppColors.richGold, size: 32),
      title: Text(l.uexpConsentTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_methods.length > 1) ...[
              Text(l.uexpConsentPickMethod,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 6, children: [
                for (final x in _methods)
                  ChoiceChip(
                    key: ValueKey('consent-method-${x.name}'),
                    selected: m == x,
                    onSelected: (_) => setState(() => _method = x),
                    avatar: Icon(ExperienceL10n.paymentMethodIcon(x),
                        size: 16),
                    label: Text(ExperienceL10n.paymentMethod(l, x)),
                  ),
              ]),
              const SizedBox(height: 12),
            ],
            if (m != null) ...[
              Text(
                m == PaymentMethod.cash
                    ? l.uexpConsentBodyCash
                    : l.uexpConsentBodyLink,
                style: body,
              ),
              const SizedBox(height: 10),
              for (final g in BookingConsentDialog.guidance(l, e, m))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.info_outline,
                            size: 15, color: AppColors.richGold),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(g, style: body)),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 4),
            Text(
              l.uexpConsentPolicy(
                  ExperienceL10n.policy(l, e.cancellationPolicy)),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(ExperienceL10n.policyDescription(l, e.cancellationPolicy),
                style: body),
            const SizedBox(height: 8),
            CheckboxListTile(
              key: const ValueKey('consent-understand'),
              value: _understood,
              onChanged: (v) => setState(() => _understood = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.richGold,
              title: Text(l.uexpConsentUnderstand,
                  style: const TextStyle(color: AppColors.textPrimary)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        ElevatedButton(
          key: const ValueKey('consent-continue'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.richGold,
            foregroundColor: AppColors.deepBlack,
            minimumSize: const Size(0, 40),
          ),
          onPressed: _understood && m != null
              ? () => Navigator.pop(context, m)
              : null,
          child: Text(l.uexpConsentContinue),
        ),
      ],
    );
  }
}
