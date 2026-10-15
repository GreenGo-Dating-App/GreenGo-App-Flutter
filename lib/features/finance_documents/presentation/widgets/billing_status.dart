import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/presentation/widgets/edit_section_card.dart';
import '../../data/billing_profile_repository.dart';
import '../bloc/billing_profile_cubit.dart';
import '../screens/invoice_details_screen.dart';

/// Loads the seller's invoice-details status ONCE for a subtree (one callable),
/// shared by [BillingRequiredBanner] and [InvoiceDetailsTile]; reloads after
/// the form closes.
class BillingStatusScope extends StatefulWidget {
  const BillingStatusScope({required this.child, this.repository, super.key});

  final Widget child;

  /// Injectable for tests.
  final BillingProfileRepository? repository;

  @override
  State<BillingStatusScope> createState() => _BillingStatusScopeState();
}

class _BillingStatusScopeState extends State<BillingStatusScope> {
  late final BillingProfileRepository _repo = widget.repository ?? BillingProfileRepository();
  late final BillingProfileCubit _cubit = BillingProfileCubit(_repo)..load();

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
        value: _repo,
        child: BlocProvider.value(value: _cubit, child: widget.child),
      );
}

/// Opens the form, then refreshes the shared status.
Future<void> openInvoiceDetails(BuildContext context) async {
  final cubit = context.read<BillingProfileCubit>();
  final repo = context.read<BillingProfileRepository>();
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => InvoiceDetailsScreen(repository: repo)),
  );
  await cubit.load();
}

/// Prominent "required" banner, shown only once we KNOW details are missing
/// (never while loading or on a load error).
class BillingRequiredBanner extends StatelessWidget {
  const BillingRequiredBanner({super.key, this.compact = false});

  /// Shorter text (Invoices screen shortcut).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<BillingProfileCubit, BillingProfileState>(
      builder: (context, state) {
        if (state.status != BillingLoadStatus.ready || state.complete) return const SizedBox.shrink();
        return Container(
          key: const ValueKey('billing-required-banner'),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.richGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.richGold.withValues(alpha: 0.6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.assignment_late_outlined, color: AppColors.richGold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!compact)
                      Text(l10n.financeBillingBannerTitle,
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                    if (!compact) const SizedBox(height: 4),
                    Text(compact ? l10n.financeBillingInvoicesShortcut : l10n.financeBillingBannerBody,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        key: const ValueKey('billing-banner-action'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.richGold, padding: EdgeInsets.zero),
                        onPressed: () => openInvoiceDetails(context),
                        child: Text(l10n.financeBillingBannerAction),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Business hub tile with the complete / missing status.
class InvoiceDetailsTile extends StatelessWidget {
  const InvoiceDetailsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<BillingProfileCubit, BillingProfileState>(
      builder: (context, state) {
        final known = state.status == BillingLoadStatus.ready;
        return EditSectionCard(
          key: const ValueKey('business-hub-invoice-details'),
          title: l10n.financeBillingTitle,
          subtitle: !known
              ? l10n.financeBillingIntro
              : (state.complete ? l10n.financeBillingSubtitleComplete : l10n.financeBillingSubtitleMissing),
          icon: known && !state.complete ? Icons.assignment_late_outlined : Icons.badge_outlined,
          onTap: () => openInvoiceDetails(context),
        );
      },
    );
  }
}
