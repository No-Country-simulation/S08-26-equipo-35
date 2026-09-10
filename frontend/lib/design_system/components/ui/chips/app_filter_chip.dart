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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
        child: Text(
          label,
          style: AppTypography.bodyMd(
            color: selected ? Colors.white : AppSemanticColors.slate600,
          ),
        ),
      ),
    );
  }
}
