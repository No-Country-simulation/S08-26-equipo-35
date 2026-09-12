import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Tarjeta de estadística: caption arriba + valor grande abajo, con ícono
/// circular opcional a la derecha, sobre fondo tintado. Cubre tanto "Total
/// Group Spending" (con ícono, alineado a la izquierda) como "Total Amount"
/// (sin ícono, centrado) con `centered: true`.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.background = AppMd3Colors.surfaceContainer,
    this.iconBackground = Colors.white,
    this.centered = false,
  });

  final String label;
  final String value;
  final Widget? icon;
  final Color background;
  final Color iconBackground;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final textColumn = Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelMd(color: AppSemanticColors.slate600),
        ),
        const SizedBox(height: AppSpacing.xs2),
        Text(value, style: AppTypography.headlineLg(color: AppSemanticColors.slate900)),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.lgRadius),
      child: icon == null
          ? Center(child: textColumn)
          : Row(
              children: [
                Expanded(child: textColumn),
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
