import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Pill de texto pequeño reutilizable. Sirve tanto para eyebrows en
/// mayúsculas ("EFFORTLESS GROUP MATH") como para pills de estado con
/// case normal ("Barcelona Summer Trip", "4 selected") — controla cuál
/// con `uppercase`.
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.icon,
    this.background = AppMd3Colors.surfaceContainer,
    this.foreground = AppMd3Colors.primaryContainer,
    this.uppercase = true,
  });

  final String label;
  final Widget? icon;
  final Color background;
  final Color foreground;
  final bool uppercase;

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
            uppercase ? label.toUpperCase() : label,
            style: uppercase
                ? AppTypography.labelMd(color: foreground)
                : AppTypography.bodySm(color: foreground),
          ),
        ],
      ),
    );
  }
}