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
    this.description,
    this.descriptionWidget,
    this.background = AppMd3Colors.surfaceContainerLow,
    this.iconBackground = Colors.white,
    this.trailing,
  });

  final Widget icon;
  final String title;

  /// Texto plano simple. Para descripciones con negritas u otros estilos
  /// mezclados (ej. "You paid **$124.00**..."), usa `descriptionWidget` en
  /// vez de esto — si ambos vienen, `descriptionWidget` gana.
  final String? description;
  final Widget? descriptionWidget;
  final Color background;
  final Color iconBackground;
  final Widget? trailing;

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
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: AppTypography.titleMd(color: AppSemanticColors.slate900)),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                if (descriptionWidget != null || description != null) ...[
                  const SizedBox(height: 2),
                  descriptionWidget ??
                      Text(description!, style: AppTypography.bodySm(color: AppSemanticColors.slate600)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
