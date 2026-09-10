import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_tokens.dart';
import '../tokens/app_typography.dart';

class AppBottomNavItem {
  const AppBottomNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Barra de navegación inferior (Groups/Activity/Balances/Profile). Igual
/// que AppTopBar, vive en navigation/ por ser layout de Scaffold, no un
/// átomo de components/ui/.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppSemanticColors.slate200)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i].icon,
                      color: i == currentIndex
                          ? AppMd3Colors.primaryContainer
                          : AppSemanticColors.slate400,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].label,
                      style: AppTypography.labelSm(
                        color: i == currentIndex
                            ? AppMd3Colors.primaryContainer
                            : AppSemanticColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
