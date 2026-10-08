import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';

/// Notification `data.action` of a moderation decision (DSA art. 17).
const String kModerationDecisionAction = 'moderation_decision';

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
  });

  /// Parses the notification `data` map (in-app doc or FCM payload, where
  /// every value is a string). Returns null without a decision id.
  static ModerationDecision? fromData(Map<String, dynamic> data) {
    final id = data['decisionId'];
    if (id is! String || id.isEmpty) return null;
    final appealable = data['appealable'];
    final deadline = data['appealDeadline'];
    return ModerationDecision(
      decisionId: id,
      moderationAction: (data['moderationAction'] as String?) ?? '',
      reasonCode: (data['reasonCode'] as String?) ?? 'other',
      explanation: (data['explanation'] as String?) ?? '',
      appealable: appealable == true || appealable == 'true',
      appealDeadline: deadline is String ? DateTime.tryParse(deadline) : null,
    );
  }

  final String decisionId;
  final String moderationAction;
  final String reasonCode;
  final String explanation;
  final bool appealable;
  final DateTime? appealDeadline;

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
    default:
      return l10n.moderationReasonOther;
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
        appealArea = [_note(l10n.moderationDecisionAppealSent)];
      case _AppealState.already:
        appealArea = [_note(l10n.moderationDecisionAppealAlready)];
      case _AppealState.closed:
        appealArea = [_note(l10n.moderationDecisionAppealClosed)];
      case _AppealState.idle:
        if (!d.appealable) {
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
            ElevatedButton.icon(
              key: const Key('appealButton'),
              onPressed: _openAppealDialog,
              icon: const Icon(Icons.gavel_outlined),
              label: Text(l10n.moderationDecisionAppealButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ];
        }
    }

    return Scaffold(
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
                Text(l10n.moderationDecisionIntro,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
                const SizedBox(height: 20),
                field(l10n.moderationDecisionActionLabel,
                    moderationActionLabel(l10n, d.moderationAction)),
                field(l10n.moderationDecisionReasonLabel,
                    moderationReasonLabel(l10n, d.reasonCode)),
                if (d.explanation.trim().isNotEmpty)
                  field(l10n.moderationDecisionExplanationLabel, d.explanation),
                const SizedBox(height: 8),
                ...appealArea,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _note(String text) => Text(text,
      style: const TextStyle(color: AppColors.textSecondary, height: 1.4));
}
