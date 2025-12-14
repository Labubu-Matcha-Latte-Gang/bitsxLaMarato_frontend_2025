import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import '../initialPage/initialPage.dart';
import 'registerDoctor.dart';
import 'registerPacient.dart';
import '../login/login.dart';

class RegisterLobby extends StatefulWidget {
  final bool isDarkMode;
  const RegisterLobby({super.key, this.isDarkMode = false});

  @override
  State<RegisterLobby> createState() => _RegisterLobbyState();
}

class _RegisterLobbyState extends State<RegisterLobby> {
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
  }

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
            child: Column(
              children: [
                // Header con botón de tema y back
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón de back
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.getBlurContainerColor(isDarkMode),
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
                            Icons.arrow_back,
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const InitialPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      // Botón de tema
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.getBlurContainerColor(isDarkMode),
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
                            color: AppColors.getPrimaryTextColor(isDarkMode),
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
                      children: [],
                    ),
                  ),
                ),

                // Spacer para empujar el contenido hacia arriba
                const Spacer(),
              ],
            ),
          ),

          // Logo fijo en la parte superior
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.only(bottom: 30),
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
          ),

          // Recuadro inferior posicionado
          Positioned(
            top: MediaQuery.of(context).size.height * 0.40,
            left: MediaQuery.of(context).size.width >= 800
                ? MediaQuery.of(context).size.width * 0.25
                : 0,
            right: MediaQuery.of(context).size.width >= 800
                ? MediaQuery.of(context).size.width * 0.25
                : 0,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.getSecondaryBackgroundColor(isDarkMode),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40.0, vertical: 15.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Texto "Registrar-se com a:" dentro del recuadro
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0, bottom: 8.0),
                      child: Text(
                        'Registrar-se com a:',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.getSecondaryTextColor(isDarkMode),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Columna con botones
                    Column(
                      children: [
                        // Botón PACIENT
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.getPrimaryButtonColor(isDarkMode),
                              foregroundColor:
                                  AppColors.getPrimaryButtonTextColor(
                                      isDarkMode),
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
                                      RegisterPacient(isDarkMode: isDarkMode),
                                ),
                              );
                            },
                            child: const Text(
                              'PACIENT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Texto "o" entre botones
                        Text(
                          'o',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.getTertiaryTextColor(isDarkMode),
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Botón DOCTOR
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.getPrimaryButtonColor(isDarkMode),
                              foregroundColor:
                                  AppColors.getPrimaryButtonTextColor(
                                      isDarkMode),
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
                                      RegisterDoctor(isDarkMode: isDarkMode),
                                ),
                              );
                            },
                            child: const Text(
                              'DOCTOR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Texto "Already have an account? Login"
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) =>
                                    LoginScreen(isDarkMode: isDarkMode),
                              ),
                            );
                          },
                          child: Text(
                            'Ja tens un compte? Inicia sessió',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.getTertiaryTextColor(isDarkMode),
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.underline,
                              decorationColor:
                                  AppColors.getTertiaryTextColor(isDarkMode),
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
    );
  }
}
