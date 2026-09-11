import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Tile de acción rápida: ícono circular de color + label debajo, en una
/// tarjeta bordeada. Es el mismo patrón que "Share Link" / "Balances" /
/// "Summary" en Group Details, y también el de "+ New Group" en Home
/// (que se dejó como widget privado ahí antes de que se repitiera aquí).
/// Si tienes tiempo, vale la pena reemplazar el `_NewGroupAction` privado
/// de home.dart por este componente para no mantener dos versiones.
class AppQuickActionTile extends StatelessWidget {
  const AppQuickActionTile({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final Color iconBackground;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppSemanticColors.slate200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
              child: Center(child: icon),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: AppTypography.bodySm(color: AppSemanticColors.slate900)),
          ],
        ),
      ),
    );
  }
}
