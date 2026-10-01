import 'package:flutter/material.dart';
import '../avatars/avatar_stack.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Chip seleccionable de participante (checkbox + avatar + nombre), usado
/// en "For whom?" para elegir quién participó de un gasto.
class SelectableParticipantChip extends StatelessWidget {
  const SelectableParticipantChip({
    super.key,
    required this.avatar,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final AppAvatar avatar;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppMd3Colors.surfaceContainerLow : Colors.white,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(
            color: selected ? AppMd3Colors.primaryContainer : AppSemanticColors.slate200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected ? AppMd3Colors.primaryContainer : AppSemanticColors.slate400,
            ),
            const SizedBox(width: AppSpacing.xs),
            avatar,
            const SizedBox(width: AppSpacing.xs),
            Text(name, style: AppTypography.bodyMd(color: AppSemanticColors.slate900)),
          ],
        ),
      ),
    );
  }
}
