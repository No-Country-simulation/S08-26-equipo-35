import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Tarjeta de estadística: caption arriba + valor grande abajo + ícono
/// circular a la derecha, sobre fondo tintado. Usada para "TOTAL GROUP
/// SPENDING $1,420.00" y reutilizable para cualquier otro stat destacado.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.background = AppMd3Colors.surfaceContainer,
    this.iconBackground = Colors.white,
  });

  final String label;
  final String value;
  final Widget icon;
  final Color background;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.lgRadius),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTypography.labelMd(color: AppSemanticColors.slate600),
                ),
                const SizedBox(height: AppSpacing.xs2),
                Text(value, style: AppTypography.headlineLg(color: AppSemanticColors.slate900)),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
            child: Center(child: icon),
          ),
        ],
      ),
    );
  }
}
