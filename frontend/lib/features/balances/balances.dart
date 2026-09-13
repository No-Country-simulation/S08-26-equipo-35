import 'package:flutter/material.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/badges/balance_badge.dart';
import '../../design_system/components/ui/banners/settlement_cta_card.dart';
import '../../design_system/components/ui/cards/app_balance_hero_card.dart';
import '../../design_system/components/ui/cards/settlement_card.dart';
import '../../design_system/components/ui/cards/transaction_row.dart';
import '../../design_system/components/ui/headers/group_context_bar.dart';
import '../../design_system/components/ui/icon_boxes/app_icon_box.dart';
import '../../design_system/components/ui/progress/linear_progress_track.dart';
import '../../design_system/components/ui/row/meta_row.dart';
import '../../design_system/components/ui/row/peer_settlement_row.dart';
import '../../design_system/components/ui/row/stat_row.dart';
import '../../design_system/components/ui/summaries/calculation_summary_box.dart';
import '../../design_system/components/ui/tags/app_tag.dart';
import '../../design_system/navigations/app_bottom_nav_bar.dart';
import '../../design_system/navigations/app_top_bar.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../router/app_router.dart';

/// SOLO MAQUETA — sin cálculos reales, sin navegación entre tabs, sin
/// lógica de settlement. Todo hardcodeado igual que en la captura.
class Balances extends StatelessWidget {
  const Balances({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      appBar: AppTopBar(
        title: 'Balances',
        leading: const AppIconBox(
          icon: Icon(Icons.call_split, color: Colors.white, size: 18),
          background: AppMd3Colors.primaryContainer,
          size: 32,
          radius: BorderRadius.all(Radius.circular(8)),
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
            GroupContextBar(
              icon: const Icon(
                Icons.card_travel,
                size: 18,
                color: AppMd3Colors.primaryContainer,
              ),
              groupName: 'Barcelona Summer Trip',
              emoji: '🇪🇸',
              memberCountLabel: '4 Members',
              memberAvatars: const [
                AppAvatar(initials: 'A', size: 24),
                AppAvatar(
                  initials: 'M',
                  size: 24,
                  backgroundColor: Color(0xFFEA580C),
                ),
                AppAvatar(
                  initials: 'Y',
                  size: 24,
                  backgroundColor: AppMd3Colors.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            AppBalanceHeroCard(
              statusIcon: const Icon(
                Icons.check_circle,
                size: 14,
                color: AppSemanticColors.positiveText,
              ),
              statusLabel: 'You are owed',
              amount: '+\$180.00',
              background: AppSemanticColors.positiveContainer,
              foreground: AppSemanticColors.positiveText,
              trailingAction: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  color: AppMd3Colors.primaryContainer,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppMd3Colors.surfaceContainer,
                borderRadius: AppRadius.lgRadius,
              ),
              child: Column(
                children: [
                  StatRow(
                    icon: const Icon(
                      Icons.bar_chart,
                      size: 18,
                      color: AppMd3Colors.primaryContainer,
                    ),
                    label: 'Total trip spend',
                    value: '\$1,420.00',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  StatRow(
                    icon: const Icon(
                      Icons.attach_money,
                      size: 18,
                      color: AppSemanticColors.positiveText,
                    ),
                    label: 'You paid',
                    value: '\$540.00',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const LinearProgressTrack(
                    value: 0.38,
                    fillColor: AppSemanticColors.positive,
                  ),
                  const SizedBox(height: AppSpacing.xs2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'You covered 38% of all group costs',
                      style: AppTypography.bodySm(
                        color: AppSemanticColors.slate600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Who owes who (3 direct settlements)',
                    style: AppTypography.headlineSm(
                      color: AppSemanticColors.slate900,
                    ),
                  ),
                ),
                AppTag(label: 'Optimized', uppercase: false),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            SettlementCard(
              fromAvatar: const AppAvatar(initials: 'J', size: 32),
              toAvatar: const AppAvatar(
                initials: 'Y',
                size: 32,
                backgroundColor: AppMd3Colors.primaryContainer,
              ),
              name: 'Juan P.',
              subtitle: 'owes you',
              amountLabel: '+\$110.00',
              status: BalanceBadgeStatus.owed,
              onDetailsTap: () {},
              onRemindTap: () {},
              onRecordPaymentTap: () {},
            ),
            const SizedBox(height: AppSpacing.sm),

            // Detalle expandido de la deuda de Juan P.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.lgRadius,
                boxShadow: AppShadows.level1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EXPENSE BREAKDOWN',
                        style: AppTypography.labelMd(
                          color: AppSemanticColors.slate600,
                        ),
                      ),
                      Text(
                        '4 transactions',
                        style: AppTypography.bodySm(
                          color: AppSemanticColors.slate400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TransactionRow(
                    icon: const Icon(
                      Icons.local_bar,
                      size: 16,
                      color: Color(0xFFEA580C),
                    ),
                    iconBackground: const Color(0xFFFFF7ED),
                    title: 'Tapas Dinner',
                    subtitle: 'You paid \$64.00',
                    amountLabel: '+\$20.00',
                    captionLabel: 'his share',
                    direction: TransactionDirection.credit,
                  ),
                  TransactionRow(
                    icon: const Icon(
                      Icons.restaurant,
                      size: 16,
                      color: Color(0xFFEA580C),
                    ),
                    iconBackground: const Color(0xFFFFF7ED),
                    title: 'Paella & Sangria',
                    subtitle: 'You paid \$124.00',
                    amountLabel: '+\$31.00',
                    captionLabel: 'his share',
                    direction: TransactionDirection.credit,
                  ),
                  TransactionRow(
                    icon: const Icon(
                      Icons.directions_car,
                      size: 16,
                      color: Color(0xFF0284C7),
                    ),
                    iconBackground: const Color(0xFFF0F9FF),
                    title: 'Rental car gas',
                    subtitle: 'You paid \$85.00',
                    amountLabel: '+\$42.50',
                    captionLabel: 'his share',
                    direction: TransactionDirection.credit,
                  ),
                  TransactionRow(
                    icon: const Icon(
                      Icons.local_taxi,
                      size: 16,
                      color: Color(0xFFF9A8D4),
                    ),
                    iconBackground: const Color(0xFFFFF1F2),
                    title: 'Airport Taxi',
                    subtitle: 'Juan paid \$36.00',
                    amountLabel: '-\$12.00',
                    captionLabel: 'your share',
                    direction: TransactionDirection.debit,
                  ),
                  TransactionRow(
                    icon: const Icon(
                      Icons.sync_alt,
                      size: 16,
                      color: AppSemanticColors.positiveText,
                    ),
                    iconBackground: AppSemanticColors.positiveContainer,
                    title: 'Route Rebalance',
                    subtitle: 'Group simplified debt transfer',
                    amountLabel: '+\$28.50',
                    captionLabel: 'rebalanced',
                    direction: TransactionDirection.credit,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const CalculationSummaryBox(
                    subtotalLabel: 'Direct subtotal:',
                    subtotalValue: '\$20 + \$31 + \$42.50 - \$12 = \$81.50',
                    finalLabel: 'Final direct settlement:',
                    finalValue: '+\$110.00',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            SettlementCard(
              fromAvatar: const AppAvatar(
                initials: 'M',
                size: 32,
                backgroundColor: Color(0xFFEA580C),
              ),
              toAvatar: const AppAvatar(
                initials: 'Y',
                size: 32,
                backgroundColor: AppMd3Colors.primaryContainer,
              ),
              name: 'María G.',
              subtitle: 'owes you',
              amountLabel: '+\$70.00',
              status: BalanceBadgeStatus.owed,
              onDetailsTap: () {},
              onRemindTap: () {},
              onRecordPaymentTap: () {},
            ),
            const SizedBox(height: AppSpacing.sm),

            PeerSettlementRow(
              fromAvatar: const AppAvatar(
                initials: 'C',
                size: 32,
                backgroundColor: Color(0xFF7C3AED),
              ),
              toAvatar: const AppAvatar(
                initials: 'M',
                size: 32,
                backgroundColor: Color(0xFFEA580C),
              ),
              name: 'Chloe L.',
              subtitle: 'owes María G.',
              amountLabel: '\$45.00',
              captionLabel: 'Airbnb city tax',
              statusLabel: 'Pending confirmation',
            ),
            const SizedBox(height: AppSpacing.lg),

            SettlementCtaCard(
              icon: const Icon(Icons.bolt, color: Colors.white),
              title: 'Simplified Settlement',
              description: 'Clears all 3 balances in 2 transfers',
              buttonLabel: 'Settle Up All Balances',
              onButtonTap: () {},
              footerText: 'Already paid in cash?',
              footerLinkText: 'Mark manual payment',
              onFooterLinkTap: () {},
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
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
        currentIndex: 2,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }
}

/// Navegación compartida entre tabs — misma lógica que en home.dart y
/// history.dart. Duplicada por ahora en cada pantalla (es una maqueta).
void _onNavTap(BuildContext context, int index) {
  switch (index) {
    case 0:
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      break;
    case 1:
      Navigator.pushReplacementNamed(context, AppRoutes.history);
      break;
    case 2:
      Navigator.pushReplacementNamed(context, AppRoutes.balances);
      break;
    default:
      break; // Profile todavía no existe
  }
}
