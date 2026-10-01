import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_typography.dart';

/// Monto grande con símbolo "$" al lado y un hint de edición debajo
/// ("✏️ Tap to edit custom sum"). Distinto de AppStatCard: este es
/// específicamente para montos que el usuario puede tocar para editar,
/// no para stats de solo lectura.
class EditableAmountDisplay extends StatelessWidget {
  const EditableAmountDisplay({
    super.key,
    required this.amount,
    this.editHint,
    this.onTap,
  });

  final String amount; // ej. "110.00" (sin el símbolo $)
  final String? editHint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '\$',
                  style: AppTypography.headlineLg(color: AppMd3Colors.primaryContainer),
                ),
              ),
              const SizedBox(width: 6),
              Text(amount, style: AppTypography.displayCurrency(color: AppSemanticColors.slate900)),
            ],
          ),
          if (editHint != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_outlined, size: 14, color: AppSemanticColors.slate400),
                const SizedBox(width: 4),
                Text(editHint!, style: AppTypography.bodySm(color: AppSemanticColors.slate400)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
