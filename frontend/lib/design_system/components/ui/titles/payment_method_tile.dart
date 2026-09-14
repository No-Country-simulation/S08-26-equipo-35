import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Tile de método de pago (ícono + título + subtítulo, seleccionable).
/// Distinto de AppQuickActionTile (que es ícono+un solo label centrado) y
/// de CategoryChip (que es ícono+label en una sola línea) — este es un
/// bloque de dos líneas de texto, pensado para grids 2x2.
class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? Colors.white : AppSemanticColors.slate900;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppMd3Colors.primaryContainer : AppMd3Colors.surfaceContainer,
          borderRadius: AppRadius.mdRadius,
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMd(color: fg)),
                  Text(
                    subtitle,
                    style: AppTypography.bodySm(
                      color: selected ? Colors.white.withValues(alpha: 0.85) : AppSemanticColors.slate600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
