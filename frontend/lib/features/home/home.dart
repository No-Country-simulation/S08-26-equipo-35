import 'package:flutter/material.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/badges/balance_badge.dart';
import '../../design_system/components/ui/banners/app_info_banner.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/cards/group_card.dart';
import '../../design_system/components/ui/chips/app_filter_chip.dart';
import '../../design_system/components/ui/icon_boxes/app_icon_box.dart';
import '../../design_system/components/ui/row/meta_row.dart';
import '../../design_system/navigations/app_bottom_nav_bar.dart';
import '../../design_system/navigations/app_top_bar.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';

/// SOLO MAQUETA — sin controllers, sin onTap reales, sin navegación.
/// Todos los datos están hardcodeados igual que en la captura de diseño.
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      appBar: AppTopBar(
        title: 'Home',
        leading: const AppIconBox(
          icon: Icon(Icons.call_split, color: Colors.white, size: 18),
          background: AppMd3Colors.primaryContainer,
          size: 32,
          radius: BorderRadius.all(Radius.circular(8)),
        ),
        trailing: const AppAvatar(initials: 'AX', size: 36),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMobile,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryCard(),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(
                  title: 'Active Groups',
                  count: 3,
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.swap_vert,
                      color: AppMd3Colors.primaryContainer,
                    ),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AppFilterChip(label: 'All', selected: true, onTap: () {}),
                      const SizedBox(width: AppSpacing.xs),
                      AppFilterChip(
                        label: 'Trips',
                        selected: false,
                        onTap: () {},
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AppFilterChip(
                        label: 'Apartment',
                        selected: false,
                        onTap: () {},
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AppFilterChip(
                        label: 'Social',
                        selected: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                GroupCard(
                  icon: const Icon(
                    Icons.card_travel,
                    color: AppMd3Colors.primaryContainer,
                  ),
                  iconBackground: AppMd3Colors.surfaceContainer,
                  title: 'Barcelona Summer Trip',
                  emoji: '🇪🇸',
                  memberAvatars: const [
                    AppAvatar(
                      initials: 'A',
                      backgroundColor: Color(0xFFEA580C),
                    ),
                    AppAvatar(
                      initials: 'B',
                      backgroundColor: Color(0xFF7C3AED),
                    ),
                    AppAvatar(
                      initials: 'C',
                      backgroundColor: AppMd3Colors.primaryContainer,
                    ),
                  ],
                  memberCountLabel: '4 members',
                  balanceAmountLabel: '+\$180.00',
                  balanceStatus: BalanceBadgeStatus.owed,
                  balanceCaption: 'you are owed',
                  metaIcon: const Icon(
                    Icons.restaurant,
                    size: 16,
                    color: AppSemanticColors.slate400,
                  ),
                  metaText: 'Last added: Tapas dinner (\$64.00)',
                  metaTrailingText: '2h ago',
                ),
                const SizedBox(height: AppSpacing.sm),
                GroupCard(
                  icon: const Icon(
                    Icons.home,
                    color: AppMd3Colors.primaryContainer,
                  ),
                  iconBackground: AppMd3Colors.surfaceContainer,
                  title: 'Oak Street Apt 4B',
                  emoji: '🏠',
                  memberAvatars: const [
                    AppAvatar(
                      initials: 'D',
                      backgroundColor: Color(0xFF0284C7),
                    ),
                    AppAvatar(
                      initials: 'E',
                      backgroundColor: Color(0xFFCA8A04),
                    ),
                  ],
                  memberCountLabel: '3 roommates',
                  balanceAmountLabel: '-\$42.50',
                  balanceStatus: BalanceBadgeStatus.owe,
                  balanceCaption: 'you owe',
                  metaIcon: const Icon(
                    Icons.bolt,
                    size: 16,
                    color: AppSemanticColors.slate400,
                  ),
                  metaText: 'Last added: Wi-Fi & Electricity',
                  metaTrailingText: 'Yesterday',
                ),
                const SizedBox(height: AppSpacing.sm),
                GroupCard(
                  icon: const Icon(
                    Icons.forest,
                    color: AppMd3Colors.primaryContainer,
                  ),
                  iconBackground: AppMd3Colors.surfaceContainer,
                  title: 'Weekend Camping & BBQ',
                  emoji: '🌲',
                  memberAvatars: const [
                    AppAvatar(
                      initials: 'F',
                      backgroundColor: Color(0xFF006C49),
                    ),
                    AppAvatar(
                      initials: 'G',
                      backgroundColor: Color(0xFFEA580C),
                    ),
                    AppAvatar(
                      initials: 'H',
                      backgroundColor: AppMd3Colors.primaryContainer,
                    ),
                  ],
                  memberCountLabel: '6 friends',
                  balanceAmountLabel: '\$0.00',
                  balanceStatus: BalanceBadgeStatus.settled,
                  balanceCaption: 'settled',
                  metaIcon: const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppSemanticColors.positive,
                  ),
                  metaText: 'All payments settled',
                  metaTrailingText: '3d ago',
                ),
                const SizedBox(height: AppSpacing.lg),
                AppInfoBanner(
                  icon: const Icon(
                    Icons.celebration,
                    color: AppMd3Colors.primaryContainer,
                  ),
                  title: "You're in good shape!",
                  description: 'No urgent settlements pending today.',
                ),
                // Espacio para que el botón flotante no tape la última tarjeta.
                const SizedBox(height: 80),
              ],
            ),
          ),
          Positioned(
            right: AppSpacing.marginMobile,
            bottom: AppSpacing.md,
            child: AppButton(
              label: 'Add Expense',
              leadingIcon: const Icon(Icons.add, color: Colors.white, size: 18),
              expand: false,
              onPressed: () {},
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        items: const [
          AppBottomNavItem(icon: Icons.groups, label: 'Groups'),
          AppBottomNavItem(icon: Icons.receipt_long, label: 'Activity'),
          AppBottomNavItem(
            icon: Icons.account_balance_wallet,
            label: 'Balances',
          ),
          AppBottomNavItem(icon: Icons.person, label: 'Profile'),
        ],
        currentIndex: 0,
        onTap: (_) {},
      ),
    );
  }
}

/// Tarjeta de resumen superior. Se queda como widget privado de Home: solo
/// se usa una vez en toda la app, no amerita ser un componente del design
/// system todavía.
class _SummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppSemanticColors.positiveContainer,
        borderRadius: AppRadius.xlRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // No usamos AppTag aquí: AppTag pone el texto en mayúsculas
                // (pensado para eyebrows tipo "EFFORTLESS GROUP MATH"), y
                // este texto necesita su casing normal.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: AppRadius.fullRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_downward,
                        size: 14,
                        color: AppSemanticColors.positiveText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Overall, you are owed',
                        style: AppTypography.bodySm(
                          color: AppSemanticColors.positiveText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '\$145.50',
                  style: AppTypography.displayCurrency(
                    color: AppSemanticColors.slate900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppSemanticColors.positive,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs2),
                    Text(
                      'Across 3 active groups',
                      style: AppTypography.bodySm(
                        color: AppSemanticColors.slate600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const _NewGroupAction(),
        ],
      ),
    );
  }
}

/// Botón "+ New Group". También privado de Home — geometría única
/// (círculo + label debajo), no se repite en ninguna otra pantalla vista.
class _NewGroupAction extends StatelessWidget {
  const _NewGroupAction();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: AppRadius.lgRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppMd3Colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs2),
          Text(
            'New Group',
            style: AppTypography.labelMd(color: AppSemanticColors.slate900),
          ),
        ],
      ),
    );
  }
}
