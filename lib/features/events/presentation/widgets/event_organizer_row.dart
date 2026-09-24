import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/user_directory_service.dart';
import '../../../../generated/app_localizations.dart';
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../domain/entities/event.dart';

/// "Organised by" row on the event detail screen: the organiser's CURRENT
/// photo + name (resolved through the cached [UserDirectoryService], falling
/// back to the name/photo snapshotted on the event), tappable to open their
/// profile. One cached read per organiser, not per viewer render.
class EventOrganizerRow extends StatefulWidget {
  const EventOrganizerRow({
    super.key,
    required this.event,
    required this.currentUserId,
  });

  final Event event;
  final String currentUserId;

  @override
  State<EventOrganizerRow> createState() => _EventOrganizerRowState();
}

class _EventOrganizerRowState extends State<EventOrganizerRow> {
  late final Future<Map<String, UserBrief>> _brief =
      UserDirectoryService.instance.resolve([widget.event.organizerId]);
  bool _opening = false;

  bool get _isMe => widget.event.organizerId == widget.currentUserId;

  Future<void> _openProfile() async {
    if (_isMe || _opening) return;
    setState(() => _opening = true);
    try {
      final profile = await di
          .sl<ProfileRemoteDataSource>()
          .getProfile(widget.event.organizerId);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProfileDetailScreen(
          profile: profile,
          currentUserId: widget.currentUserId,
        ),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.attendeesProfileFailed)));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, UserBrief>>(
      future: _brief,
      builder: (context, snap) {
        final brief = snap.data?[widget.event.organizerId];
        final snapshotName = widget.event.organizerName.trim();
        final name = (brief?.name.trim().isNotEmpty ?? false)
            ? brief!.name.trim()
            : (snapshotName.isNotEmpty && snapshotName != 'Current User'
                ? snapshotName
                : '?');
        final photo = brief?.photoUrl ?? widget.event.organizerPhotoUrl;
        final hasPhoto = photo != null && photo.isNotEmpty;

        return InkWell(
          onTap: _isMe ? null : _openProfile,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.backgroundInput,
                  backgroundImage:
                      hasPhoto ? CachedNetworkImageProvider(photo) : null,
                  child: hasPhoto
                      ? null
                      : Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.eventsOrganizedBy,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isMe ? l10n.eventsOrganizerYou(name) : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_opening)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.richGold),
                  )
                else if (!_isMe)
                  const Icon(Icons.chevron_right,
                      color: AppColors.textTertiary),
              ],
            ),
          ),
        );
      },
    );
  }
}
