import 'package:flutter/material.dart';

/// Sistema centralizado de colores para la aplicación BitsxLaMarato
/// Organiza todos los colores por categorías y modos (dark/light)
class AppColors {
  // =============== COLORES PRINCIPALES ===============

  /// Colores de fondo principales
  static const Color darkBackground = Color(0xFF1E2124);
  static const Color lightBackground = Color(0xFF90E0EF);

  /// Colores de fondo secundarios
  static const Color darkSecondaryBackground = Color(0xFF282B30);
  static const Color lightSecondaryBackground = Color(0xFFCAF0F8);

  // =============== COLORES DE TEXTO ===============

  /// Texto principal
  static const Color darkPrimaryText = Colors.white;
  static const Color lightPrimaryText = Color(0xFF1E3A8A);

  /// Texto secundario
  static const Color darkSecondaryText = Colors.white70;
  static const Color lightSecondaryText = Color(0xFF1E3A8A);

  /// Texto terciario/suave
  static const Color darkTertiaryText = Colors.white60;
  static const Color lightTertiaryText = Color(0xFF1E3A8A);

  // =============== COLORES DE BOTONES ===============

  /// Botones primarios
  static const Color darkPrimaryButton = Color(0xFF7289DA);
  static const Color lightPrimaryButton = Color(0xFF0077B6);

  /// Texto de botones primarios
  static const Color darkPrimaryButtonText = Colors.white;
  static const Color lightPrimaryButtonText = Colors.white;

  /// Botones secundarios
  static const Color darkSecondaryButton = Color(0xFF7289DA);
  static const Color lightSecondaryButton = Colors.white;

  /// Texto de botones secundarios
  static const Color darkSecondaryButtonText = Colors.white;
  static const Color lightSecondaryButtonText = Color(0xFF1E3A8A);

  // =============== COLORES DE CONTENEDORES ===============

  /// Contenedores con blur/transparencia
  static Color darkBlurContainer = Colors.grey[800]!.withOpacity(0.8);
  static Color lightBlurContainer = Colors.white.withOpacity(0.3);

  /// Sombras de contenedores
  static Color containerShadow = Colors.black.withOpacity(0.1);

  // =============== COLORES DE FORMULARIOS ===============

  /// Fondos de campos de entrada
  static const Color darkFieldBackground = Color(0xFF7289DA);
  static const Color lightFieldBackground = Colors.white;

  /// Texto de placeholder/hint
  static const Color darkPlaceholderText = Colors.white70;
  static const Color lightPlaceholderText = Color(0xFF1E3A8A);

  /// Texto de entrada
  static const Color darkInputText = Colors.white;
  static const Color lightInputText = Color(0xFF1E3A8A);

  // =============== COLORES ESPECIALES ===============

  /// Toggle/Switch activo
  static const Color activeToggle = Color(0xFF7289DA);

  /// Partículas del sistema de efectos
  static const Color darkParticles = Colors.white;
  static const Color lightParticles = Color(0xFF1E3A8A);

  // =============== MÉTODOS HELPER ===============

  /// Obtiene el color de fondo según el modo
  static Color getBackgroundColor(bool isDarkMode) {
    return isDarkMode ? darkBackground : lightBackground;
  }

  /// Obtiene el color de fondo secundario según el modo
  static Color getSecondaryBackgroundColor(bool isDarkMode) {
    return isDarkMode ? darkSecondaryBackground : lightSecondaryBackground;
  }

  /// Obtiene el color de texto principal según el modo
  static Color getPrimaryTextColor(bool isDarkMode) {
    return isDarkMode ? darkPrimaryText : lightPrimaryText;
  }

  /// Obtiene el color de texto secundario según el modo
  static Color getSecondaryTextColor(bool isDarkMode) {
    return isDarkMode ? darkSecondaryText : lightSecondaryText;
  }

  /// Obtiene el color de texto terciario según el modo
  static Color getTertiaryTextColor(bool isDarkMode) {
    return isDarkMode ? darkTertiaryText : lightTertiaryText;
  }

  /// Obtiene el color de botón primario según el modo
  static Color getPrimaryButtonColor(bool isDarkMode) {
    return isDarkMode ? darkPrimaryButton : lightPrimaryButton;
  }

  /// Obtiene el color de texto de botón primario según el modo
  static Color getPrimaryButtonTextColor(bool isDarkMode) {
    return isDarkMode ? darkPrimaryButtonText : lightPrimaryButtonText;
  }

  /// Obtiene el color de botón secundario según el modo
  static Color getSecondaryButtonColor(bool isDarkMode) {
    return isDarkMode ? darkSecondaryButton : lightSecondaryButton;
  }

  /// Obtiene el color de texto de botón secundario según el modo
  static Color getSecondaryButtonTextColor(bool isDarkMode) {
    return isDarkMode ? darkSecondaryButtonText : lightSecondaryButtonText;
  }

  /// Obtiene el color del contenedor con blur según el modo
  static Color getBlurContainerColor(bool isDarkMode) {
    return isDarkMode ? darkBlurContainer : lightBlurContainer;
  }

  /// Obtiene el color de fondo de campo según el modo
  static Color getFieldBackgroundColor(bool isDarkMode) {
    return isDarkMode ? darkFieldBackground : lightFieldBackground;
  }

  /// Obtiene el color de placeholder según el modo
  static Color getPlaceholderTextColor(bool isDarkMode) {
    return isDarkMode ? darkPlaceholderText : lightPlaceholderText;
  }

  /// Obtiene el color de texto de entrada según el modo
  static Color getInputTextColor(bool isDarkMode) {
    return isDarkMode ? darkInputText : lightInputText;
  }

  /// Obtiene el color de partículas según el modo
  static Color getParticleColor(bool isDarkMode) {
    return isDarkMode ? darkParticles : lightParticles;
  }

  // =============== GRADIENTES ===============

  /// Gradiente de fondo dark
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      darkBackground,
      darkBackground,
      darkBackground,
    ],
  );

  /// Gradiente de fondo light
  static const LinearGradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      lightBackground,
      lightBackground,
      lightBackground,
    ],
  );

  /// Obtiene el gradiente de fondo según el modo
  static LinearGradient getBackgroundGradient(bool isDarkMode) {
    return isDarkMode ? darkBackgroundGradient : lightBackgroundGradient;
  }
}
