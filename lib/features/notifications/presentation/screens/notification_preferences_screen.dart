import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/city_normalizer.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/notification_preferences.dart';
import 'city_picker_screen.dart';
import '../bloc/notification_preferences_bloc.dart';
import '../bloc/notification_preferences_event.dart';
import '../bloc/notification_preferences_state.dart';

/// Notification Preferences Screen — per-category push controls, sound/vibration,
/// quiet hours, and the list of cities the user wants event alerts for.
class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({required this.userId, super.key});
  final String userId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) => di.sl<NotificationPreferencesBloc>()
        ..add(NotificationPreferencesLoadRequested(userId: userId)),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.notificationSettingsTitle)),
        body: BlocBuilder<NotificationPreferencesBloc,
            NotificationPreferencesState>(
          builder: (context, state) {
            if (state is NotificationPreferencesLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.richGold),
              );
            }
            if (state is NotificationPreferencesError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.message,
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (state is NotificationPreferencesLoaded) {
              final prefs = state.preferences;
              final bloc = context.read<NotificationPreferencesBloc>();
              final on = prefs.pushEnabled;

              void update(NotificationPreferences next) =>
                  bloc.add(NotificationPreferencesUpdated(preferences: next));

              return ListView(
                children: [
                  // ── Master ──
                  _section(title: l10n.notificationMasterControls, children: [
                    _switch(
                      title: l10n.notificationPushTitle,
                      subtitle: l10n.notificationPushSubtitle,
                      value: prefs.pushEnabled,
                      onChanged: (v) => update(prefs.copyWith(pushEnabled: v)),
                    ),
                  ]),
                  const Divider(height: 32),

                  // ── Categories ──
                  _section(title: l10n.notificationCategories, children: [
                    _switch(
                      title: l10n.notificationCatMessages,
                      subtitle: l10n.notificationCatMessagesSubtitle,
                      value: prefs.messages,
                      enabled: on,
                      onChanged: (v) => update(prefs.copyWith(messages: v)),
                    ),
                    _switch(
                      title: l10n.notificationCatEvents,
                      subtitle: l10n.notificationCatEventsSubtitle,
                      value: prefs.events,
                      enabled: on,
                      onChanged: (v) => update(prefs.copyWith(events: v)),
                    ),
                    _switch(
                      title: l10n.notificationCatCommunities,
                      subtitle: l10n.notificationCatCommunitiesSubtitle,
                      value: prefs.communities,
                      enabled: on,
                      onChanged: (v) => update(prefs.copyWith(communities: v)),
                    ),
                    _switch(
                      title: l10n.notificationCatSocial,
                      subtitle: l10n.notificationCatSocialSubtitle,
                      value: prefs.social,
                      enabled: on,
                      onChanged: (v) => update(prefs.copyWith(social: v)),
                    ),
                    _switch(
                      title: l10n.notificationCatAccount,
                      subtitle: l10n.notificationCatAccountSubtitle,
                      value: prefs.account,
                      enabled: on,
                      onChanged: (v) => update(prefs.copyWith(account: v)),
                    ),
                  ]),
                  const Divider(height: 32),

                  // ── Community events by city ──
                  _section(
                    title: l10n.notificationEventCities,
                    subtitle: l10n.notificationEventCitiesSubtitle,
                    children: [
                      _CityChips(
                        cities: prefs.eventCities,
                        enabled: on && prefs.events,
                        onRemove: (city) => update(prefs.copyWith(
                          eventCities: prefs.eventCities
                              .where((c) => c != city)
                              .toList(),
                        )),
                        onAdd: (raw) {
                          final key = CityNormalizer.normalize(raw);
                          if (key.isEmpty ||
                              prefs.eventCities.contains(key)) {
                            return;
                          }
                          update(prefs.copyWith(
                            eventCities: [...prefs.eventCities, key],
                          ));
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // ── Sound & vibration ──
                  _section(title: l10n.notificationSoundVibration, children: [
                    _switch(
                      title: l10n.notificationSound,
                      subtitle: l10n.notificationSoundSubtitle,
                      value: prefs.soundEnabled,
                      enabled: on,
                      onChanged: (v) => update(prefs.copyWith(soundEnabled: v)),
                    ),
                    _switch(
                      title: l10n.notificationVibration,
                      subtitle: l10n.notificationVibrationSubtitle,
                      value: prefs.vibrationEnabled,
                      enabled: on,
                      onChanged: (v) =>
                          update(prefs.copyWith(vibrationEnabled: v)),
                    ),
                  ]),
                  const Divider(height: 32),

                  // ── Quiet hours ──
                  _section(
                    title: l10n.notificationQuietHours,
                    subtitle: l10n.notificationQuietHoursSubtitle,
                    children: [
                      _switch(
                        title: l10n.notificationEnableQuietHours,
                        subtitle: l10n.notificationQuietHoursDescription,
                        value: prefs.quietHoursEnabled,
                        enabled: on,
                        onChanged: (v) =>
                            update(prefs.copyWith(quietHoursEnabled: v)),
                      ),
                      if (prefs.quietHoursEnabled)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: _timePicker(
                                  context: context,
                                  label: l10n.notificationStartTime,
                                  time: prefs.quietHoursStart,
                                  onSelected: (t) => update(
                                      prefs.copyWith(quietHoursStart: t)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _timePicker(
                                  context: context,
                                  label: l10n.notificationEndTime,
                                  time: prefs.quietHoursEnd,
                                  onSelected: (t) =>
                                      update(prefs.copyWith(quietHoursEnd: t)),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required List<Widget> children,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _switch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? AppColors.textSecondary : AppColors.textTertiary,
          fontSize: 14,
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: AppColors.richGold,
    );
  }

  Widget _timePicker({
    required BuildContext context,
    required String label,
    required String time,
    required ValueChanged<String> onSelected,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _parseTime(time),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.richGold,
                onPrimary: Colors.white,
                surface: AppColors.backgroundCard,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          onSelected(
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              _formatTime(time),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(String time) {
    final t = _parseTime(time);
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

/// City chips + an "Add city" text-input dialog. Cities are stored normalized.
class _CityChips extends StatelessWidget {
  const _CityChips({
    required this.cities,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> cities;
  final bool enabled;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cities.isEmpty)
            Text(
              l10n.notificationNoCities,
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 13),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final city in cities)
                Chip(
                  label: Text(
                    CityNormalizer.display(city),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  backgroundColor: AppColors.backgroundCard,
                  deleteIconColor: AppColors.textSecondary,
                  onDeleted: enabled ? () => onRemove(city) : null,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: enabled ? () => _pickCityFromMap(context) : null,
              icon: const Icon(Icons.add_location_alt_outlined,
                  color: AppColors.richGold, size: 20),
              label: Text(
                l10n.notificationAddCity,
                style: const TextStyle(color: AppColors.richGold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the full-screen [CityPickerScreen]: search a city or tap the map,
  /// then "Use this city" returns the resolved city name to add.
  Future<void> _pickCityFromMap(BuildContext context) async {
    final city = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CityPickerScreen()),
    );
    if (city != null && city.trim().isNotEmpty) {
      onAdd(city);
    }
  }
}
