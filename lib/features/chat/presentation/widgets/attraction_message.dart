import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../attractions/data/datasources/attractions_datasource.dart';
import '../../../attractions/domain/entities/attraction.dart';
import '../../../attractions/presentation/screens/attraction_detail_screen.dart';

/// Sending an attraction into the open chat ("Attractions in <city>" ->
/// send button). The chat screen registers [sender] while it is open; the
/// attraction travels as a text message (name, city and link, readable by
/// older app versions) with `metadata['attraction']`, which newer versions
/// render as a card that opens the attraction page.
class ChatAttractionShare {
  ChatAttractionShare._();

  /// The open chat's sender, or null (no chat open: no send buttons).
  static final ValueNotifier<Future<void> Function(Attraction a, String bucket)?> sender =
      ValueNotifier(null);

  static Map<String, dynamic> metadataFor(Attraction a, String bucket) => {
        'attraction': {
          'id': a.id,
          'name': a.name,
          if (a.names.isNotEmpty) 'names': a.names,
          'city': a.cityName,
          'iso2': a.countryIso2,
          'score': a.greengoScore,
          'img': a.imageUrl('thumb', bucket: bucket),
        },
      };

  /// Message text for apps that do not know the card.
  static String contentFor(Attraction a, Locale locale) =>
      '${a.nameFor(locale)} · ${a.cityName}\n${DeepLinkService.buildAttractionLink(a.id)}';

  /// The attraction in [metadata], if the message carries one.
  static Map<String, dynamic>? of(Map<String, dynamic>? metadata) {
    final v = metadata?['attraction'];
    return v is Map && v['id'] is num ? Map<String, dynamic>.from(v) : null;
  }
}

/// The card shown for a sent attraction; tap opens the whole attraction page.
class AttractionMessageCard extends StatelessWidget {
  const AttractionMessageCard({super.key, required this.attraction, this.onDark = false});

  final Map<String, dynamic> attraction;

  /// The bubble is gold (own message): darker text.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final names = attraction['names'];
    final key = locale.languageCode == 'pt' && locale.countryCode == 'BR' ? 'pt_BR' : locale.languageCode;
    final name = (names is Map ? (names[key] ?? names[locale.languageCode]) : null)?.toString() ??
        '${attraction['name'] ?? ''}';
    final textColor = onDark ? AppColors.deepBlack : AppColors.textPrimary;
    final img = attraction['img'];
    return InkWell(
      key: const ValueKey('attraction-message-card'),
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final bucket = await AttractionsDataSource().bucket();
        if (!context.mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AttractionDetailScreen(attractionId: (attraction['id'] as num).toInt(), bucket: bucket),
        ));
      },
      child: SizedBox(
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: img is String && img.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        memCacheWidth: 480,
                        placeholder: (_, __) => Container(color: AppColors.backgroundInput),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.backgroundInput,
                          child: const Icon(Icons.place_outlined, color: AppColors.richGold),
                        ),
                      )
                    : Container(
                        color: AppColors.backgroundInput,
                        child: const Icon(Icons.place_outlined, color: AppColors.richGold),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 14.5)),
              ),
              if (attraction['score'] is num) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: onDark ? AppColors.deepBlack.withValues(alpha: 0.15) : AppColors.richGold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text((attraction['score'] as num).toString(),
                      style: TextStyle(
                          color: onDark ? AppColors.deepBlack : AppColors.richGold,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.location_on_outlined, size: 14, color: textColor.withValues(alpha: 0.7)),
              const SizedBox(width: 3),
              Expanded(
                child: Text(attraction['city']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor.withValues(alpha: 0.75), fontSize: 12.5)),
              ),
              Icon(Icons.chevron_right, size: 18, color: textColor.withValues(alpha: 0.7)),
            ]),
          ],
        ),
      ),
    );
  }
}
