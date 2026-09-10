import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Pill pequeño tipo "eyebrow" sobre un título, ej. "EFFORTLESS GROUP MATH".
/// Genérico: el color por defecto es el tinte indigo, pero acepta otro
/// background/foreground si se reutiliza en otro contexto.
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.icon,
    this.background = AppMd3Colors.surfaceContainer,
    this.foreground = AppMd3Colors.primaryContainer,
  });

  final String label;
  final Widget? icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: AppSpacing.xs2)],
          Text(
            label.toUpperCase(),
            style: AppTypography.labelMd(color: foreground),
          ),
        ],
      ),
    );
  }
}
