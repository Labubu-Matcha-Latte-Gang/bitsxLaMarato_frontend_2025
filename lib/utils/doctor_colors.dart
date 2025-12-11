import 'package:flutter/material.dart';

import 'app_colors.dart';

class DoctorColors {
  static const Color lightPrimary = Color(0xFF005A8D);
  static const Color lightSecondary = Color(0xFF4A90E2);
  static const Color lightAccent = Color(0xFFE1F5FE);
  static const Color lightBackground = Color(0xFFF4F6F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightTextPrimary = Color(0xFF2C3E50);
  static const Color lightTextSecondary = Color(0xFF7F8C8D);
  static const Color success = Color(0xFF27AE60);
  static const Color _critical = Color(0xFFC0392B);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF2980B9);

  static Color critical(bool isDarkMode) => isDarkMode ? _critical : _critical;

  static Color background(bool isDarkMode) =>
      isDarkMode ? AppColors.getBackgroundColor(true) : lightBackground;

  static Color surface(bool isDarkMode) =>
      isDarkMode ? AppColors.getSecondaryBackgroundColor(true) : lightSurface;

  static Color primary(bool isDarkMode) =>
      isDarkMode ? AppColors.getPrimaryButtonColor(true) : lightPrimary;

  static Color secondary(bool isDarkMode) =>
      isDarkMode ? AppColors.getSecondaryButtonColor(true) : lightSecondary;

  static Color textPrimary(bool isDarkMode) =>
      isDarkMode ? AppColors.getPrimaryTextColor(true) : lightTextPrimary;

  static Color textSecondary(bool isDarkMode) =>
      isDarkMode ? AppColors.getSecondaryTextColor(true) : lightTextSecondary;

  static Color border(bool isDarkMode) =>
      isDarkMode ? AppColors.getBlurContainerColor(true).withOpacity(0.35) : lightBorder;

  static Color cardShadow(bool isDarkMode) =>
      isDarkMode ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.08);

  static LinearGradient headerGradient(bool isDarkMode) {
    if (isDarkMode) {
      return AppColors.getBackgroundGradient(true);
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0A6AA3),
        lightPrimary,
        lightSecondary,
      ],
    );
  }
}
