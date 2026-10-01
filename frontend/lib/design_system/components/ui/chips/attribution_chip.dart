import 'package:flutter/material.dart';
import '../avatars/avatar_stack.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Chip compacto de atribución: avatar + "Added by **Alex (You)** · 3 hours
/// ago". Reutilizable para cualquier "quién hizo qué y cuándo" (agregado,
/// editado, comentado...).
class AttributionChip extends StatelessWidget {
  const AttributionChip({
    super.key,
    required this.avatar,
    required this.prefix,
    required this.name,
    required this.timeLabel,
  });

  final AppAvatar avatar;
  final String prefix; // ej. "Added by"
  final String name; // ej. "Alex (You)" — se muestra en negrita
  final String timeLabel; // ej. "3 hours ago"

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
          Text.rich(
            TextSpan(
              style: AppTypography.bodySm(color: AppSemanticColors.slate600),
              children: [
                TextSpan(text: '$prefix '),
                TextSpan(
                  text: name,
                  style: AppTypography.bodySm(color: AppSemanticColors.slate900)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ' · $timeLabel'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
