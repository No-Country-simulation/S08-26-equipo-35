import 'package:flutter/material.dart';
import '../../design_system/tokens/app_colors.dart';

/// Devuelve (ícono, color de fondo, color de acento) para una categoría
/// de gasto. Las 4 que reconoce son las que esta misma app manda desde
/// Log Expense (ver `_categoryApiLabel` ahí) — cualquier otro texto (de
/// otro cliente, u otro idioma) cae en el genérico.
///
/// Compartido por Group Details (lista de gastos + filtros) y Balances
/// (desglose de deuda).
(IconData, Color, Color) categoryVisual(String category) {
  switch (category) {
    case 'Food & Drink':
      return (
        Icons.restaurant,
        const Color(0xFFFFF7ED),
        const Color(0xFFEA580C),
      );
    case 'Transport':
      return (
        Icons.directions_car,
        const Color(0xFFF0F9FF),
        const Color(0xFF0284C7),
      );
    case 'Stay':
      return (Icons.home, const Color(0xFFF5F3FF), const Color(0xFF7C3AED));
    case 'Activities':
      return (
        Icons.local_activity,
        const Color(0xFFFEFCE8),
        const Color(0xFFCA8A04),
      );
    default:
      return (
        Icons.receipt_long,
        AppMd3Colors.surfaceContainer,
        AppMd3Colors.primaryContainer,
      );
  }
}
