import 'package:flutter/material.dart';
import '../../features/main/presentation/screens/main_navigation_screen.dart';

/// Safe navigation utilities to prevent black screen on back navigation.
/// Ensures the app always has a valid screen to display.
class SafeNavigation {
  /// Safely navigate back. If the navigation stack would be empty,
  /// redirects to the main navigation screen (Discovery tab).
  static void pop(BuildContext context, {String? userId}) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // Can't pop - navigate to home instead
      _navigateToHome(context, userId);
    }
  }

  /// Check if we can safely pop without going to a black screen
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  /// Navigate to home screen, clearing the navigation stack
  static void navigateToHome(BuildContext context, String userId) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MainNavigationScreen(userId: userId),
      ),
      (route) => false,
    );
  }

  /// Navigate to home screen if userId is available, otherwise just try to pop
  static void _navigateToHome(BuildContext context, String? userId) {
    if (userId != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MainNavigationScreen(userId: userId),
        ),
        (route) => false,
      );
    } else {
      // Fallback: try to navigate to home route
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  /// Pop and return a result, with fallback to home
  static void popWithResult<T>(BuildContext context, T result, {String? userId}) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    } else {
      _navigateToHome(context, userId);
    }
  }
}

/// Mixin for StatefulWidgets that need safe back navigation
mixin SafeBackNavigationMixin<T extends StatefulWidget> on State<T> {
  String? get currentUserId;

  /// Override this to handle back button press
  Future<bool> onWillPop() async {
    if (Navigator.of(context).canPop()) {
      return true; // Allow normal pop
    } else {
      // Navigate to home instead of showing black screen
      SafeNavigation.navigateToHome(context, currentUserId ?? '');
      return false;
    }
  }
}
