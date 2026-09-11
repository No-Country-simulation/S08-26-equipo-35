import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Chip de filtro tipo segmento. Un widget con estado `selected` — no un
/// chip distinto por cada opción de filtro.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Punto de color antes del label (ej. filtros de categoría en Group
  /// Details: naranja para "Food & Drink", azul para "Transport"...).
  /// Distinto de CategoryChip, que usa un ícono lleno en vez de un punto.
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppMd3Colors.primaryContainer : AppMd3Colors.surfaceContainer,
          borderRadius: AppRadius.fullRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.xs2),
            ],
            Text(
              label,
              style: AppTypography.bodyMd(
                color: selected ? Colors.white : AppSemanticColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
