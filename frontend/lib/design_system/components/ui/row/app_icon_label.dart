import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_typography.dart';

/// Ícono + texto en línea, SIN fondo ni padding de pill — para captions
/// simples como "🕐 Today, July 16, 2024 at 2:15 PM". Distinto de AppTag
/// (que siempre lleva un contenedor con color de fondo) y de MetaRow (que
/// lleva fondo + trailing) — este es el más simple de los tres.
class AppIconLabel extends StatelessWidget {
  const AppIconLabel({
    super.key,
    required this.icon,
    required this.text,
    this.color = AppSemanticColors.slate600,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: AppTypography.bodySm(color: color)),
      ],
    );
  }
}
