import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/date_format.dart';
import '../../design_system/components/ui/avatars/avatar_badge.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/banners/app_notice_box.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/buttons/app_circle_icon_button.dart';
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
///  - **Lista**: solo `groupId` → `GET /groups/{id}/payments`; los pagos
///    pendientes se tocan para pasar al modo confirmar.
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
/// GET /groups/{id}/payments, POST /groups/{id}/payments y
/// PATCH /payments/{id}/pay.
///
/// Métodos de pago, fecha y nota quedan visuales igual que en la maqueta —
/// el backend todavía no los guarda. Tras confirmar o registrar vuelve con
/// `true` para que Balances recargue.
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
  }

  Future<List<SettlementResponse>> _loadPayments(String groupId) async {
    await _loadNames(groupId);
    return GroupRepository.instance.listPayments(groupId);
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

  /// El status de SettlementResponse es string libre en la API; se asume
  /// "settled"/"PAID" = confirmado (cualquier case), resto = pendiente.
  static bool _isPending(String status) {
    final s = status.toLowerCase();
    return s != 'settled' && s != 'paid';
  }

  String _nameOf(String userId) {
    final cached = _names[userId];
    if (cached == null) return '…';
    if (cached.isEmpty) return 'Member';
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
  /// la confirmación tuvo éxito.
  Future<void> _openConfirm(MarkPaymentArgs from, SettlementResponse p) async {
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
            args.isConfirm ? 'Payment confirmed.' : 'Payment recorded.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo conectar con el servidor.')),
      );
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
        title: const Text('Custom amount'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: '0.00', prefixText: '\$'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
          const SnackBar(content: Text('Enter a valid amount.')),
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
        title: 'Mark Payment',
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
              'Payment details not found.',
              style: AppTypography.bodyMd(color: AppSemanticColors.slate600),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Go back',
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
                eyebrow: 'Settlement',
                title: 'Pending Payments',
              ),
              const SizedBox(height: AppSpacing.md),
              body,
            ],
          ),
        );
      },
    );
  }

  Widget _listError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Text(
            'Could not load payments.',
            style: AppTypography.bodyMd(color: AppSemanticColors.slate600),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Retry',
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
        ? 'No pending payment from $name yet — it will appear here for '
            'confirmation once it is recorded.'
        : 'No pending payments in this group yet. Payments recorded from '
            'a debt card in Balances will appear here.';
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
      subtitle: 'paid $receiverName',
      amountLabel: '\$${(double.tryParse(p.amount) ?? 0).toStringAsFixed(2)}',
      captionLabel: formatShortDate(p.settledAt),
      statusLabel: pending ? 'Pending confirmation' : 'Settled',
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
        : (AuthSession.instance.userName ?? 'You');
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
                  eyebrow: 'Settlement',
                  title: 'Settle Balance',
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
            fromRole: 'Payer',
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
            toRole: 'Recipient',
            connectorLabel: 'Direct',
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
                      'SETTLEMENT AMOUNT',
                      style: AppTypography.labelMd(
                        color: AppSemanticColors.slate600,
                      ),
                    ),
                    AppTag(
                      label:
                          '${isConfirm ? 'Pending' : 'Owed'}: \$${_owedAmount.toStringAsFixed(2)}',
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
                      isConfirm ? null : 'Tap to edit custom sum',
                  onTap: isConfirm ? null : _editCustomAmount,
                ),
                if (!isConfirm) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppFilterChip(
                          label:
                              'Full (\$${_owedAmount.toStringAsFixed(2)})',
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
                              'Half (\$${(_owedAmount / 2).toStringAsFixed(2)})',
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
                          label: 'Custom',
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
            'PAYMENT METHOD',
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
            label: 'Payment Date',
            trailing: AppTag(
              label: 'Today, ${formatShortDate(DateTime.now())}',
              background: AppMd3Colors.surfaceContainer,
              foreground: AppMd3Colors.primaryContainer,
              uppercase: false,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppTextField(
            hintText: 'Optional note (e.g. Sent via Bizum)',
            prefixIcon: Icon(Icons.notes, color: AppSemanticColors.slate400),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'CONFIRMATION STATUS',
            style: AppTypography.labelMd(color: AppSemanticColors.slate600),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSegmentedToggle(
            options: const ['Pending Confirmation', 'Paid & Confirmed'],
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
                        : 'Recording this payment will reduce what you owe $receiverName from ',
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
                ? 'Confirm & Mark as Paid (\$${_amount.toStringAsFixed(2)})'
                : 'Record Payment (\$${_amount.toStringAsFixed(2)})',
            leadingIcon: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 18,
            ),
            isLoading: _submitting,
            onPressed: _submitting ? null : () => _submit(args),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
