import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../app_tour/presentation/widgets/page_tour_host.dart';
import '../../../app_tour/presentation/tour_environment.dart';
import '../../../app_tour/presentation/tour_keys.dart';
import '../../../app_tour/presentation/tour_controller.dart';

/// Notification `data.action` of a moderation decision (DSA art. 17).
const String kModerationDecisionAction = 'moderation_decision';

/// Notification `data.action` of the reporter's "your report was reviewed"
/// notice. When it carries a `decisionId` (no action taken), the reporter can
/// appeal that decision (Terms 18.4 a, DSA art. 20).
const String kReportReviewedAction = 'report_reviewed';

/// True when a notification payload opens [ModerationDecisionScreen].
bool isModerationDecisionPayload(Map<String, dynamic> data) {
  final action = data['action'];
  if (action == kModerationDecisionAction) return true;
  final id = data['decisionId'];
  return action == kReportReviewedAction && id is String && id.isNotEmpty;
}

/// A moderation decision as carried by the notification payload.
@immutable
class ModerationDecision {
  const ModerationDecision({
    required this.decisionId,
    required this.moderationAction,
    required this.reasonCode,
    required this.explanation,
    required this.appealable,
    this.appealDeadline,
    this.role = 'affected',
    this.contentType = '',
    this.contentId = '',
    this.contentExcerpt = '',
    this.automated = false,
    this.automatedDecision = false,
    this.appealOutcome = '',
    this.appealExplanation = '',
  });

  /// Parses the notification `data` map (in-app doc or FCM payload, where
  /// every value is a string). Returns null without a decision id.
  static ModerationDecision? fromData(Map<String, dynamic> data) {
    final id = data['decisionId'];
    if (id is! String || id.isEmpty) return null;
    final appealable = data['appealable'];
    final deadline = data['appealDeadline'];
    bool flag(String k) => data[k] == true || data[k] == 'true';
    String str(String k) => data[k] is String ? data[k] as String : '';
    return ModerationDecision(
      decisionId: id,
      moderationAction: (data['moderationAction'] as String?) ?? '',
      reasonCode: (data['reasonCode'] as String?) ?? 'other',
      explanation: (data['explanation'] as String?) ?? '',
      appealable: appealable == true || appealable == 'true',
      appealDeadline: deadline is String ? DateTime.tryParse(deadline) : null,
      role: str('role').isEmpty ? 'affected' : str('role'),
      contentType: str('contentType'),
      contentId: str('contentId'),
      contentExcerpt: str('contentExcerpt'),
      automated: flag('automated'),
      automatedDecision: flag('automatedDecision'),
      appealOutcome: str('appealOutcome'),
      appealExplanation: str('appealExplanation'),
    );
  }

  final String decisionId;
  final String moderationAction;
  final String reasonCode;
  final String explanation;
  final bool appealable;
  final DateTime? appealDeadline;

  /// 'affected' (action on your account / content) or 'reporter' (decision
  /// not to act on a report you made).
  final String role;

  /// Which content the decision concerns (Terms 18.3).
  final String contentType;
  final String contentId;
  final String contentExcerpt;

  /// Automated tools detected / flagged the item.
  final bool automated;

  /// The automated tool itself applied the measure (held upload).
  final bool automatedDecision;

  /// upheld | overturned | partially_overturned | report_reopened, or empty.
  final String appealOutcome;
  final String appealExplanation;

  bool get isReporterDecision => role == 'reporter';

  bool get appealWindowOpen =>
      appealable &&
      (appealDeadline == null || appealDeadline!.isAfter(DateTime.now()));
}

/// Calls the `submitAppeal` callable. Abstracted for tests.
typedef AppealSubmitter = Future<void> Function(
    {required String decisionId, required String appealReason});

Future<void> _submitAppeal(
    {required String decisionId, required String appealReason}) async {
  await FirebaseFunctions.instance
      .httpsCallable('submitAppeal',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 30)))
      .call<dynamic>({'decisionId': decisionId, 'appealReason': appealReason});
}

String moderationActionLabel(AppLocalizations l10n, String action) {
  switch (action) {
    case 'removeContent':
      return l10n.moderationActionRemoveContent;
    case 'issueWarning':
      return l10n.moderationActionWarning;
    case 'suspendUser':
      return l10n.moderationActionSuspend;
    case 'banUser':
      return l10n.moderationActionBan;
    case 'shadowBan':
      return l10n.moderationActionShadowBan;
    case 'requireVerification':
      return l10n.moderationActionRequireVerification;
    case 'restrictAccount':
      return l10n.moderationActionRestrict;
    case 'noAction':
      return l10n.moderationActionNoAction;
    case 'reporterWarning':
      return l10n.moderationActionReporterWarning;
    case 'suspendReporting':
      return l10n.moderationActionSuspendReporting;
    default:
      return l10n.moderationActionOther;
  }
}

