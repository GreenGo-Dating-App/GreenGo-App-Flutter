import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/user_experience.dart';
import '../experience_l10n.dart';

/// Read-only stars (supports halves), e.g. 4.3 → ★★★★½.
class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({super.key, required this.rating, this.size = 14});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : (rating >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded),
            size: size,
            color: AppColors.richGold,
          ),
      ],
    );
  }
}

/// Tappable 1..5 star picker.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 36,
  });
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: true,
            selected: value >= i,
            label: '$i',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: size,
              onPressed: () => onChanged(i),
              icon: Icon(
                value >= i ? Icons.star_rounded : Icons.star_outline_rounded,
                color: AppColors.richGold,
              ),
            ),
          ),
      ],
    );
  }
}

/// Network image with the app's placeholder / error styling.
class ExperienceImage extends StatelessWidget {
  const ExperienceImage({
    super.key,
    required this.url,
    this.height,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.category,
  });
  final String url;
  final double? height;
  final double width;
  final BoxFit fit;
  final ExperienceCategory? category;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    Widget placeholder() => Container(
          height: height,
          width: width,
          color: AppColors.backgroundInput,
          child: Icon(
            ExperienceL10n.categoryIcon(category ?? ExperienceCategory.other),
            color: AppColors.textTertiary,
            size: 32,
          ),
        );
    if (url.isEmpty) return placeholder();
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: width,
      fit: fit,
      memCacheWidth: (mq.size.width * mq.devicePixelRatio).round(),
      placeholder: (_, __) => Container(
        height: height,
        width: width,
        color: AppColors.backgroundInput,
      ),
      errorWidget: (_, __, ___) => placeholder(),
    );
  }
}

/// Avatar + live display name of a user (never their uid): the
/// UserDirectoryService brief first, then [fallbackName]/[fallbackPhoto].
class UserNameAvatar extends StatelessWidget {
  const UserNameAvatar({
    super.key,
    required this.uid,
    this.fallbackName,
    this.fallbackPhoto,
    this.radius = 16,
    this.textStyle,
    this.trailing,
    this.onTap,
  });
  final String uid;
  final String? fallbackName;
  final String? fallbackPhoto;
  final double radius;
  final TextStyle? textStyle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserDirectoryService.instance,
      builder: (context, _) {
        final brief = UserDirectoryService.instance.cached(uid);
        if (brief == null) {
          // Kick off the (batched, cached) resolve; the listener repaints.
          UserDirectoryService.instance.resolve([uid]);
        }
        final name = (brief?.name.trim().isNotEmpty ?? false)
            ? brief!.name.trim()
            : (fallbackName?.trim() ?? '');
        final photo = brief?.photoUrl ?? fallbackPhoto;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius + 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: radius,
                backgroundColor: AppColors.backgroundInput,
                backgroundImage: photo != null && photo.isNotEmpty
                    ? CachedNetworkImageProvider(photo)
                    : null,
                child: photo == null || photo.isEmpty
                    ? Icon(Icons.person,
                        size: radius, color: AppColors.textTertiary)
                    : null,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  name.isEmpty ? '…' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle ??
                      const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            ],
          ),
        );
      },
    );
  }
}

/// The host's OVERALL rating across all their experiences (server-owned
/// profile totals, read through the cached + batched UserDirectoryService
/// brief — no extra reads where the host avatar is already shown):
/// "★ 4.7 · 23 ratings", or "New host" when nobody has rated them yet.
/// [compact] (cards) drops the word: "★ 4.7 (23)".
class HostRatingBadge extends StatelessWidget {
  const HostRatingBadge({super.key, required this.hostId, this.compact = false});
  final String hostId;
  final bool compact;

