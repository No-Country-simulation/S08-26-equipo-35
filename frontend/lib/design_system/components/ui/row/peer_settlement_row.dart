import 'package:flutter/material.dart';
import '../avatars/avatar_stack.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Fila compacta de solo lectura para una deuda "entre otros miembros"
/// (no involucra al usuario), sin acciones ni badge de color — ej. "Chloe
/// L. owes María G. — $45.00 — Pending confirmation". Distinto de
/// SettlementCard, que sí tiene acciones y aplica al usuario actual.
class PeerSettlementRow extends StatelessWidget {
  const PeerSettlementRow({
    super.key,
    required this.fromAvatar,
    required this.toAvatar,
    required this.name,
    required this.subtitle,
    required this.amountLabel,
    required this.captionLabel,
    required this.statusLabel,
  });

  final AppAvatar fromAvatar;
  final AppAvatar toAvatar;
  final String name;
  final String subtitle; // ej. "owes María G."
  final String amountLabel;
  final String captionLabel; // ej. "Airbnb city tax"
  final String statusLabel; // ej. "Pending confirmation"

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: [
              fromAvatar,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward, size: 16, color: AppSemanticColors.slate400),
              ),
              toAvatar,
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.titleMd(color: AppSemanticColors.slate900)),
                    Text(subtitle, style: AppTypography.bodySm(color: AppSemanticColors.slate600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(amountLabel, style: AppTypography.amountRow(color: AppSemanticColors.slate900)),
                  Text(captionLabel, style: AppTypography.labelSm(color: AppSemanticColors.slate400)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: AppSemanticColors.slate400),
              const SizedBox(width: 4),
              Text('Between other members', style: AppTypography.bodySm(color: AppSemanticColors.slate400)),
              const Spacer(),
              Text(statusLabel, style: AppTypography.labelSm(color: AppSemanticColors.positiveText)),
            ],
          ),
        ],
      ),
    );
  }
}
