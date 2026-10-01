import 'package:flutter/material.dart';
import '../avatars/avatar_stack.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Fila genérica: leading (ícono o avatar) + label pequeño arriba + valor
/// destacado abajo + trailing libre. Cubre "Description" (leading=ícono,
/// trailing=botón cerrar) y "Paid by" (leading=avatar, trailing=tag+chevron)
/// con el mismo widget.
class AppInfoRow extends StatelessWidget {
  const AppInfoRow({
    super.key,
    required this.leading,
    required this.label,
    required this.value,
    this.trailing,
  });

  final Widget leading;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppSemanticColors.slate200),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodySm(color: AppSemanticColors.slate600)),
                Text(value, style: AppTypography.titleMd(color: AppSemanticColors.slate900)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Fila de participante con monto editable (usada en "Custom amounts"):
/// avatar + nombre + subtítulo a la izquierda, campo de monto a la derecha.
class ParticipantAmountRow extends StatelessWidget {
  const ParticipantAmountRow({
    super.key,
    required this.avatar,
    required this.name,
    required this.subtitle,
    required this.amountController,
  });

  final AppAvatar avatar;
  final String name;
  final String subtitle;
  final TextEditingController amountController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppSemanticColors.slate50,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.bodyMd(color: AppSemanticColors.slate900)),
                Text(subtitle, style: AppTypography.bodySm(color: AppSemanticColors.slate600)),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: TextField(
              controller: amountController,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.amountRow(color: AppSemanticColors.slate900),
              decoration: const InputDecoration(
                prefixText: '\$',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
