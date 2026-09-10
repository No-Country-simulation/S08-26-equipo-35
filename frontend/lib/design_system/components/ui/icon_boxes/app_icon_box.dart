import 'package:flutter/material.dart';
import '../../../tokens/app_tokens.dart';

/// Cuadro con ícono sobre fondo de color — "avatar" de grupo, categoría
/// de gasto, etc. Un solo widget: solo cambian icon/background/size.
class AppIconBox extends StatelessWidget {
  const AppIconBox({
    super.key,
    required this.icon,
    required this.background,
    this.size = 48,
    this.radius,
  });

  final Widget icon;
  final Color background;
  final double size;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius ?? AppRadius.mdRadius,
      ),
      child: Center(child: icon),
    );
  }
}
