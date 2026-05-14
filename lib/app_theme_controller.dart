import 'package:flutter/material.dart';

class AppThemeController {
  static bool isDark = true;

  static void setDark(bool value) {
    isDark = value;
  }

  static Color color(Color dark, Color light) => isDark ? dark : light;
}
