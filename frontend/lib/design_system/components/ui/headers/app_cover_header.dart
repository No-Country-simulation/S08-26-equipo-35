import 'package:flutter/material.dart';
import '../../../tokens/app_tokens.dart';

/// Imagen de portada con un botón circular flotante arriba a la derecha
/// (ej. el ícono de ajustes de Group Details). Reutilizable para cualquier
/// pantalla con foto de cabecera + acción flotante.
class AppCoverHeader extends StatelessWidget {
  const AppCoverHeader({
    super.key,
    required this.imageUrl,
    this.height = 180,
    this.floatingAction,
  });

  final String imageUrl;
  final double height;
  final Widget? floatingAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: AppRadius.lgRadius,
            child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, height: height),
          ),
          if (floatingAction != null)
            Positioned(top: AppSpacing.sm, right: AppSpacing.sm, child: floatingAction!),
        ],
      ),
    );
  }
}
