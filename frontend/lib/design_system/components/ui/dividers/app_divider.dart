import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Línea divisoria con texto centrado, ej. "or with email".
class AppDividerWithLabel extends StatelessWidget {
  const AppDividerWithLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppSemanticColors.slate200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            label,
            style: AppTypography.bodySm(color: AppSemanticColors.slate400),
          ),
        ),
        const Expanded(child: Divider(color: AppSemanticColors.slate200)),
      ],
    );
  }
}
