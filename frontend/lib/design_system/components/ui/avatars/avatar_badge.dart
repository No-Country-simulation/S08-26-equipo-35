import 'package:flutter/material.dart';
import 'avatar_stack.dart';
import '../../../tokens/app_colors.dart';

/// Envuelve un AppAvatar con un badge pequeño en la esquina inferior
/// derecha — checkmark de confirmado, iniciales de rol, etc. Distinto de
/// AppAvatarStack (que apila varios avatares); este decora uno solo.
class AvatarBadge extends StatelessWidget {
  const AvatarBadge({
    super.key,
    required this.avatar,
    required this.avatarSize,
    this.icon,
    this.text,
    this.badgeColor = AppSemanticColors.positive,
  });

  final AppAvatar avatar;
  final double avatarSize;
  final IconData? icon;
  final String? text; // ej. "JP" — se ignora si `icon` viene
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final badgeSize = avatarSize * 0.4;

    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, size: badgeSize * 0.6, color: Colors.white)
                    : Text(
                        text ?? '',
                        style: TextStyle(
                          fontSize: badgeSize * 0.45,
                          color: Colors.white,
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
