import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Toggle segmentado de ancho completo con 2+ opciones mutuamente
/// excluyentes (ej. "Split equally" / "Custom amounts"). Distinto de
/// AppFilterChip: aquí las opciones ocupan el mismo ancho y solo una
/// puede estar activa, como un switch, no como filtros independientes.
class AppSegmentedToggle extends StatelessWidget {
  const AppSegmentedToggle({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppSemanticColors.slate100,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? Colors.white : Colors.transparent,
                    borderRadius: AppRadius.baseRadius,
                    boxShadow: i == selectedIndex ? AppShadows.level1 : null,
                  ),
                  child: Text(
                    options[i],
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd(
                      color: i == selectedIndex
                          ? AppMd3Colors.primaryContainer
                          : AppSemanticColors.slate600,
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
