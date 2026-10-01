import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_typography.dart';

/// Fila compacta ícono + label + valor, sin card ni fondo — para stats
/// inline dentro de otra tarjeta ("📊 Total trip spend  $1,420.00"). Más
/// simple que AppInfoRow (que sí lleva su propio card bordeado).
class StatRow extends StatelessWidget {
  const StatRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTypography.bodyMd(color: AppSemanticColors.slate600)),
        ),
        Text(value, style: AppTypography.titleMd(color: AppSemanticColors.slate900)),
      ],
    );
  }
}
