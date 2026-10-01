import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/external_event.dart';

/// Grid columns shared by every Events sub-tab: more on wide/web screens.
int eventsGridColumns(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  return w >= 1100 ? 6 : (w >= 800 ? 4 : 3);
}

/// Small gold "Partner" pill marking third-party (ticketmaster / viator)
/// items inside the merged "All" feeds, so they read differently from
/// community-created events and experiences.
class PartnerBadge extends StatelessWidget {
  const PartnerBadge({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: AppColors.deepBlack.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.richGold),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.handshake_outlined,
              size: compact ? 9 : 12, color: AppColors.richGold),
          SizedBox(width: compact ? 2 : 4),
          Text(
            AppLocalizations.of(context)!.partnerBadge,
            style: TextStyle(
              color: AppColors.richGold,
              fontSize: compact ? 8 : 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hostname of a URL without the leading "www." (e.g. "curitiba.pr.gov.br").
String _hostOf(String url) {
  try {
    final h = Uri.parse(url).host;
    return h.startsWith('www.') ? h.substring(4) : h;
  } catch (_) {
    return '';
  }
}

/// Source pill: the destination domain (viator.com, ticketmaster.com, …).
Widget _sourceBadge(ExternalEvent e) {
  final color = e.source == 'tiqets' || e.source == 'geoapify'
      ? Colors.purple
      : e.source == 'ticketmaster'
          ? Colors.indigo
          : e.source == 'google'
              ? Colors.green
              : Colors.teal;
  final host = _hostOf(e.bookingUrl);
  final label = host.isNotEmpty ? host : e.sourceLabel;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}

/// Category-themed placeholder for an event without (or with a broken) image.
Widget _imgPlaceholder(ExternalEvent e, double height) {
  IconData icon;
  switch (e.category) {
    case 'museum':
      icon = Icons.museum;
      break;
    case 'park':
    case 'national_park':
      icon = Icons.park;
      break;
    case 'theme_park':
      icon = Icons.attractions;
      break;
    default:
      icon = Icons.place;
  }
  return Container(
      height: height,
      width: double.infinity,
      color: AppColors.backgroundInput,
      child: Icon(icon, color: AppColors.textTertiary, size: 32));
}

/// Disk-cached image decoded at the tile's on-screen width ([cols] per row).
Widget _img(BuildContext context, ExternalEvent e, double height, int cols) {
  if (e.imageUrl != null && e.imageUrl!.isNotEmpty) {
    final mq = MediaQuery.of(context);
    return CachedNetworkImage(
      imageUrl: e.imageUrl!,
      height: height,
      width: double.infinity,
      memCacheWidth: (mq.size.width / cols * mq.devicePixelRatio).round(),
      fit: BoxFit.cover,
      placeholder: (c, _) => Container(
        height: height,
        color: AppColors.backgroundInput,
        child: const Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.richGold))),
      ),
      errorWidget: (_, __, ___) => _imgPlaceholder(e, height),
    );
  }
  return _imgPlaceholder(e, height);
}

String _place(ExternalEvent e) =>
    [e.city, e.country].where((s) => s != null && s.isNotEmpty).join(', ');

/// Full-width list card for an external (partner) event / experience.
class ExternalEventCard extends StatelessWidget {
  const ExternalEventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.showPartnerBadge = false,
  });

  final ExternalEvent event;
  final VoidCallback onTap;

  /// Merged "All" feeds mark partner items with a [PartnerBadge].
  final bool showPartnerBadge;

  String _price(BuildContext context) {
    final e = event;
    if (e.fromPrice == null) return '';
    final l10n = AppLocalizations.of(context)!;
    return '${l10n.eventsFromPrice} ${e.currency ?? ''} ${e.fromPrice!.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final e = event;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: _img(context, e, 160, 1),
                ),
                Positioned(top: 8, left: 8, child: _sourceBadge(e)),
                if (showPartnerBadge)
                  const Positioned(top: 8, right: 8, child: PartnerBadge()),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  if (e.startDate != null && e.startDate!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event,
                            size: 14, color: AppColors.richGold),
                        const SizedBox(width: 4),
                        Text(e.startDate!,
                            style: const TextStyle(
                                color: AppColors.richGold,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          _place(e),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                      if (e.rating != null && e.rating! > 0) ...[
                        const Icon(Icons.star,
                            size: 14, color: AppColors.richGold),
                        const SizedBox(width: 2),
                        Text('${e.rating}',
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                        if (e.reviewCount != null && e.reviewCount! > 0)
                          Text(' (${e.reviewCount})',
                              style: const TextStyle(
                                  color: AppColors.textTertiary, fontSize: 11)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_price(context),
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text(AppLocalizations.of(context)!.eventsBook),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: AppColors.deepBlack,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact grid tile for an external (partner) event / experience.
class ExternalEventGridTile extends StatelessWidget {
  const ExternalEventGridTile({
    super.key,
    required this.event,
    required this.onTap,
    this.showPartnerBadge = false,
  });

  final ExternalEvent event;
  final VoidCallback onTap;
  final bool showPartnerBadge;

  @override
  Widget build(BuildContext context) {
    final e = event;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: AppColors.backgroundCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _img(context, e, double.infinity,
                        eventsGridColumns(context)),
                    Positioned(top: 4, left: 4, child: _sourceBadge(e)),
                    if (showPartnerBadge)
                      const Positioned(
                          bottom: 4,
                          left: 4,
                          child: PartnerBadge(compact: true)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    if (e.startDate != null && e.startDate!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.event,
                            size: 10, color: AppColors.richGold),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(e.startDate!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.richGold, fontSize: 10)),
                        ),
                      ]),
                    ],
                    if (_place(e).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _place(e),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (e.rating != null && e.rating! > 0) ...[
                          const Icon(Icons.star,
                              size: 10, color: AppColors.richGold),
                          Text('${e.rating}',
                              style: const TextStyle(
                                  color: AppColors.textTertiary, fontSize: 10)),
                          const Spacer(),
                        ],
                        if (e.fromPrice != null)
                          Text(
                              '${e.currency ?? ''}${e.fromPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: AppColors.richGold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
