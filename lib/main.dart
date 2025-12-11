import 'package:bitsxlamarato_frontend_2025/features/screens/initialPage/initialPage.dart';
import 'package:bitsxlamarato_frontend_2025/features/screens/register/registerLobby.dart';
import 'package:bitsxlamarato_frontend_2025/features/screens/login/login.dart';
import 'package:bitsxlamarato_frontend_2025/features/screens/micro/mic.dart';
import 'package:bitsxlamarato_frontend_2025/features/screens/patient/patient_menu_page.dart';
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
  final userData = await SessionManager.getUserData();
  final alreadyRespondedToday =
      userData != null && userData['already_responded_today'] == true;
  runApp(
    MyApp(
      startLoggedIn: startLoggedIn,
      startInActivities: alreadyRespondedToday,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool startLoggedIn;
  final bool startInActivities;
  const MyApp({
    super.key,
    this.startLoggedIn = false,
    this.startInActivities = false,
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
          ? (startInActivities
              ? const PatientMenuPage()
              : const MicScreen())
          : const InitialPage(),
      routes: {
        '/initial': (context) => const InitialPage(),
        '/register': (context) => const RegisterLobby(),
        '/login': (context) => const LoginScreen(),
      }
    );
  }
}
