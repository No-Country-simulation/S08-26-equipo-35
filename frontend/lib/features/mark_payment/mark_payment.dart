import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/settlement_status.dart';
import '../../core/utils/date_format.dart';
import '../../design_system/components/ui/avatars/avatar_badge.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/banners/app_notice_box.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/buttons/app_circle_icon_button.dart';
import '../../design_system/components/ui/buttons/app_text_action.dart';
import '../../design_system/components/ui/cards/editable_amount_display.dart';
import '../../design_system/components/ui/cards/transfer_parties_card.dart';
import '../../design_system/components/ui/chips/app_filter_chip.dart';
import '../../design_system/components/ui/row/app_settings_row.dart';
import '../../design_system/components/ui/row/peer_settlement_row.dart';
import '../../design_system/components/ui/tags/app_tag.dart';
import '../../design_system/components/ui/text_fields/app_text_field.dart';
import '../../design_system/components/ui/titles/app_eyebrow_heading.dart';
import '../../design_system/components/ui/titles/payment_method_tile.dart';
import '../../design_system/components/ui/toggles/app_segmented_toggle.dart';
import '../../design_system/navigations/app_top_bar.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../core/network/api_error_ui.dart';
import '../../router/app_router.dart';
import '../auth/data/auth_session.dart';
import '../groups/data/group_detail.dart';
import '../groups/data/group_repository.dart';

/// Argumentos para abrir Mark Payment. Tres modos según los campos que
/// vengan seteados:
///
///  - **Confirmar**: `settlement` != null → pantalla de confirmación de un
///    pago existente → `PATCH /payments/{id}/pay`.
///  - **Registrar**: `receiverUserId` != null → registrar un pago propio →
///    `POST /groups/{id}/payments`.
///  - **Lista**: solo `groupId` → `GET /groups/{id}/payments` (con filtro de
///    `status` elegido en la UI); los pagos pendientes se tocan para pasar al
///    modo confirmar.
class MarkPaymentArgs {
  const MarkPaymentArgs({
    required this.groupId,
    this.receiverUserId,
    this.receiverName,
    this.amount,
    this.settlement,
    this.payerName,
  });

  final String groupId;

  /// Modo registrar: a quién le pago.
  final String? receiverUserId;
  final String? receiverName;

  /// Modo registrar: monto sugerido (lo que debo según Balances).
  final double? amount;

  /// Modo confirmar: pago pendiente existente.
  final SettlementResponse? settlement;

  /// Nombres ya resueltos (opcionales; si faltan se buscan con GET
  /// /groups/{id}/balances).
  final String? payerName;

  bool get isConfirm => settlement != null;
  bool get isRecord => settlement == null && receiverUserId != null;
}

/// Mark Payment conectado a la API de pagos del grupo:
/// GET /groups/{id}/payments (con filtros de status/payer/receiver/limit/offset),
/// GET /groups/{id}/payments/{sid}, POST /groups/{id}/payments,
/// PATCH /payments/{id}/pay y PATCH /payments/{id}/cancel.
///
/// Al abrir el modo confirmar el pago se refresca contra la API: si otro
/// usuario ya lo confirmó o rechazó, no se deja mandar un cambio que el
/// backend va a rechazar. Métodos de pago, fecha y nota quedan visuales
/// igual que en la maqueta — el backend todavía no los guarda. Tras
/// confirmar, registrar o rechazar vuelve con `true` para que Balances recargue.
class MarkPayment extends StatefulWidget {
  const MarkPayment({super.key, this.args});

  final MarkPaymentArgs? args;

  @override
  State<MarkPayment> createState() => _MarkPaymentState();
}

class _MarkPaymentState extends State<MarkPayment> {
  static const List<(IconData, String, String)> _paymentMethods = [
    (Icons.bolt, 'Bizum', 'Instant transfer'),
    (Icons.payments_outlined, 'Cash', 'In person'),
    (Icons.account_balance, 'Bank', 'Wire transfer'),
    (Icons.credit_card, 'PayPal', 'Venmo / App'),
  ];