  /// Pure formatter (unit-tested): null count/avg → "New host".
  static String label(
    AppLocalizations l,
    String locale, {
    required int count,
    required double avg,
    bool compact = false,
  }) {
    if (count <= 0) return l.uexpNewHost;
    String avgText;
    String countText;
    try {
      avgText = NumberFormat('0.0', locale).format(avg);
      countText = NumberFormat.compact(locale: locale).format(count);
    } catch (_) {
      avgText = avg.toStringAsFixed(1);
      countText = NumberFormat.compact().format(count);
    }
    return compact
        ? '$avgText ($countText)'
        : '$avgText · ${l.uexpHostRatings(count, countText)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return ListenableBuilder(
      listenable: UserDirectoryService.instance,
      builder: (context, _) {
        final brief = UserDirectoryService.instance.cached(hostId);
        if (brief == null) {
          UserDirectoryService.instance.resolve([hostId]);
          return const SizedBox.shrink();
        }
        final count = brief.hostRatingCount;
        final text = label(l, locale,
            count: count, avg: brief.hostRatingAvg, compact: compact);
        final size = compact ? 11.0 : 13.0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(count > 0 ? Icons.star_rounded : Icons.fiber_new_rounded,
                size: size + 2, color: AppColors.richGold),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: count > 0
                        ? AppColors.textSecondary
                        : AppColors.richGold,
                    fontSize: size,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Price + "Pay / Book" bar of the detail page.
///
/// The price is ALWAYS one line (ellipsized only when even the full width is
/// too narrow). The app theme gives every ElevatedButton
/// `minimumSize: Size(double.infinity, …)`; as an inflexible Row child that
/// asks for infinite width, leaving the price's Expanded ~0 px wide, which
/// rendered it one character per line. So: on narrow widths the button goes
/// full-width UNDER the price; on wide ones it sits beside it with a finite
/// minimum size.
class ExperiencePriceBar extends StatelessWidget {
  const ExperiencePriceBar({
    super.key,
    required this.priceText,
    this.payLabel,
    this.payIcon,
    this.onPay,
  });
  final String priceText;

  /// Null = no payment link (free / not set): price only.
  final String? payLabel;
  final IconData? payIcon;
  final VoidCallback? onPay;

  /// Below this width the button wraps under the price.
  static const double sideBySideMinWidth = 420;
  static const TextStyle priceStyle = TextStyle(
      color: AppColors.richGold, fontSize: 22, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    final price = Text(
      priceText,
      key: const ValueKey('experience-price'),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: priceStyle,
    );
    if (payLabel == null) return price;
    return LayoutBuilder(builder: (context, c) {
      final wide = c.hasBoundedWidth && c.maxWidth >= sideBySideMinWidth;
      final button = ElevatedButton.icon(
        key: const ValueKey('experience-pay'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.richGold,
          foregroundColor: AppColors.deepBlack,
          // Finite: never inherit the theme's infinite minimum width.
          minimumSize: Size(wide || !c.hasBoundedWidth ? 0 : c.maxWidth, 44),
        ),
        onPressed: onPay,
        icon: Icon(payIcon ?? Icons.open_in_new),
        label: Text(payLabel!, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
      if (wide) {
        return Row(children: [
          Expanded(child: price),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: c.maxWidth * 0.5),
            child: button,
          ),
        ]);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [price, const SizedBox(height: 10), button],
      );
    });
  }
}

/// Feed card: main photo, title, category, price, rating + host avatar.
class ExperienceCard extends StatelessWidget {
  const ExperienceCard({
    super.key,
    required this.experience,
    required this.onTap,
    this.compact = false,
    this.showStatus = false,
    this.distanceKm,
  });
  final UserExperience experience;
  final VoidCallback onTap;
  final bool compact; // grid tile
  final bool showStatus; // "My experiences"
  final double? distanceKm;

  /// True when the host's account is known to be inactive (banned /
  /// suspended / deleted) — from the cached directory brief, no read.
  static bool isHostHidden(String hostId) {
    final b = UserDirectoryService.instance.cached(hostId);
    return b != null && !b.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final e = experience;
    // Banned / suspended / deleted hosts: never shown in feeds. The server
    // also hides their listings on ban (status 'hidden', host_banned); this
    // covers cached pages and the window before that trigger runs.
    if (!showStatus && isHostHidden(e.hostId)) return const SizedBox.shrink();
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.deepBlack.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ExperienceL10n.categoryIcon(e.category),
            size: compact ? 10 : 12, color: AppColors.richGold),
        const SizedBox(width: 4),
        Flexible(
          child: Text(ExperienceL10n.category(l, e.category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: compact ? 9 : 11,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
    final statusChip = showStatus && !e.isPublished
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: e.isHidden
                  ? AppColors.errorRed.withValues(alpha: 0.9)
                  : AppColors.warningAmber.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(ExperienceL10n.status(l, e.status),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          )
        : null;

    final ratingRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 14, color: AppColors.richGold),
        const SizedBox(width: 2),
        Text(
          e.ratingCount == 0 ? '–' : e.averageRating.toStringAsFixed(1),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        ),
        if (!compact) ...[
          const SizedBox(width: 4),
          Text('(${l.uexpReviewsCount(e.ratingCount)})',
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 11)),
        ],
      ],
    );

    final place = [e.city, e.country]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    if (compact) {
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
                  child: Stack(fit: StackFit.expand, children: [
                    ExperienceImage(url: e.mainPhotoUrl, category: e.category),
                    Positioned(top: 4, left: 4, right: 4, child: Align(alignment: Alignment.topLeft, child: badge)),
                    if (statusChip != null)
                      Positioned(bottom: 4, left: 4, child: statusChip),
                  ]),
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
                      const SizedBox(height: 2),
                      Row(children: [
                        ratingRow,
                        const Spacer(),
                        Flexible(
                          child: Text(ExperienceL10n.price(l, e),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.richGold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.richGold.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: ExperienceImage(
                    url: e.mainPhotoUrl, height: 170, category: e.category),
              ),
              Positioned(top: 8, left: 8, child: badge),
              if (statusChip != null)
                Positioned(top: 8, right: 8, child: statusChip),
            ]),
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
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        [
                          if (place.isNotEmpty) place else e.locationName,
                          if (distanceKm != null)
                            '${distanceKm!.toStringAsFixed(distanceKm! < 10 ? 1 : 0)} km',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                    ratingRow,
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: UserNameAvatar(
                        uid: e.hostId,
                        fallbackName: e.hostName,
                        fallbackPhoto: e.hostPhotoUrl,
                        radius: 12,
                        trailing: Flexible(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            UserVerifiedBadge(
                                uid: e.hostId,
                                size: 13,
                                padding: const EdgeInsets.only(right: 4)),
                            Flexible(
                                child: HostRatingBadge(
                                    hostId: e.hostId, compact: true)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bounded + single line: a long price ellipsizes instead
                    // of squeezing the host row or wrapping.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(ExperienceL10n.price(l, e),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.richGold,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen, pinch-to-zoom gallery (swipe between photos).
class ExperiencePhotoViewer extends StatefulWidget {
  const ExperiencePhotoViewer({
    super.key,
    required this.urls,
    this.initialIndex = 0,
  });
  final List<String> urls;
  final int initialIndex;

  static Future<void> open(BuildContext context, List<String> urls, int index) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ExperiencePhotoViewer(urls: urls, initialIndex: index),
      ));

  @override
  State<ExperiencePhotoViewer> createState() => _ExperiencePhotoViewerState();
}

class _ExperiencePhotoViewerState extends State<ExperiencePhotoViewer> {
  late final PageController _page =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _page,
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.urls[i],
                fit: BoxFit.contain,
                placeholder: (_, __) => const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.richGold),
                ),
                errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textTertiary,
                    size: 48),
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        if (widget.urls.length > 1)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text('${_index + 1} / ${widget.urls.length}',
                  style: const TextStyle(color: Colors.white70)),
            ),
          ),
      ]),
    );
  }
}
