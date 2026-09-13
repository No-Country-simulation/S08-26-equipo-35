import 'package:flutter/material.dart';
import '../icon_boxes/app_icon_box.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

enum TransactionDirection { credit, debit, neutral }

/// Fila de transacción dentro de un desglose ("Tapas Dinner — You paid
/// $64.00 — +$20.00 his share"). Distinto de ExpenseListRow: ahí el color
/// va en el texto de estado pequeño y el monto grande es siempre negro;
/// aquí es al revés — el monto grande ES el que lleva el color.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.captionLabel,
    this.direction = TransactionDirection.neutral,
  });

  final Widget icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String amountLabel;
  final String captionLabel;
  final TransactionDirection direction;

  @override
  Widget build(BuildContext context) {
    final Color amountColor = switch (direction) {
      TransactionDirection.credit => AppSemanticColors.positiveText,
      TransactionDirection.debit => AppSemanticColors.negativeText,
      TransactionDirection.neutral => AppSemanticColors.slate900,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          AppIconBox(icon: icon, background: iconBackground, size: 36),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMd(color: AppSemanticColors.slate900)),
                Text(subtitle, style: AppTypography.bodySm(color: AppSemanticColors.slate600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amountLabel, style: AppTypography.amountRow(color: amountColor)),
              Text(captionLabel, style: AppTypography.labelSm(color: AppSemanticColors.slate400)),
            ],
          ),
        ],
      ),
    );
  }
}
