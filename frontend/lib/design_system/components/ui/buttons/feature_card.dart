import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.description,
  });

  final Widget icon;
  final Color iconBackground;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppMd3Colors.surfaceContainerLowest,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.headlineSm(color: AppSemanticColors.slate900),
          ),
          const SizedBox(height: AppSpacing.xs2),
          Text(
            description,
            style: AppTypography.bodySm(color: AppSemanticColors.slate600),
          ),
        ],
      ),
    );
  }
}
