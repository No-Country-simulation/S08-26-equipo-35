import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

enum BalanceBadgeStatus { owed, owe, settled }

/// Pill de balance: "+$180.00 you are owed" / "-$42.50 you owe" / "settled".
/// Un widget, tres colores según `status` — mismo criterio que AppButton.
class BalanceBadge extends StatelessWidget {
  const BalanceBadge({
    super.key,
    required this.amountLabel,
    required this.status,
    this.caption,
  });

  final String amountLabel; // ej. "+$180.00"
  final BalanceBadgeStatus status;
  final String? caption; // ej. "you are owed", se muestra debajo

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final (Color bg, Color fg) = switch (status) {
      BalanceBadgeStatus.owed => (semantic.positiveContainer, semantic.positiveText),
      BalanceBadgeStatus.owe => (semantic.negativeContainer, semantic.negativeText),
      BalanceBadgeStatus.settled => (AppSemanticColors.slate100, AppSemanticColors.slate600),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs2,
          ),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadius.fullRadius),
          child: Text(amountLabel, style: AppTypography.amountRow(color: fg)),
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(caption!, style: AppTypography.labelSm(color: fg)),
        ],
      ],
    );
  }
}

/// Círculo pequeño con un número, ej. el "3" junto a "Active Groups".
class AppCountBadge extends StatelessWidget {
  const AppCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppMd3Colors.surfaceContainer,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Text(
        '$count',
        style: AppTypography.labelMd(color: AppSemanticColors.slate600),
      ),
    );
  }
}