String moderationReasonLabel(AppLocalizations l10n, String code) {
  switch (code) {
    case 'csae':
      return l10n.moderationReasonCsae;
    case 'underage':
      return l10n.moderationReasonUnderage;
    case 'sexual_content':
      return l10n.moderationReasonSexualContent;
    case 'inappropriate':
      return l10n.moderationReasonInappropriate;
    case 'threats':
      return l10n.moderationReasonThreats;
    case 'violence':
      return l10n.moderationReasonViolence;
    case 'harassment':
      return l10n.moderationReasonHarassment;
    case 'hate':
      return l10n.moderationReasonHate;
    case 'spam':
      return l10n.moderationReasonSpam;
    case 'scam':
      return l10n.moderationReasonScam;
    case 'impersonation':
      return l10n.moderationReasonImpersonation;
    case 'privacy':
      return l10n.moderationReasonPrivacy;
    case 'misleading':
      return l10n.moderationReasonMisleading;
    case 'no_show':
      return l10n.moderationReasonNoShow;
    case 'off_platform_payment':
      return l10n.moderationReasonOffPlatformPayment;
    case 'copyright':
      return l10n.copyrightHelpEntry;
    case 'ncii':
      return l10n.safetyReportReasonNcii;
    case 'no_violation':
      return l10n.moderationReasonNoViolation;
    case 'unfounded_reports':
      return l10n.moderationReasonUnfoundedReports;
    case 'repeat_violations':
      return l10n.moderationReasonRepeatViolations;
    default:
      return l10n.moderationReasonOther;
  }
}

/// "Message: "excerpt"" / "Photo (a.jpg)" / "Your account" (Terms 18.3).
String moderationContentLabel(AppLocalizations l10n, ModerationDecision d) {
  final String type;
  switch (d.contentType) {
    case 'message':
      type = l10n.moderationContentTypeMessage;
    case 'photo':
      type = l10n.moderationContentTypePhoto;
    case 'profile':
      type = l10n.moderationContentTypeProfile;
    case 'event':
      type = l10n.moderationContentTypeEvent;
    case 'experience':
      type = l10n.moderationContentTypeExperience;
    case 'review':
      type = l10n.moderationContentTypeReview;
    case 'report':
      type = l10n.moderationContentTypeReport;
    case 'account':
    case '':
      type = d.isReporterDecision
          ? l10n.moderationContentTypeReport
          : l10n.moderationContentTypeAccount;
    default:
      type = l10n.moderationContentTypeOther;
  }
  if (d.contentExcerpt.trim().isNotEmpty) return '$type: "${d.contentExcerpt}"';
  final showId = d.contentId.isNotEmpty &&
      !const {'account', 'profile', 'report', ''}.contains(d.contentType);
  return showId ? '$type (${d.contentId})' : type;
}

String moderationAutomatedLabel(AppLocalizations l10n, ModerationDecision d) {
  if (d.automatedDecision) return l10n.moderationDecisionAutomatedHeld;
  if (d.automated) return l10n.moderationDecisionAutomatedFlagged;
  return l10n.moderationDecisionAutomatedNone;
}

String? moderationAppealOutcomeLabel(AppLocalizations l10n, String outcome) {
  switch (outcome) {
    case 'upheld':
      return l10n.moderationAppealOutcomeUpheld;
    case 'overturned':
      return l10n.moderationAppealOutcomeOverturned;
    case 'partially_overturned':
      return l10n.moderationAppealOutcomePartial;
    case 'report_reopened':
      return l10n.moderationAppealOutcomeReportReopened;
    default:
      return null;
  }
}

/// Statement of reasons for a moderation action + in-app appeal (DSA art.
/// 17 / 20). Opened from the in-app notification list and from a push tap.
class ModerationDecisionScreen extends StatefulWidget {
  const ModerationDecisionScreen({
    required this.decision,
    super.key,
    this.submitter,
  });

  final ModerationDecision decision;
  final AppealSubmitter? submitter;

  static Route<void> route(ModerationDecision decision) => MaterialPageRoute(
        builder: (_) => ModerationDecisionScreen(decision: decision),
      );

  @override
  State<ModerationDecisionScreen> createState() =>
      _ModerationDecisionScreenState();
}

enum _AppealState { idle, sending, sent, already, closed }

class _ModerationDecisionScreenState extends State<ModerationDecisionScreen> {
  _AppealState _appeal = _AppealState.idle;

  /// Owned by the state (not the dialog) so it outlives the dialog's exit
  /// animation.
  final TextEditingController _appealController = TextEditingController();

  @override
  void dispose() {
    _appealController.dispose();
    super.dispose();
  }

