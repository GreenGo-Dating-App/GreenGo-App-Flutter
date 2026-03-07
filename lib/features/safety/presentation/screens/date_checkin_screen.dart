import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/date_checkin.dart';

/// Date Check-in Screen - Safety feature for real dates
class DateCheckInScreen extends StatefulWidget {
  final String userId;
  final String? matchId;
  final String? matchName;
  final Function(DateCheckIn)? onCheckInCreated;

  const DateCheckInScreen({
    super.key,
    required this.userId,
    this.matchId,
    this.matchName,
    this.onCheckInCreated,
  });

  @override
  State<DateCheckInScreen> createState() => _DateCheckInScreenState();
}

class _DateCheckInScreenState extends State<DateCheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Duration _checkInInterval = const Duration(minutes: 30);
  bool _shareLocation = false;
  final List<EmergencyContact> _emergencyContacts = [];

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.richGold,
              surface: AppColors.backgroundCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.richGold,
              surface: AppColors.backgroundCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _addEmergencyContact() {
    showDialog(
      context: context,
      builder: (context) => _AddEmergencyContactDialog(
        onAdd: (contact) {
          setState(() {
            _emergencyContacts.add(contact);
          });
        },
      ),
    );
  }

  void _removeContact(EmergencyContact contact) {
    setState(() {
      _emergencyContacts.remove(contact);
    });
  }

  void _createCheckIn() {
    if (!_formKey.currentState!.validate()) return;

    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.safetyAddAtLeastOneContact),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final checkIn = DateCheckIn(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: widget.userId,
      matchId: widget.matchId,
      matchName: widget.matchName,
      locationName: _locationController.text,
      scheduledDate: scheduledDateTime,
      checkInInterval: _checkInInterval,
      emergencyContacts: _emergencyContacts,
      status: CheckInStatus.scheduled,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: DateTime.now(),
      shareLocationEnabled: _shareLocation,
    );

    widget.onCheckInCreated?.call(checkIn);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.safetyCheckInScheduled),
        backgroundColor: AppColors.successGreen,
      ),
    );

    Navigator.pop(context, checkIn);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.safetyDateCheckIn,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Safety banner
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: AppColors.successGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield,
                      color: AppColors.successGreen,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.safetyStaySafe,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.safetyCheckInDescription,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Meeting with
              if (widget.matchName != null) ...[
                Text(
                  l10n.safetyMeetingWith,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.richGold.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: AppColors.richGold),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.matchName!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Location
              Text(
                l10n.safetyLocation,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.safetyMeetingLocationHint,
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.location_on, color: AppColors.richGold),
                  filled: true,
                  fillColor: AppColors.backgroundCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.safetyPleaseEnterLocation;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Date & Time
              Text(
                l10n.safetyDateTime,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingM),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.richGold, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM d, yyyy').format(_selectedDate),
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingM),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: AppColors.richGold, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Check-in interval
              Text(
                l10n.safetyCheckInEvery,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _IntervalChip(
                    label: l10n.safetyInterval15Min,
                    selected: _checkInInterval.inMinutes == 15,
                    onTap: () => setState(() => _checkInInterval = const Duration(minutes: 15)),
                  ),
                  _IntervalChip(
                    label: l10n.safetyInterval30Min,
                    selected: _checkInInterval.inMinutes == 30,
                    onTap: () => setState(() => _checkInInterval = const Duration(minutes: 30)),
                  ),
                  _IntervalChip(
                    label: l10n.safetyInterval1Hour,
                    selected: _checkInInterval.inMinutes == 60,
                    onTap: () => setState(() => _checkInInterval = const Duration(minutes: 60)),
                  ),
                  _IntervalChip(
                    label: l10n.safetyInterval2Hours,
                    selected: _checkInInterval.inMinutes == 120,
                    onTap: () => setState(() => _checkInInterval = const Duration(minutes: 120)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Share location toggle
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: AppColors.richGold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.safetyShareLiveLocation,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            l10n.safetyEmergencyContactsLocation,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _shareLocation,
                      onChanged: (value) => setState(() => _shareLocation = value),
                      activeColor: AppColors.richGold,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Emergency contacts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.safetyEmergencyContacts,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addEmergencyContact,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.safetyAdd),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.richGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_emergencyContacts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.contact_phone_outlined,
                        color: AppColors.textTertiary,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.safetyAddEmergencyContacts,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        l10n.safetyEmergencyContactsHelp,
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._emergencyContacts.map((contact) => _EmergencyContactCard(
                      contact: contact,
                      onRemove: () => _removeContact(contact),
                    )),

              const SizedBox(height: 20),

              // Notes
              Text(
                l10n.safetyNotesOptional,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.safetyAdditionalDetailsHint,
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.backgroundCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Create button
              ElevatedButton(
                onPressed: _createCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
                child: Text(
                  l10n.safetyScheduleCheckIn,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntervalChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _IntervalChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.richGold : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.richGold : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onRemove;

  const _EmergencyContactCard({
    required this.contact,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.richGold.withValues(alpha: 0.2),
            child: Text(
              contact.name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.richGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${contact.relationship} - ${contact.phoneNumber}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textTertiary),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _AddEmergencyContactDialog extends StatefulWidget {
  final Function(EmergencyContact) onAdd;

  const _AddEmergencyContactDialog({required this.onAdd});

  @override
  State<_AddEmergencyContactDialog> createState() => _AddEmergencyContactDialogState();
}

class _AddEmergencyContactDialogState extends State<_AddEmergencyContactDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _relationship = 'Friend';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: Text(
        l10n.safetyAddEmergencyContact,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: l10n.safetyNameLabel,
              labelStyle: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            style: const TextStyle(color: AppColors.textPrimary),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.safetyPhoneLabel,
              labelStyle: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _relationship,
            dropdownColor: AppColors.backgroundCard,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: l10n.safetyRelationshipLabel,
              labelStyle: const TextStyle(color: AppColors.textSecondary),
            ),
            items: [
                  DropdownMenuItem(value: 'Friend', child: Text(l10n.safetyRelationshipFriend)),
                  DropdownMenuItem(value: 'Family', child: Text(l10n.safetyRelationshipFamily)),
                  DropdownMenuItem(value: 'Partner', child: Text(l10n.safetyRelationshipPartner)),
                  DropdownMenuItem(value: 'Roommate', child: Text(l10n.safetyRelationshipRoommate)),
                  DropdownMenuItem(value: 'Other', child: Text(l10n.safetyRelationshipOther)),
                ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _relationship = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
              widget.onAdd(EmergencyContact(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                phoneNumber: _phoneController.text,
                relationship: _relationship,
              ));
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.richGold,
          ),
          child: Text(l10n.safetyAdd),
        ),
      ],
    );
  }
}
