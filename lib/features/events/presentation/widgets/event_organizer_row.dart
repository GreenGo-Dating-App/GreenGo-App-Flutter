import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/user_directory_service.dart';
import '../../../../generated/app_localizations.dart';
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../domain/entities/event.dart';

/// "Organised by" card on the event detail screen: the organiser AND every
/// co-owner, side by side as equal people (photo + current name, resolved in
/// one cached [UserDirectoryService] batch; the organiser falls back to the
/// name/photo snapshotted on the event). Each person taps through to their
/// profile. A co-owner whose name isn't resolved yet is left out rather than
/// shown as an id.
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
      UserDirectoryService.instance.resolve(
          [widget.event.organizerId, ...widget.event.coOrganizerIds]);
  String? _opening;

  Future<void> _openProfile(String uid) async {
    if (uid == widget.currentUserId || _opening != null) return;
    setState(() => _opening = uid);
    try {
      final profile = await di.sl<ProfileRemoteDataSource>().getProfile(uid);
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
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, UserBrief>>(
      future: _brief,
      builder: (context, snap) {
        final briefs = snap.data ?? const <String, UserBrief>{};
        final organizer = briefs[widget.event.organizerId];
        final snapshotName = widget.event.organizerName.trim();
        final organizerName = (organizer?.name.trim().isNotEmpty ?? false)
            ? organizer!.name.trim()
            : (snapshotName.isNotEmpty && snapshotName != 'Current User'
                ? snapshotName
                : '?');

        final people = <({String uid, String name, String? photo})>[
          (
            uid: widget.event.organizerId,
            name: organizerName,
            photo: organizer?.photoUrl ?? widget.event.organizerPhotoUrl,
          ),
          for (final id in widget.event.coOrganizerIds)
            if ((briefs[id]?.name.trim() ?? '').isNotEmpty)
              (uid: id, name: briefs[id]!.name.trim(), photo: briefs[id]!.photoUrl),
        ];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
          ),
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in people)
                    _PersonChip(
                      name: p.uid == widget.currentUserId
                          ? l10n.eventsOrganizerYou(p.name)
                          : p.name,
                      photo: p.photo,
                      loading: _opening == p.uid,
                      onTap: p.uid == widget.currentUserId
                          ? null
                          : () => _openProfile(p.uid),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({
    required this.name,
    required this.photo,
    required this.loading,
    required this.onTap,
  });

  final String name;
  final String? photo;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo != null && photo!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        decoration: BoxDecoration(
          color: AppColors.backgroundInput,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.richGold.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.backgroundCard,
              backgroundImage:
                  hasPhoto ? CachedNetworkImageProvider(photo!) : null,
              child: hasPhoto
                  ? null
                  : Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (loading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.richGold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
