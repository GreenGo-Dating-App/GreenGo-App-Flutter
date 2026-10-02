import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/translatable_text.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/cancellation_rules.dart';
import '../../domain/entities/user_experience.dart';
import '../experience_l10n.dart';

/// "Cancellation policy" section of the detail page: the policy, a small
/// "if you cancel → refund" table, the universal rules every guest gets, and
/// the host's notes (auto-translated).
class CancellationPolicyCard extends StatelessWidget {
  const CancellationPolicyCard({
    super.key,
    required this.policy,
    this.notes,
    required this.targetLang,
  });

  final CancellationPolicy policy;
  final String? notes;
  final String targetLang;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const head = TextStyle(
        color: AppColors.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w600);
    const cell = TextStyle(color: AppColors.textPrimary, fontSize: 13);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.policy_outlined,
                size: 20, color: AppColors.richGold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l.uexpCancellationLabel,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            PolicyChip(policy: policy),
          ]),
          const SizedBox(height: 8),
          Text(ExperienceL10n.policyDescription(l, policy),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {1: IntrinsicColumnWidth()},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(children: [
                Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(l.uexpPolicyWhen, style: head)),
                Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 12),
                    child: Text(l.uexpPolicyRefund, style: head)),
              ]),
              for (final t in CancellationRules.tiers(policy))
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(ExperienceL10n.cancelWindow(l, t.window),
                        style: cell),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      ExperienceL10n.percent(context, t.refund),
                      style: cell.copyWith(
                          fontWeight: FontWeight.bold,
                          color: t.refund >= 1
                              ? AppColors.successGreen
                              : (t.refund > 0
                                  ? AppColors.warningAmber
                                  : AppColors.errorRed)),
                    ),
                  ),
                ]),
            ],
          ),
          const Divider(height: 24, color: AppColors.divider),
          Text(l.uexpPolicyAlwaysTitle, style: head),
          const SizedBox(height: 6),
          for (final rule in [
            l.uexpRuleHostCancels,
            l.uexpRuleGrace,
            l.uexpRuleReport,
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.shield_outlined,
                        size: 15, color: AppColors.richGold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(rule,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.35)),
                  ),
                ],
              ),
            ),
          if (notes != null && notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(l.uexpPolicyHostNotes, style: head),
            const SizedBox(height: 4),
            TranslatableText(
              text: notes!,
              autoTranslate: true,
              targetLang: targetLang,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small coloured label with the policy name.
class PolicyChip extends StatelessWidget {
  const PolicyChip({super.key, required this.policy});
  final CancellationPolicy policy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = switch (policy) {
      CancellationPolicy.flexible => AppColors.successGreen,
      CancellationPolicy.moderate => AppColors.warningAmber,
      CancellationPolicy.strict => AppColors.errorRed,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(ExperienceL10n.policy(l, policy),
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Editor picker: the three fixed policies with their one-line explanation.
class CancellationPolicyPicker extends StatelessWidget {
  const CancellationPolicyPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final CancellationPolicy value;
  final ValueChanged<CancellationPolicy> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in CancellationPolicy.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(p),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: p == value
                          ? AppColors.richGold
                          : Colors.transparent),
                ),
                child: Row(children: [
                  Icon(
                    p == value
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: p == value
                        ? AppColors.richGold
                        : AppColors.textTertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ExperienceL10n.policy(l, p),
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(ExperienceL10n.policyDescription(l, p),
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

/// "Accepted payment" rows for the detail page (cash at the meeting / link).
class PaymentMethodsList extends StatelessWidget {
  const PaymentMethodsList({super.key, required this.experience});
  final UserExperience experience;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final e = experience;
    final methods = [
      if (e.acceptsCash) PaymentMethod.cash,
      if (e.acceptsLink) PaymentMethod.link,
    ];
    if (methods.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final m in methods)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.backgroundInput,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(ExperienceL10n.paymentMethodIcon(m),
                  size: 16, color: AppColors.richGold),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  m == PaymentMethod.link && e.paymentLink != null
                      ? '${ExperienceL10n.paymentMethod(l, m)} · '
                          '${ExperienceL10n.paymentType(l, e.paymentLink!.type)}'
                      : ExperienceL10n.paymentMethod(l, m),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 12),
                ),
              ),
            ]),
          ),
      ],
    );
  }
}
