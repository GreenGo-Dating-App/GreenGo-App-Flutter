import 'package:flutter/material.dart';

import 'app_sound_service.dart';

/// Plays the "sheet open" sound for every modal bottom sheet (79 call sites
/// use showModalBottomSheet; one observer covers them all). Dialogs are not
/// included: success / error / celebration dialogs play their own sound.
class SoundNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is ModalBottomSheetRoute) {
      AppSoundService().play(AppSound.sheetOpen);
    }
  }
}

/// Wraps a switch's onChanged so turning it on / off plays a soft click.
/// A null callback (disabled switch) stays null.
ValueChanged<bool>? withToggleSound(ValueChanged<bool>? onChanged) {
  if (onChanged == null) return null;
  return (value) {
    AppSoundService().play(value ? AppSound.toggleOn : AppSound.toggleOff);
    onChanged(value);
  };
}
