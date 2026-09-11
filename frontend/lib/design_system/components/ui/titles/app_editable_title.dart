import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Título + ícono de lápiz para editar. Usado en el nombre del grupo, y
/// reutilizable en cualquier otro título que el usuario pueda renombrar
/// (nombre de perfil, título de un gasto, etc.).
class AppEditableTitle extends StatelessWidget {
  const AppEditableTitle({
    super.key,
    required this.title,
    required this.onEdit,
    this.emoji,
  });

  final String title;
  final String? emoji;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTypography.headlineLg(color: AppSemanticColors.slate900),
              children: [
                TextSpan(text: title),
                if (emoji != null) TextSpan(text: ' $emoji'),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20, color: AppSemanticColors.slate400),
          onPressed: onEdit,
        ),
      ],
    );
  }
}
