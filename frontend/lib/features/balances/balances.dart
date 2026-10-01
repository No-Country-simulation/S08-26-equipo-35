import 'package:flutter/material.dart';
import '../../core/network/api_error_ui.dart';
import '../../core/utils/category_visual.dart';
import '../../core/utils/settlement_status.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/badges/balance_badge.dart';
import '../../design_system/components/ui/banners/app_info_banner.dart';
import '../../design_system/components/ui/banners/settlement_cta_card.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/buttons/app_text_action.dart';
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
import '../../core/utils/money.dart';
import '../auth/data/auth_session.dart';
import '../balances/data/balance_summary.dart';
import '../groups/data/group.dart';
import '../groups/data/group_detail.dart';
import '../groups/data/group_repository.dart';
import '../groups/group_picker_dialog.dart';
import '../mark_payment/mark_payment.dart';

/// Balances de un grupo desde la API:
/// GET /groups/detail/{id} (nombre y miembros), GET /groups/{id}/settlements
/// (balances + deudas crudas con su desglose) y GET /groups/{id}/balance-summary
/// (totales, contadores y transferencias sugeridas).
///
/// Antes esto pedía `/settlements/status`; `/balance-summary` trae los mismos
/// tres campos (`is_settled`, `pending_count`, `total_pending_amount`) más los
/// totales, así que el status quedó redundante y se dejó de pedir.
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
    required this.summary,
    this.settlementsError,
  });

  final GroupDetail detail;
  final List<BalanceResponse> balances;

  /// Deudas crudas de `/settlements`, con el desglose por gasto.
  ///
  /// Esta lista NO se reemplaza por `summary.suggestedTransfers` aunque
  /// exista: las sugeridas son un set *recalculado y minimizado* por el
  /// backend, y sus entradas son sintéticas — el `expenses` de una sugerida
  /// no corresponde a gastos reales. Acá vive el drill-down por transacción
  /// y las acciones por deuda, y para eso hacen falta las deudas de verdad.
  final List<DebtResponse> debts;

  /// `/balance-summary`: totales del grupo, contadores y transferencias
  /// sugeridas. Reemplaza a `/settlements/status` (trae los mismos tres
  /// campos) y suma lo que el status no traía.
  final GroupBalanceSummary summary;

  final Object? settlementsError;

  bool get hasSettlements => settlementsError == null;

  bool get isSettled => summary.isSettled;
  int get pendingCount => summary.pendingCount;

  /// `double` y no `String` como en `GroupSettlementStatus`: el summary ya
  /// parsea el monto a número en el borde (ver `parseMoney`), así que
  /// envolverlo en `double.parse` otra vez sería redundante.
  double get totalPendingAmount => summary.totalPendingAmount;

  /// Deudas que siguen sin resolverse.
  ///
  /// El conteo de abajo compara contra ÉSTAS y no contra `debts.length`,
  /// porque las deudas ya saldadas o canceladas (`PAID` / `CANCELLED`) no
  /// son transfers que valga la pena simplificar, y contarlas haría
  /// aparecer el bloque de sugerencias sobre un grupo ya cerrado.
  List<DebtResponse> get pendingDebts =>
      debts.where((d) => isPendingStatus(d.status)).toList();

  /// Las transferencias sugeridas sólo se muestran si el backend *realmente*
  /// simplificó: menos transferencias que deudas directas pendientes.
  ///
  /// Sin esta condición, un grupo de 2 personas con 1 deuda dibujaría dos
  /// secciones visualmente idénticas una debajo de la otra — ruido puro. Y en
  /// el caso chico, que es el más común al empezar, no hay nada que
  /// simplificar que valga la pena contarle al usuario.
  List<DebtResponse> get suggestedTransfers {
    if (isSettled) return const [];
    final suggested = summary.suggestedTransfers;
    if (suggested.isEmpty) return const [];
    if (suggested.length >= pendingDebts.length) return const [];
    return suggested;
  }
}

const List<Color> _avatarPalette = [
  Color(0xFFEA580C),
  AppMd3Colors.primaryContainer,
  Color(0xFF7C3AED),
  Color(0xFF0284C7),
  Color(0xFFCA8A04),
];

/// Formatea un monto como `$12.34`.
///
/// Top-level y no método del State porque la usan también los widgets de
/// transferencias sugeridas, que son clases sueltas.
String _amount(double value) => '\$${value.toStringAsFixed(2)}';

