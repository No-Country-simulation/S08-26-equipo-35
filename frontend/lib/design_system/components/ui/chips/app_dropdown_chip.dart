import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Chip que dispara un dropdown/selector (ej. "📅 July 2024 ⌄", "Sort by:
/// Newest ⌄"). Distinto de AppFilterChip (que alterna entre seleccionado/no
/// seleccionado) — este siempre luce igual y solo abre un menú al tocar.
class AppDropdownChip extends StatelessWidget {
  const AppDropdownChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.prefixText,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  /// Texto antes del label con menor énfasis, ej. "Sort by: " antes de "Newest".
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppMd3Colors.surfaceContainer,
          borderRadius: AppRadius.mdRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppSemanticColors.slate600),
              const SizedBox(width: 4),
            ],
            if (prefixText != null)
              Text(prefixText!, style: AppTypography.bodySm(color: AppSemanticColors.slate600)),
            Text(
              label,
              style: AppTypography.bodySm(color: AppSemanticColors.slate900)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.expand_more, size: 16, color: AppSemanticColors.slate600),
          ],
        ),
      ),
    );
  }
}
