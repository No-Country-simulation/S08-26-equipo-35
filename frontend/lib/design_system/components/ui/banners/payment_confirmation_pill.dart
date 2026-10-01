import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Pill centrado de confirmación de pago dentro de una línea de tiempo
/// ("✓ Juan P. paid María G. $50.00 via Bizum · Jul 15"). Distinto de
/// AppTag: este es de ancho completo y siempre representa un evento
/// consumado (color positivo fijo), no un estado seleccionable.
class PaymentConfirmationPill extends StatelessWidget {
  const PaymentConfirmationPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs2),
        decoration: BoxDecoration(
          color: AppSemanticColors.positiveContainer,
          borderRadius: AppRadius.fullRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: AppSemanticColors.positiveText),
            const SizedBox(width: 4),
            Text(text, style: AppTypography.bodySm(color: AppSemanticColors.positiveText)),
          ],
        ),
      ),
    );
  }
}
