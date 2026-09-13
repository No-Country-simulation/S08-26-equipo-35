import 'package:flutter/material.dart';
import '../tags/app_tag.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Tarjeta hero de balance: tag de estado arriba + monto grande + acción
/// circular flotante a la derecha. Es el mismo patrón que la tarjeta
/// resumen de Home (ahí quedó como widget privado `_SummaryCard`) y la
/// tarjeta superior de Balances — vale la pena migrar Home a este
/// componente para no mantener dos versiones del mismo patrón.
class AppBalanceHeroCard extends StatelessWidget {
  const AppBalanceHeroCard({
    super.key,
    required this.statusIcon,
    required this.statusLabel,
    required this.amount,
    required this.background,
    required this.foreground,
    this.trailingAction,
  });

  final Widget statusIcon;
  final String statusLabel;
  final String amount;
  final Color background;
  final Color foreground;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.xlRadius),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTag(
                  icon: statusIcon,
                  label: statusLabel,
                  background: Colors.white.withValues(alpha: 0.5),
                  foreground: foreground,
                  uppercase: false,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(amount, style: AppTypography.displayCurrency(color: AppSemanticColors.slate900)),
              ],
            ),
          ),
          if (trailingAction != null) trailingAction!,
        ],
      ),
    );
  }
}
