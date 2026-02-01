import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #28: Quick Dark Mode Toggle
/// Quick access settings shortcuts
class QuickSettingsToggle extends StatelessWidget {
  final bool isDarkMode;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final Function(bool)? onDarkModeChanged;
  final Function(bool)? onNotificationsChanged;
  final Function(bool)? onSoundChanged;

  const QuickSettingsToggle({
    super.key,
    this.isDarkMode = true,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.onDarkModeChanged,
    this.onNotificationsChanged,
    this.onSoundChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Settings',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickToggle(
                icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
                label: isDarkMode ? 'Dark' : 'Light',
                isActive: isDarkMode,
                onTap: () => onDarkModeChanged?.call(!isDarkMode),
              ),
              _QuickToggle(
                icon: notificationsEnabled
                    ? Icons.notifications
                    : Icons.notifications_off,
                label: 'Notifications',
                isActive: notificationsEnabled,
                onTap: () => onNotificationsChanged?.call(!notificationsEnabled),
              ),
              _QuickToggle(
                icon: soundEnabled ? Icons.volume_up : Icons.volume_off,
                label: 'Sound',
                isActive: soundEnabled,
                onTap: () => onSoundChanged?.call(!soundEnabled),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickToggle({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.richGold.withOpacity(0.2)
                  : AppColors.backgroundInput,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? AppColors.richGold : AppColors.divider,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.richGold : AppColors.textTertiary,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.richGold : AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick toggle button for app bar
class QuickToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;
  final String? tooltip;

  const QuickToggleButton({
    super.key,
    required this.icon,
    required this.isActive,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: isActive ? AppColors.richGold : AppColors.textSecondary,
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
