import 'package:flutter/material.dart';
import '../icon_boxes/app_icon_box.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

enum ActivityStatus { owed, owe, neutral }

/// Tarjeta de gasto del Historial/Activity. Distinto de ExpenseListRow
/// (usado en Group Details): aquí "pagado por" y la hora van en una sola
/// línea con separador, el estado lleva flecha + monto en una sola
/// oración, y hay una segunda fila de detalle (participantes/recibo) bajo
/// un separador — ExpenseListRow no tiene esa segunda fila.
class ActivityExpenseCard extends StatelessWidget {
  const ActivityExpenseCard({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.paidByLabel,
    required this.timeLabel,
    required this.totalAmountLabel,
    required this.statusLabel,
    this.status = ActivityStatus.neutral,
    required this.footerLeading,
    this.footerTrailing,
    this.onTap,
  });

  final Widget icon;
  final Color iconBackground;
  final String title;
  final String paidByLabel; // ej. "Paid by You"
  final String timeLabel; // ej. "2:15 PM"
  final String totalAmountLabel;
  final String statusLabel; // ej. "+ You are owed $94.00"
  final ActivityStatus status;
  final String footerLeading; // ej. "Split equally (You, María, Juan, Chloe)"
  final String? footerTrailing; // ej. "Receipt attached"
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (status) {
      ActivityStatus.owed => AppSemanticColors.positiveText,
      ActivityStatus.owe => AppSemanticColors.negativeText,
      ActivityStatus.neutral => AppSemanticColors.slate600,
    };
    final IconData statusIcon = switch (status) {
      ActivityStatus.owed => Icons.arrow_downward,
      ActivityStatus.owe => Icons.arrow_upward,
      ActivityStatus.neutral => Icons.remove,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.lgRadius,
          boxShadow: AppShadows.level1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIconBox(icon: icon, background: iconBackground, size: 44),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMd(color: AppSemanticColors.slate900),
                      ),
                      Text(
                        '$paidByLabel · $timeLabel',
                        style: AppTypography.bodySm(color: AppSemanticColors.slate600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(totalAmountLabel, style: AppTypography.amountRow(color: AppSemanticColors.slate900)),
                    Row(
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 2),
                        Text(statusLabel, style: AppTypography.labelSm(color: statusColor)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: AppSpacing.md, color: AppSemanticColors.slate200),
            Row(
              children: [
                Expanded(
                  child: Text(
                    footerLeading,
                    style: AppTypography.bodySm(color: AppSemanticColors.slate600),
                  ),
                ),
                if (footerTrailing != null)
                  Text(
                    footerTrailing!,
                    style: AppTypography.bodySm(color: AppMd3Colors.primaryContainer),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
