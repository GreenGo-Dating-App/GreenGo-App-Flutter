import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A full-screen APPROVED / DENIED confirmation shown after scanning an event
/// ticket QR code. Entirely green (approved) or red (denied), centered, showing
/// the attendee's name, a big approved/denied icon, and the date-time of the
/// scan. Auto-dismisses after a short delay or on tap.
///
/// Shared by the QR hub scanner and the per-event scanner so both surfaces show
/// exactly the same door-check result.
Future<void> showScanResult(
  BuildContext context, {
  required bool approved,
  required String statusLabel,
  required DateTime time,
  String? name,
  String? detail,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: statusLabel,
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => _ScanResultPage(
      approved: approved,
      statusLabel: statusLabel,
      time: time,
      name: name,
      detail: detail,
    ),
    transitionBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}

class _ScanResultPage extends StatefulWidget {
  const _ScanResultPage({
    required this.approved,
    required this.statusLabel,
    required this.time,
    this.name,
    this.detail,
  });

  final bool approved;
  final String statusLabel;
  final DateTime time;
  final String? name;
  final String? detail;

  @override
  State<_ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<_ScanResultPage> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss so the scanner can move on to the next ticket hands-free.
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.approved ? Colors.green.shade600 : Colors.red.shade700;
    final name = widget.name?.trim();
    final formattedTime = DateFormat('EEE, MMM d • h:mm a').format(widget.time);

    return Material(
      color: bg,
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        splashColor: Colors.white24,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.approved
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: Colors.white,
                    size: 120,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.statusLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (name != null && name.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (widget.detail != null && widget.detail!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.detail!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
