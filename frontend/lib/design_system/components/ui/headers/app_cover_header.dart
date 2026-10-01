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
    this.borderRadius,
    this.scrim = false,
    this.floatingActionTop = 0,
  });

  final String imageUrl;
  final double height;
  final Widget? floatingAction;

  /// Empuja la acción flotante hacia abajo.
  ///
  /// En una cabecera a sangre la imagen arranca en `y=0`, así que la acción
  /// de la esquina superior derecha queda debajo del reloj y de la barra. Se
  /// pasa el inset + el alto de la barra para dejarla en el lugar de siempre.
  final double floatingActionTop;

  /// Esquinas redondeadas. `null` las redondea todas.
  ///
  /// Para una cabecera **a sangre** (la imagen llega hasta arriba del todo,
  /// detrás del reloj) hay que redondear sólo las de abajo: arriba quedaría un
  /// hueco del color del fondo contra el borde de la pantalla.
  final BorderRadius? borderRadius;

  /// Velo oscuro degradado en la parte superior.
  ///
  /// Necesario cuando la imagen queda detrás de la barra superior: el título
  /// y los íconos se dibujan sobre la foto y sin el velo no hay contraste
  /// garantizado — depende de qué foto haya salido en `picsum`.
  final bool scrim;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: borderRadius ?? AppRadius.lgRadius,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: height,
            ),
          ),
          if (scrim)
            // Se pinta sólo arriba y con alpha decreciente: en la parte baja
            // la foto se ve igual que antes, sin un rectángulo gris encima.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Color(0x00000000)],
                  stops: [0.0, 0.75],
                ),
              ),
            ),
          if (floatingAction != null)
            Positioned(
              top: AppSpacing.sm + floatingActionTop,
              right: AppSpacing.sm,
              child: floatingAction!,
            ),
        ],
      ),
    );
  }
}
