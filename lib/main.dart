import 'package:bitsxlamarato_frontend_2025/features/screens/initialPage/initialPage.dart';
import 'package:bitsxlamarato_frontend_2025/features/screens/register/registerLobby.dart';
import 'package:bitsxlamarato_frontend_2025/features/screens/login/login.dart';
import 'package:bitsxlamarato_frontend_2025/features/screens/micro/mic.dart';
import 'package:bitsxlamarato_frontend_2025/features/screens/patient/patient_menu_page.dart';
import 'package:bitsxlamarato_frontend_2025/features/screens/doctor/doctor_home_page.dart';
import 'package:bitsxlamarato_frontend_2025/services/api_service.dart';
import 'package:bitsxlamarato_frontend_2025/services/navigation_service.dart';
import 'package:bitsxlamarato_frontend_2025/services/session_manager.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SessionManager.registerSessionExpiredCallback(
    NavigationService.redirectToLogin,
  );

  final startLoggedIn = await ApiService.restoreSession();
  final savedThemeDark = await SessionManager.getThemeMode() ?? false;
  Map<String, dynamic>? userData = await SessionManager.getUserData();
  if (startLoggedIn && (userData == null || userData['user_type'] == null)) {
    try {
      await ApiService.getAndCacheCurrentUser();
      userData = await SessionManager.getUserData();
    } catch (_) {}
  }
  final alreadyRespondedToday =
      userData != null && userData['already_responded_today'] == true;
  final userType = (userData?['user_type'] as String?) ?? 'unknown';
  runApp(
    MyApp(
      startLoggedIn: startLoggedIn,
      startInActivities: alreadyRespondedToday,
      userType: userType,
      initialDarkMode: savedThemeDark,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool startLoggedIn;
  final bool startInActivities;
  final String userType;
  final bool initialDarkMode;
  const MyApp({
    super.key,
    this.startLoggedIn = false,
    this.startInActivities = false,
    this.userType = 'unknown',
    this.initialDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'LMLG - BitsxLaMarató 2025',
        navigatorKey: NavigationService.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: startLoggedIn
            ? (userType == 'doctor'
                ? DoctorHomePage(initialDarkMode: initialDarkMode)
                : (startInActivities
                    ? PatientMenuPage(initialDarkMode: initialDarkMode)
                    : const MicScreen()))
            : InitialPage(initialDarkMode: initialDarkMode),
        routes: {
          '/initial': (context) =>
              InitialPage(initialDarkMode: initialDarkMode),
          '/register': (context) => const RegisterLobby(),
          '/login': (context) => const LoginScreen(),
          '/doctor': (context) =>
              DoctorHomePage(initialDarkMode: initialDarkMode),
        });
  }
}
