import 'package:flutter/material.dart';
import '../tags/app_tag.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Banner de validación de reparto: "Matches total" (Log Expense) y
/// "Total split 100% matched" (Expense Details) son el mismo patrón —
/// ícono de estado + título + monto asignado + pill de diferencia.
class SplitStatusBanner extends StatelessWidget {
  const SplitStatusBanner({
    super.key,
    required this.isMatched,
    required this.title,
    required this.allocatedLabel,
    required this.diffLabel,
  });

  final bool isMatched;
  final String title; // ej. "Matches total"
  final String allocatedLabel; // ej. "Allocated: $120.00"
  final String diffLabel; // ej. "Diff: $0.00"

  @override
  Widget build(BuildContext context) {
    final Color bg = isMatched
        ? AppSemanticColors.positiveContainer
        : AppSemanticColors.negativeContainer;
    final Color fg = isMatched
        ? AppSemanticColors.positiveText
        : AppSemanticColors.negativeText;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.mdRadius),
      child: Row(
        children: [
          Icon(isMatched ? Icons.check_circle : Icons.error_outline, color: fg, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelMd(color: fg)),
                Text(allocatedLabel, style: AppTypography.bodySm(color: AppSemanticColors.slate600)),
              ],
            ),
          ),
          AppTag(label: diffLabel, background: bg, foreground: fg, uppercase: false),
        ],
      ),
    );
  }
}
