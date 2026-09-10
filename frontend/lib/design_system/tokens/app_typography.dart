import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Escala tipográfica de DESIGN.md. Los valores de línea/letter-spacing
/// vienen en px/em (unidades web) y aquí se convierten a lo que Flutter
/// espera: `height` es un MULTIPLICADOR de fontSize, y `letterSpacing`
/// son px lógicos absolutos, no em.
///
/// Requiere el paquete `google_fonts` (`flutter pub add google_fonts`).
class AppTypography {
  AppTypography._();

  static TextStyle _style({
    required double fontSize,
    required FontWeight fontWeight,
    required double lineHeightPx,
    required double letterSpacingEm,
    Color? color,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: lineHeightPx / fontSize,
      letterSpacing: letterSpacingEm * fontSize,
      color: color,
    );
  }

  // DESIGN.md exige font-variant-numeric: tabular-nums en TODAS las cifras
  // monetarias (display-currency y amount-row), para que los decimales
  // alineen verticalmente en listas de gastos.
  static TextStyle displayCurrency({Color? color}) => _style(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        lineHeightPx: 44,
        letterSpacingEm: -0.03,
        color: color,
      ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle amountRow({Color? color}) => _style(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        lineHeightPx: 20,
        letterSpacingEm: -0.01,
        color: color,
      ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle headlineLg({Color? color}) => _style(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        lineHeightPx: 34,
        letterSpacingEm: -0.02,
        color: color,
      );

  static TextStyle headlineMd({Color? color}) => _style(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        lineHeightPx: 28,
        letterSpacingEm: -0.015,
        color: color,
      );

  static TextStyle headlineSm({Color? color}) => _style(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        lineHeightPx: 24,
        letterSpacingEm: -0.01,
        color: color,
      );

  static TextStyle titleMd({Color? color}) => _style(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        lineHeightPx: 22,
        letterSpacingEm: -0.005,
        color: color,
      );

  static TextStyle bodyLg({Color? color}) => _style(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        lineHeightPx: 24,
        letterSpacingEm: 0,
        color: color,
      );

  static TextStyle bodyMd({Color? color}) => _style(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        lineHeightPx: 20,
        letterSpacingEm: 0,
        color: color,
      );

  static TextStyle bodySm({Color? color}) => _style(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        lineHeightPx: 18,
        letterSpacingEm: 0.01,
        color: color,
      );

  static TextStyle labelMd({Color? color}) => _style(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        lineHeightPx: 16,
        letterSpacingEm: 0.02,
        color: color,
      );

  static TextStyle labelSm({Color? color}) => _style(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        lineHeightPx: 14,
        letterSpacingEm: 0.03,
        color: color,
      );
}
