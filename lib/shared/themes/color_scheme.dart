import 'package:flutter/material.dart';

class AppColorScheme {
  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFE2231A),
    onPrimary: Colors.white,
    secondary: Color(0xFFE2231A),
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
  );

  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFE2231A),
    onPrimary: Colors.white,
    secondary: Color(0xFFE2231A),
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    surface: Colors.black,
    onSurface: Colors.white,
  );
}
