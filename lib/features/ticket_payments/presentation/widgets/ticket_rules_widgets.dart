import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/ticket_rules.dart';

/// Event editor, Tickets step (owner rules 2026-10-18), kept apart from the
/// big editor so it can be widget-tested:
///
///  * [PlusOnesField]: "Guests allowed per attendee" stepper on FREE events;
///    on paid events a note instead (every person needs their own ticket).
///  * [TicketsPerBuyerField]: tickets per person, 1..[kMaxTicketsPerBuyer].
///  * [AttendeeNamesSwitch]: "Ask for attendee names" (paid events).
class PlusOnesField extends StatelessWidget {
  const PlusOnesField({
    super.key,
    required this.isFree,
    required this.value,
    required this.onChanged,
    this.max = 10,
  });

  final bool isFree;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (!isFree) {
      return Text(
        l.eventPlusOnesPaidNote,
        key: const ValueKey('event-plus-ones-paid-note'),
        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5),
      );
    }
    return Row(
      key: const ValueKey('event-guests-per-attendee'),
      children: [
        Expanded(
          child: Text(l.eventGuestsAllowedLabel, style: const TextStyle(color: AppColors.textPrimary)),
        ),
        IconButton(
          key: const ValueKey('event-guests-minus'),
          onPressed: value <= 0 ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.richGold,
        ),
        Text(
          '$value',
          key: const ValueKey('event-guests-value'),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        IconButton(
          key: const ValueKey('event-guests-plus'),
          onPressed: value >= max ? null : () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.richGold,
        ),
      ],
    );
  }
}

/// Tickets per person (1..[kMaxTicketsPerBuyer], all their orders together).
class TicketsPerBuyerField extends StatelessWidget {
  const TicketsPerBuyerField({super.key, required this.controller, required this.decoration, this.onChanged});

  final TextEditingController controller;
  final InputDecoration decoration;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return TextFormField(
      key: const ValueKey('event-max-per-user'),
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      keyboardType: TextInputType.number,
      decoration: decoration.copyWith(
        labelText: l.tpMaxTicketsPerUser,
        helperText: l.tpMaxTicketsPerUserRange(kMaxTicketsPerBuyer),
        helperStyle: const TextStyle(color: AppColors.textTertiary),
        errorText: ticketsPerBuyerInvalid(controller.text) ? l.tpMaxTicketsPerUserRange(kMaxTicketsPerBuyer) : null,
      ),
      onChanged: onChanged,
    );
  }
}

/// "Ask for attendee names" switch (paid events).
class AttendeeNamesSwitch extends StatelessWidget {
  const AttendeeNamesSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SwitchListTile(
      key: const ValueKey('event-require-names'),
      contentPadding: EdgeInsets.zero,
      title: Text(l.tpAttendeeNamesSwitch, style: const TextStyle(color: AppColors.textPrimary)),
      subtitle: Text(
        l.tpAttendeeNamesSwitchHint,
        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.3),
      ),
      value: value,
      activeThumbColor: AppColors.richGold,
      onChanged: onChanged,
    );
  }
}
