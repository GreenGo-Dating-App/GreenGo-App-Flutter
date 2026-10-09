import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';

/// Result of asking the server to email the participants list.
enum ParticipantsListOutcome { sent, rateLimited, noEmail, failed }

/// Organizer tool: emails the participants list (CSV) of an event or an
/// experience slot to the caller's account email (`sendParticipantsList`
/// callable; organizer / co-organizer / host only, 1 request per 5 minutes).
class ParticipantsListService {
  ParticipantsListService({FirebaseFunctions? functions}) : _functions = functions;

  final FirebaseFunctions? _functions;
  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instance;

  /// [kind] is 'event' or 'experience'. For an experience, [slotStart] picks
  /// the date; without it the server uses the next slot with bookings.
  Future<ParticipantsListOutcome> send({
    required String kind,
    required String id,
    DateTime? slotStart,
  }) async {
    try {
      await _fn.httpsCallable('sendParticipantsList').call<dynamic>({
        'kind': kind,
        'id': id,
        if (slotStart != null) 'slotStart': slotStart.millisecondsSinceEpoch,
      });
      return ParticipantsListOutcome.sent;
    } on FirebaseFunctionsException catch (e) {
      return outcomeFor(e.code, e.message);
    } catch (_) {
      return ParticipantsListOutcome.failed;
    }
  }

  /// Maps a callable error (code + reason) to an outcome. Public for tests.
  static ParticipantsListOutcome outcomeFor(String code, String? reason) {
    if (code == 'resource-exhausted') return ParticipantsListOutcome.rateLimited;
    if (code == 'failed-precondition' && reason == 'no_email') {
      return ParticipantsListOutcome.noEmail;
    }
    return ParticipantsListOutcome.failed;
  }
}

/// Localized snackbar text for [outcome].
String participantsListMessage(AppLocalizations l, ParticipantsListOutcome outcome) {
  switch (outcome) {
    case ParticipantsListOutcome.sent:
      return l.participantsEmailSent;
    case ParticipantsListOutcome.rateLimited:
      return l.participantsEmailRateLimited;
    case ParticipantsListOutcome.noEmail:
      return l.participantsEmailNoEmail;
    case ParticipantsListOutcome.failed:
      return l.participantsEmailFailed;
  }
}

/// Calls the service and confirms the result with a snackbar.
Future<ParticipantsListOutcome> emailParticipantsList(
  BuildContext context, {
  required String kind,
  required String id,
  DateTime? slotStart,
  ParticipantsListService? service,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l = AppLocalizations.of(context)!;
  final outcome = await (service ?? ParticipantsListService())
      .send(kind: kind, id: id, slotStart: slotStart);
  messenger?.showSnackBar(SnackBar(
    key: ValueKey('participants-email-${outcome.name}'),
    content: Text(participantsListMessage(l, outcome)),
  ));
  return outcome;
}

/// "Email me the participants list" button (organizer views), with a
/// spinner while the request runs.
class EmailParticipantsButton extends StatefulWidget {
  const EmailParticipantsButton({
    required this.kind,
    required this.id,
    this.slotStart,
    this.service,
    super.key,
  });

  final String kind;
  final String id;
  final DateTime? slotStart;
  final ParticipantsListService? service;

  @override
  State<EmailParticipantsButton> createState() => _EmailParticipantsButtonState();
}

class _EmailParticipantsButtonState extends State<EmailParticipantsButton> {
  bool _busy = false;

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await emailParticipantsList(context,
          kind: widget.kind, id: widget.id, slotStart: widget.slotStart, service: widget.service);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      key: const ValueKey('email-participants-list'),
      onPressed: _busy ? null : _send,
      icon: _busy
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.forward_to_inbox_outlined),
      label: Text(l.participantsEmailButton),
    );
  }
}