/// Inicial para un avatar: la primera letra del nombre, o los dos primeros
/// caracteres del user_id cuando el nombre vino vacío (típico de un miembro
/// recién invitado, que todavía no aparece en `/balances`).
String _initial(String? name, String userId) {
  if (name != null && name.isNotEmpty) {
    return name.substring(0, 1).toUpperCase();
  }
  return userId.substring(0, 2).toUpperCase();
}

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
  ///
  /// `groupDetail` no es redundante con `/balance-summary`: el summary trae
  /// `member_count` pero NO `group_name`, así que el nombre y la lista de
  /// miembros (para los avatares) salen del detail.
  Future<_BalancesData> _load(String groupId) async {
    final detail = await GroupRepository.instance.groupDetail(groupId);

    var balances = <BalanceResponse>[];
    var debts = <DebtResponse>[];
    var summary = _emptySummary(groupId);
    Object? settlementsError;

    try {
      // `/settlements` sigue haciendo falta para las deudas crudas con su
      // desglose por gasto; `/balance-summary` reemplaza a
      // `/settlements/status` y además trae los totales y las sugeridas.
      final results = await Future.wait([
        GroupRepository.instance.getSettlements(groupId),
        GroupRepository.instance.getBalanceSummary(groupId),
      ]);
      final bundle = results[0] as GroupDebtsBundle;
      balances = bundle.balances;
      debts = bundle.debts;
      summary = results[1] as GroupBalanceSummary;
    } catch (error) {
      settlementsError = error;
    }

    return _BalancesData(
      detail: detail,
      balances: balances,
      debts: debts,
      summary: summary,
      settlementsError: settlementsError,
    );
  }

  /// Summary neutro para cuando la llamada falló.
  ///
  /// `isSettled: false` a propósito: con `true` el badge "Settled" quedaría
  /// optimista mientras la pantalla además muestra el aviso de error. Es más
  /// honesto que todavía no se sepa nada.
  static GroupBalanceSummary _emptySummary(String groupId) {
    return GroupBalanceSummary(
      groupId: groupId,
      totalExpenses: 0,
      totalSettledAmount: 0,
      totalPendingAmount: 0,
      pendingCount: 0,
      memberCount: 0,
      isSettled: false,
      balances: const [],
      suggestedTransfers: const [],
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
        const SnackBar(
          content: Text('Aún no hay grupos — crea uno en Inicio.'),
        ),
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

  @override
  Widget build(BuildContext context) {
    final future = _future;
    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      appBar: AppTopBar(
        title: 'Saldos',
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
          AppBottomNavItem(icon: Icons.groups, label: 'Grupos'),
          AppBottomNavItem(icon: Icons.receipt_long, label: 'Actividad'),
          AppBottomNavItem(
            icon: Icons.account_balance_wallet,
            label: 'Saldos',
          ),
          AppBottomNavItem(icon: Icons.person, label: 'Perfil'),
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
            'Elegí un grupo para ver sus saldos',
            style: AppTypography.bodyMd(color: AppSemanticColors.slate600),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(label: 'Elegir grupo', expand: false, onPressed: _openPicker),
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
            'No pudimos cargar los saldos.',
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
              '${data.detail.members.length} miembro'
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
              title: 'Saldos no disponibles',
              description:
                  '${apiErrorMessage(data.settlementsError!)} We could not '
                  'cargar los saldos de este grupo.',
              background: AppSemanticColors.slate100,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Reintentar',
              expand: false,
              onPressed: _retry,
            ),
          ],
        ),
      );
    }

    final myUserId = AuthSession.instance.userId;
    final debts = data.debts;
    final suggested = data.suggestedTransfers;

    BalanceResponse? myBalance;
    if (myUserId != null) {
      for (final b in data.balances) {
        if (b.userId == myUserId) {
          myBalance = b;
          break;
        }
      }
    }

    // El total del grupo viene del servidor (`total_expenses`) y no de sumar
    // los `paid` de cada balance. Deberían dar lo mismo, pero la suma es una
    // reconstrucción: si un miembro falta en `balances` o su `paid` vino
    // malformado, el "you covered X%" se corría en silencio. Con el valor del
    // backend el denominador es lo que el grupo realmente gastó.
    final totalSpent = data.summary.totalExpenses;
    final myPaid = myBalance == null ? 0.0 : parseMoney(myBalance.paid);
    final myNet = myBalance == null ? 0.0 : parseMoney(myBalance.netBalance);
    final ratio = totalSpent > 0 ? (myPaid / totalSpent).clamp(0.0, 1.0) : 0.0;
    final pct = (ratio * 100).round();

    final settled = myBalance == null || myNet.abs() < 0.005;
    final heroLabel = settled
        ? 'Todo saldado'
        : (myNet > 0 ? 'Te deben' : 'Debes');
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
            memberCountLabel: '${data.detail.members.length} miembros',
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
                  label: 'Gasto total del grupo',
                  value: _amount(totalSpent),
                ),
                const SizedBox(height: AppSpacing.xs),
                StatRow(
                  icon: const Icon(
                    Icons.attach_money,
                    size: 18,
                    color: AppSemanticColors.positiveText,
                  ),
                  label: 'Vos pagaste',
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
                    'Cubriste el $pct% de los gastos del grupo',
                    style: AppTypography.bodySm(
                      color: AppSemanticColors.slate600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Transferencias sugeridas. Van ANTES del libro de deudas porque
          // son lo accionable: dicen qué hay que hacer para quedar en cero.
          // El libro queda abajo como material de consulta, con su drill-down
          // de gastos por transacción.
          if (suggested.isNotEmpty) ...[
            _SuggestedTransfersBlock(
              transfers: suggested,
              myUserId: myUserId,
              directDebtCount: data.pendingDebts.length,
              onPayTap: (DebtResponse transfer) {
                final gid = _groupId;
                if (gid == null) return;
                // Sólo yo soy el deudor → abro el flujo de pagos con la otra
                // parte ya precargada. Si me deben a mí, el mismo flujo sirve
                // para confirmar el pago que registró la otra persona.
                _openMarkPayment(
                  MarkPaymentArgs(
                    groupId: gid,
                    receiverName: transfer.debtorName,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Quién le debe a quién (${debts.length} '
                  'liquidación${debts.length == 1 ? '' : 's'} directa${debts.length == 1 ? '' : 's'})',
                  style: AppTypography.headlineSm(
                    color: AppSemanticColors.slate900,
                  ),
                ),
              ),
              AppTag(
                label: data.isSettled
                    ? 'Saldado'
                    : '${data.pendingCount} pending',
                uppercase: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          if (debts.isEmpty)
            Text(
              'No hay deudas.',
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
              subtitle: 'debe ${d.creditorName}',
              amountLabel: _amount(parseMoney(d.amount)),
              captionLabel:
                  d.expenses.isNotEmpty ? d.expenses.first.title : '',
              statusLabel: switch (settlementStatusOf(d.status)) {
                SettlementStatusKind.settled => 'Pagado',
                SettlementStatusKind.cancelled => 'Cancelado',
                SettlementStatusKind.pending => 'Pendiente de confirmación',
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (myDebts.isNotEmpty || peerDebts.isNotEmpty)
            const SizedBox(height: AppSpacing.lg),

          if (!data.isSettled && data.pendingCount > 0)
            SettlementCtaCard(
              icon: const Icon(Icons.bolt, color: Colors.white),
              title: 'Saldo simplificado',
              description:
                  '${data.pendingCount} pending settlement'
                  '${data.pendingCount == 1 ? '' : 's'} · '
                  '${_amount(data.totalPendingAmount)}',
              buttonLabel: 'Saldar todos los balances',
              onButtonTap: () => _openMarkPayment(
                MarkPaymentArgs(groupId: _groupId ?? ''),
              ),
              footerText: '¿Ya pagaste en efectivo?',
              footerLinkText: 'Registrar pago manual',
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
    final amount = parseMoney(d.amount);
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
          subtitle: iAmCreditor ? 'te debe' : 'le debés',
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
      subtotal += parseMoney(e.amount);
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
                'DESGLOSE DE GASTOS',
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
              subtitle: categoryDisplayLabel(e.expenseCategory),
              amountLabel: _amount(parseMoney(e.amount)),
              captionLabel: 'parte',
              direction: TransactionDirection.credit,
            ),
          const SizedBox(height: AppSpacing.xs),
          CalculationSummaryBox(
            subtotalLabel: 'Subtotal del desglose:',
            subtotalValue: _amount(subtotal),
            finalLabel: 'Total a saldar:',
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

/// Bloque "Settle up in N payments": las transferencias ya minimizadas por el
/// backend (`suggested_transfers` de `/balance-summary`).
///
/// Sólo se construye cuando la lista viene no vacía, que es la condición que
/// evalúa `_BalancesData.suggestedTransfers` (o sea, que el backend
/// efectivamente simplificó). Las entradas son `DebtResponse` pero
/// **sintéticas**: su desglose `expenses` no corresponde a gastos reales, así
/// que este bloque muestra montos y partes, nunca el drill-down por
/// transacción. Para eso está el libro de deudas de la pantalla.
///
/// El encabezado contrasta las dos cifras a propósito: sin un "5 direct debts
/// — 2 is enough" el usuario no entiende que está mirando una versión
/// optimizada y cree que le faltan pagos por registrar.
class _SuggestedTransfersBlock extends StatelessWidget {
  const _SuggestedTransfersBlock({
    required this.transfers,
    required this.myUserId,
    required this.directDebtCount,
    required this.onPayTap,
  });

  final List<DebtResponse> transfers;
  final String? myUserId;

  /// Cuántas deudas directas había, para poder mostrar cuánto se ahorra.
  final int directDebtCount;
  final void Function(DebtResponse transfer) onPayTap;

  @override
  Widget build(BuildContext context) {
    final mine = <DebtResponse>[];
    final others = <DebtResponse>[];
    for (final t in transfers) {
      final involvesMe = myUserId != null &&
          (t.debtorUserId == myUserId || t.creditorUserId == myUserId);
      (involvesMe ? mine : others).add(t);
    }

    final saved = directDebtCount - transfers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Saldá en ${transfers.length} '
                'pago${transfers.length == 1 ? '' : 's'}',
                style: AppTypography.headlineSm(
                  color: AppSemanticColors.slate900,
                ),
              ),
            ),
            AppTag(
              label: saved > 0 ? 'ahorra $saved' : 'simplificado',
              background: AppSemanticColors.positiveContainer,
              foreground: AppSemanticColors.positiveText,
              uppercase: false,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          saved > 0
              ? '$directDebtCount deudas directas entre miembros — '
                  '${transfers.length} alcanza para saldar.'
              : 'El conjunto mínimo de pagos para dejar este grupo en cero.',
          style: AppTypography.bodySm(color: AppSemanticColors.slate600),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Las que me involucran van primero y son las únicas accionables.
        for (final t in mine) ...[
          _SuggestedTransferRow(
            transfer: t,
            isMyDebt: t.debtorUserId == myUserId,
            onPayTap: () => onPayTap(t),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],

        if (others.isNotEmpty) ...[
          if (mine.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          Text(
            'Entre otros miembros',
            style: AppTypography.labelMd(color: AppSemanticColors.slate600),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final t in others) ...[
            _SuggestedTransferRow(transfer: t, isMyDebt: false),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ],
    );
  }
}

/// Una fila del bloque de sugeridas: "A → B, $monto" con la acción de
/// registrar el pago cuando me corresponde pagarlo a mí.
class _SuggestedTransferRow extends StatelessWidget {
  const _SuggestedTransferRow({
    required this.transfer,
    required this.isMyDebt,
    this.onPayTap,
  });

  final DebtResponse transfer;

  /// Yo soy quien debe (no quien recibe). Sólo ese caso lleva acción: si me
  /// deben a mí, la acción posible es confirmar, y eso lo hace Mark Payment
  /// igual, así que no se duplica el botón acá.
  final bool isMyDebt;
  final VoidCallback? onPayTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.level1,
      ),
      child: Row(
        children: [
          AppAvatar(
            initials: _initial(transfer.debtorName, transfer.debtorUserId),
            size: 32,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward,
              size: 16,
              color: AppSemanticColors.slate400,
            ),
          ),
          AppAvatar(
            initials: _initial(transfer.creditorName, transfer.creditorUserId),
            size: 32,
            backgroundColor: AppMd3Colors.primaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transfer.debtorName,
                  style: AppTypography.titleMd(
                    color: AppSemanticColors.slate900,
                  ),
                ),
                Text(
                  isMyDebt
                      ? 'le debés ${transfer.creditorName}'
                      : 'debe ${transfer.creditorName}',
                  style: AppTypography.bodySm(
                    color: AppSemanticColors.slate600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _amount(parseMoney(transfer.amount)),
            style: AppTypography.amountRow(color: AppSemanticColors.slate900),
          ),
          if (onPayTap != null) ...[
            const SizedBox(width: AppSpacing.xs),
            AppTextAction(
              label: 'Pagar',
              emphasized: true,
              onPressed: onPayTap,
            ),
          ],
        ],
      ),
    );
  }
}
