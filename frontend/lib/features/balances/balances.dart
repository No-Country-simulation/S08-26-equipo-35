import 'package:flutter/material.dart';
import '../../core/network/api_error_ui.dart';
import '../../core/utils/category_visual.dart';
import '../../core/utils/settlement_status.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/badges/balance_badge.dart';
import '../../design_system/components/ui/banners/app_info_banner.dart';
import '../../design_system/components/ui/banners/settlement_cta_card.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/cards/app_balance_hero_card.dart';
import '../../design_system/components/ui/cards/settlement_card.dart';
import '../../design_system/components/ui/cards/transaction_row.dart';
import '../../design_system/components/ui/headers/group_context_bar.dart';
import '../../design_system/components/ui/icon_boxes/app_icon_box.dart';
import '../../design_system/components/ui/progress/linear_progress_track.dart';
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
import '../auth/data/auth_session.dart';
import '../groups/data/group.dart';
import '../groups/data/group_detail.dart';
import '../groups/data/group_repository.dart';
import '../groups/group_picker_dialog.dart';
import '../mark_payment/mark_payment.dart';

/// Balances de un grupo desde la API:
/// GET /groups/detail/{id}, GET /groups/{id}/settlements (trae balances + debts)
/// y GET /groups/{id}/settlements/status.
///
/// Entrada: `groupId` opcional. Desde Group Details llega el grupo y carga
/// directo; desde el bottom nav (sin grupo) abre el selector
/// [GroupPickerDialog]; si se cancela queda un estado vacío con botón
/// para reabrirlo.
class Balances extends StatefulWidget {
  const Balances({super.key, this.groupId});

  final String? groupId;

  @override
  State<Balances> createState() => _BalancesState();
}

class _BalancesData {
  const _BalancesData({
    required this.detail,
    required this.balances,
    required this.debts,
    required this.settlementStatus,
    this.settlementsError,
  });

  final GroupDetail detail;
  final List<BalanceResponse> balances;
  final List<DebtResponse> debts;
  final GroupSettlementStatus settlementStatus;

  /// Error de /settlements y /settlements/status. Esta pantalla ES
  /// settlements, así que no hay contenido que mostrar igual, pero el grupo
  /// sí se conserva para que el usuario sepa sobre qué grupo falló.
  final Object? settlementsError;

  bool get hasSettlements => settlementsError == null;
}

const List<Color> _avatarPalette = [
  Color(0xFFEA580C),
  AppMd3Colors.primaryContainer,
  Color(0xFF7C3AED),
  Color(0xFF0284C7),
  Color(0xFFCA8A04),
];

class _BalancesState extends State<Balances> {
  String? _groupId;
  Future<_BalancesData>? _future;
  String? _expandedDebtKey;

