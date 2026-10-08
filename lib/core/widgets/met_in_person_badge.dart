import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';

/// "Met in person · {date}" — shown on a profile when the viewer and that
/// member were both checked in by QR at the same event or experience
/// (`met_in_person/{pairId}`, written only by the server). One doc read per
/// profile open; renders nothing when they have not met, or on any error.
class MetInPersonBadge extends StatefulWidget {
  const MetInPersonBadge({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
  });

  final String currentUserId;
  final String otherUserId;

  /// Same id the server builds: both uids sorted, joined by '_'.
  static String pairIdOf(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  @override
  State<MetInPersonBadge> createState() => _MetInPersonBadgeState();
}

class _MetInPersonBadgeState extends State<MetInPersonBadge> {
  DateTime? _lastMet;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = widget.currentUserId;
    final b = widget.otherUserId;
    if (a.isEmpty || b.isEmpty || a == b) return;
    try {
      final d = (await FirebaseFirestore.instance
              .collection('met_in_person')
              .doc(MetInPersonBadge.pairIdOf(a, b))
              .get())
          .data();
      if (d == null) return;
      // Only verified (signed-ticket) meetings count.
      final verified = (d['verifiedCount'] as num?)?.toInt() ?? 0;
      final last = d['lastMetAt'];
      if (verified <= 0 || last is! Timestamp || !mounted) return;
      setState(() {
        _lastMet = last.toDate();
        _count = verified;
      });
    } catch (_) {/* nothing to show */}
  }

  @override
  Widget build(BuildContext context) {
    final last = _lastMet;
    if (last == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(last);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.handshake_outlined,
            color: AppColors.successGreen, size: 14),
        const SizedBox(width: 6),
        Text(
          _count > 1 ? l.metInPersonTimes(_count, date) : l.metInPersonOn(date),
          style: const TextStyle(
              color: AppColors.successGreen,
              fontSize: 12.5,
              fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}
