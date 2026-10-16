import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/trader_repository.dart';
import '../../domain/trader_declaration.dart';

/// Seller information for guests (Terms 12.4, EU Digital Services Act art.
/// 30): a trader's name, address, phone, email and trade register, or the
/// "private person, not a trader" notice. Shown on the Experience detail and
/// at event ticket checkout, for every viewer. Nothing is shown while
/// loading or when the seller has not declared yet.
class SellerTraderInfo extends StatefulWidget {
  const SellerTraderInfo(
      {required this.sellerId, this.repository, this.info, this.topSpacing = 0, super.key});

  final String sellerId;

  /// Space above the card (only when there is a card).
  final double topSpacing;
  final TraderRepository? repository;

  /// Test seam: the public info (skips the read).
  final TraderPublicInfo? info;

  @override
  State<SellerTraderInfo> createState() => _SellerTraderInfoState();
}

class _SellerTraderInfoState extends State<SellerTraderInfo> {
  late Future<TraderPublicInfo?> _future = _load();

  Future<TraderPublicInfo?> _load() async {
    if (widget.info != null) return widget.info;
    try {
      return await (widget.repository ?? TraderRepository()).publicInfo(widget.sellerId);
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(SellerTraderInfo old) {
    super.didUpdateWidget(old);
    if (old.sellerId != widget.sellerId || old.info != widget.info) _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TraderPublicInfo?>(
      future: _future,
      builder: (context, snap) {
        final info = snap.data;
        if (info == null) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(top: widget.topSpacing),
          child: _card(context, info),
        );
      },
    );
  }

  Widget _card(BuildContext context, TraderPublicInfo info) {
    final l = AppLocalizations.of(context)!;
    const label = TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4);
    final lines = info.isTrader
        ? [
            if (info.name.isNotEmpty) info.name,
            if (info.address.isNotEmpty) info.address,
            if (info.phone.isNotEmpty) info.phone,
            if (info.email.isNotEmpty) info.email,
            if (info.tradeRegister.isNotEmpty)
              l.traderCardRegister(info.tradeRegister, info.tradeRegisterNumber),
          ]
        : [l.traderCardNonTrader];
    return Container(
      key: ValueKey(info.isTrader ? 'seller-trader-info' : 'seller-non-trader'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(info.isTrader ? Icons.storefront_outlined : Icons.person_outline,
                size: 16, color: AppColors.richGold),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                info.isTrader ? l.traderCardTitle : l.traderCardNonTraderTitle,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          for (final s in lines) SelectableText(s, style: label),
        ],
      ),
    );
  }
}
