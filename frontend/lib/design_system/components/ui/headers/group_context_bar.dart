import 'package:flutter/material.dart';
import '../avatars/avatar_stack.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Barra compacta con el contexto del grupo activo: ícono + nombre + conteo
/// de miembros a la izquierda, avatar stack a la derecha. Usada arriba de
/// Balances, y reutilizable en cualquier pantalla que necesite recordar
/// "en qué grupo estás" sin repetir el header completo de Group Details.
class GroupContextBar extends StatelessWidget {
  const GroupContextBar({
    super.key,
    required this.icon,
    required this.groupName,
    this.emoji,
    required this.memberCountLabel,
    required this.memberAvatars,
  });

  final Widget icon;
  final String groupName;
  final String? emoji;
  final String memberCountLabel; // ej. "4 Members"
  final List<AppAvatar> memberAvatars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppMd3Colors.surfaceContainerLow,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTypography.bodyMd(color: AppSemanticColors.slate900),
                children: [
                  TextSpan(text: groupName),
                  if (emoji != null) TextSpan(text: ' $emoji'),
                  TextSpan(
                    text: ' · $memberCountLabel',
                    style: AppTypography.bodySm(color: AppSemanticColors.slate600),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppAvatarStack(avatars: memberAvatars, size: 24),
        ],
      ),
    );
  }
}
