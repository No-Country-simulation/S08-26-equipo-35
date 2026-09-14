import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_typography.dart';

/// Caption pequeño en mayúsculas + título grande debajo, ej. "SETTLEMENT"
/// / "Settle Balance". Reutilizable como encabezado de cualquier pantalla
/// modal que necesite ese patrón de "categoría + título".
class AppEyebrowHeading extends StatelessWidget {
  const AppEyebrowHeading({super.key, required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(), style: AppTypography.labelMd(color: AppSemanticColors.slate600)),
        Text(title, style: AppTypography.headlineLg(color: AppSemanticColors.slate900)),
      ],
    );
  }
}
