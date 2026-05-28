import 'package:flutter/material.dart';

class AppColorScheme {
  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFE2231A),
    onPrimary: Colors.white,
    secondary: Color(0xFF0071C2),
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
    secondary: Color(0xFF22C55E),
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    surface: Color(0xFF121212),
    onSurface: Colors.white,
  );

  /// Returns blue (#0071C2) in light mode, green (#22C55E) in dark mode.
  /// Use for location icons/text and interactive accent elements.
  static Color accentFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF22C55E)
        : const Color(0xFF0071C2);
  }

  /// Returns dark navy (#1A1F36) in light mode, green (#22C55E) in dark mode.
  /// Use for section titles and page headings.
  static Color titleFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF22C55E)
        : const Color(0xFF1A1F36);
  }

  /// Returns a readable text color for body/secondary text.
  /// Dark gray in light mode, white (70%) in dark mode.
  static Color subtitleFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : const Color(0xFF4A5772);
  }
}