  @override
  void initState() {
    super.initState();
    _groupId = widget.groupId;
    if (_groupId != null) {
      _future = _load(_groupId!);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPicker());
    }
  }

  /// El grupo se carga aparte de settlements: si solo falla el bloque de
  /// balances, la pantalla igual muestra contra qué grupo es en vez de caer
  /// en un error genérico sin contexto.
  Future<_BalancesData> _load(String groupId) async {
    final detail = await GroupRepository.instance.groupDetail(groupId);

    var balances = <BalanceResponse>[];
    var debts = <DebtResponse>[];
    var settlementStatus = GroupSettlementStatus(
      groupId: groupId,
      isSettled: true,
      pendingCount: 0,
      totalPendingAmount: '0',
      debts: const [],
    );
    Object? settlementsError;

    try {
      final results = await Future.wait([
        GroupRepository.instance.getSettlements(groupId),
        GroupRepository.instance.getSettlementStatus(groupId),
      ]);
      final bundle = results[0] as GroupDebtsBundle;
      balances = bundle.balances;
      debts = bundle.debts;
      settlementStatus = results[1] as GroupSettlementStatus;
    } catch (error) {
      settlementsError = error;
    }

    return _BalancesData(
      detail: detail,
      balances: balances,
      debts: debts,
      settlementStatus: settlementStatus,
      settlementsError: settlementsError,
    );
  }

  void _retry() {
    final groupId = _groupId;
    if (groupId == null) return;
    setState(() => _future = _load(groupId));
  }

  Future<void> _openPicker() async {
    List<Group> groups;
    try {
      groups = await GroupRepository.instance.listGroups();
    } catch (_) {
      // Sin conexión: queda el estado vacío, el botón reintenta.
      return;
    }
    if (!mounted) return;
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No groups yet — create one in Home.')),
      );
      return;
    }
    final groupId = await showDialog<String>(
      context: context,
      builder: (_) => GroupPickerDialog(groups: groups),
    );
    if (groupId == null || !mounted) return;
    setState(() {
      _groupId = groupId;
      _future = _load(groupId);
    });
  }

  String _amount(double value) => '\$${value.toStringAsFixed(2)}';

  /// Abre Mark Payment y, si vuelve con `true` (pago registrado o
  /// confirmado), recarga balances/deudas/estado.
  Future<void> _openMarkPayment(MarkPaymentArgs args) async {
    final refreshed = await Navigator.pushNamed<bool>(
      context,
      AppRoutes.markPayment,
      arguments: args,
    );
    if (refreshed == true && mounted) _retry();
  }

  String _initial(String? name, String userId) {
    if (name != null && name.isNotEmpty) {
      return name.substring(0, 1).toUpperCase();
    }
    return userId.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
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
      body: future == null
          ? _emptyState()
          : FutureBuilder<_BalancesData>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _errorState();
                }
                final data = snapshot.data;
                if (data == null) return _errorState();
                return _content(data);
              },
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select a group to see its balances',
            style: AppTypography.bodyMd(color: AppSemanticColors.slate600),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(label: 'Select group', expand: false, onPressed: _openPicker),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No pudimos cargar los balances.',
            style: AppTypography.bodyMd(color: AppSemanticColors.slate600),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(label: 'Reintentar', expand: false, onPressed: _retry),
        ],
      ),
    );
  }

  Widget _content(_BalancesData data) {
    // Degradado: se conserva el grupo y se explica qué falló, en vez de la
    // pantalla de error genérica que no dice ni sobre qué grupo falló.
    if (!data.hasSettlements) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.detail.groupName,
              style: AppTypography.headlineLg(
                color: AppSemanticColors.slate900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${data.detail.members.length} member'
              '${data.detail.members.length == 1 ? '' : 's'}',
              style: AppTypography.bodySm(
                color: AppSemanticColors.slate600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppInfoBanner(
              icon: const Icon(
                Icons.cloud_off,
                color: AppSemanticColors.slate400,
                size: 20,
              ),
              title: 'Settlements unavailable',
              description:
                  '${apiErrorMessage(data.settlementsError!)} We could not '
                  'load the balances for this group.',
              background: AppSemanticColors.slate100,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Retry',
              expand: false,
              onPressed: _retry,
            ),
          ],
        ),
      );
    }

    final myUserId = AuthSession.instance.userId;
    final status = data.settlementStatus;
    final debts = data.debts;

    BalanceResponse? myBalance;
    if (myUserId != null) {
      for (final b in data.balances) {
        if (b.userId == myUserId) {
          myBalance = b;
          break;
        }
      }
    }

    var totalSpent = 0.0;
    for (final b in data.balances) {
      totalSpent += double.parse(b.paid);
    }
    final myPaid =
        myBalance == null ? 0.0 : double.parse(myBalance.paid);
    final myNet =
        myBalance == null ? 0.0 : double.parse(myBalance.netBalance);
    final ratio = totalSpent > 0 ? (myPaid / totalSpent).clamp(0.0, 1.0) : 0.0;
    final pct = (ratio * 100).round();

    final settled = myBalance == null || myNet.abs() < 0.005;
    final heroLabel = settled
        ? "You're all settled up"
        : (myNet > 0 ? 'You are owed' : 'You owe');
    final heroAmount = settled
        ? _amount(0)
        : (myNet > 0
            ? '+${_amount(myNet)}'
            : '-${_amount(myNet.abs())}');
    final heroPositive = settled || myNet > 0;

    final nameByUserId = {
      for (final b in data.balances) b.userId: b.name,
    };
    final avatars = [
      for (var i = 0; i < data.detail.members.length; i++)
        AppAvatar(
          initials: _initial(
            nameByUserId[data.detail.members[i].userId],
            data.detail.members[i].userId,
          ),
          size: 24,
          backgroundColor: _avatarPalette[i % _avatarPalette.length],
        ),
    ];

    final myDebts = <DebtResponse>[];
    final peerDebts = <DebtResponse>[];
    for (final d in debts) {
      if (d.debtorUserId == myUserId || d.creditorUserId == myUserId) {
        myDebts.add(d);
      } else {
        peerDebts.add(d);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.marginMobile,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GroupContextBar(
            icon: const Icon(
              Icons.groups,
              size: 18,
              color: AppMd3Colors.primaryContainer,
            ),
            groupName: data.detail.groupName,
            memberCountLabel: '${data.detail.members.length} Members',
            memberAvatars: avatars,
          ),
          const SizedBox(height: AppSpacing.md),

          AppBalanceHeroCard(
            statusIcon: Icon(
              heroPositive ? Icons.check_circle : Icons.remove_circle,
              size: 14,
              color: heroPositive
                  ? AppSemanticColors.positiveText
                  : AppSemanticColors.negativeText,
            ),
            statusLabel: heroLabel,
            amount: heroAmount,
            background: heroPositive
                ? AppSemanticColors.positiveContainer
                : AppSemanticColors.negativeContainer,
            foreground: heroPositive
                ? AppSemanticColors.positiveText
                : AppSemanticColors.negativeText,
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
                  label: 'Total group spend',
                  value: _amount(totalSpent),
                ),
                const SizedBox(height: AppSpacing.xs),
                StatRow(
                  icon: const Icon(
                    Icons.attach_money,
                    size: 18,
                    color: AppSemanticColors.positiveText,
                  ),
                  label: 'You paid',
                  value: _amount(myPaid),
                ),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressTrack(
                  value: ratio,
                  fillColor: heroPositive
                      ? AppSemanticColors.positive
                      : AppSemanticColors.negative,
                ),
                const SizedBox(height: AppSpacing.xs2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'You covered $pct% of all group costs',
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
                  'Who owes who (${debts.length} direct '
                  'settlement${debts.length == 1 ? '' : 's'})',
                  style: AppTypography.headlineSm(
                    color: AppSemanticColors.slate900,
                  ),
                ),
              ),
              AppTag(
                label: status.isSettled
                    ? 'Settled'
                    : '${status.pendingCount} pending',
                uppercase: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          if (debts.isEmpty)
            Text(
              'No debts found.',
              style: AppTypography.bodyMd(
                color: AppSemanticColors.slate600,
              ),
            ),
          for (var i = 0; i < myDebts.length; i++) ...[
            _myDebtCard(myDebts[i], myUserId),
            const SizedBox(height: AppSpacing.sm),
          ],
          for (final d in peerDebts) ...[
            PeerSettlementRow(
              fromAvatar: AppAvatar(
                initials: _initial(d.debtorName, d.debtorUserId),
                size: 32,
              ),
              toAvatar: AppAvatar(
                initials: _initial(d.creditorName, d.creditorUserId),
                size: 32,
                backgroundColor: AppMd3Colors.primaryContainer,
              ),
              name: d.debtorName,
              subtitle: 'owes ${d.creditorName}',
              amountLabel: _amount(double.parse(d.amount)),
              captionLabel:
                  d.expenses.isNotEmpty ? d.expenses.first.title : '',
              statusLabel: switch (settlementStatusOf(d.status)) {
                SettlementStatusKind.settled => 'Paid',
                SettlementStatusKind.cancelled => 'Cancelled',
                SettlementStatusKind.pending => 'Pending confirmation',
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (myDebts.isNotEmpty || peerDebts.isNotEmpty)
            const SizedBox(height: AppSpacing.lg),

          if (!status.isSettled && status.pendingCount > 0)
            SettlementCtaCard(
              icon: const Icon(Icons.bolt, color: Colors.white),
              title: 'Simplified Settlement',
              description:
                  '${status.pendingCount} pending settlement'
                  '${status.pendingCount == 1 ? '' : 's'} · '
                  '${_amount(double.parse(status.totalPendingAmount))}',
              buttonLabel: 'Settle Up All Balances',
              onButtonTap: () => _openMarkPayment(
                MarkPaymentArgs(groupId: _groupId ?? ''),
              ),
              footerText: 'Already paid in cash?',
              footerLinkText: 'Mark manual payment',
              onFooterLinkTap: () => _openMarkPayment(
                MarkPaymentArgs(groupId: _groupId ?? ''),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _myDebtCard(DebtResponse d, String? myUserId) {
    final iAmCreditor = d.creditorUserId == myUserId;
    final otherName = iAmCreditor ? d.debtorName : d.creditorName;
    final otherId = iAmCreditor ? d.debtorUserId : d.creditorUserId;
    final amount = double.parse(d.amount);
    final key = '${d.debtorUserId}->${d.creditorUserId}';
    final expanded = _expandedDebtKey == key && d.expenses.isNotEmpty;

    final youAvatar = const AppAvatar(
      initials: 'Y',
      size: 32,
      backgroundColor: AppMd3Colors.primaryContainer,
    );
    final otherAvatar = AppAvatar(
      initials: _initial(otherName, otherId),
      size: 32,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettlementCard(
          fromAvatar: iAmCreditor ? otherAvatar : youAvatar,
          toAvatar: iAmCreditor ? youAvatar : otherAvatar,
          name: otherName,
          subtitle: iAmCreditor ? 'owes you' : 'you owe',
          amountLabel:
              '${iAmCreditor ? '+' : '-'}${_amount(amount)}',
          status: iAmCreditor ? BalanceBadgeStatus.owed : BalanceBadgeStatus.owe,
          onDetailsTap: d.expenses.isEmpty
              ? null
              : () => setState(() {
                    _expandedDebtKey = expanded ? null : key;
                  }),
          onRecordPaymentTap: () {
            final gid = _groupId;
            if (gid == null) return;
            if (iAmCreditor) {
              // Me deben: abrir los pagos pendientes del grupo para
              // confirmar el que ya registró la otra persona.
              _openMarkPayment(
                MarkPaymentArgs(groupId: gid, receiverName: otherName),
              );
            } else {
              // Yo debo: registrar el pago que hice.
              _openMarkPayment(
                MarkPaymentArgs(
                  groupId: gid,
                  receiverUserId: otherId,
                  receiverName: otherName,
                  amount: amount,
                ),
              );
            }
          },
        ),
        if (expanded) ...[
          const SizedBox(height: AppSpacing.sm),
          _debtBreakdown(d, amount),
        ],
      ],
    );
  }

  Widget _debtBreakdown(DebtResponse d, double amount) {
    var subtotal = 0.0;
    for (final e in d.expenses) {
      subtotal += double.parse(e.amount);
    }
    return Container(
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
                '${d.expenses.length} transaction'
                '${d.expenses.length == 1 ? '' : 's'}',
                style: AppTypography.bodySm(
                  color: AppSemanticColors.slate400,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final e in d.expenses)
            TransactionRow(
              icon: Icon(
                categoryVisual(e.expenseCategory).$1,
                size: 16,
                color: categoryVisual(e.expenseCategory).$3,
              ),
              iconBackground: categoryVisual(e.expenseCategory).$2,
              title: e.title,
              subtitle: e.expenseCategory,
              amountLabel: _amount(double.parse(e.amount)),
              captionLabel: 'share',
              direction: TransactionDirection.credit,
            ),
          const SizedBox(height: AppSpacing.xs),
          CalculationSummaryBox(
            subtotalLabel: 'Breakdown subtotal:',
            subtotalValue: _amount(subtotal),
            finalLabel: 'Total settlement:',
            finalValue: _amount(amount),
          ),
        ],
      ),
    );
  }
}

/// Navegación del bottom nav — misma lógica que home/history. Caso 2:
/// si ya estás en Balances no navega (evita reabrir el selector de
/// grupo).
void _onNavTap(BuildContext context, int index) {
  switch (index) {
    case 0:
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      break;
    case 1:
      Navigator.pushReplacementNamed(context, AppRoutes.history);
      break;
    case 2:
      if (ModalRoute.of(context)?.settings.name != AppRoutes.balances) {
        Navigator.pushReplacementNamed(context, AppRoutes.balances);
      }
      break;
    default:
      Navigator.pushReplacementNamed(context, AppRoutes.profile);
      break;
  }
}
