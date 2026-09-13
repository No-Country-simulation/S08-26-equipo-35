import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_typography.dart';

/// Divisor de sección por fecha dentro de una lista cronológica ("● TODAY
/// — JULY 16" + "$142.50" a la derecha). Reutilizable en cualquier lista
/// agrupada por día (Historial, notificaciones, etc.).
class DateSectionHeader extends StatelessWidget {
  const DateSectionHeader({
    super.key,
    required this.dateLabel,
    this.totalLabel,
    this.dotColor = AppMd3Colors.primaryContainer,
  });

  final String dateLabel; // ej. "TODAY — JULY 16"
  final String? totalLabel; // ej. "$142.50"
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(dateLabel, style: AppTypography.labelMd(color: AppSemanticColors.slate600)),
        ),
        if (totalLabel != null)
          Text(totalLabel!, style: AppTypography.titleMd(color: AppSemanticColors.slate900)),
      ],
    );
  }
}
