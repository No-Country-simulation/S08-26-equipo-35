import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Banner informativo: ícono circular + título + descripción sobre fondo
/// tintado. Mismo patrón que "Trusted Community" (onboarding) y "You're
/// in good shape!" (home) — antes hubiera sido fácil duplicarlo como
/// widget privado de cada pantalla; ahora es un solo componente.
class AppInfoBanner extends StatelessWidget {
  const AppInfoBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.background = AppMd3Colors.surfaceContainerLow,
    this.iconBackground = Colors.white,
  });

  final Widget icon;
  final String title;
  final String description;
  final Color background;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.lgRadius),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
            child: Center(child: icon),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMd(color: AppSemanticColors.slate900)),
                const SizedBox(height: 2),
                Text(description, style: AppTypography.bodySm(color: AppSemanticColors.slate600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
