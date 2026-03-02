import 'dart:ui' show Color;
import 'package:flutter/material.dart';

/// Operación segura de alpha que usa solo manipulación de bits ARGB.
/// Evita withOpacity/withValues que fallan en dart2js release mode.
extension SafeAlpha on Color {
  Color op(double opacity) {
    final alpha = (opacity.clamp(0.0, 1.0) * 255).round();
    return Color((value & 0x00FFFFFF) | (alpha << 24));
  }
}

/// Paleta: azul turquesa sutilmente verdoso (tecnológico). Verde solo para premio/cannabis.
class AppColors {
  static const Color background = Color(0xFF050A12);
  static const Color surface = Color(0xFF0C1220);
  static const Color glassSurface = Color.fromRGBO(15, 35, 50, 0.6);

  /// Turquesa principal (tecnológico)
  static const Color primary = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0D9488);
  static const Color secondary = Color(0xFF5EEAD4);

  /// Verde solo para premio / cannabis / REPROCAN / chalas
  static const Color prizeGreen = Color(0xFF22C55E);
  static const Color prizeGreenDark = Color(0xFF16A34A);

  static const Color error = Color(0xFFFF003C);
  static const Color success = Color(0xFF00FF94);
  static const Color warning = Color(0xFFFF9900);

  static const Color textPrimary = Color(0xFFE0E6ED);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color borderGlass = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color borderHighlight = Color.fromRGBO(20, 184, 166, 0.4);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2DD4BF), Color(0xFF14B8A6), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente verde para elementos del premio (cannabis, etc.)
  static const LinearGradient prizeGreenGradient = LinearGradient(
    colors: [Color(0xFF4ADE80), Color(0xFF22C55E), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
