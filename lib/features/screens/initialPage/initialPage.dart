import 'package:flutter/material.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import '../login/login.dart';
import '../register/registerLobby.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  bool isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        const Color(0xFF1E2124),
                        const Color(0xFF1E2124),
                        const Color(0xFF1E2124)
                      ]
                    : [
                        const Color(0xFF90E0EF),
                        const Color(0xFF90E0EF),
                        const Color(0xFF90E0EF)
                      ],
              ),
            ),
          ),

          // Sistema de partículas usando el widget reutilizable
          ParticleSystemWidget(
            isDarkMode: isDarkMode,
            particleCount: 50,
            maxSize: 3.0,
            minSize: 1.0,
            speed: 0.5,
            maxOpacity: 0.6,
            minOpacity: 0.2,
          ),

          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                // Header con botón de tema
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[800]?.withOpacity(0.8)
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isDarkMode
                                ? Icons.wb_sunny
                                : Icons.nightlight_round,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1E3A8A),
                          ),
                          onPressed: _toggleTheme,
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido principal centrado
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo LMLG con imagen real
                        Container(
                          margin: const EdgeInsets.only(bottom: 40),
                          child: Column(
                            children: [
                              // Logo con imagen real
                              SizedBox(
                                height: 260,
                                width: 380,
                                child: Image.asset(
                                  isDarkMode
                                      ? TImages.lightLogoText
                                      : TImages.darkLogoText,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback en caso de que la imagen no se encuentre
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.local_hospital,
                                          size: 80,
                                          color: isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF1E3A8A),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'LMLG',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode
                                                ? Colors.white
                                                : const Color(0xFF1E3A8A),
                                            letterSpacing: 4,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Recuadro inferior con botones (35% de la pantalla)
                Container(
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF282B30)
                        : const Color(0xFFCAF0F8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40.0, vertical: 25.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Texto "Començem!" dentro del recuadro
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 10.0, bottom: 25.0),
                          child: Text(
                            'Començem!',
                            style: TextStyle(
                              fontSize: 18,
                              color: isDarkMode
                                  ? Colors.white70
                                  : const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // Columna con botones
                        Column(
                          children: [
                            // Botón LOGIN
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode
                                      ? const Color(
                                          0xFF7289DA) // Nuevo color para modo oscuro
                                      : const Color(
                                          0xFF0077B6), // Nuevo color para modo claro
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen()),
                                  );
                                },
                                child: const Text(
                                  'ENTRAR',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Botón REGISTER
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode
                                      ? const Color(
                                          0xFF7289DA) // Nuevo color para modo oscuro
                                      : const Color(
                                          0xFF0077B6), // Nuevo color para modo claro
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const RegisterLobby()),
                                  );
                                },
                                child: const Text(
                                  'REGISTRAR-SE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
