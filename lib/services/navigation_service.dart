import 'package:flutter/material.dart';

/// Provides a global navigator key so non-UI layers can trigger navigation
/// events (e.g. redirect to login when a session expires).
class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void redirectToLogin() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  }
}
