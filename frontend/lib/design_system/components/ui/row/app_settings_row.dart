import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Fila de una sola línea: ícono + label + trailing, dentro de una tarjeta
/// bordeada. Distinto de AppInfoRow (que tiene label pequeño + valor grande
/// apilados) — este es para filas simples tipo "Payment Date  |  Today,
/// Jul 16", donde no hay jerarquía label/valor, solo un dato con acción.
class AppSettingsRow extends StatelessWidget {
  const AppSettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final Widget icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: AppSemanticColors.slate200),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(label, style: AppTypography.bodyMd(color: AppSemanticColors.slate900)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
