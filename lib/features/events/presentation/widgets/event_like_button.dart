import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/repositories/events_repository.dart';

/// Heart toggle + like count for an event. The per-user like is written to the
/// `events/{id}/likes/{uid}` subcollection; the denormalized `likeCount` on the
/// event (used for the "Popular" sort) is maintained by the onEventLikeWrite
/// Cloud Function. Optimistic so the tap feels instant, then reconciles with
/// the live like state and the refreshed count.
class EventLikeButton extends StatefulWidget {
  const EventLikeButton({
    super.key,
    required this.eventId,
    required this.userId,
    required this.likeCount,
    this.compact = false,
  });

  final String eventId;
  final String userId;
  final int likeCount;

  /// Tighter layout for grid tiles.
  final bool compact;

  @override
  State<EventLikeButton> createState() => _EventLikeButtonState();
}

class _EventLikeButtonState extends State<EventLikeButton> {
  bool? _serverLiked;
  bool? _optimisticLiked;
  int? _optimisticCount;

  bool get _liked => _optimisticLiked ?? _serverLiked ?? false;
  int get _count => _optimisticCount ?? widget.likeCount;

  @override
  void didUpdateWidget(EventLikeButton old) {
    super.didUpdateWidget(old);
    // The denormalized count caught up → drop the optimistic override.
    if (old.likeCount != widget.likeCount) _optimisticCount = null;
  }

  Future<void> _toggle() async {
    if (widget.userId.isEmpty || widget.eventId.isEmpty) return;
    final next = !_liked;
    HapticFeedback.lightImpact();
    setState(() {
      _optimisticLiked = next;
      _optimisticCount = (_count + (next ? 1 : -1)).clamp(0, 1 << 31);
    });
    try {
      await di
          .sl<EventsRepository>()
          .setEventLiked(widget.eventId, widget.userId, next);
    } catch (_) {
      if (mounted) {
        setState(() {
          _optimisticLiked = !next;
          _optimisticCount = (_count + (next ? -1 : 1)).clamp(0, 1 << 31);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: di
          .sl<EventsRepository>()
          .watchEventLiked(widget.eventId, widget.userId),
      builder: (context, snap) {
        if (snap.hasData) {
          _serverLiked = snap.data;
          // Once the server reflects our intent, clear the optimistic flag.
          if (_optimisticLiked != null && _optimisticLiked == _serverLiked) {
            _optimisticLiked = null;
          }
        }
        final liked = _liked;
        final color = liked ? AppColors.errorRed : AppColors.textSecondary;
        final size = widget.compact ? 18.0 : 22.0;
        return InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(widget.compact ? 2 : 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(liked ? Icons.favorite : Icons.favorite_border,
                    size: size, color: color),
                if (_count > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$_count',
                    style: TextStyle(
                      color: color,
                      fontSize: widget.compact ? 12 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
