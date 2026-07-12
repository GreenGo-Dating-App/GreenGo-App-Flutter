// TEMPORARY preview entrypoint — boots straight into the glass ExploreScreen
// so the redesign can be viewed in a browser without auth/onboarding gates.
// Not shipped. Build with: flutter build web --target lib/main_preview.dart
import 'package:flutter/material.dart';
import 'generated/app_localizations.dart';
import 'features/explore/presentation/screens/explore_screen.dart';

void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const ExploreScreen(userId: 'preview-user'),
    );
  }
}
