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
import '../../router/app_router.dart';
import '../auth/data/auth_session.dart';
import '../expenses/data/expense.dart';
import '../expenses/data/expense_repository.dart';
import '../groups/data/group.dart';
import '../groups/data/group_detail.dart';
import '../groups/data/group_repository.dart';
import '../groups/domain/balance_calculator.dart';

/// Resumen ya calculado de un grupo: el grupo en sí + cuántos miembros
/// tiene + el balance neto del usuario + el último gasto agregado.
class _GroupSummary {
  const _GroupSummary({
    required this.group,
    required this.memberCount,
    required this.netBalance,
    this.lastExpense,
  });

  final Group group;
  final int memberCount;

  /// null = no se pudo calcular (ej. no hay userId de sesión disponible) —
  /// distinto de 0, que significa "saldado de verdad".
  final double? netBalance;
  final Expense? lastExpense;
}

class _HomeData {
  const _HomeData({required this.groups, required this.overallNet});
  final List<_GroupSummary> groups;
  final double? overallNet;
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<_HomeData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadHomeData();
  }

  void _retry() {
    setState(() {
      _dataFuture = _loadHomeData();
    });
  }

  /// Trae los grupos y, para cada uno, su detalle (miembros) y sus gastos,
  /// y calcula el balance. Se hace secuencial (grupo por grupo) en vez de
  /// todo en paralelo para no saturar de golpe un backend gratuito de
  /// Render — si tu API aguanta más carga, se puede paralelizar con
  /// Future.wait sobre la lista completa de grupos.
  Future<_HomeData> _loadHomeData() async {
    final groups = await GroupRepository.instance.listGroups();
    final myUserId = AuthSession.instance.userId;

    final summaries = <_GroupSummary>[];
    double? overall = myUserId == null ? null : 0;

    for (final group in groups) {
      final results = await Future.wait([
        GroupRepository.instance.groupDetail(group.groupId),
        ExpenseRepository.instance.listGroupExpenses(group.groupId),
      ]);
      final detail = results[0] as GroupDetail;
      final expenses = results[1] as List<Expense>;

      double? net;
      if (myUserId != null) {
        net = calculateNetBalance(
          expenses: expenses,
          myUserId: myUserId,
          memberCount: detail.members.length,
        );
        overall = (overall ?? 0) + net;
      }

      Expense? last;
      for (final e in expenses) {
        if (last == null || e.createdAt.isAfter(last.createdAt)) last = e;
      }

      summaries.add(
        _GroupSummary(
          group: group,
          memberCount: detail.members.length,
          netBalance: net,
          lastExpense: last,
        ),
      );
    }

    return _HomeData(groups: summaries, overallNet: overall);
  }

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
            child: FutureBuilder<_HomeData>(
              future: _dataFuture,
              builder: (context, snapshot) {
                final loading =
                    snapshot.connectionState != ConnectionState.done;
                final hasError = snapshot.hasError;
                final data = snapshot.data;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryCard(
                      isLoading: loading,
                      overallNet: data?.overallNet,
                      groupCount: data?.groups.length,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          AppFilterChip(
                            label: 'All',
                            selected: true,
                            onTap: () {},
                          ),
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
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl2),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (hasError)
                      _ErrorState(onRetry: _retry)
                    else if (data == null || data.groups.isEmpty)
                      const _EmptyState()
                    else ...[
                      SectionHeader(
                        title: 'Active Groups',
                        count: data.groups.length,
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.swap_vert,
                            color: AppMd3Colors.primaryContainer,
                          ),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final summary in data.groups) ...[
                        _buildGroupCard(context, summary),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppInfoBanner(
                      icon: const Icon(
                        Icons.celebration,
                        color: AppMd3Colors.primaryContainer,
                      ),
                      title: "You're in good shape!",
                      description: 'No urgent settlements pending today.',
                    ),
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
          ),
          Positioned(
            right: AppSpacing.marginMobile,
            bottom: AppSpacing.md,
            child: AppButton(
              label: 'Add Expense',
              leadingIcon: const Icon(Icons.add, color: Colors.white, size: 18),
              expand: false,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.logExpense),
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
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, _GroupSummary summary) {
    final net = summary.netBalance;
    final BalanceBadgeStatus status;
    final String amountLabel;
    final String? caption;

    if (net == null) {
      status = BalanceBadgeStatus.unknown;
      amountLabel = '—';
      caption = null;
    } else if (net > 0.005) {
      status = BalanceBadgeStatus.owed;
      amountLabel = '+\$${net.toStringAsFixed(2)}';
      caption = 'you are owed';
    } else if (net < -0.005) {
      status = BalanceBadgeStatus.owe;
      amountLabel = '-\$${net.abs().toStringAsFixed(2)}';
      caption = 'you owe';
    } else {
      status = BalanceBadgeStatus.settled;
      amountLabel = '\$0.00';
      caption = 'settled';
    }

    final metaText = summary.lastExpense != null
        ? 'Last added: ${summary.lastExpense!.title} (\$${summary.lastExpense!.totalAmount.toStringAsFixed(2)})'
        : 'No expenses yet';

    return GroupCard(
      // Ícono genérico: la API no tiene campo de ícono/color por grupo.
      icon: const Icon(Icons.groups, color: AppMd3Colors.primaryContainer),
      iconBackground: AppMd3Colors.surfaceContainer,
      title: summary.group.groupName,
      memberAvatars:
          const [], // sin fotos/nombres: no hay endpoint de usuarios por id
      memberCountLabel:
          '${summary.memberCount} member${summary.memberCount == 1 ? '' : 's'}',
      balanceAmountLabel: amountLabel,
      balanceStatus: status,
      balanceCaption: caption,
      metaIcon: const Icon(
        Icons.receipt_long,
        size: 16,
        color: AppSemanticColors.slate400,
      ),
      metaText: metaText,
      onTap: () => Navigator.pushNamed(context, AppRoutes.groupDetails),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppSemanticColors.negativeText,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No pudimos cargar tus grupos.',
            style: AppTypography.bodyMd(color: AppSemanticColors.slate600),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(label: 'Reintentar', expand: false, onPressed: onRetry),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
            Icons.groups_outlined,
            color: AppSemanticColors.slate400,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Todavía no tienes grupos. Crea el primero para empezar.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd(color: AppSemanticColors.slate600),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de resumen superior. Muestra "—" mientras carga; una vez que
/// `overallNet` llega, ya es el balance real sumado de todos los grupos.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.isLoading,
    this.overallNet,
    this.groupCount,
  });

  final bool isLoading;
  final double? overallNet;
  final int? groupCount;

  @override
  Widget build(BuildContext context) {
    final bool unknown = !isLoading && overallNet == null;
    final net = overallNet ?? 0;
    final isOwed = net >= 0;
    final amountLabel = (isLoading || unknown)
        ? '—'
        : '${isOwed ? '+' : '-'}\$${net.abs().toStringAsFixed(2)}';
    final statusLabel = unknown
        ? 'Overall balance'
        : (isOwed ? 'Overall, you are owed' : 'Overall, you owe');
    final countLabel = groupCount == null
        ? 'Across your active groups'
        : 'Across $groupCount active group${groupCount == 1 ? '' : 's'}';

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
                      Icon(
                        isOwed ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 14,
                        color: AppSemanticColors.positiveText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: AppTypography.bodySm(
                          color: AppSemanticColors.positiveText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  amountLabel,
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
                      countLabel,
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
