import 'package:flutter/material.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/components/ui/chips/category_chip.dart';

/// Etiqueta que la API espera en `expense_category`.
///
/// `ExpenseCategory` (el enum del chip) es la identidad interna de la app;
/// este string es lo que viaja por la API y lo que vuelve en las
/// respuestas. La conversión va en un solo lugar para que Log Expense y el
/// editor de Edit Expense no puedan mandarse valores distintos.
const Map<ExpenseCategory, String> expenseCategoryApiLabel = {
  ExpenseCategory.food: 'Food & Drink',
  ExpenseCategory.transport: 'Transport',
  ExpenseCategory.stay: 'Stay',
  ExpenseCategory.activities: 'Activities',
};

/// Inversa de [expenseCategoryApiLabel]: el string de la API → el enum de
/// la app. Los gastos ya guardados traen el texto, así que al editar uno
/// hay que poder volver a un `ExpenseCategory` para pintar el chip.
///
/// Devuelve `null` si la categoría viene de otro cliente u otro idioma —
/// en ese caso la UI cae en el estilo genérico de [categoryVisual] en vez
/// de mentir diciendo que es "Comida y bebida".
ExpenseCategory? expenseCategoryFromApiLabel(String label) {
  for (final entry in expenseCategoryApiLabel.entries) {
    if (entry.value == label) return entry.key;
  }
  return null;
}

/// Etiqueta en español para mostrar una categoría que viene de la API.
///
/// Hace falta porque hay dos puntos de la UI que muestran el string crudo
/// de `expense_category` en vez del label del chip:
/// los filtros de categoría de Group Details y el subtítulo del desglose de
/// deuda en Balances. Sin este mapeo esos dos lugares seguirían mostrando
/// "Food & Drink" al lado de un chip que dice "Comida y bebida".
///
/// Fallback deliberado a la etiqueta cruda: si la categoría no es una de las
/// cuatro que esta app manda, viene de otro cliente y su texto es lo mejor
/// que se puede mostrar — traducirlo sería inventar.
///
/// Ojo con la asimetría que esto crea, que es intencional: el chip muestra
/// español y la API recibe inglés. El round-trip de
/// [expenseCategoryFromApiLabel] sigue funcionando porque matchea contra
/// [expenseCategoryApiLabel], que es el mapa congelado.
String categoryDisplayLabel(String apiLabel) {
  final category = expenseCategoryFromApiLabel(apiLabel);
  if (category == null) return apiLabel;
  return categoryChipLabel(category);
}

/// Etiqueta en español de una categoría, tal como la pinta el chip.
///
/// Reenvía al label del `CategoryChip` para que haya una sola fuente de
/// verdad: si mañana se cambia el texto del chip, este helper lo sigue sin
/// tocar nada.
String categoryChipLabel(ExpenseCategory category) {
  return categoryChipLabelOf(category);
}

/// Devuelve (ícono, color de fondo, color de acento) para una categoría
/// de gasto. Las 4 que reconoce son las que esta misma app manda desde
/// Log Expense (ver [expenseCategoryApiLabel]) — cualquier otro texto (de
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
