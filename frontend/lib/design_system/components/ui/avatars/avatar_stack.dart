import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_typography.dart';

/// Avatar circular individual, con borde blanco de aislamiento (2px) para
/// cuando se apila con otros dentro de AppAvatarStack.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 32,
    this.backgroundColor = AppMd3Colors.primaryContainer,
  });

  final String? imageUrl;
  final String? initials;
  final double size;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: Colors.white, width: 2),
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null && initials != null
          ? Center(
              child: Text(
                initials!,
                style: AppTypography.labelSm(color: Colors.white),
              ),
            )
          : null,
    );
  }
}

/// Grupo de avatares superpuestos + badge final opcional ("+3k"), como en
/// la tarjeta "Trusted Community".
class AppAvatarStack extends StatelessWidget {
  const AppAvatarStack({
    super.key,
    required this.avatars,
    this.extraCountLabel,
    this.size = 32,
  });

  final List<AppAvatar> avatars;
  final String? extraCountLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final overlap = size * 0.3;
    final extraCount = extraCountLabel;
    final itemCount = avatars.length + (extraCount != null ? 1 : 0);

    return SizedBox(
      height: size,
      width: size + (itemCount - 1) * (size - overlap),
      child: Stack(
        children: [
          for (var i = 0; i < avatars.length; i++)
            Positioned(left: i * (size - overlap), child: avatars[i]),
          if (extraCount != null)
            Positioned(
              left: avatars.length * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppSemanticColors.slate100,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    extraCount,
                    style: AppTypography.labelSm(
                      color: AppSemanticColors.slate600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
