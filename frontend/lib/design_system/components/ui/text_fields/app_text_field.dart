import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Campo de texto estándar. El borde/radio/focus ya vienen del
/// InputDecorationTheme global (ver app_theme.dart) — este wrapper solo
/// fija la firma que van a usar todas las pantallas: label arriba + ícono
/// prefijo opcional.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.controller,
    this.keyboardType,
    this.onChanged,
  });

  final String label;
  final String? hintText;
  final Widget? prefixIcon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMd(color: AppSemanticColors.slate900),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: AppTypography.bodyLg(color: AppSemanticColors.slate900),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.bodyLg(color: AppSemanticColors.slate400),
            prefixIcon: prefixIcon,
          ),
        ),
      ],
    );
  }
}