  Future<List<SettlementResponse>>? _paymentsFuture;

  /// Nombres id → nombre (GET /balances); ver [_loadNames].
  final Map<String, String> _names = {};
  Future<void>? _namesFuture;

  double _owedAmount = 0;
  double _amount = 0;
  int _amountChip = 0; // 0 full, 1 half, 2 custom
  int _methodIndex = 0;
  int _statusIndex = 1;
  bool _submitting = false;

  /// Filtro de la lista de pagos: 0 = todos (sin `status` en la query),
  /// 1 = PENDING, 2 = PAID, 3 = CANCELLED. Filtra el servidor, no el cliente.
  int _filterIndex = 0;

  /// El pago abierto en modo confirmar, refrescado contra la API. Si deja de
  /// estar PENDING (otro lo confirmó o rechazó) el botón se deshabilita en
  /// vez de mandar un cambio que el backend va a rechazar.
  SettlementResponse? _freshSettlement;
  bool _refreshingSettlement = false;

  /// 404: el pago ya no existe. Distinto de "todavía no lo consulté", que
  /// deja `_freshSettlement` en null pero permite actuar.
  bool _settlementMissing = false;

  @override
  void initState() {
    super.initState();
    final args = widget.args;
    if (args == null) return;
    if (args.isConfirm) {
      _owedAmount = double.tryParse(args.settlement!.amount) ?? 0;
      _amount = _owedAmount;
      if (args.payerName == null || args.receiverName == null) {
        _loadNames(args.groupId);
      }
    } else if (args.isRecord) {
      _owedAmount = args.amount ?? 0;
      _amount = _owedAmount;
    } else {
      _paymentsFuture = _loadPayments(args.groupId);
    }
    if (args.isConfirm) {
      _refreshSettlement(args);
    }
  }

  /// Filtro activo → valor de `status` para la query (null = todos).
  static const List<String?> _statusFilters = [null, 'PENDING', 'PAID', 'CANCELLED'];

