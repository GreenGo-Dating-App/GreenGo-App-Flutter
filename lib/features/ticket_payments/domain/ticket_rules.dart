import 'package:equatable/equatable.dart';

import '../../events/domain/entities/event.dart';
import 'ticket_payments.dart';

/// Event ticket / guest rules (owner request 2026-10-17/18). Mirrors
/// functions/src/ticket_payments/ticketRules.ts; the server is the source of
/// truth (createTicketCheckout + firestore.rules), the app only shows the
/// same limits up front.
///
///  * at most [kMaxTicketsPerBuyer] paid tickets per buyer per event (all
///    their open and paid orders together), see [eventTicketLimit];
///  * "Ask for attendee names": a first + last name per ticket
///    ([cleanAttendeeName], [kAttendeeNameMaxLength]);
///  * plus-ones only on free events ([Event.plusOnesAllowed]) and every
///    going attendee takes 1 + plus-ones places ([Event.goingCount]).

/// Owner rule 2026-10-18 (= MAX_TICKETS_PER_BUYER in
/// functions/src/ticket_payments/config.ts; a test keeps them in sync).
const int kMaxTicketsPerBuyer = 4;

/// Max length of an attendee's first / last name (= ATTENDEE_NAME_MAX).
const int kAttendeeNameMaxLength = 50;

/// The per-buyer cap of [event]: its own limit (null = none) but never above
/// [kMaxTicketsPerBuyer].
int eventTicketLimit(Event event) {
  final own = event.maxTicketsPerUser;
  if (own == null || own <= 0 || own > kMaxTicketsPerBuyer) return kMaxTicketsPerBuyer;
  return own;
}

/// How many more tickets the buyer may pick now: the per-event cap minus what
/// they already hold or own, and the places left.
int ticketsBuyerCanAdd(Event event, {required int alreadyHeld, required int? remainingCapacity}) =>
    remainingForBuyer(
      limit: eventTicketLimit(event),
      alreadyHeld: alreadyHeld,
      remainingCapacity: remainingCapacity,
    ) ??
    kMaxTicketsPerBuyer;

final RegExp _badNameChars =
    RegExp('[\u0000-\u001f\u007f-\u009f\u200b-\u200f\u202a-\u202e\u2066-\u2069\ufeff<>]');

/// A trimmed name (inner whitespace collapsed), 1..[kAttendeeNameMaxLength]
/// characters, or null when empty / too long / with control characters.
String? cleanAttendeeName(String? v) {
  if (v == null) return null;
  final s = v.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.isEmpty || s.runes.length > kAttendeeNameMaxLength || _badNameChars.hasMatch(s)) return null;
  return s;
}

/// The holder of one ticket.
class AttendeeName extends Equatable {
  const AttendeeName(this.firstName, this.lastName);

  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName';

  Map<String, String> toMap() => {'firstName': firstName, 'lastName': lastName};

  @override
  List<Object?> get props => [firstName, lastName];
}

/// One [AttendeeName] per row when every row is valid, else null.
List<AttendeeName>? validAttendeeNames(List<(String, String)> rows) {
  final out = <AttendeeName>[];
  for (final (f, l) in rows) {
    final first = cleanAttendeeName(f);
    final last = cleanAttendeeName(l);
    if (first == null || last == null) return null;
    out.add(AttendeeName(first, last));
  }
  return out;
}

/// The editor's "tickets per person" text: empty = the cap; otherwise it
/// must be 1..[kMaxTicketsPerBuyer].
bool ticketsPerBuyerInvalid(String text) {
  final t = text.trim();
  if (t.isEmpty) return false;
  final n = int.tryParse(t);
  return n == null || n < 1 || n > kMaxTicketsPerBuyer;
}

/// The value saved for "tickets per person" (1..[kMaxTicketsPerBuyer]).
int ticketsPerBuyerValue(String text) {
  final n = int.tryParse(text.trim());
  if (n == null || n < 1 || n > kMaxTicketsPerBuyer) return kMaxTicketsPerBuyer;
  return n;
}

/// Rule 4: a capacity (> 0) lower than the tickets of the price phases.
/// Returns the phases total to show in the message, or null when it fits
/// (unlimited, no phases, or capacity >= total).
int? capacityBelowPhases({required int? capacity, required bool unlimited, required Iterable<int> phaseQuantities}) {
  if (unlimited || capacity == null || capacity < 1) return null;
  final total = phaseQuantities.fold<int>(0, (s, q) => s + q);
  if (total == 0 || capacity >= total) return null;
  return total;
}
