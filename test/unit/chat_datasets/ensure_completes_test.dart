import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/chat_datasets/chat_datasets.dart';

/// Regression (first-run download stuck at 0%): ensure() must COMPLETE once a
/// dataset is loaded. A `whenComplete(() => _loading.remove(name))` returned
/// the in-flight future itself, so every load waited on itself forever.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ensure() completes for a bundled dataset', () async {
    await ChatDatasets.instance.ensure('icebreakers').timeout(const Duration(seconds: 20));
    expect(ChatDatasets.instance.icebreakers, isNotEmpty);
    // A second call returns at once.
    await ChatDatasets.instance.ensure('icebreakers').timeout(const Duration(seconds: 1));
  });
}
