import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/notification_preferences.dart';
import '../bloc/notification_preferences_bloc.dart';
import '../bloc/notification_preferences_event.dart';
import '../bloc/notification_preferences_state.dart';

/// Notification Preferences Screen
///
/// Allows users to configure their notification settings
class NotificationPreferencesScreen extends StatelessWidget {
  final String userId;

  const NotificationPreferencesScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) => di.sl<NotificationPreferencesBloc>()
        ..add(NotificationPreferencesLoadRequested(userId: userId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.notificationSettingsTitle),
        ),
        body: BlocBuilder<NotificationPreferencesBloc,
            NotificationPreferencesState>(
          builder: (context, state) {
            if (state is NotificationPreferencesLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.richGold,
                ),
              );
            }

            if (state is NotificationPreferencesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.errorRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (state is NotificationPreferencesLoaded) {
              final prefs = state.preferences;

              return ListView(
                children: [
                  // Master Controls
                  _buildSection(
                    title: l10n.notificationMasterControls,
                    children: [
                      _buildSwitchTile(
                        context: context,
                        title: l10n.notificationPushTitle,
                        subtitle: l10n.notificationPushSubtitle,
                        value: prefs.pushNotificationsEnabled,
                        onChanged: (value) {
                          context.read<NotificationPreferencesBloc>().add(
                                NotificationPreferencesUpdated(
                                  preferences: prefs.copyWith(
                                    pushNotificationsEnabled: value,
                                  ),
                                ),
                              );
                        },
                      ),
                      _buildSwitchTile(
                        context: context,
                        title: l10n.notificationEmailTitle,
                        subtitle: l10n.notificationEmailSubtitle,
                        value: prefs.emailNotificationsEnabled,
                        onChanged: (value) {
                          context.read<NotificationPreferencesBloc>().add(
                                NotificationPreferencesUpdated(
                                  preferences: prefs.copyWith(
                                    emailNotificationsEnabled: value,
                                  ),
                                ),
                              );
                        },
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Notification Types
                  _buildSection(
                    title: l10n.notificationTypes,
                    children: [
                      _buildSwitchTile(
                        context: context,
                        title: l10n.notificationNewMatches,
                        subtitle: l10n.notificationNewMatchesSubtitle,
                        value: prefs.newMatchNotifications,
                        enabled: prefs.pushNotificationsEnabled,
                        onChanged: (value) {
                          context.read<NotificationPreferencesBloc>().add(
                                NotificationPreferencesUpdated(
                                  preferences: prefs.copyWith(
                                    newMatchNotifications: value,
                                  ),
                                ),
                              );
                        },
                      ),
                      _buildSwitchTile(
                        context: context,
                        title: l10n.notificationNewMessages,
                        subtitle: l10n.notificationNewMessagesSubtitle,
                        value: prefs.newMessageNotifications,
                        enabled: prefs.pushNotificationsEnabled,
                        onChanged: (value) {
                          context.read<NotificationPreferencesBloc>().add(
                                NotificationPreferencesUpdated(
                                  preferences: prefs.copyWith(
                                    newMessageNotifications: value,
                                  ),
                                ),
                              );
                        },
                      ),
                      _buildSwitchTile(
                        context: context,
                        title: l10n.notificationNewLikes,
                        subtitle: l10n.notificationNewLikesSubtitle,
                        value: prefs.newLikeNotifications,
                        enabled: prefs.pushNotificationsEnabled,
                        onChanged: (value) {
                          context.read<NotificationPreferencesBloc>().add(
                                NotificationPreferencesUpdated(
                                  preferences: prefs.copyWith(
                                    newLikeNotifications: value,
                                  ),
                                ),
                              );
                        },
                      ),
                      _buildSwitchTile(
                        context: context,
                        title: l10n.notificationProfileViews,
                        subtitle: l10n.notificationProfileViewsSubtitle,
                        value: prefs.profileViewNotifications,
                        enabled: prefs.pushNotificationsEnabled,
                        onChanged: (value) {
                          context.read<NotificationPreferencesBloc>().add(
                                NotificationPreferencesUpdated(
                                  preferences: prefs.copyWith(
                                    profileViewNotifications: value,
                                  ),
                                ),
                              );
                        },
                      ),
                      _buildSwitchTile(
                        context: context,
                        title: l10n.notificationSuperLikes,
                        subtitle: l10n.notificationSuperLikesSubtitle,
                        value: prefs.superLikeNotifications,
                        enabled: prefs.pushNotificationsEnabled,
                        onChanged: (value) {
                          context.read<NotificationPreferencesBloc>().add(
                                NotificationPreferencesUpdated(
                                  preferences: prefs.copyWith(
                                    superLikeNotifications: value,
                                  ),
                                ),
                              );
                        },
                      ),
                      _buildSwitchTile(
                        context: context,
                        title: l10n.notificationMatchExpiring,
                        subtitle: l10n.notificationMatchExpiringSubtitle,
                        value: prefs.matchExpiringNotifications,
                        enabled: prefs.pushNotificationsEnabled,
                        onChanged: (value) {
                          context.read<NotificationPreferencesBloc>().add(
                                NotificationPreferencesUpdated(
                                  preferences: prefs.copyWith(
                                    matchExpiringNotifications: value,
                                  ),
                                ),
                              );
                        },
                      ),
                      _buildSwitchTile(
                        context: context,
                        title: l10n.notificationPromotional,
                        subtitle: l10n.notificationPromotionalSubtitle,
                        value: prefs.promotionalNotifications,
                        enabled: prefs.pushNotificationsEnabled,
                        onChanged: (value) {
                          context.read<NotificationPreferencesBloc>().add(
                                NotificationPreferencesUpdated(
                                  preferences: prefs.copyWith(
                                    promotionalNotifications: value,
                                  ),
                                ),
                              );
                        },
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Sound & Vibration
                  _buildSection(
                    title: l10n.notificationSoundVibration,
                    children: [
                      _buildSwitchTile(
                        context: context,
                        title: l10n.notificationSound,
                        subtitle: l10n.notificationSoundSubtitle,
                        value: prefs.soundEnabled,
                        enabled: prefs.pushNotificationsEnabled,
                        onChanged: (value) {
                          context.read<NotificationPreferencesBloc>().add(
                                NotificationPreferencesUpdated(
                                  preferences: prefs.copyWith(
                                    soundEnabled: value,
                                  ),
                                ),
                              );
                        },
                      ),
                      _buildSwitchTile(
                        context: context,
                        title: l10n.notificationVibration,
                        subtitle: l10n.notificationVibrationSubtitle,
                        value: prefs.vibrationEnabled,
                        enabled: prefs.pushNotificationsEnabled,
                        onChanged: (value) {
                          context.read<NotificationPreferencesBloc>().add(
                                NotificationPreferencesUpdated(
                                  preferences: prefs.copyWith(
                                    vibrationEnabled: value,
                                  ),
                                ),
                              );
                        },
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Quiet Hours
                  _buildSection(
                    title: l10n.notificationQuietHours,
                    subtitle: l10n.notificationQuietHoursSubtitle,
                    children: [
                      _buildSwitchTile(
                        context: context,
                        title: l10n.notificationEnableQuietHours,
                        subtitle: l10n.notificationQuietHoursDescription,
                        value: prefs.quietHoursEnabled,
                        enabled: prefs.pushNotificationsEnabled,
                        onChanged: (value) {
                          context.read<NotificationPreferencesBloc>().add(
                                NotificationPreferencesUpdated(
                                  preferences: prefs.copyWith(
                                    quietHoursEnabled: value,
                                  ),
                                ),
                              );
                        },
                      ),
                      if (prefs.quietHoursEnabled)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTimePicker(
                                  context: context,
                                  label: l10n.notificationStartTime,
                                  time: prefs.quietHoursStart,
                                  onTimeSelected: (time) {
                                    context
                                        .read<NotificationPreferencesBloc>()
                                        .add(
                                          NotificationPreferencesUpdated(
                                            preferences: prefs.copyWith(
                                              quietHoursStart: time,
                                            ),
                                          ),
                                        );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTimePicker(
                                  context: context,
                                  label: l10n.notificationEndTime,
                                  time: prefs.quietHoursEnd,
                                  onTimeSelected: (time) {
                                    context
                                        .read<NotificationPreferencesBloc>()
                                        .add(
                                          NotificationPreferencesUpdated(
                                            preferences: prefs.copyWith(
                                              quietHoursEnd: time,
                                            ),
                                          ),
                                        );
                                  },
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

  Widget _buildSection({
    required String title,
    String? subtitle,
    required List<Widget> children,
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
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
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
      activeColor: AppColors.richGold,
    );
  }

  Widget _buildTimePicker({
    required BuildContext context,
    required String label,
    required String time,
    required Function(String) onTimeSelected,
  }) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _parseTime(time),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.richGold,
                  onPrimary: Colors.white,
                  surface: AppColors.backgroundCard,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          final formattedTime =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onTimeSelected(formattedTime);
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
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
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
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(String time) {
    final timeOfDay = _parseTime(time);
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

/// Extension to add copyWith method to NotificationPreferences
extension NotificationPreferencesExtension on NotificationPreferences {
  NotificationPreferences copyWith({
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? newMatchNotifications,
    bool? newMessageNotifications,
    bool? newLikeNotifications,
    bool? profileViewNotifications,
    bool? superLikeNotifications,
    bool? matchExpiringNotifications,
    bool? promotionalNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? quietHoursEnabled,
  }) {
    return NotificationPreferences(
      userId: userId,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      newMatchNotifications:
          newMatchNotifications ?? this.newMatchNotifications,
      newMessageNotifications:
          newMessageNotifications ?? this.newMessageNotifications,
      newLikeNotifications: newLikeNotifications ?? this.newLikeNotifications,
      profileViewNotifications:
          profileViewNotifications ?? this.profileViewNotifications,
      superLikeNotifications:
          superLikeNotifications ?? this.superLikeNotifications,
      matchExpiringNotifications:
          matchExpiringNotifications ?? this.matchExpiringNotifications,
      promotionalNotifications:
          promotionalNotifications ?? this.promotionalNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    );
  }
}
