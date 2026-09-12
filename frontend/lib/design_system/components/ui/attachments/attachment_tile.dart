import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Tile de adjunto (recibo/foto). Dos estados con el mismo widget: si
/// `imageUrl` viene, muestra la foto + caption abajo ("Receipt #408"); si
/// no, muestra el placeholder de "agregar" (ícono + título + subtítulo).
class AttachmentTile extends StatelessWidget {
  const AttachmentTile({
    super.key,
    this.imageUrl,
    this.caption,
    this.addTitle = 'Add Photo',
    this.addSubtitle,
    required this.onTap,
  });

  final String? imageUrl;
  final String? caption; // ej. "Receipt #408" — solo aplica si hay imageUrl
  final String addTitle;
  final String? addSubtitle; // ej. "Card slip or item"
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: hasImage ? null : AppMd3Colors.surfaceContainer,
            borderRadius: AppRadius.lgRadius,
            image: hasImage
                ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: hasImage
              ? Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    margin: const EdgeInsets.all(AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: AppRadius.baseRadius,
                    ),
                    child: Text(
                      caption ?? '',
                      style: AppTypography.labelSm(color: Colors.white),
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, color: AppMd3Colors.primaryContainer),
                      const SizedBox(height: AppSpacing.xs2),
                      Text(addTitle, style: AppTypography.bodyMd(color: AppSemanticColors.slate900)),
                      if (addSubtitle != null)
                        Text(addSubtitle!, style: AppTypography.bodySm(color: AppSemanticColors.slate600)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
