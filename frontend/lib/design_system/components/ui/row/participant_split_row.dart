import 'package:flutter/material.dart';
import '../avatars/avatar_stack.dart';
import '../tags/app_tag.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Fila de participante en un desglose de reparto YA CALCULADO (solo
/// lectura): avatar + nombre + tag opcional ("Payer") + subtítulo a la
/// izquierda, monto + porcentaje a la derecha. Distinto de
/// ParticipantAmountRow (que tiene un campo de monto EDITABLE) — este es
/// para mostrar un resultado, no para capturarlo.
class ParticipantSplitRow extends StatelessWidget {
  const ParticipantSplitRow({
    super.key,
    required this.avatar,
    required this.name,
    required this.subtitle,
    required this.amountLabel,
    required this.percentageLabel,
    this.tagLabel,
  });

  final AppAvatar avatar;
  final String name;
  final String subtitle;
  final String amountLabel;
  final String percentageLabel;
  final String? tagLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: AppTypography.titleMd(color: AppSemanticColors.slate900)),
                    if (tagLabel != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      AppTag(
                        label: tagLabel!,
                        background: AppMd3Colors.surfaceContainer,
                        foreground: AppMd3Colors.primaryContainer,
                        uppercase: false,
                      ),
                    ],
                  ],
                ),
                Text(subtitle, style: AppTypography.bodySm(color: AppSemanticColors.slate600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amountLabel, style: AppTypography.amountRow(color: AppSemanticColors.slate900)),
              Text(percentageLabel, style: AppTypography.labelSm(color: AppSemanticColors.slate400)),
            ],
          ),
        ],
      ),
    );
  }
}
