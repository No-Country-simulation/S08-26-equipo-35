import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_typography.dart';

/// Acción de texto plano sin contenedor, tipo "Cancel"/"Save" en el header
/// de un modal. Distinto de AppButton (que siempre tiene fondo/borde y
/// altura fija de 48px) — este es solo texto tappeable.
class AppTextAction extends StatelessWidget {
  const AppTextAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// true = texto indigo en negrita (ej. "Save"); false = texto slate (ej. "Cancel").
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
      child: Text(
        label,
        style: AppTypography.titleMd(
          color: emphasized ? AppMd3Colors.primaryContainer : AppSemanticColors.slate600,
        ),
      ),
    );
  }
}
