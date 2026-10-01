import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Caja con el desglose matemático de un settlement ("Direct subtotal: $20
/// + $31 + $42.50 - $12 = $81.50" / "Final direct settlement: +$110.00").
/// Aparece al expandir "Details" en SettlementCard.
class CalculationSummaryBox extends StatelessWidget {
  const CalculationSummaryBox({
    super.key,
    required this.subtotalLabel,
    required this.subtotalValue,
    required this.finalLabel,
    required this.finalValue,
  });

  final String subtotalLabel;
  final String subtotalValue;
  final String finalLabel;
  final String finalValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppMd3Colors.surfaceContainerLow,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subtotalLabel, style: AppTypography.bodySm(color: AppSemanticColors.slate600)),
              Text(subtotalValue, style: AppTypography.bodySm(color: AppSemanticColors.slate600)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(finalLabel, style: AppTypography.titleMd(color: AppSemanticColors.slate900)),
              Text(
                finalValue,
                style: AppTypography.titleMd(color: AppSemanticColors.slate900)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
