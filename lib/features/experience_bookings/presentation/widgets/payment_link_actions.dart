import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../user_experiences/domain/entities/user_experience.dart';

/// Opens the host's payment link (a URL) or copies it (a PIX key / any
/// non-URL value). The payment happens outside GreenGo.
Future<void> openBookingPaymentLink(
    BuildContext context, PaymentLink link) async {
  final l = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  if (!link.isOpenable) {
    await Clipboard.setData(ClipboardData(text: link.value));
    messenger.showSnackBar(SnackBar(content: Text(l.uexpPixCopied)));
    return;
  }
  final uri = Uri.tryParse(link.value);
  final ok = uri != null &&
      await launchUrl(uri, mode: LaunchMode.externalApplication)
          .catchError((_) => false);
  if (!ok) {
    messenger.showSnackBar(SnackBar(
        content: Text(l.uexpOpenLinkFailed),
        backgroundColor: AppColors.errorRed));
  }
}