  /// Trae el pago fresco antes de mostrar la pantalla de confirmar. La lista
  /// puede tener una copia vieja: si otro usuario ya lo confirmó o rechazó,
  /// mandar el cambio sería un error, así quepreferimos avisar.
  Future<void> _refreshSettlement(MarkPaymentArgs args) async {
    final settlement = args.settlement;
    if (settlement == null) return;
    setState(() => _refreshingSettlement = true);
    try {
      final fresh = await GroupRepository.instance.getPayment(
        args.groupId,
        settlement.settlementId,
      );
      if (!mounted) return;
      setState(() {
        _freshSettlement = fresh;
        _refreshingSettlement = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        // 404 = el pago ya no existe, no se puede actuar sobre él. Otro
        // error = no sabemos su estado real, así que dejamos la copia de
        // la lista y dejamos pasar.
        if (e.statusCode == 404) _settlementMissing = true;
        _refreshingSettlement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _refreshingSettlement = false);
    }
  }

  /// El pago con el que se está trabajando: el refrescado si está, si no el
  /// de la lista.
  SettlementResponse? get _currentSettlement =>
      _freshSettlement ?? widget.args?.settlement;

  /// Solo se puede confirmar/rechazar un pago que sigue PENDING y existe.
  bool get _canAct =>
      !_refreshingSettlement &&
      !_settlementMissing &&
      isPendingStatus(_currentSettlement?.status ?? 'PENDING');

  Future<List<SettlementResponse>> _loadPayments(String groupId) async {
    await _loadNames(groupId);
    // limit 100 = el máximo del schema. El default del backend es 50, que
    // truncaría en silencio; más de 100 pagos pediría paginar con `offset`.
    return GroupRepository.instance.listPayments(
      groupId,
      status: _statusFilters[_filterIndex],
      limit: 100,
    );
  }

  /// Nombres id → nombre desde GET /groups/{id}/balances (la API no tiene
  /// GET /users/{id}); una sola llamada cacheada para lista y confirmación.
  Future<void> _loadNames(String groupId) {
    return _namesFuture ??= _fetchNames(groupId);
  }

  Future<void> _fetchNames(String groupId) async {
    try {
      final balances = await GroupRepository.instance.listBalances(groupId);
      if (!mounted) return;
      setState(() {
        for (final b in balances) {
          _names[b.userId] = b.name;
        }
      });
    } catch (_) {
      // Sin nombres: quedan placeholders ("…" / "Member").
    }
  }

  /// El status de SettlementResponse es string libre en la API. Solo un
  /// pago PENDING se puede confirmar: un PAID ya está saldado y un
  /// CANCELLED fue rechazado (hay que registrar otro, no confirmarlo).
  /// Ver `settlementStatusOf`.
  static bool _isPending(String status) => isPendingStatus(status);

  String _nameOf(String userId) {
    final cached = _names[userId];
    if (cached == null) return '…';
    if (cached.isEmpty) return 'Miembro';
    return cached;
  }

  String? _nameOrNull(String userId) {
    final cached = _names[userId];
    if (cached == null || cached.isEmpty) return null;
    return cached;
  }

  String _initial(String? name, String userId) {
    if (name != null && name.isNotEmpty && name != '…') {
      return name.substring(0, 1).toUpperCase();
    }
    if (userId.isEmpty) return 'U';
    return userId.substring(0, userId.length < 2 ? userId.length : 2).toUpperCase();
  }

  void _retryList() {
    final args = widget.args;
    if (args == null) return;
    setState(() => _paymentsFuture = _loadPayments(args.groupId));
  }

  /// Abre el modo confirmar para un pago pendiente y recarga la lista si
  /// la confirmación/rechazo tuvo éxito.
  Future<void> _openConfirm(MarkPaymentArgs from, SettlementResponse p) async {
    // Refresco antes de abrir: la fila puede estar vieja (otro usuario ya
    // confirmó o rechazó). No abrimos si el pago ya no está pendiente.
    try {
      final fresh = await GroupRepository.instance.getPayment(
        from.groupId,
        p.settlementId,
      );
      if (!mounted) return;
      if (!isPendingStatus(fresh.status)) {
        _notifyStale(fresh);
        _retryList();
        return;
      }
      p = fresh;
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 404) {
        _notifyStale(null);
        _retryList();
        return;
      }
      // Otro error (red/500): seguimos con la fila de la lista.
    } catch (_) {
      // Sin conexión: seguimos con la fila de la lista.
    }

    if (!mounted) return;
    final result = await Navigator.pushNamed<bool>(
      context,
      AppRoutes.markPayment,
      arguments: MarkPaymentArgs(
        groupId: from.groupId,
        settlement: p,
        payerName: _nameOrNull(p.payerUserId),
        receiverName: _nameOrNull(p.receiverUserId),
      ),
    );
    if (result == true && mounted) _retryList();
  }

  void _notifyStale(SettlementResponse? settlement) {
    final label = switch (settlement == null
        ? SettlementStatusKind.cancelled
        : settlementStatusOf(settlement.status)) {
      SettlementStatusKind.settled => 'ya estaba pagado',
      SettlementStatusKind.cancelled => 'fue rechazado',
      SettlementStatusKind.pending => 'ya no está disponible',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Este pago $label.')),
    );
  }

