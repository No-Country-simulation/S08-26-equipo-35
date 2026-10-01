import 'package:flutter/material.dart';

/// Botón circular con ícono — editar, borrar, ajustes (el gear flotante
/// de la portada en Group Details también encaja acá, aunque ahí se armó
/// a mano con CircleAvatar+IconButton; puedes reemplazarlo por este).
class AppCircleIconButton extends StatelessWidget {
  const AppCircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.background = const Color(0xFFF1F5F9),
    this.iconColor = const Color(0xFF475569),
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color background;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: iconColor, size: size * 0.45),
        onPressed: onPressed,
      ),
    );
  }
}
