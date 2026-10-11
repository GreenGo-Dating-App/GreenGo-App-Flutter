import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../safety/presentation/screens/moderation_decision_screen.dart';
import '../../data/copyright_service.dart';
import 'copyright_counter_notice_screen.dart';

/// Notification `data.action` of a copyright removal / restoration.
const String kCopyrightNoticeAction = 'copyright_notice';

/// Copyright notices about the signed-in user's content, their active
/// strikes, and the two remedies: a §512(g) counter-notice and the DSA
/// art. 20 appeal (existing moderation-decision appeal flow).
class CopyrightMyNoticesScreen extends StatelessWidget {
  const CopyrightMyNoticesScreen({super.key, this.service, this.userId});

  final CopyrightService? service;
  final String? userId;

  static Route<void> route() => MaterialPageRoute<void>(builder: (_) => const CopyrightMyNoticesScreen());

  String statusLabel(AppLocalizations l, String status) {
    switch (status) {
      case 'counter_noticed':
        return l.copyrightStatusCounterNoticed;
      case 'restored':
        return l.copyrightStatusRestored;
      case 'lawsuit_filed':
        return l.copyrightStatusLawsuit;
      default:
        return l.copyrightStatusAccepted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    String? uid = userId;
    if (uid == null) {
      try {
        uid = FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {
        uid = null;
      }
    }
    final svc = service ?? CopyrightService();
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(backgroundColor: AppColors.backgroundDark, elevation: 0, title: Text(l.copyrightMyNoticesTitle)),
      body: uid == null
          ? const SizedBox.shrink()
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      StreamBuilder<int>(
                        stream: svc.watchActiveStrikes(uid),
                        builder: (context, snap) => Text(
                          l.copyrightActiveStrikes(snap.data ?? 0),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(l.copyrightPolicyRepeatBody, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                      const SizedBox(height: 16),
                      StreamBuilder<List<CopyrightNoticeView>>(
                        stream: svc.watchNoticesAboutMe(uid),
                        builder: (context, snap) {
                          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                          final items = snap.data!;
                          if (items.isEmpty) {
                            return Text(l.copyrightMyNoticesEmpty, style: const TextStyle(color: AppColors.textSecondary));
                          }
                          return Column(
                            children: [
                              for (final n in items)
                                Card(
                                  color: AppColors.backgroundCard,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(statusLabel(l, n.status),
                                            style: const TextStyle(color: AppColors.richGold, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 6),
                                        Text(l.copyrightNoticeFrom(n.complainantName, n.complainantEmail),
                                            style: const TextStyle(color: AppColors.textPrimary)),
                                        const SizedBox(height: 4),
                                        Text('${l.copyrightFormWorkDescription}: ${n.work}',
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                        Text('${l.copyrightFormContentLocation}: ${n.location}',
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                        if (n.status == 'counter_noticed' && n.restoreAfter != null) ...[
                                          const SizedBox(height: 6),
                                          Text(l.copyrightRestoreOn(DateFormat.yMMMd(locale).format(n.restoreAfter!.toLocal())),
                                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                        ],
                                        if (n.status == 'accepted') ...[
                                          const SizedBox(height: 10),
                                          Wrap(spacing: 8, runSpacing: 8, children: [
                                            ElevatedButton(
                                              key: ValueKey('counter-${n.id}'),
                                              onPressed: () => Navigator.of(context).push(CopyrightCounterNoticeScreen.route(n)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.richGold,
                                                foregroundColor: AppColors.deepBlack,
                                              ),
                                              child: Text(l.copyrightCounterButton),
                                            ),
                                            if (n.decisionId != null)
                                              OutlinedButton(
                                                onPressed: () => Navigator.of(context).push(ModerationDecisionScreen.route(ModerationDecision(
                                                  decisionId: n.decisionId!,
                                                  moderationAction: 'removeContent',
                                                  reasonCode: 'copyright',
                                                  explanation: n.decisionReason ?? '',
                                                  appealable: true,
                                                  appealDeadline: n.decidedAt?.add(const Duration(days: 183)),
                                                ))),
                                                child: Text(l.copyrightAppealButton),
                                              ),
                                          ]),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
