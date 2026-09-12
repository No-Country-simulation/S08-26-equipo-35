import 'package:flutter/material.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/banners/app_info_banner.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/buttons/app_text_action.dart';
import '../../design_system/components/ui/cards/app_stat_card.dart';
import '../../design_system/components/ui/cards/expense_list_row.dart';
import '../../design_system/components/ui/chips/app_filter_chip.dart';
import '../../design_system/components/ui/chips/member_chip.dart';
import '../../design_system/components/ui/headers/app_cover_header.dart';
import '../../design_system/components/ui/icon_boxes/app_icon_box.dart';
import '../../design_system/components/ui/row/meta_row.dart';
import '../../design_system/components/ui/titles/app_quick_action_tile.dart';
import '../../design_system/components/ui/titles/app_editable_title.dart';
import '../../design_system/navigations/app_top_bar.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../router/app_router.dart';

/// SOLO MAQUETA — sin lógica de carga de datos, sin navegación real.
/// Todo hardcodeado igual que en la captura de diseño.
class GroupDetails extends StatelessWidget {
  const GroupDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      appBar: AppTopBar(
        title: 'Group Details',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppSemanticColors.slate900),
          onPressed: () {},
        ),
        trailing: const AppAvatar(initials: 'AX', size: 36),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCoverHeader(
              imageUrl: 'https://picsum.photos/seed/barcelona/800/400',
              floatingAction: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: AppSemanticColors.slate900,
                    size: 20,
                  ),
                  onPressed: () {},
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppEditableTitle(
              title: 'Barcelona Summer Trip',
              emoji: '🇪🇸',
              onEdit: () {},
            ),
            const SizedBox(height: 2),
            Text(
              'Created Jul 14 · 4 active travelers',
              style: AppTypography.bodySm(color: AppSemanticColors.slate600),
            ),
            const SizedBox(height: AppSpacing.md),

            AppStatCard(
              label: 'Total group spending',
              value: '\$1,420.00',
              icon: const Icon(
                Icons.receipt_long,
                color: AppMd3Colors.primaryContainer,
                size: 20,
              ),
              iconBackground: AppSemanticColors.slate100,
            ),
            const SizedBox(height: AppSpacing.sm),

            AppInfoBanner(
              icon: const Icon(
                Icons.trending_up,
                color: AppSemanticColors.positiveText,
              ),
              title: 'You are owed \$180.00',
              description: '3 settlements pending',
              background: AppSemanticColors.positiveContainer,
              trailing: AppButton(
                label: 'Settle up',
                expand: false,
                backgroundOverride: const Color(
                  0xFF065F46,
                ), // verde oscuro, no es ninguna variante
                onPressed: () {},
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Crew & Friends',
                  style: AppTypography.titleMd(
                    color: AppSemanticColors.slate900,
                  ),
                ),
                AppTextAction(
                  label: 'SPLIT-BCN-24',
                  emphasized: true,
                  icon: const Icon(
                    Icons.copy,
                    size: 14,
                    color: AppMd3Colors.primaryContainer,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const MemberChip(
                    avatar: AppAvatar(initials: 'A', size: 24),
                    name: 'Alex (You)',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const MemberChip(
                    avatar: AppAvatar(
                      initials: 'M',
                      size: 24,
                      backgroundColor: Color(0xFFEA580C),
                    ),
                    name: 'María G.',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const MemberChip(
                    avatar: AppAvatar(
                      initials: 'J',
                      size: 24,
                      backgroundColor: Color(0xFF0284C7),
                    ),
                    name: 'Juan P.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(
                  child: AppQuickActionTile(
                    icon: const Icon(
                      Icons.link,
                      color: AppMd3Colors.primaryContainer,
                      size: 20,
                    ),
                    iconBackground: AppMd3Colors.surfaceContainer,
                    label: 'Share Link',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppQuickActionTile(
                    icon: const Icon(
                      Icons.account_balance,
                      color: AppSemanticColors.positiveText,
                      size: 20,
                    ),
                    iconBackground: AppSemanticColors.positiveContainer,
                    label: 'Balances',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppQuickActionTile(
                    icon: const Icon(
                      Icons.ios_share,
                      color: AppMd3Colors.primaryContainer,
                      size: 20,
                    ),
                    iconBackground: AppMd3Colors.surfaceContainer,
                    label: 'Summary',
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            SectionHeader(
              title: 'Recent Expenses',
              trailing: Text(
                '14 total',
                style: AppTypography.bodySm(color: AppSemanticColors.slate400),
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
                    label: 'Food & Drink',
                    selected: false,
                    dotColor: const Color(0xFFEA580C),
                    onTap: () {},
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppFilterChip(
                    label: 'Transport',
                    selected: false,
                    dotColor: const Color(0xFF0284C7),
                    onTap: () {},
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppFilterChip(
                    label: 'Stay',
                    selected: false,
                    dotColor: const Color(0xFF7C3AED),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            ExpenseListRow(
              icon: const Icon(
                Icons.restaurant,
                color: Color(0xFFEA580C),
                size: 20,
              ),
              iconBackground: const Color(0xFFFFF7ED),
              title: 'Paella & Sangria at Ca...',
              metaText: 'Paid by You · Split equally',
              timeLabel: 'Today 2:15 PM',
              totalAmountLabel: '\$124.00',
              statusLabel: '+\$93.00 for you',
              status: ExpenseRowStatus.owed,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.expenseDetails),
            ),
            const SizedBox(height: AppSpacing.xs),
            ExpenseListRow(
              icon: const Icon(
                Icons.local_activity,
                color: Color(0xFFCA8A04),
                size: 20,
              ),
              iconBackground: const Color(0xFFFEFCE8),
              title: 'Sagrada Família Tick...',
              metaText: 'Paid by María · Split...',
              timeLabel: 'Yesterday',
              totalAmountLabel: '\$104.00',
              statusLabel: 'You owe \$26.00',
              status: ExpenseRowStatus.owe,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.expenseDetails),
            ),
            const SizedBox(height: AppSpacing.xs),
            ExpenseListRow(
              icon: const Icon(
                Icons.directions_bus,
                color: Color(0xFF0284C7),
                size: 20,
              ),
              iconBackground: const Color(0xFFF0F9FF),
              title: 'Airport Taxi (Aerobus)',
              metaText: 'Paid by Juan · Split...',
              timeLabel: '2 days ago',
              totalAmountLabel: '\$36.00',
              statusLabel: 'You owe \$12.00',
              status: ExpenseRowStatus.owe,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.expenseDetails),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: AppButton(
        label: 'Add expense',
        leadingIcon: const Icon(Icons.add, color: Colors.white, size: 18),
        expand: false,
        onPressed: () {},
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
