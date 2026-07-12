import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';

/// "I've arrived safely" event check-in, shown on the event detail body to a
/// user who is GOING to the event.
///
/// Writes `checkedInSafe:true` + `checkedInSafeAt` onto the user's OWN attendee
/// doc (`events/{eventId}/attendees/{userId}`). That doc is already writable by
/// its owner under the existing firestore rules, so no rules change or new
/// collection is needed. Bounded to a single self-write per event.
class EventSafetyCheckIn extends StatefulWidget {

  const EventSafetyCheckIn({
    required this.eventId,
    required this.userId,
    super.key,
  });

  final String eventId;
  final String userId;

  @override
  State<EventSafetyCheckIn> createState() => _EventSafetyCheckInState();
}

class _EventSafetyCheckInState extends State<EventSafetyCheckIn> {
  bool _checkedIn = false;
  bool _loading = true;
  bool _submitting = false;

  DocumentReference<Map<String, dynamic>> get _attendeeRef =>
      FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('attendees')
          .doc(widget.userId);

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final doc = await _attendeeRef.get();
      final already = doc.data()?['checkedInSafe'] == true;
      if (mounted) {
        setState(() {
          _checkedIn = already;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkIn() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();
    try {
      await _attendeeRef.set({
        'checkedInSafe': true,
        'checkedInSafeAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        setState(() {
          _checkedIn = true;
          _submitting = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    if (_checkedIn) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.successGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.successGreen.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_user,
                color: AppColors.successGreen, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.safetyCheckInDone,
                style: const TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.successGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.safetyCheckInTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _checkIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                l10n.safetyCheckInArrived,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
