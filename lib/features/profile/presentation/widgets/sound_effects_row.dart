import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_sound_service.dart';
import '../../../../core/widgets/menu_row.dart';
import '../../../../generated/app_localizations.dart';

/// Profile > Settings: turns the in-app sound effects on or off (saved on
/// this device). Push-notification sounds are set in Notification settings.
class SoundEffectsRow extends StatefulWidget {
  const SoundEffectsRow({super.key});

  @override
  State<SoundEffectsRow> createState() => _SoundEffectsRowState();
}

class _SoundEffectsRowState extends State<SoundEffectsRow> {
  bool _enabled = AppSoundService().isSoundEnabled;

  @override
  void initState() {
    super.initState();
    // The saved choice loads with the service; reflect it once it has.
    AppSoundService().initialize().then((_) {
      if (mounted) setState(() => _enabled = AppSoundService().isSoundEnabled);
    });
  }

  Future<void> _set(bool value) async {
    setState(() => _enabled = value);
    await AppSoundService().setSoundEnabled(value);
    if (value) AppSoundService().play(AppSound.toggleOn);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MenuRow(
      key: const ValueKey('profile-sound-effects'),
      title: l10n.soundEffectsTitle,
      subtitle: l10n.soundEffectsSubtitle,
      icon: _enabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
      onTap: () => _set(!_enabled),
      trailing: Switch(
        value: _enabled,
        onChanged: _set,
        activeThumbColor: AppColors.richGold,
      ),
    );
  }
}
