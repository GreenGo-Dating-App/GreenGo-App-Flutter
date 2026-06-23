import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../../chat/domain/usecases/report_user.dart';
import '../../domain/entities/external_event.dart';
import 'share_external_sheet.dart';

/// The tap window for an attraction / experience: image on the left, info on the
/// right, and actions (open link, open the official website referenced in
/// Wikidata, open Wikidata, open in maps, share to chat / group, report).
Future<void> showAttractionMenu(
  BuildContext context, {
  required ExternalEvent event,
  required String currentUserId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        _AttractionMenuDialog(event: event, currentUserId: currentUserId),
  );
}

class _AttractionMenuDialog extends StatefulWidget {
  const _AttractionMenuDialog(
      {required this.event, required this.currentUserId});

  final ExternalEvent event;
  final String currentUserId;

  @override
  State<_AttractionMenuDialog> createState() => _AttractionMenuDialogState();
}

class _AttractionMenuDialogState extends State<_AttractionMenuDialog> {
  String _hostOf(String url) {
    try {
      final h = Uri.parse(url).host;
      return h.startsWith('www.') ? h.substring(4) : h;
    } catch (_) {
      return '';
    }
  }

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  String? _mapsUrl(ExternalEvent e) {
    if (e.lat != null && e.lng != null) {
      return 'https://www.google.com/maps/search/?api=1&query=${e.lat},${e.lng}';
    }
    final place = '${e.title} ${e.city ?? ''}'.trim();
    if (place.isEmpty) return null;
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(place)}';
  }

  Future<void> _report() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.attractionReport,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.attractionReportConfirm,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.groupCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.attractionReport,
                  style: const TextStyle(color: Colors.orange))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await di.sl<ReportUser>()(ReportUserParams(
        reporterId: widget.currentUserId,
        reportedUserId: widget.event.id,
        reason: 'external_event',
        additionalDetails:
            '${widget.event.source} · ${widget.event.title} · ${widget.event.bookingUrl}',
      ));
    } catch (_) {/* best-effort */}
    if (!mounted) return;
    Navigator.pop(context); // close the window
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.groupReportSubmitted)));
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap,
      {Color color = AppColors.richGold}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final e = widget.event;
    final maps = _mapsUrl(e);
    final seen = <String>{};
    final options = <Widget>[];

    void addLink(IconData icon, String label, String url) {
      if (url.isEmpty) return;
      final host = _hostOf(url);
      if (host.isNotEmpty && !seen.add(host)) return;
      options.add(_tile(icon, label, () {
        Navigator.pop(context);
        _open(url);
      }));
    }

    // Primary link (the "original url" — for Wikidata items this is wikidata.org).
    final primaryHost = _hostOf(e.bookingUrl);
    addLink(Icons.open_in_new,
        '${l10n.attractionOpenLink}${primaryHost.isNotEmpty ? '  ·  $primaryHost' : ''}',
        e.bookingUrl);
    // Official website — preloaded in the DB (OSM tag, or scraped from the
    // Wikidata P856 referenced inside wikidata.org during ingest/backfill).
    final site = e.website;
    if (site != null && site.isNotEmpty) {
      addLink(Icons.public, '${l10n.attractionOpenWebsite}  ·  ${_hostOf(site)}',
          site);
    }
    // Explicit Wikidata link (deduped if it's already the primary).
    if (e.wikidataUrl != null && e.wikidataUrl!.isNotEmpty) {
      addLink(Icons.menu_book, l10n.attractionVisitWikidata, e.wikidataUrl!);
    }
    if (maps != null) {
      options.add(_tile(Icons.map, l10n.attractionOpenInMaps, () {
        Navigator.pop(context);
        _open(maps);
      }));
    }
    options.add(_tile(Icons.chat_bubble_outline, l10n.attractionShareChat, () {
      Navigator.pop(context);
      showShareExternalSheet(context,
          item: e, currentUserId: widget.currentUserId, mode: 'chats');
    }));
    options.add(_tile(Icons.groups, l10n.attractionShareGroup, () {
      Navigator.pop(context);
      showShareExternalSheet(context,
          item: e, currentUserId: widget.currentUserId, mode: 'groups');
    }));
    options.add(_tile(Icons.flag_outlined, l10n.attractionReport, _report,
        color: Colors.orange));

    final place = [e.city, e.country]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    return Dialog(
      backgroundColor: AppColors.backgroundCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 130,
                child: (e.imageUrl != null && e.imageUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: e.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(color: AppColors.backgroundInput),
                      )
                    : Container(color: AppColors.backgroundInput),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      if (place.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.place,
                                size: 14, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(place,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                      if (e.description != null && e.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(e.description!,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.3)),
                      ],
                      const Divider(height: 18, color: AppColors.divider),
                      ...options,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
