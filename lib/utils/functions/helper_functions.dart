import 'package:flutter/material.dart';

/// Class with helper functions

class THelperFunctions {
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}