  Future<void> _submit(MarkPaymentArgs args) async {
    setState(() => _submitting = true);
    try {
      if (args.isConfirm) {
        await GroupRepository.instance
            .paySettlement(args.settlement!.settlementId);
      } else {
        await GroupRepository.instance.createPayment(
          groupId: args.groupId,
          receiverUserId: args.receiverUserId!,
          amount: _amount,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            args.isConfirm ? 'Pago confirmado.' : 'Pago registrado.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Rechaza un pago pendiente (PATCH /payments/{id}/cancel). Pide
  /// confirmación porque deshace un pago ya registrado: la deuda vuelve a
  /// existir para el pagador.
  Future<void> _reject(MarkPaymentArgs args) async {
    final settlement = _currentSettlement ?? args.settlement;
    if (settlement == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Rechazar este pago?'),
        content: Text(
          'El pago de \$${(double.tryParse(settlement.amount) ?? 0).toStringAsFixed(2)} '
          'será rechazado y el balance volverá a quedar pendiente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await GroupRepository.instance.cancelSettlement(
        settlement.settlementId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago rechazado.')),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _editCustomAmount() async {
    final controller = TextEditingController(
      text: _amount > 0 ? _amount.toStringAsFixed(2) : '',
    );
    var invalid = false;
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monto personalizado'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: '0.00', prefixText: '\$'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );
              if (v == null || v <= 0) {
                invalid = true;
                Navigator.pop(ctx);
              } else {
                Navigator.pop(ctx, v);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) {
      if (invalid && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escribe un monto válido.')),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _amount = value;
      _amountChip = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      appBar: AppTopBar(
        title: 'Registrar pago',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppSemanticColors.slate900),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: const AppAvatar(initials: 'AX', size: 36),
      ),
      body: args == null
          ? _missingArgs()
          : args.isConfirm
              ? _formView(args)
              : args.isRecord
                  ? _formView(args)
                  : _listView(args),
    );
  }

  Widget _missingArgs() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No se encontraron los datos del pago.',
              style: AppTypography.bodyMd(color: AppSemanticColors.slate600),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Volver',
              expand: false,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Modo lista: GET /groups/{id}/payments
  // ------------------------------------------------------------------

  Widget _listView(MarkPaymentArgs args) {
    final future = _paymentsFuture;
    if (future == null) return _missingArgs();
    return FutureBuilder<List<SettlementResponse>>(
      future: future,
      builder: (context, snapshot) {
        Widget body;
        if (snapshot.connectionState != ConnectionState.done) {
          body = const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          body = _listError();
        } else {
          final payments = snapshot.data ?? const <SettlementResponse>[];
          body = payments.isEmpty
              ? _listEmpty(args)
              : _paymentList(args, payments);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppEyebrowHeading(
                eyebrow: 'Saldos',
                title: 'Pagos',
              ),
              const SizedBox(height: AppSpacing.md),
              _filterRow(args),
              const SizedBox(height: AppSpacing.md),
              body,
            ],
          ),
        );
      },
    );
  }

  /// Filtros All / Pending / Paid / Cancelled. El estado se manda al server
  /// (GET /payments?status=...) en vez de filtrar la lista en cliente.
  Widget _filterRow(MarkPaymentArgs args) {
    const labels = ['Todos', 'Pendientes', 'Pagados', 'Cancelados'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            AppFilterChip(
              label: labels[i],
              selected: _filterIndex == i,
              onTap: () {
                if (_filterIndex == i) return;
                setState(() => _filterIndex = i);
                _retryList();
              },
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }

  Widget _listError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Text(
            'No pudimos cargar los pagos.',
            style: AppTypography.bodyMd(color: AppSemanticColors.slate600),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Reintentar',
            expand: false,
            onPressed: _retryList,
          ),
        ],
      ),
    );
  }

  Widget _listEmpty(MarkPaymentArgs args) {
    final name = args.receiverName;
    final text = name != null
        ? 'Todavía no hay pagos pendientes de $name — aparecerán aquí para '
            'confirmarlos una vez registrados.'
        : 'Este grupo todavía no tiene pagos pendientes. Los pagos que se '
            'registren desde una tarjeta de deuda en Saldos aparecerán aquí.';
    return AppNoticeBox(
      icon: const Icon(
        Icons.info_outline,
        size: 18,
        color: AppSemanticColors.slate600,
      ),
      content: Text(
        text,
        style: AppTypography.bodySm(color: AppSemanticColors.slate600),
      ),
    );
  }

  Widget _paymentList(MarkPaymentArgs args, List<SettlementResponse> payments) {
    final sorted = [...payments]..sort(
        (a, b) => (_isPending(a.status) ? 0 : 1)
            .compareTo(_isPending(b.status) ? 0 : 1),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sorted.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _paymentRow(args, sorted[i]),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _paymentRow(MarkPaymentArgs args, SettlementResponse p) {
    final pending = _isPending(p.status);
    final payerName = _nameOf(p.payerUserId);
    final receiverName = _nameOf(p.receiverUserId);
    final row = PeerSettlementRow(
      fromAvatar: AppAvatar(
        initials: _initial(payerName, p.payerUserId),
        size: 32,
      ),
      toAvatar: AppAvatar(
        initials: _initial(receiverName, p.receiverUserId),
        size: 32,
        backgroundColor: AppMd3Colors.primaryContainer,
      ),
      name: payerName,
      subtitle: 'le pagó $receiverName',
      amountLabel: '\$${(double.tryParse(p.amount) ?? 0).toStringAsFixed(2)}',
      captionLabel: p.settledAt == null ? '' : formatShortDate(p.settledAt!),
      statusLabel: switch (settlementStatusOf(p.status)) {
        SettlementStatusKind.pending => 'Pendiente de confirmación',
        SettlementStatusKind.settled => 'Saldado',
        SettlementStatusKind.cancelled => 'Cancelado',
      },
    );
    if (!pending) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openConfirm(args, p),
      child: row,
    );
  }

  // ------------------------------------------------------------------
  // Modos registrar / confirmar
  // ------------------------------------------------------------------

  Widget _formView(MarkPaymentArgs args) {
    final isConfirm = args.isConfirm;
    final settlement = args.settlement;

    final payerId =
        isConfirm ? settlement!.payerUserId : (AuthSession.instance.userId ?? '');
    final receiverId = isConfirm
        ? settlement!.receiverUserId
        : args.receiverUserId!;
    final payerName = isConfirm
        ? (args.payerName ?? _nameOf(payerId))
        : (AuthSession.instance.userName ?? 'Vos');
    final receiverName = args.receiverName ?? _nameOf(receiverId);

    final remaining = _owedAmount - _amount;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.marginMobile,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: AppEyebrowHeading(
                  eyebrow: 'Saldos',
                  title: 'Saldar el balance',
                ),
              ),
              AppCircleIconButton(
                icon: Icons.close,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          TransferPartiesCard(
            fromAvatar: AvatarBadge(
              avatar: AppAvatar(
                initials: _initial(payerName, payerId),
                size: 64,
                backgroundColor: const Color(0xFFEA580C),
              ),
              avatarSize: 64,
              text: _initial(payerName, payerId),
              badgeColor: AppMd3Colors.primaryContainer,
            ),
            fromName: payerName,
            fromRole: 'Pagador',
            toAvatar: AvatarBadge(
              avatar: AppAvatar(
                initials: _initial(receiverName, receiverId),
                size: 64,
                backgroundColor: AppMd3Colors.primaryContainer,
              ),
              avatarSize: 64,
              icon: Icons.check,
              badgeColor: AppSemanticColors.positive,
            ),
            toName: receiverName,
            toRole: 'Receptor',
            connectorLabel: 'Directo',
          ),
          const SizedBox(height: AppSpacing.sm),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.lgRadius,
              boxShadow: AppShadows.level1,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MONTO DEL SALDO',
                      style: AppTypography.labelMd(
                        color: AppSemanticColors.slate600,
                      ),
                    ),
                    AppTag(
                      label:
                          '${isConfirm ? 'Pendiente' : 'Debido'}: \$${_owedAmount.toStringAsFixed(2)}',
                      background: AppSemanticColors.positiveContainer,
                      foreground: AppSemanticColors.positiveText,
                      uppercase: false,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                EditableAmountDisplay(
                  amount: _amount.toStringAsFixed(2),
                  editHint:
                      isConfirm ? null : 'Tocá para editar el monto',
                  onTap: isConfirm ? null : _editCustomAmount,
                ),
                if (!isConfirm) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppFilterChip(
                          label:
                              'Total (\$${_owedAmount.toStringAsFixed(2)})',
                          selected: _amountChip == 0,
                          onTap: () => setState(() {
                            _amountChip = 0;
                            _amount = _owedAmount;
                          }),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: AppFilterChip(
                          label:
                              'Mitad (\$${(_owedAmount / 2).toStringAsFixed(2)})',
                          selected: _amountChip == 1,
                          onTap: () => setState(() {
                            _amountChip = 1;
                            _amount = double.parse(
                              (_owedAmount / 2).toStringAsFixed(2),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: AppFilterChip(
                          label: 'Otro',
                          selected: _amountChip == 2,
                          onTap: _editCustomAmount,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'MÉTODO DE PAGO',
            style: AppTypography.labelMd(color: AppSemanticColors.slate600),
          ),
          const SizedBox(height: AppSpacing.sm),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.1,
            children: [
              for (var i = 0; i < _paymentMethods.length; i++)
                PaymentMethodTile(
                  icon: _paymentMethods[i].$1,
                  title: _paymentMethods[i].$2,
                  subtitle: _paymentMethods[i].$3,
                  selected: _methodIndex == i,
                  onTap: () => setState(() => _methodIndex = i),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          AppSettingsRow(
            icon: const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppSemanticColors.slate600,
            ),
            label: 'Fecha del pago',
            trailing: AppTag(
              label: 'Hoy, ${formatShortDate(DateTime.now())}',
              background: AppMd3Colors.surfaceContainer,
              foreground: AppMd3Colors.primaryContainer,
              uppercase: false,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppTextField(
            hintText: 'Nota opcional (ej. Enviado por Bizum)',
            prefixIcon: Icon(Icons.notes, color: AppSemanticColors.slate400),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'ESTADO DE CONFIRMACIÓN',
            style: AppTypography.labelMd(color: AppSemanticColors.slate600),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSegmentedToggle(
            options: const ['Pendiente de confirmación', 'Pagado y confirmado'],
            selectedIndex: _statusIndex,
            onChanged: (i) => setState(() => _statusIndex = i),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppNoticeBox(
            icon: const Icon(
              Icons.info_outline,
              size: 18,
              color: AppSemanticColors.positiveText,
            ),
            content: Text.rich(
              TextSpan(
                style: AppTypography.bodySm(color: AppSemanticColors.slate600),
                children: [
                  TextSpan(
                    text: isConfirm
                        ? "Confirming this payment will settle $payerName's balance with you from "
                        : 'Registrar este pago reduce lo que le debés a $receiverName de ',
                  ),
                  TextSpan(
                    text: '\$${_owedAmount.toStringAsFixed(2)}',
                    style: AppTypography.bodySm(
                      color: AppSemanticColors.slate900,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' to '),
                  TextSpan(
                    text:
                        '\$${(remaining > 0 ? remaining : 0).toStringAsFixed(2)}',
                    style: AppTypography.bodySm(
                      color: AppSemanticColors.positiveText,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          AppButton(
            label: isConfirm
                ? 'Confirmar y marcar como pagado (\$${_amount.toStringAsFixed(2)})'
                : 'Registrar pago (\$${_amount.toStringAsFixed(2)})',
            leadingIcon: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 18,
            ),
            isLoading: _submitting,
            onPressed: _submitting || (isConfirm && !_canAct)
                ? null
                : () => _submit(args),
          ),
          // Rechazar es la contra-operación de confirmar: deja el pago
          // CANCELLED y la deuda vuelve a existir. Solo tiene sentido si el
          // pago sigue pendiente.
          if (isConfirm) ...[
            const SizedBox(height: AppSpacing.xs),
            if (!_canAct)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: AppNoticeBox(
                  icon: const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppSemanticColors.slate600,
                  ),
                  content: Text(
                    _settlementMissing
                        ? 'Este pago ya no existe.'
                        : 'Este pago ya no está pendiente, así que no se puede '
                              'confirmado o rechazado.',
                    style: AppTypography.bodySm(
                      color: AppSemanticColors.slate600,
                    ),
                  ),
                ),
              ),
            Center(
              child: AppTextAction(
                label: 'Rechazar este pago',
                destructive: true,
                onPressed: _submitting || !_canAct
                    ? null
                    : () => _reject(args),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
