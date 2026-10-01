import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_tokens.dart';
import '../tokens/app_typography.dart';

/// Barra superior reutilizable: leading (logo o flecha de volver) + título
/// + trailing (normalmente el avatar del usuario). Un solo widget cubre
/// tanto "Home" (logo) como "Group Details" (back arrow).
///
/// Vive en design_system/navigation/, no en components/ui/, porque es
/// estructura de layout (ocupa un slot fijo de Scaffold), no un átomo de
/// UI que se combine libremente dentro de otras pantallas.
///
/// ## Por qué el inset va en el `build` y no en `preferredSize`
///
/// `Scaffold` mide el **alto realmente renderizado** del appBar y lo usa como
/// `contentTop` del body, así que alcanza con que el `build` devuelva una caja
/// más alta. Además `_appBarMaxHeight` se calcula como
/// `AppBar.preferredHeightFor(...) + MediaQuery.paddingOf(context).top`, o sea
/// que el inset ya está contemplado como techo y por eso `preferredSize`
/// puede seguir siendo el alto del contenido.
///
/// Es el mismo criterio que usa el `AppBar` nativo de Flutter. Sin esto, con
/// `targetSdk >= 35` Android fuerza edge-to-edge y los 56px de la barra
/// arrancan en `y=0`, con el reloj y la batería encima.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.backgroundColor,
  });

  /// Alto del contenido, sin contar el inset de status bar.
  static const double contentHeight = 56;

  final String title;
  final Widget? leading;
  final Widget? trailing;

  /// Fondo de la barra. `null` usa el color de superficie de la app.
  ///
  /// Se hace configurable para las pantallas con cabecera a sangre: si el
  /// `Scaffold` va con `extendBodyBehindAppBar: true`, la imagen queda detrás
  /// de la barra y un fondo opaco la taparía. Pasando
  /// `Colors.transparent` el contenido de la barra se dibuja sobre la foto.
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(contentHeight);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      height: contentHeight + topInset,
      // El inset va como padding interno y no como margen: así el fondo del
      // container se pinta también detrás del reloj, que es el look nativo.
      padding: EdgeInsets.only(
        top: topInset,
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
      ),
      color: backgroundColor ?? AppMd3Colors.background,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.sm)],
          Expanded(
            child: Text(
              title,
              style: AppTypography.headlineSm(color: AppSemanticColors.slate900),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
