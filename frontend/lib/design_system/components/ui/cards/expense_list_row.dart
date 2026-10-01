import 'package:flutter/material.dart';
import '../icon_boxes/app_icon_box.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

enum ExpenseRowStatus { owed, owe, neutral }

/// Fila de gasto dentro de una lista ("Paella & Sangria... $124.00 +$93.00
/// for you"). Distinto de GroupCard (que resume un grupo completo, no un
/// gasto individual) — combina AppIconBox + texto + monto/estado a la derecha.
class ExpenseListRow extends StatelessWidget {
  const ExpenseListRow({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.metaText,
    required this.timeLabel,
    required this.totalAmountLabel,
    required this.statusLabel,
    this.status = ExpenseRowStatus.neutral,
    this.onTap,
  });

  final Widget icon;
  final Color iconBackground;
  final String title;
  final String metaText; // ej. "Paid by You · Split equally"
  final String timeLabel; // ej. "Today 2:15 PM"
  final String totalAmountLabel; // ej. "$124.00"
  final String statusLabel; // ej. "+$93.00 for you" / "You owe $26.00"
  final ExpenseRowStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (status) {
      ExpenseRowStatus.owed => AppSemanticColors.positiveText,
      ExpenseRowStatus.owe => AppSemanticColors.negativeText,
      ExpenseRowStatus.neutral => AppSemanticColors.slate600,
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
        child: Row(
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
                  const SizedBox(height: 2),
                  Text(metaText, style: AppTypography.bodySm(color: AppSemanticColors.slate600)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(totalAmountLabel, style: AppTypography.amountRow(color: AppSemanticColors.slate900)),
                const SizedBox(height: 2),
                Text(statusLabel, style: AppTypography.labelSm(color: statusColor)),
                const SizedBox(height: 2),
                Text(timeLabel, style: AppTypography.labelSm(color: AppSemanticColors.slate400)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
