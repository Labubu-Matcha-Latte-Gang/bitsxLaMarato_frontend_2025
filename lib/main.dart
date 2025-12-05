import 'package:bitsxlamarato_frontend_2025/features/screens/initialPage/initialPage.dart';
import 'package:flutter/material.dart';
import 'package:bitsxlamarato_frontend_2025/features/screens/login/login.dart';
import 'package:bitsxlamarato_frontend_2025/features/screens/register/registerLobby.dart';
import 'package:bitsxlamarato_frontend_2025/features/screens/micro/mic.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LMLG - BitsxLaMarató 2025',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const InitialPage(),
      routes: {
        '/home': (context) => const InitialPage(),
        '/register': (context) => const RegisterLobby(),
        '/login': (context) => const LoginScreen(),
        '/mic': (context) => const MicScreen(),
      },
    );
  }
}
