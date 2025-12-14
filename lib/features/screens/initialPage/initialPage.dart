import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../services/session_manager.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import '../login/login.dart';
import '../register/registerLobby.dart';

class InitialPage extends StatefulWidget {
  final bool initialDarkMode;

  const InitialPage({super.key, this.initialDarkMode = true});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  bool isDarkMode = true;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    _loadThemePreference();
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    SessionManager.saveThemeMode(isDarkMode);
  }

  Future<void> _loadThemePreference() async {
    final saved = await SessionManager.getThemeMode();
    if (saved != null && mounted) {
      setState(() {
        isDarkMode = saved;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.getBackgroundGradient(isDarkMode),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                final double logoHeight =
                    (availableHeight * 0.35).clamp(180.0, 260.0) as double;
                final double footerHeight =
                    (availableHeight * 0.35).clamp(140.0, 280.0) as double;

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: availableHeight),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header con botón de tema
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.getBlurContainerColor(
                                      isDarkMode),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.containerShadow,
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
                                    color: AppColors.getPrimaryTextColor(
                                        isDarkMode),
                                  ),
                                  onPressed: _toggleTheme,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Spacer para dejar espacio para el logo fijo
                        SizedBox(
                            height: (logoHeight * 0.85).clamp(180.0, 240.0)
                                as double),

                        // Contenido principal centrado con tamaño adaptable
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Column(
                            children: [],
                          ),
                        ),

                        // Recuadro inferior con botones (adaptable a pantallas pequeñas)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width >= 800
                                ? MediaQuery.of(context).size.width * 0.25
                                : 0,
                          ),
                          child: Container(
                            width: double.infinity,
                            constraints:
                                BoxConstraints(minHeight: footerHeight),
                            decoration: BoxDecoration(
                              color: AppColors.getSecondaryBackgroundColor(
                                  isDarkMode),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(32)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40.0, vertical: 25.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  // Texto "Començem!" dentro del recuadro
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 10.0, bottom: 25.0),
                                    child: Text(
                                      'Començem!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: AppColors.getSecondaryTextColor(
                                            isDarkMode),
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
                                              borderRadius:
                                                  BorderRadius.circular(32),
                                            ),
                                            elevation: 0,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      LoginScreen(
                                                          isDarkMode:
                                                              isDarkMode)),
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
                                            backgroundColor:
                                                AppColors.getPrimaryButtonColor(
                                                    isDarkMode),
                                            foregroundColor: AppColors
                                                .getPrimaryButtonTextColor(
                                                    isDarkMode),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(32),
                                            ),
                                            elevation: 0,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      RegisterLobby(
                                                          isDarkMode:
                                                              isDarkMode)),
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
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Logo fijo (no se mueve)
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                height: 120,
                width: 180,
                child: Image.asset(
                  isDarkMode ? TImages.lightLogoText : TImages.darkLogoText,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.local_hospital,
                      size: 60,
                      color: AppColors.getPrimaryTextColor(isDarkMode),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
