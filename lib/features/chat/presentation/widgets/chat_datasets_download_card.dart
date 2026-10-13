import 'package:flutter/widgets.dart';

import '../../../../core/services/chat_datasets/chat_datasets.dart';

/// From the first access: downloads every chat dataset (ice-breakers,
/// sentences, cultural tips, keywords, word lists, quotes) into the device
/// cache silently in the background - nothing is shown. Later starts load
/// them from the cache; anything that failed is fetched again then.
class ChatDatasetsFirstRun {
  ChatDatasetsFirstRun._();

  static bool _started = false;

  /// Starts the background download once per app run. Safe to call often.
  static void maybeStart(BuildContext context, {ChatDatasets? datasets}) {
    if (_started) return;
    _started = true;
    (datasets ?? ChatDatasets.instance).preloadAll().catchError((Object _) => false);
  }
}
