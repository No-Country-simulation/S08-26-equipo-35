import 'package:flutter/material.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/buttons/app_circle_icon_button.dart';
import '../../design_system/components/ui/banners/payment_confirmation_pill.dart';
import '../../design_system/components/ui/cards/activity_expense_card.dart';
import '../../design_system/components/ui/cards/app_stat_card.dart';
import '../../design_system/components/ui/chips/app_dropdown_chip.dart';
import '../../design_system/components/ui/chips/app_filter_chip.dart';
import '../../design_system/components/ui/chips/category_chip.dart';
import '../../design_system/components/ui/headers/trip_summary_card.dart';
import '../../design_system/components/ui/icon_boxes/app_icon_box.dart';
import '../../design_system/components/ui/text_fields/app_search_field.dart';
import '../../design_system/components/ui/row/date_section_header.dart';
import '../../design_system/components/ui/tags/app_tag.dart';
import '../../design_system/navigations/app_bottom_nav_bar.dart';
import '../../design_system/navigations/app_top_bar.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../router/app_router.dart';

/// SOLO MAQUETA — sin búsqueda real, sin filtros funcionales, sin
/// navegación a detalle. Todo hardcodeado igual que en la captura.
class History extends StatelessWidget {
  const History({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      appBar: AppTopBar(
        title: 'History',
        leading: const AppIconBox(
          icon: Icon(Icons.call_split, color: Colors.white, size: 18),
          background: AppMd3Colors.primaryContainer,
          size: 32,
          radius: BorderRadius.all(Radius.circular(8)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: AppSemanticColors.slate600,
              ),
              onPressed: () {},
            ),
            const SizedBox(width: AppSpacing.xs),
            const AppAvatar(initials: 'AX', size: 36),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TripSummaryCard(
              imageUrl: 'https://picsum.photos/seed/barcelona2/200/200',
              title: 'Barcelona Summer Trip',
              emoji: '🇪🇸',
              subtitle: 'July 12 – 19, 2024 · 4 explorers',
              trailingAction: AppCircleIconButton(
                icon: Icons.ios_share,
                onPressed: () {},
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            const AppSearchField(
              hintText: 'Search expenses, participants, notes...',
            ),
            const SizedBox(height: AppSpacing.sm),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppDropdownChip(
                  icon: Icons.calendar_month,
                  label: 'July 2024',
                  onTap: () {},
                ),
                AppDropdownChip(
                  prefixText: 'Sort by: ',
                  label: 'Newest',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  AppFilterChip(
                    label: 'All   14',
                    selected: true,
                    onTap: () {},
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  CategoryChip(
                    category: ExpenseCategory.food,
                    count: 6,
                    selected: false,
                    onTap: () {},
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  CategoryChip(
                    category: ExpenseCategory.transport,
                    count: 3,
                    selected: false,
                    onTap: () {},
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  CategoryChip(
                    category: ExpenseCategory.stay,
                    selected: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

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
                const SizedBox(width: 6),
                Text(
                  '14 expenses recorded',
                  style: AppTypography.bodySm(
                    color: AppSemanticColors.slate600,
                  ),
                ),
                const Spacer(),
                AppTag(
                  label: 'Group balance healthy',
                  background: AppSemanticColors.positiveContainer,
                  foreground: AppSemanticColors.positiveText,
                  uppercase: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppStatCard(
                    label: 'Total spend',
                    value: '\$1,420.00',
                    centered: true,
                    background: AppMd3Colors.surfaceContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppStatCard(
                    label: 'You paid',
                    value: '\$540.00',
                    centered: true,
                    background: AppMd3Colors.surfaceContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            const DateSectionHeader(
              dateLabel: 'TODAY — JULY 16',
              totalLabel: '\$142.50',
            ),
            const SizedBox(height: AppSpacing.sm),
            ActivityExpenseCard(
              icon: const Icon(
                Icons.restaurant,
                color: Color(0xFFEA580C),
                size: 20,
              ),
              iconBackground: const Color(0xFFFFF7ED),
              title: 'Paella & Sangria at Ca...',
              paidByLabel: 'Paid by You',
              timeLabel: '2:15 PM',
              totalAmountLabel: '\$124.00',
              statusLabel: 'You are owed \$94.00',
              status: ActivityStatus.owed,
              footerLeading: 'Split equally (You, María, Juan, Chloe)',
              footerTrailing: 'Receipt attached',
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.xs),
            ActivityExpenseCard(
              icon: const Icon(
                Icons.icecream,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
              iconBackground: const Color(0xFFF5F3FF),
              title: 'Gelato in Gràcia',
              paidByLabel: 'Paid by Chloe',
              timeLabel: '11:30 AM',
              totalAmountLabel: '\$18.50',
              statusLabel: 'You owe \$4.62',
              status: ActivityStatus.owe,
              footerLeading: '4 people · Pistachio & Stracciatella',
              footerTrailing: 'Settled via group card',
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            const PaymentConfirmationPill(
              text: 'Juan P. paid María G. \$50.00 via Bizum · Jul 15',
            ),
            const SizedBox(height: AppSpacing.md),

            const DateSectionHeader(
              dateLabel: 'YESTERDAY — JULY 15',
              totalLabel: '\$152.20',
              dotColor: AppSemanticColors.slate400,
            ),
            const SizedBox(height: AppSpacing.sm),
            ActivityExpenseCard(
              icon: const Icon(
                Icons.local_activity,
                color: Color(0xFFCA8A04),
                size: 20,
              ),
              iconBackground: const Color(0xFFFEFCE8),
              title: 'Sagrada Família Tick...',
              paidByLabel: 'Paid by María',
              timeLabel: '4:00 PM',
              totalAmountLabel: '\$104.00',
              statusLabel: 'You owe \$26.00',
              status: ActivityStatus.owe,
              footerLeading: 'Fast track tower access',
              footerTrailing: '4 e-tickets saved',
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.xs),
            ActivityExpenseCard(
              icon: const Icon(
                Icons.shopping_cart,
                color: Color(0xFF0284C7),
                size: 20,
              ),
              iconBackground: const Color(0xFFF0F9FF),
              title: 'Supermarket M...',
              paidByLabel: 'Paid by You',
              timeLabel: '9:15 AM',
              totalAmountLabel: '\$48.20',
              statusLabel: 'You are owed \$36.15',
              status: ActivityStatus.owed,
              footerLeading: 'Breakfast provisions · Poblenou',
              footerTrailing: 'Auto-categorized',
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.md),

            const DateSectionHeader(
              dateLabel: 'JULY 14',
              totalLabel: '\$96.00',
              dotColor: AppSemanticColors.slate400,
            ),
            const SizedBox(height: AppSpacing.sm),
            ActivityExpenseCard(
              icon: const Icon(
                Icons.local_taxi,
                color: Color(0xFF0284C7),
                size: 20,
              ),
              iconBackground: const Color(0xFFF0F9FF),
              title: 'Airport Taxi (Aerobus)',
              paidByLabel: 'Paid by Juan',
              timeLabel: '8:45 PM',
              totalAmountLabel: '\$36.00',
              statusLabel: 'You owe \$12.00',
              status: ActivityStatus.owe,
              footerLeading: 'BCN Terminal 1 to Eixample',
              footerTrailing: '3 riders',
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.xs),
            ActivityExpenseCard(
              icon: const Icon(
                Icons.vpn_key,
                color: Color(0xFFE11D48),
                size: 20,
              ),
              iconBackground: const Color(0xFFFFF1F2),
              title: 'Airbnb City Tax & K...',
              paidByLabel: 'Paid by María',
              timeLabel: '2:30 PM',
              totalAmountLabel: '\$60.00',
              statusLabel: 'You owe \$15.00',
              status: ActivityStatus.owe,
              footerLeading: 'Tourist tax & late check-in fee',
              footerTrailing: 'Flat rate',
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.lg),

            AppButton(
              label: 'Export CSV / PDF report',
              variant: AppButtonVariant.secondary,
              leadingIcon: const Icon(
                Icons.download,
                color: AppMd3Colors.primaryContainer,
                size: 18,
              ),
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                'Automated expense audit generated with live SplitFlow balances',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm(color: AppSemanticColors.slate400),
              ),
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
        currentIndex: 1,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }
}

/// Navegación compartida entre tabs — misma lógica que se necesita en
/// home.dart y balances.dart para que las 4 pestañas se puedan cambiar
/// entre sí. Duplicada por ahora en cada pantalla (es una maqueta); si
/// agregas más tabs, vale la pena moverla a un solo lugar común.
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
