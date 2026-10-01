import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Categorías de gasto de "Components > Category Chips" en DESIGN.md.
/// Un enum + un mapa de estilos — así, si mañana agregas una categoría,
/// solo agregas un caso aquí, no un widget nuevo.
enum ExpenseCategory { food, transport, stay, activities }

class _CategoryStyle {
  const _CategoryStyle({required this.icon, required this.tint, required this.label});
  final IconData icon;
  final Color tint; // color del ícono en estado NO seleccionado
  final String label;
}

const Map<ExpenseCategory, _CategoryStyle> _categoryStyles = {
  ExpenseCategory.food: _CategoryStyle(
    icon: Icons.restaurant,
    tint: Color(0xFFEA580C),
    label: 'Comida y bebida',
  ),
  ExpenseCategory.transport: _CategoryStyle(
    icon: Icons.directions_car,
    tint: Color(0xFF0284C7),
    label: 'Transporte',
  ),
  ExpenseCategory.stay: _CategoryStyle(
    icon: Icons.home,
    tint: Color(0xFF7C3AED),
    label: 'Alojamiento',
  ),
  ExpenseCategory.activities: _CategoryStyle(
    icon: Icons.local_activity,
    tint: Color(0xFFCA8A04),
    label: 'Actividades',
  ),
};

/// Etiqueta en español de una categoría: la misma que pinta el chip.
///
/// Expuesta para que `core/utils/category_visual.dart` pueda mostrar el mismo
/// texto en los puntos de la UI que reciben el string crudo de la API (los
/// filtros de Group Details, el subtítulo del desglose de Balances) sin
/// duplicar el texto en dos lugares que después se desincronizarían.
///
/// Ojo: esto NO es lo que viaja a la API. Ese valor en inglés vive en
/// `expenseCategoryApiLabel` y no se toca.
String categoryChipLabelOf(ExpenseCategory category) =>
    _categoryStyles[category]!.label;

/// Chip de categoría: seleccionado se llena de indigo (ícono/texto blanco);
/// no seleccionado queda blanco con borde y el ícono en su color de tinte.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final ExpenseCategory category;
  final bool selected;
  final VoidCallback onTap;

  /// Conteo opcional junto al label, ej. "Food 6", "Transport 3".
  final int? count;

  @override
  Widget build(BuildContext context) {
    final style = _categoryStyles[category]!;
    final textColor = selected ? Colors.white : AppSemanticColors.slate900;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppMd3Colors.primaryContainer : Colors.white,
          borderRadius: AppRadius.fullRadius,
          border: selected ? null : Border.all(color: AppSemanticColors.slate200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 18, color: selected ? Colors.white : style.tint),
            const SizedBox(width: AppSpacing.xs),
            Text(style.label, style: AppTypography.bodyMd(color: textColor)),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text('$count', style: AppTypography.bodySm(color: textColor)),
            ],
          ],
        ),
      ),
    );
  }
}
