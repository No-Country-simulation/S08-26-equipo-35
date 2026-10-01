import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Tarjeta compacta con foto miniatura + título + subtítulo + acción
/// trailing (ej. compartir). Distinto de GroupContextBar (que no lleva
/// foto, solo ícono+avatares) y de AppCoverHeader (que es una foto grande
/// de portada, no una miniatura dentro de una tarjeta).
class TripSummaryCard extends StatelessWidget {
  const TripSummaryCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.emoji,
    this.trailingAction,
  });

  final String imageUrl;
  final String title;
  final String? emoji;
  final String subtitle;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppMd3Colors.surfaceContainerLow,
        borderRadius: AppRadius.lgRadius,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.mdRadius,
            child: Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: AppTypography.titleMd(color: AppSemanticColors.slate900),
                    children: [
                      TextSpan(text: title),
                      if (emoji != null) TextSpan(text: ' $emoji'),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(subtitle, style: AppTypography.bodySm(color: AppSemanticColors.slate600)),
              ],
            ),
          ),
          if (trailingAction != null) trailingAction!,
        ],
      ),
    );
  }
}
