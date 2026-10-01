import 'package:flutter/material.dart';
import '../badges/balance_badge.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Fila de metadato: ícono + texto + timestamp opcional. Usada en el pie
/// de cada GroupCard ("Last added: Tapas dinner · 2h ago") y reutilizable
/// en Historial/Activity con el mismo patrón.
class MetaRow extends StatelessWidget {
  const MetaRow({
    super.key,
    required this.icon,
    required this.text,
    this.trailingText,
    this.background = AppSemanticColors.slate50,
  });

  final Widget icon;
  final String text;
  final String? trailingText;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.mdRadius),
      child: Row(
        children: [
          icon,
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm(color: AppSemanticColors.slate600),
            ),
          ),
          if (trailingText != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(trailingText!, style: AppTypography.labelSm(color: AppSemanticColors.slate400)),
          ],
        ],
      ),
    );
  }
}

/// Encabezado de sección: título + badge de conteo opcional + acción trailing.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.trailing,
  });

  final String title;
  final int? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTypography.headlineSm(color: AppSemanticColors.slate900)),
        if (count != null) ...[
          const SizedBox(width: AppSpacing.xs),
          AppCountBadge(count: count!),
        ],
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}
