import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/legal/bundled_font_licenses.dart';

/// The OFL notices of the fonts we ship must reach Flutter's licenses page.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LicenseRegistry.reset();
    resetBundledFontLicensesForTest();
  });

  Future<Map<String, String>> collect() async {
    final out = <String, String>{};
    await for (final entry in LicenseRegistry.licenses) {
      final text = entry.paragraphs.map((p) => p.text).join('\n');
      for (final pkg in entry.packages) {
        out[pkg] = text;
      }
    }
    return out;
  }

  test('Poppins OFL is registered on every platform', () async {
    registerBundledFontLicenses(isWeb: false);
    final licenses = await collect();
    expect(licenses.keys, contains('Poppins (font)'));
    expect(licenses['Poppins (font)'], contains('SIL OPEN FONT LICENSE Version 1.1'));
    expect(licenses['Poppins (font)'], contains('The Poppins Project Authors'));
    expect(licenses.keys, isNot(contains('Roboto (font)')));
  });

  test('web also registers the Roboto/Noto OFL (served from /gfonts)', () async {
    registerBundledFontLicenses(isWeb: true);
    final licenses = await collect();
    expect(licenses.keys, containsAll(<String>['Poppins (font)', 'Roboto (font)', 'Noto fonts']));
    expect(licenses['Noto fonts'], contains('The Noto Project Authors'));
    expect(licenses['Noto fonts'], contains('SIL OPEN FONT LICENSE Version 1.1'));
  });

  test('registering twice does not duplicate entries', () async {
    registerBundledFontLicenses(isWeb: false);
    registerBundledFontLicenses(isWeb: false);
    var count = 0;
    await for (final entry in LicenseRegistry.licenses) {
      if (entry.packages.contains('Poppins (font)')) count++;
    }
    expect(count, 1);
  });
}
