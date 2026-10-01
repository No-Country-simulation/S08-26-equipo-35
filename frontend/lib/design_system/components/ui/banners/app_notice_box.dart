import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';

/// Aviso simple: ícono + texto (plano o enriquecido con negritas), sin
/// título ni ícono circular de fondo. Más liviano que AppInfoBanner (que
/// siempre lleva título + círculo de color) — para notas informativas
/// cortas tipo "Recording this payment will adjust Juan's balance...".
class AppNoticeBox extends StatelessWidget {
  const AppNoticeBox({
    super.key,
    required this.icon,
    required this.content,
    this.background = AppMd3Colors.surfaceContainerLow,
  });

  final Widget icon;
  final Widget content; // normalmente un Text.rich con spans en negrita
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.mdRadius),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: content),
        ],
      ),
    );
  }
}
