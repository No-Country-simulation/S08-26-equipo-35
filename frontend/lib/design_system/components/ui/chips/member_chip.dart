import 'package:flutter/material.dart';
import '../avatars/avatar_stack.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Chip de miembro solo para mostrar (avatar + nombre), sin selección.
/// Distinto de SelectableParticipantChip (que tiene checkbox y estado
/// seleccionado) — este es de solo lectura, para listas tipo "Crew & Friends".
class MemberChip extends StatelessWidget {
  const MemberChip({super.key, required this.avatar, required this.name});

  final AppAvatar avatar;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs2),
      decoration: BoxDecoration(
        color: AppMd3Colors.surfaceContainer,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          const SizedBox(width: AppSpacing.xs),
          Text(name, style: AppTypography.bodyMd(color: AppSemanticColors.slate900)),
        ],
      ),
    );
  }
}
