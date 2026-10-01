import 'package:flutter/material.dart';
import '../../../tokens/app_tokens.dart';

class ProgressSegment {
  const ProgressSegment({required this.color, required this.fraction});
  final Color color;
  final double fraction; // 0.0 a 1.0, todos los segmentos deberían sumar 1.0
}

/// Barra horizontal dividida en segmentos de color proporcionales — usada
/// bajo "Total split" en el desglose de un gasto, y reutilizable en
/// cualquier otro lugar que muestre proporciones (ej. "cubriste 38% de los
/// gastos del grupo" en Balances).
class SegmentedProgressBar extends StatelessWidget {
  const SegmentedProgressBar({super.key, required this.segments, this.height = 8});

  final List<ProgressSegment> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (final segment in segments)
              Expanded(
                flex: (segment.fraction * 1000).round(),
                child: Container(color: segment.color),
              ),
          ],
        ),
      ),
    );
  }
}
