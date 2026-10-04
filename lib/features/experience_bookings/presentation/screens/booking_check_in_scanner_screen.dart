import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/booking_rules.dart';

/// Host: scans the guest's check-in QR (`greengo:checkin:{bookingId}:{code}`)
/// and pops with the code when it belongs to [bookingId]. Works in browsers
/// too (mobile_scanner uses getUserMedia on web).
class BookingCheckInScannerScreen extends StatefulWidget {
  const BookingCheckInScannerScreen({super.key, required this.bookingId});
  final String bookingId;

  static Route<String> route(String bookingId) => MaterialPageRoute(
      builder: (_) => BookingCheckInScannerScreen(bookingId: bookingId));

  @override
  State<BookingCheckInScannerScreen> createState() =>
      _BookingCheckInScannerScreenState();
}

class _BookingCheckInScannerScreenState
    extends State<BookingCheckInScannerScreen> {
  final MobileScannerController _controller =
      MobileScannerController(detectionSpeed: DetectionSpeed.normal);
  bool _done = false;
  String? _lastRejected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;
      final parsed = BookingRules.parseCheckInQr(raw);
      if (parsed != null && parsed.bookingId == widget.bookingId) {
        _done = true;
        Navigator.of(context).pop(parsed.code);
        return;
      }
      if (raw != _lastRejected) {
        _lastRejected = raw;
        final l = AppLocalizations.of(context)!;
        // A short bar, not a popup: the camera must stay clear so the host
        // can scan the next code right away. The text is already localized.
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(
                parsed == null ? l.bkErrInvalidCode : l.bkWrongBooking),
            duration: const Duration(milliseconds: 1600),
            behavior: SnackBarBehavior.floating,
          ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        title: Text(l.bkCheckInGuest),
        actions: [
          if (!kIsWeb)
            IconButton(
              tooltip: l.bkTorch,
              onPressed: () => _controller.toggleTorch(),
              icon: const Icon(Icons.flash_on, color: AppColors.richGold),
            ),
          IconButton(
            tooltip: l.bkSwitchCamera,
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch, color: AppColors.richGold),
          ),
        ],
      ),
      body: Stack(children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.no_photography,
                    color: AppColors.textTertiary, size: 48),
                const SizedBox(height: 16),
                Text(l.eventCameraPermission,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ]),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.richGold, width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Text(l.bkScanInstructions,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}
