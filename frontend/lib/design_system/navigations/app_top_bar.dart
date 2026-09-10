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
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      color: AppMd3Colors.background,
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
