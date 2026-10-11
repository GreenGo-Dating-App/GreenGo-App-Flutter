import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/copyright_service.dart';
import 'copyright_my_notices_screen.dart';
import 'copyright_notice_form_screen.dart';

/// In-app copyright policy (DMCA §512, EU DSA, Brazil Lei 9.610) with the
/// designated agent and the entry points to the notice form and to the
/// notices about the user's own content. Reached from Help & Support.
class CopyrightPolicyScreen extends StatelessWidget {
  const CopyrightPolicyScreen({super.key});

  static Route<void> route() => MaterialPageRoute<void>(builder: (_) => const CopyrightPolicyScreen());

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    Widget section(String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.richGold, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              SelectableText(body, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5)),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(backgroundColor: AppColors.backgroundDark, elevation: 0, title: Text(l.copyrightPolicyTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(l.copyrightPolicyIntro, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  key: const ValueKey('copyright-open-form'),
                  onPressed: () => openCopyrightNoticeForm(context),
                  icon: const Icon(Icons.copyright),
                  label: Text(l.copyrightPolicySubmitButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const ValueKey('copyright-open-mine'),
                  onPressed: () => Navigator.of(context).push(CopyrightMyNoticesScreen.route()),
                  icon: const Icon(Icons.folder_shared_outlined),
                  label: Text(l.copyrightMyNoticesButton),
                ),
                const SizedBox(height: 24),
                section(l.copyrightPolicyNoticeTitle, l.copyrightPolicyNoticeBody),
                section(l.copyrightPolicyCounterTitle, l.copyrightPolicyCounterBody),
                section(l.copyrightPolicyRepeatTitle, l.copyrightPolicyRepeatBody),
                section(l.copyrightPolicyMisrepTitle, l.copyrightPolicyMisrepBody),
                section(l.copyrightPolicyJurisdictionTitle, l.copyrightPolicyJurisdictionBody),
                section(l.copyrightPolicyAgentTitle, l.copyrightPolicyAgentBody(kCopyrightAgentPostalAddress)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