  Future<void> _openAppealDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = _appealController;
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String? error;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            title: Text(l10n.moderationDecisionAppealButton,
                style: const TextStyle(color: AppColors.textPrimary)),
            content: SizedBox(
              width: 480,
              child: TextField(
                key: const Key('appealReasonField'),
                controller: controller,
                maxLines: 6,
                minLines: 3,
                maxLength: 2000,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.moderationDecisionAppealHint,
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  errorText: error,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                key: const Key('appealSubmit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                ),
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.length < 10) {
                    setLocal(() => error = l10n.moderationDecisionAppealTooShort);
                    return;
                  }
                  Navigator.of(ctx).pop(text);
                },
                child: Text(l10n.moderationDecisionAppealSubmit),
              ),
            ],
          ),
        );
      },
    );
    if (reason == null || !mounted) return;
    await _send(reason);
  }

  Future<void> _send(String reason) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _appeal = _AppealState.sending);
    String? message;
    var next = _AppealState.idle;
    try {
      await (widget.submitter ?? _submitAppeal)(
        decisionId: widget.decision.decisionId,
        appealReason: reason,
      );
      next = _AppealState.sent;
      message = l10n.moderationDecisionAppealSent;
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'already-exists':
          next = _AppealState.already;
          message = l10n.moderationDecisionAppealAlready;
        case 'failed-precondition':
          next = _AppealState.closed;
          message = l10n.moderationDecisionAppealClosed;
        default:
          message = l10n.moderationDecisionAppealError;
      }
    } catch (_) {
      message = l10n.moderationDecisionAppealError;
    }
    if (!mounted) return;
    setState(() => _appeal = next);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor:
          next == _AppealState.idle ? AppColors.errorRed : AppColors.backgroundCard,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = widget.decision;
    final locale = Localizations.localeOf(context).toLanguageTag();

    Widget field(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15, height: 1.4)),
            ],
          ),
        );

    final List<Widget> appealArea;
    switch (_appeal) {
      case _AppealState.sending:
        appealArea = const [Center(child: CircularProgressIndicator())];
      case _AppealState.sent:
        appealArea = [
          _note(l10n.moderationDecisionAppealSent),
          const SizedBox(height: 8),
          _note(l10n.moderationAppealOutcomePending),
        ];
      case _AppealState.already:
        appealArea = [_note(l10n.moderationDecisionAppealAlready)];
      case _AppealState.closed:
        appealArea = [_note(l10n.moderationDecisionAppealClosed)];
      case _AppealState.idle:
        final outcome = moderationAppealOutcomeLabel(l10n, d.appealOutcome);
        if (outcome != null) {
          appealArea = [
            field(l10n.moderationAppealOutcomeLabel, outcome),
            if (d.appealExplanation.trim().isNotEmpty)
              field(l10n.moderationAppealReviewerNoteLabel, d.appealExplanation),
          ];
        } else if (!d.appealable) {
          appealArea = [_note(l10n.moderationDecisionNotAppealable)];
        } else if (!d.appealWindowOpen) {
          appealArea = [_note(l10n.moderationDecisionAppealClosed)];
        } else {
          appealArea = [
            if (d.appealDeadline != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.moderationDecisionAppealUntil(
                      DateFormat.yMMMd(locale).format(d.appealDeadline!.toLocal())),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            TourAnchor(
              tourId: TourController.safetyAppealTourId,
              showcaseKey: TourKeys.safetyAppeal,
              title: l10n.tourSafetyAppealTitle,
              description: l10n.tourSafetyAppealDesc,
              child: ElevatedButton.icon(
              key: const Key('appealButton'),
              onPressed: _openAppealDialog,
              icon: const Icon(Icons.gavel_outlined),
              label: Text(l10n.moderationDecisionAppealButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            )),
          ];
        }
    }

    return PageTourHost(
      tourId: TourController.safetyAppealTourId,
      userId: TourEnvironment.currentUid(),
      keys: () => [TourKeys.safetyAppeal],
      child: Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(l10n.moderationDecisionTitle),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                    d.isReporterDecision
                        ? l10n.moderationDecisionReporterIntro
                        : l10n.moderationDecisionIntro,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
                const SizedBox(height: 20),
                field(l10n.moderationDecisionActionLabel,
                    moderationActionLabel(l10n, d.moderationAction)),
                field(l10n.moderationDecisionReasonLabel,
                    moderationReasonLabel(l10n, d.reasonCode)),
                field(l10n.moderationDecisionContentLabel,
                    moderationContentLabel(l10n, d)),
                if (d.explanation.trim().isNotEmpty)
                  field(l10n.moderationDecisionExplanationLabel, d.explanation),
                field(l10n.moderationDecisionAutomatedLabel,
                    moderationAutomatedLabel(l10n, d)),
                const SizedBox(height: 8),
                ...appealArea,
                const SizedBox(height: 24),
                Text(l10n.moderationDecisionOtherOptions,
                    key: const Key('moderationOtherOptions'),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _note(String text) => Text(text,
      style: const TextStyle(color: AppColors.textSecondary, height: 1.4));
}
