import 'package:flutter/material.dart';

/// Roles de color Material 3 tal como los exportó Stitch en DESIGN.md.
/// Úsalos SOLO para construir el ColorScheme (ver app_theme.dart) —
/// en widgets, prefiere `Theme.of(context).colorScheme.xxx` para que el
/// tema responda si algún día agregas modo oscuro.
class AppMd3Colors {
  AppMd3Colors._();

  static const surface = Color(0xFFF8F9FF);
  static const surfaceDim = Color(0xFFCBDBF5);
  static const surfaceBright = Color(0xFFF8F9FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEFF4FF);
  static const surfaceContainer = Color(0xFFE5EEFF);
  static const surfaceContainerHigh = Color(0xFFDCE9FF);
  static const surfaceContainerHighest = Color(0xFFD3E4FE);
  static const onSurface = Color(0xFF0B1C30);
  static const onSurfaceVariant = Color(0xFF464555);
  static const inverseSurface = Color(0xFF213145);
  static const inverseOnSurface = Color(0xFFEAF1FF);
  static const outline = Color(0xFF777587);
  static const outlineVariant = Color(0xFFC7C4D8);
  static const surfaceTint = Color(0xFF4D44E3);

  // OJO: `primary` (#3525CD) es más oscuro que el indigo de marca real.
  // El indigo de marca (#4F46E5) vive en `primaryContainer`. El botón
  // primario de la app usa `primaryContainer`, no `primary` — ver
  // app_theme.dart donde ya está resuelto.
  static const primary = Color(0xFF3525CD);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF4F46E5); // <- indigo de marca real
  static const onPrimaryContainer = Color(0xFFDAD7FF);
  static const inversePrimary = Color(0xFFC3C0FF);

  static const secondary = Color(0xFF006C49);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF6CF8BB);
  static const onSecondaryContainer = Color(0xFF00714D);

  static const tertiary = Color(0xFF95002B);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFBF0F3C);
  static const onTertiaryContainer = Color(0xFFFFD0D2);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const primaryFixed = Color(0xFFE2DFFF);
  static const primaryFixedDim = Color(0xFFC3C0FF);
  static const onPrimaryFixed = Color(0xFF0F0069);
  static const onPrimaryFixedVariant = Color(0xFF3323CC);

  static const secondaryFixed = Color(0xFF6FFBBE);
  static const secondaryFixedDim = Color(0xFF4EDEA3);
  static const onSecondaryFixed = Color(0xFF002113);
  static const onSecondaryFixedVariant = Color(0xFF005236);

  static const tertiaryFixed = Color(0xFFFFDADB);
  static const tertiaryFixedDim = Color(0xFFFFB2B7);
  static const onTertiaryFixed = Color(0xFF40000D);
  static const onTertiaryFixedVariant = Color(0xFF92002A);

  static const background = Color(0xFFF8F9FF);
  static const onBackground = Color(0xFF0B1C30);
  static const surfaceVariant = Color(0xFFD3E4FE);
}

/// Colores semánticos propios de SplitFlow, tomados de las secciones
/// "Application Rules" y "Components" de DESIGN.md — DELIBERADAMENTE
/// separados de `secondary`/`tertiary` de Material (que MD3 generó como
/// verde oscuro y granate, sin relación con estos). Úsalos para badges
/// de balance y chips de categoría.
class AppSemanticColors {
  AppSemanticColors._();

  // Balance positivo ("te deben")
  static const positive = Color(0xFF10B981);
  static const positiveContainer = Color(0xFFECFDF5);
  static const positiveText = Color(0xFF059669);
  static const positiveBorder = Color(0x3310B981); // ~20% opacidad

  // Balance negativo ("debes")
  static const negative = Color(0xFFF43F5E);
  static const negativeContainer = Color(0xFFFFF1F2);
  static const negativeText = Color(0xFFE11D48);
  static const negativeBorder = Color(0x33F43F5E);

  // Escala neutra (texto/bordes, sección "Text & Borders")
  static const slate900 = Color(0xFF0F172A);
  static const slate600 = Color(0xFF475569);
  static const slate400 = Color(0xFF94A3B8);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate50 = Color(0xFFF8FAFC);

  // Secondary action button (tinte propio, distinto de primaryContainer)
  static const secondaryActionSurface = Color(0xFFEEF2FF);

  // Category chips
  static const foodTint = Color(0xFFFFF7ED);
  static const foodText = Color(0xFFEA580C);
  static const transportTint = Color(0xFFF0F9FF);
  static const transportText = Color(0xFF0284C7);
  static const stayTint = Color(0xFFF5F3FF);
  static const stayText = Color(0xFF7C3AED);
  static const activitiesTint = Color(0xFFFEFCE8);
  static const activitiesText = Color(0xFFCA8A04);
}
