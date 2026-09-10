import 'package:flutter/material.dart';

/// Escala de espaciado (DESIGN.md usa rem; 1rem = 16px).
class AppSpacing {
  AppSpacing._();

  static const double xs2 = 4; // space-2xs
  static const double xs = 8; // space-xs
  static const double sm = 12; // space-sm
  static const double md = 16; // space-md
  static const double lg = 20; // space-lg
  static const double xl = 24; // space-xl
  static const double xl2 = 32; // space-2xl
  static const double xl3 = 40; // space-3xl

  static const double gutterMobile = 16;
  static const double marginMobile = 20;
}

/// Radios de borde. DESIGN.md distingue explícitamente qué usa cada tipo
/// de elemento: chips/botones → full, cards → lg, inputs → md, avatares → full.
class AppRadius {
  AppRadius._();

  static const double sm = 4;
  static const double base = 8;
  static const double md = 12; // inputs y dropdowns
  static const double lg = 16; // cards y módulos principales
  static const double xl = 24;
  static const double full = 9999; // chips, botones, avatares

  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get baseRadius => BorderRadius.circular(base);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get fullRadius => BorderRadius.circular(full);
}

/// Niveles de elevación de DESIGN.md. El sistema evita las sombras duras
/// por defecto de Material — aplícalas manualmente en `BoxDecoration.boxShadow`,
/// NO uses la propiedad `elevation` de Card (déjala en 0, ver app_theme.dart).
class AppShadows {
  AppShadows._();

  /// Tarjetas de lista, feeds de grupo, módulos de detalle.
  static const List<BoxShadow> level1 = [
    BoxShadow(color: Color(0x0A0F172A), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(
      color: Color(0x050F172A),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: -1,
    ),
  ];

  /// CTA flotante "Add Expense", tabs activos, banners fijos.
  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x2E4F46E5),
      offset: Offset(0, 8),
      blurRadius: 20,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0x0A0F172A),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: -2,
    ),
  ];

  /// Modales, bottom sheets de settlement/calculadora.
  static const List<BoxShadow> level3 = [
    BoxShadow(
      color: Color(0x1A0F172A),
      offset: Offset(0, 20),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x0D0F172A),
      offset: Offset(0, 8),
      blurRadius: 10,
      spreadRadius: -6,
    ),
  ];
}
