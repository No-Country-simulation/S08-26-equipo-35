import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Campo de búsqueda estándar (lupa + placeholder). Distinto de
/// AppTextField (que lleva un label arriba) — este es de una sola línea,
/// sin label, pensado para barras de búsqueda.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.bodyMd(color: AppSemanticColors.slate900),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.bodyMd(color: AppSemanticColors.slate400),
        prefixIcon: const Icon(Icons.search, color: AppSemanticColors.slate400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppSemanticColors.slate200),
        ),
      ),
    );
  }
}
