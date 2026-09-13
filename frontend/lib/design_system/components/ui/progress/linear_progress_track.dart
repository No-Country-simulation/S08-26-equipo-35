import 'package:flutter/material.dart';

/// Barra de progreso simple: un track de fondo + un relleno proporcional
/// a `value` (0.0–1.0). Distinto de SegmentedProgressBar (que divide la
/// barra en varios colores que suman 1.0) — esta es para "cubriste 38% de
/// un total", un solo valor contra un fondo neutro.
class LinearProgressTrack extends StatelessWidget {
  const LinearProgressTrack({
    super.key,
    required this.value,
    required this.fillColor,
    this.trackColor = const Color(0xFFE2E8F0),
    this.height = 8,
  });

  final double value; // 0.0 a 1.0
  final Color fillColor;
  final Color trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: trackColor),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(color: fillColor),
            ),
          ],
        ),
      ),
    );
  }
}
