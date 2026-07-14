import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/widgets/country_flag_badge.dart';
import '../../../../generated/app_localizations.dart';
import '../../../matching/domain/entities/match_candidate.dart';

/// Reusable, Apple-safe replica of the 2.2.4 Network grid card.
///
/// Faithfully mirrors the visual layout of the discovery screen's private
/// `_GridProfileCard` (photo + distance badge + language flags + bottom scrim +
/// name/age + %/city row + "You" state) but strips out ALL swipe / like /
/// super-like / nope / match / priority-connect logic and overlays.
///
/// Gestures are intentionally minimal:
///   * tap the photo area        -> [onOpenChat]
///   * tap the name/age/city text -> [onOpenProfile]
///   * long-press anywhere        -> [onLongPressTag]
///   * thin gold chevrons         -> previous / next photo (internal state)
///
/// Designed to sit flush inside a zero-spacing grid: no outer margin and
/// (near-)zero corner radius.
class NetworkGridCard extends StatefulWidget {
  const NetworkGridCard({
    required this.candidate,
    required this.isSelf,
    required this.onOpenChat,
    required this.onOpenProfile,
    required this.onLongPressTag,
    this.isBusiness = false,
    super.key,
  });

  /// The candidate to render — carries the profile, distance and match score.
  final MatchCandidate candidate;

  /// When true, renders the gold "You" border + "You" badge and hides the
  /// distance badge / language flags (this is the current user's own tile).
  final bool isSelf;

  /// When true, renders the premium gold-framed treatment used for business
  /// accounts (same "featured" effect as Explore's community-event card).
  final bool isBusiness;

  /// Tap the photo area (opens the chat with this person).
  final VoidCallback onOpenChat;

  /// Tap the name / age / city block (opens the full profile).
  final VoidCallback onOpenProfile;

  /// Long-press anywhere on the tile (opens the private group-tag sheet).
  final VoidCallback onLongPressTag;

  @override
  State<NetworkGridCard> createState() => _NetworkGridCardState();
}

class _NetworkGridCardState extends State<NetworkGridCard> {
  // Internal photo carousel index — advanced by the gold chevrons only.
  int _photoIndex = 0;

  @override
  void didUpdateWidget(covariant NetworkGridCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset the carousel when the tile is recycled for a different user.
    if (oldWidget.candidate.profile.userId != widget.candidate.profile.userId) {
      _photoIndex = 0;
    }
  }

  void _prevPhoto(int count) {
    if (_photoIndex > 0) {
      HapticFeedback.selectionClick();
      setState(() => _photoIndex--);
    }
  }

  void _nextPhoto(int count) {
    if (_photoIndex < count - 1) {
      HapticFeedback.selectionClick();
      setState(() => _photoIndex++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.candidate.profile;
    final photoUrls = profile.photoUrls;
    final hasMultiplePhotos = photoUrls.length > 1;

    final location = profile.effectiveLocation;
    final distanceText = widget.candidate.distanceText;
    final matchPercentage = widget.candidate.matchScore.matchPercentageText;
    // Only surface the compatibility % when it is meaningful (> 0) and this is
    // not the user's own tile. Sources that carry no real score (e.g. the
    // Explore country grid) pass 0, in which case the row falls back to just
    // the city — keeping the exact same layout without a misleading "0%".
    final showScore =
        !widget.isSelf && widget.candidate.matchScore.overallScore > 0;
    final cityText = location.city.isNotEmpty && location.city != 'Unknown'
        ? location.city
        : (location.country.isNotEmpty && location.country != 'Unknown'
            ? location.country
            : '');

    final currentPhotoUrl =
        photoUrls.isNotEmpty && _photoIndex < photoUrls.length
            ? photoUrls[_photoIndex]
            : (photoUrls.isNotEmpty ? photoUrls.first : null);

    final showDistance = !profile.isAdmin &&
        !profile.isSupport &&
        !widget.isSelf &&
        distanceText.isNotEmpty;

    final stack = Stack(
      fit: StackFit.expand,
      children: [
        // ── Full-bleed photo ──────────────────────────────────────────────
        if (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: currentPhotoUrl,
            fit: BoxFit.cover,
            memCacheWidth: 600,
            maxWidthDiskCache: 600,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (context, url) => Container(
              color: AppColors.backgroundCard,
              child: Center(
                child: Icon(
                  Icons.person,
                  color: AppColors.textTertiary.withOpacity(0.5),
                  size: 40,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.backgroundCard,
              child: Icon(
                Icons.person,
                color: AppColors.textTertiary.withOpacity(0.5),
                size: 40,
              ),
            ),
          )
        else
          Container(
            color: AppColors.backgroundCard,
            child: const Icon(Icons.person,
                color: AppColors.textTertiary, size: 40),
          ),

        // ── Bottom dark gradient scrim (for text readability) ─────────────
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── Distance badge (top-left) ─────────────────────────────────────
        if (showDistance)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.white70, size: 10),
                  const SizedBox(width: 2),
                  Text(
                    distanceText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Language flags (top-right) ────────────────────────────────────
        if (profile.languages.isNotEmpty && !widget.isSelf)
          Positioned(
            top: 4,
            right: 4,
            child: LanguageFlagBadge(
              languages: profile.languages,
              fontSize: 12,
            ),
          ),

        // ── Base tap layer: photo tap -> chat, long-press -> tag ──────────
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onOpenChat();
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              widget.onLongPressTag();
            },
          ),
        ),

        // ── Name + age + %/city block (bottom-left) -> open profile ───────
        Positioned(
          left: 6,
          right: 6,
          bottom: 6,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onOpenProfile();
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              widget.onLongPressTag();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name, age — bold white ("Felipe, 23")
                Text(
                  '${widget.candidate.displayName}, ${widget.candidate.age}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showScore || cityText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  // % (gold) + city (grey) with the small leading icon. The %
                  // block is omitted when there is no meaningful score.
                  Row(
                    children: [
                      if (showScore) ...[
                        Icon(
                          Icons.connect_without_contact,
                          color: AppColors.richGold.withOpacity(0.8),
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          matchPercentage,
                          style: TextStyle(
                            color: AppColors.richGold.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (cityText.isNotEmpty) ...[
                        if (showScore) const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cityText,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Thin, delicate GOLD chevrons (only when multiple photos) ──────
        if (hasMultiplePhotos) ...[
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _prevPhoto(photoUrls.length),
              onLongPress: () {
                HapticFeedback.mediumImpact();
                widget.onLongPressTag();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Center(
                  child: Icon(
                    Icons.chevron_left,
                    color: AppColors.richGold.withOpacity(0.7),
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _nextPhoto(photoUrls.length),
              onLongPress: () {
                HapticFeedback.mediumImpact();
                widget.onLongPressTag();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Center(
                  child: Icon(
                    Icons.chevron_right,
                    color: AppColors.richGold.withOpacity(0.7),
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],

        // ── "You" badge (top-right) for the current user's own tile ───────
        if (widget.isSelf)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.richGold.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.richGold.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                AppLocalizations.of(context)!.yourProfile,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );

    // ── Rounded tile: clipped photo/scrim, gold border ring for "You" and
    // the premium gold frame + glow for business (featured) accounts. ────
    const radius = BorderRadius.all(Radius.circular(16));
    final bool gold = widget.isSelf || widget.isBusiness;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: gold ? Border.all(color: AppColors.richGold, width: 2) : null,
        boxShadow: widget.isBusiness ? AppGlass.goldGlow : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: stack,
      ),
    );
  }
}
