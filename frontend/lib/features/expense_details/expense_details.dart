import 'package:flutter/material.dart';
import '../../design_system/components/ui/attachments/attachment_tile.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/badges/balance_badge.dart';
import '../../design_system/components/ui/banners/app_info_banner.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/buttons/app_circle_icon_button.dart';
import '../../design_system/components/ui/cards/app_stat_card.dart';
import '../../design_system/components/ui/chips/attribution_chip.dart';
import '../../design_system/components/ui/chips/category_chip.dart';
import '../../design_system/components/ui/chips/selectable_participant_chip.dart';
import '../../design_system/components/ui/toggles/app_segmented_toggle.dart';
import '../../design_system/components/ui/icon_boxes/app_icon_box.dart';
import '../../design_system/components/ui/progress/segmented_progress_bar.dart';
import '../../design_system/components/ui/row/app_icon_label.dart';
import '../../design_system/components/ui/row/app_info_row.dart';
import '../../design_system/components/ui/row/meta_row.dart';
import '../../design_system/components/ui/row/participant_split_row.dart';
import '../../design_system/components/ui/tags/app_tag.dart';
import '../../design_system/navigations/app_top_bar.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/category_visual.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error_ui.dart';
import '../../design_system/components/ui/text_fields/app_text_field.dart';
import '../expenses/data/expense.dart';
import '../expenses/data/expense_repository.dart';
import '../expenses/domain/equal_split.dart';
import '../expenses/payer_picker_dialog.dart';
import '../groups/data/group_detail.dart';
import '../groups/data/group_repository.dart';
import '../auth/data/auth_session.dart';

/// Expense Details conectado a GET /expenses/{id}.
///
/// Muestra el detalle de un gasto específico, incluyendo:
/// - Información básica (título, fecha, monto, categoría)
/// - Balance neto del usuario actual
/// - Desglose de splits entre participantes
/// - Botones de editar/eliminar (aún no conectados)
class ExpenseDetails extends StatefulWidget {
  const ExpenseDetails({super.key, this.expenseId});

  final String? expenseId;

  @override
  State<ExpenseDetails> createState() => _ExpenseDetailsState();
}

class _ExpenseDetailsState extends State<ExpenseDetails> {
  late Future<Expense> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadExpense();
  }

  Future<Expense> _loadExpense() async {
    if (widget.expenseId == null) {
      throw Exception('No se pasó el ID del gasto');
    }
    return ExpenseRepository.instance.getExpense(widget.expenseId!);
  }

  void _retry() {
    setState(() {
      _future = _loadExpense();
    });
  }

  Future<void> _showDeleteConfirmation(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteExpenseDialog(expenseId: expense.expenseId, expenseTitle: expense.title),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _showEditDialog(Expense expense) async {
    final updated = await showDialog<Expense?>(
      context: context,
      builder: (context) => _EditExpenseDialog(expense: expense),
    );

    if (updated != null && mounted) {
      setState(() {
        _future = Future.value(updated);
      });
    }
  }

  String _displayName(String userId) {
    if (userId == AuthSession.instance.userId) {
      return AuthSession.instance.userName ?? 'Vos';
    }
    return 'Miembro ${userId.substring(0, userId.length >= 8 ? 8 : userId.length)}';
  }

  String _initials(String userId) {
    if (userId == AuthSession.instance.userId) return 'Y';
    return userId.substring(0, 2).toUpperCase();
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food & Drink':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Stay':
        return Icons.home;
      case 'Activities':
        return Icons.local_activity;
      default:
        return Icons.receipt_long;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Food & Drink':
        return const Color(0xFFEA580C);
      case 'Transport':
        return const Color(0xFF0284C7);
      case 'Stay':
        return const Color(0xFF7C3AED);
      case 'Activities':
        return const Color(0xFFCA8A04);
      default:
        return AppMd3Colors.primaryContainer;
    }
  }

  Color _categoryBackground(String category) {
    switch (category) {
      case 'Food & Drink':
        return const Color(0xFFFFF7ED);
      case 'Transport':
        return const Color(0xFFF0F9FF);
      case 'Stay':
        return const Color(0xFFF5F3FF);
      case 'Activities':
        return const Color(0xFFFEFCE8);
      default:
        return AppMd3Colors.surfaceContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      appBar: AppTopBar(
        title: 'Detalles del gasto',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppSemanticColors.slate900),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: const AppAvatar(initials: 'AX', size: 36),
      ),
      body: FutureBuilder<Expense>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppSemanticColors.negativeText,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No pudimos cargar el gasto.',
                    style: AppTypography.bodyMd(
                      color: AppSemanticColors.slate600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    snapshot.error.toString(),
                    style: AppTypography.bodySm(
                      color: AppSemanticColors.slate400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Reintentar',
                    expand: false,
                    onPressed: _retry,
                  ),
                ],
              ),
            );
          }

          final expense = snapshot.data!;
          final myUserId = AuthSession.instance.userId;
          final icon = _categoryIcon(expense.expenseCategory);
          final iconBg = _categoryBackground(expense.expenseCategory);
          final iconColor = _categoryColor(expense.expenseCategory);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMobile,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estado + acciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppTag(
                      icon: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppSemanticColors.positive,
                          shape: BoxShape.circle,
                        ),
                      ),
                      label: 'Saldo activo',
                      background: Colors.transparent,
                      foreground: AppSemanticColors.positiveText,
                      uppercase: false,
                    ),
                    Row(
                      children: [
                        AppCircleIconButton(
                          icon: Icons.edit_outlined,
                          onPressed: () => _showEditDialog(expense),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AppCircleIconButton(
                          icon: Icons.delete_outline,
                          background: AppSemanticColors.negativeContainer,
                          iconColor: AppSemanticColors.negativeText,
                          onPressed: () => _showDeleteConfirmation(expense),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Tarjeta principal: ícono, título, fecha, monto
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.xlRadius,
                    boxShadow: AppShadows.level1,
                  ),
                  child: Column(
                    children: [
                      AppIconBox(
                        icon: Icon(
                          icon,
                          color: iconColor,
                          size: 28,
                        ),
                        background: iconBg,
                        size: 64,
                        radius: AppRadius.fullRadius,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        expense.title,
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMd(
                          color: AppSemanticColors.slate900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs2),
                      AppIconLabel(
                        icon: Icons.schedule,
                        text: formatShortDate(expense.createdAt),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStatCard(
                        label: 'Monto total',
                        value: '\$${expense.totalAmount.toStringAsFixed(2)}',
                        centered: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AttributionChip(
                        avatar: AppAvatar(
                          initials: _initials(expense.payerUserId),
                          size: 20,
                        ),
                        prefix: 'Agregado por',
                        name: _displayName(expense.payerUserId),
                        timeLabel: formatShortDate(expense.createdAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Balance neto (si el usuario actual está en los splits)
                if (myUserId != null) ...[
                  _buildNetBalance(expense, myUserId),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Payment Summary
                Text(
                  'RESUMEN DEL PAGO',
                  style: AppTypography.labelMd(color: AppSemanticColors.slate600),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppInfoRow(
                  leading: AppIconBox(
                    icon: Icon(
                      Icons.credit_card,
                      color: AppMd3Colors.primaryContainer,
                      size: 20,
                    ),
                    background: AppMd3Colors.surfaceContainer,
                    size: 40,
                    radius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  label: 'Pagado por',
                  value: _displayName(expense.payerUserId),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${expense.totalAmount.toStringAsFixed(2)}',
                        style: AppTypography.amountRow(
                          color: AppSemanticColors.slate900,
                        ),
                      ),
                      Text(
                        'Pagado por completo',
                        style: AppTypography.labelSm(
                          color: AppSemanticColors.positiveText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AppInfoRow(
                  leading: AppIconBox(
                    icon: Icon(
                      Icons.pie_chart_outline,
                      color: AppMd3Colors.primaryContainer,
                      size: 20,
                    ),
                    background: AppMd3Colors.surfaceContainer,
                    size: 40,
                    radius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  label: 'Método de reparto',
                  value: expense.splitType == SplitType.equal
                      ? 'Reparto igual'
                      : (expense.splitType == SplitType.exactAmount
                          ? 'Personalizado / desigual'
                          : 'Método desconocido'),
                  trailing: AppTag(
                    label: '${expense.splits.length} persona'
                      '${expense.splits.length == 1 ? '' : 's'}',
                    background: AppMd3Colors.surfaceContainer,
                    foreground: AppSemanticColors.slate600,
                    uppercase: false,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Split Breakdown
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
                            'Desglose del reparto',
                            style: AppTypography.titleMd(
                              color: AppSemanticColors.slate900,
                            ),
                          ),
                          AppTag(
                            label: 'Verificado',
                            background: AppSemanticColors.positiveContainer,
                            foreground: AppSemanticColors.positiveText,
                            uppercase: false,
                          ),
                        ],
                      ),
                      Text(
                        expense.splitType == SplitType.equal
                            ? 'Reparto igual entre los participantes'
                            : (expense.splitType == SplitType.exactAmount
                                ? 'Por concepto y por persona'
                                : 'La app no reconoce el método de reparto'),
                        style: AppTypography.bodySm(
                          color: AppSemanticColors.slate600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final split in expense.splits) ...[
                        ParticipantSplitRow(
                          avatar: AppAvatar(
                            initials: _initials(split.userId),
                            size: 36,
                          ),
                          name: _displayName(split.userId),
                          subtitle: split.userId == expense.payerUserId
                              ? 'Pagó'
                              : 'Participante',
                          amountLabel: '\$${split.amountOwed.toStringAsFixed(2)}',
                          percentageLabel:
                              '${(split.amountOwed / expense.totalAmount * 100).toStringAsFixed(1)}%',
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      SegmentedProgressBar(
                        segments: expense.splits.map((split) {
                          return ProgressSegment(
                            color: split.userId == expense.payerUserId
                                ? AppMd3Colors.primaryContainer
                                : AppSemanticColors.slate600,
                            fraction: split.amountOwed / expense.totalAmount,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      MetaRow(
                        icon: const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppSemanticColors.positiveText,
                        ),
                        text: 'Reparto total',
                        trailingText:
                            '\$${expense.totalAmount.toStringAsFixed(2)} (100% matched)',
                        background: AppSemanticColors.positiveContainer,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Receipt & Proof (placeholder)
                SectionHeader(
                  title: 'Recibo y comprobante',
                  trailing: Text(
                    '0 photos attached',
                    style: AppTypography.bodySm(color: AppSemanticColors.slate400),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: AttachmentTile(
                        addTitle: 'Agregar foto',
                        addSubtitle: 'Ticket de tarjeta o concepto',
                        onTap: () {
                          // TODO: Implementar subida de fotos
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Botones de acción
                AppButton(
                  label: 'Editar gasto',
                  variant: AppButtonVariant.secondary,
                  leadingIcon: const Icon(
                    Icons.edit_note,
                    color: AppMd3Colors.primaryContainer,
                    size: 18,
                  ),
                  onPressed: () => _showEditDialog(expense),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label:
                      'Pedir \$${_getNetAmount(expense, myUserId).toStringAsFixed(2)} al grupo',
                  leadingIcon: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () {
                    // TODO: Implementar solicitud de pago
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetBalance(Expense expense, String myUserId) {
    final netAmount = _getNetAmount(expense, myUserId);

    if (netAmount > 0.005) {
      return AppInfoBanner(
        icon: const Icon(
          Icons.account_balance_wallet_outlined,
          color: AppSemanticColors.positiveText,
        ),
        title: 'Tu balance neto',
        background: AppSemanticColors.positiveContainer,
        trailing: BalanceBadge(
          amountLabel: '+\$${netAmount.toStringAsFixed(2)}',
          status: BalanceBadgeStatus.owed,
        ),
        descriptionWidget: Text.rich(
          TextSpan(
            style: AppTypography.bodySm(
              color: AppSemanticColors.slate600,
            ),
            children: [
              const TextSpan(text: 'Vos pagaste '),
              TextSpan(
                text: '\$${expense.totalAmount.toStringAsFixed(2)}',
                style: AppTypography.bodySm(
                  color: AppSemanticColors.slate900,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: '. You are owed '),
              TextSpan(
                text: '\$${netAmount.toStringAsFixed(2)}',
                style: AppTypography.bodySm(
                  color: AppSemanticColors.slate900,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' from this expense.'),
            ],
          ),
        ),
      );
    } else if (netAmount < -0.005) {
      return AppInfoBanner(
        icon: const Icon(
          Icons.account_balance_wallet_outlined,
          color: AppSemanticColors.negativeText,
        ),
        title: 'Tu balance neto',
        background: AppSemanticColors.negativeContainer,
        trailing: BalanceBadge(
          amountLabel: '-\$${netAmount.abs().toStringAsFixed(2)}',
          status: BalanceBadgeStatus.owe,
        ),
        descriptionWidget: Text.rich(
          TextSpan(
            style: AppTypography.bodySm(
              color: AppSemanticColors.slate600,
            ),
            children: [
              const TextSpan(text: 'Debes '),
              TextSpan(
                text: '\$${netAmount.abs().toStringAsFixed(2)}',
                style: AppTypography.bodySm(
                  color: AppSemanticColors.slate900,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' for this expense.'),
            ],
          ),
        ),
      );
    } else {
      return const AppInfoBanner(
        icon: Icon(
          Icons.check_circle,
          color: AppSemanticColors.positiveText,
        ),
        title: "You're all settled",
        description: 'Este gasto no tiene saldo pendiente.',
        background: AppSemanticColors.positiveContainer,
      );
    }
  }

  double _getNetAmount(Expense expense, String? myUserId) {
    if (myUserId == null) return 0;

    final mySplit = expense.splits.firstWhere(
      (s) => s.userId == myUserId,
      orElse: () => ExpenseSplit(
        splitId: '',
        userId: myUserId,
        amountOwed: expense.totalAmount / expense.splits.length,
      ),
    );

    if (expense.payerUserId == myUserId) {
      return expense.totalAmount - mySplit.amountOwed;
    } else {
      return -mySplit.amountOwed;
    }
  }
}

class _DeleteExpenseDialog extends StatefulWidget {
  const _DeleteExpenseDialog({required this.expenseId, required this.expenseTitle});

  final String expenseId;
  final String expenseTitle;

  @override
  State<_DeleteExpenseDialog> createState() => _DeleteExpenseDialogState();
}

class _DeleteExpenseDialogState extends State<_DeleteExpenseDialog> {
  bool _isSubmitting = false;
  String? _error;

  Future<void> _handleDelete() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ExpenseRepository.instance.deleteExpense(widget.expenseId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _isSubmitting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(error);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar gasto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Seguro que querés eliminar "${widget.expenseTitle}"? Esta acción no se puede deshacer.',
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: AppTypography.bodySm(color: AppSemanticColors.negativeText),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _handleDelete,
          style: TextButton.styleFrom(
            foregroundColor: AppSemanticColors.negativeText,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Eliminar'),
        ),
      ],
    );
  }
}

class _EditExpenseDialog extends StatefulWidget {
  const _EditExpenseDialog({required this.expense});

  final Expense expense;

  @override
  State<_EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends State<_EditExpenseDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  bool _isSubmitting = false;
  String? _error;

  /// Pagador editable — se carga con los miembros del grupo en background.
  String? _payerUserId;
  List<GroupMember> _members = [];
  final Map<String, String> _userProfiles = {};

  /// Categoría y reparto. Sólo se mandan si el usuario los tocó: el PUT
  /// es un parche, así que mandar un split reconstruido sin necesidad
  /// agrega chances de que el backend lo rechace.
  ///
  /// `_category` arranca en null cuando el gasto ya guardado trae una
  /// categoría que esta app no reconoce (ver
  /// `expenseCategoryFromApiLabel`) — en ese caso el chip queda sin
  /// seleccionar y no se manda categoría, para no sobrescribir con una
  /// cualquiera un valor que el usuario nunca tocó.
  ExpenseCategory? _category;
  SplitType _splitType = SplitType.equal;
  final Set<String> _selectedMemberIds = {};
  final Map<String, TextEditingController> _customAmountControllers = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController = TextEditingController(
      text: widget.expense.totalAmount.toStringAsFixed(2),
    );
    _payerUserId = widget.expense.payerUserId;
    _category = expenseCategoryFromApiLabel(widget.expense.expenseCategory);
    // Puede ser `SplitType.unknown` si el backend agregó un modo de reparto
    // que la app no conoce. Se deja pasar tal cual: el toggle de abajo es de
    // dos segmentos y no puede representar "ninguno". Es seguro porque
    // `splitTypeToApi` devuelve null para `unknown`, así que guardar sin
    // tocar el toggle no manda `split_type` y no pisa el reparto del servidor.
    _splitType = widget.expense.splitType;

    // Los participantes iniciales son los del split guardado — pueden
    // incluir gente que ya no es miembro, y eso es información que el
    // selector de miembros no tiene.
    for (final split in widget.expense.splits) {
      _selectedMemberIds.add(split.userId);
      _customAmountControllers.putIfAbsent(
        split.userId,
        () => TextEditingController(text: split.amountOwed.toStringAsFixed(2)),
      );
    }
    _loadPayerOptions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    for (final c in _customAmountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Carga miembros (GET /groups/detail) + nombres (GET /balances) sin
  /// bloquear el formulario; si falla, la fila queda sin chevron y no
  /// se puede cambiar el pagador (se conserva el actual).
  Future<void> _loadPayerOptions() async {
    try {
      final detail = await GroupRepository.instance.groupDetail(widget.expense.groupId);
      if (!mounted) return;
      setState(() => _members = detail.members);
    } catch (_) {
      return;
    }
    try {
      final balances = await GroupRepository.instance.listBalances(widget.expense.groupId);
      if (!mounted) return;
      setState(() {
        _userProfiles
          ..clear()
          ..addEntries(balances.map((b) => MapEntry(b.userId, b.name)));
      });
    } catch (_) {
      // Sin nombres quedan los placeholders "Member ab12cd34".
    }
  }

  String _displayName(String userId) {
    final profileName = _userProfiles[userId];
    if (profileName != null && profileName.trim().isNotEmpty) return profileName;
    if (userId == AuthSession.instance.userId) return AuthSession.instance.userName ?? 'Vos';
    return 'Miembro ${userId.substring(0, userId.length >= 8 ? 8 : userId.length)}';
  }

  String _initials(String userId) {
    if (userId == AuthSession.instance.userId) return 'Y';
    final profileName = _userProfiles[userId];
    if (profileName != null && profileName.trim().isNotEmpty) {
      final parts = profileName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) return (parts.first[0] + parts.last[0]).toUpperCase();
      return profileName.trim().substring(0, 2).toUpperCase();
    }
    return userId.substring(0, 2).toUpperCase();
  }

  Future<void> _showPayerPicker() async {
    if (_members.isEmpty) return;
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => PayerPickerDialog(
        members: _members,
        selectedUserId: _payerUserId,
        displayName: _displayName,
        initials: _initials,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _payerUserId = selected);
    }
  }

  /// Suma de los montos personalizados de los participantes actuales.
  double _customAllocatedTotal() {
    var sum = 0.0;
    for (final id in _selectedMemberIds) {
      sum += double.tryParse(_customAmountControllers[id]?.text ?? '') ?? 0;
    }
    return sum;
  }

  double get _totalAmount =>
      double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

  /// Reparto a mandar si el usuario tocó participantes, montos o tipo de
  /// split. null = no tocar el reparto guardado.
  ///
  /// Se manda completo (splits + split_type) cuando algo del reparto
  /// cambió, porque el backend necesita ver los dos juntos para no quedar
  /// con un EXACT_AMOUNT sin montos. Cuando el reparto es EQUAL se
  /// recalcula igual acá con `equalSplit` — mandar `total/n` crudo genera
  /// 33.33333333333333 y la suma de los splits no da el total.
  List<({String userId, double amountOwed})>? _buildSplits() {
    final participants = _selectedMemberIds.toList()..sort();
    final total = _totalAmount;

    final originalType = widget.expense.splitType;
    final typeChanged = _splitType != originalType;
    final participantsChanged = !_sameParticipants(participants);

    // Los montos sólo importan para EXACT_AMOUNT; en EQUAL los recalcula
    // el backend (y acá, para mandarlos consistentes).
    final amountsChanged = _splitType == SplitType.exactAmount &&
        !_sameCustomAmounts();

    if (!typeChanged && !participantsChanged && !amountsChanged) return null;

    if (participants.isEmpty) return null;

    final splits = _splitType == SplitType.equal
        ? equalSplit(total, participants)
        : [
            for (final id in participants)
              (
                userId: id,
                amountOwed:
                    double.tryParse(_customAmountControllers[id]?.text ?? '') ??
                        0,
              ),
          ];
    return splits;
  }

  bool _sameParticipants(List<String> current) {
    final original =
        widget.expense.splits.map((s) => s.userId).toSet();
    return original.length == current.length &&
        original.containsAll(current);
  }

  /// Compara los montos editados contra los que ya estaban guardados.
  bool _sameCustomAmounts() {
    final original = {
      for (final s in widget.expense.splits) s.userId: s.amountOwed,
    };
    for (final entry in _customAmountControllers.entries) {
      if (!original.containsKey(entry.key)) return false;
      final current =
          double.tryParse(entry.value.text.replaceAll(',', '.')) ?? 0;
      // Tolerancia de medio centavo: los montos son de 2 decimales.
      if ((current - original[entry.key]!).abs() > 0.005) return false;
    }
    return true;
  }

  Future<void> _handleSave() async {
    final newTitle = _titleController.text.trim();
    final newAmount = double.tryParse(_amountController.text.replaceAll(',', '.'));

    if (newTitle.isEmpty || newAmount == null || newAmount <= 0) {
      setState(() => _error = 'Escribe una descripción y un monto válidos.');
      return;
    }

    final splits = _buildSplits();
    if (splits != null && _splitType == SplitType.exactAmount) {
      final allocated = splits.fold<double>(0, (acc, s) => acc + s.amountOwed);
      // Tolerancia de medio centavo: los montos son de 2 decimales, así que
      // un desfasaje de 1 centavo sí es un error real.
      if ((allocated - newAmount).abs() > 0.005) {
        setState(() => _error = 'Los montos personalizados no suman el total.');
        return;
      }
    }

    // Solo mandamos la categoría si el usuario la tocó: si el gasto vino
    // con una categoría que no reconocemos, sobreescribirla sin que el
    // usuario lo pidiera perdería el dato original.
    final apiLabel = _category == null
        ? null
        : expenseCategoryApiLabel[_category!];

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final updated = await ExpenseRepository.instance.updateExpense(
        expenseId: widget.expense.expenseId,
        title: newTitle,
        totalAmount: newAmount,
        payerUserId: _payerUserId == widget.expense.payerUserId ? null : _payerUserId,
        splitType: splits == null ? null : _splitType,
        expenseCategory: apiLabel,
        splits: splits,
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _isSubmitting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(error);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar gasto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'Descripción',
            controller: _titleController,
            prefixIcon: const Icon(Icons.receipt_long),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: _members.isEmpty ? null : _showPayerPicker,
            behavior: HitTestBehavior.opaque,
            child: AppInfoRow(
              leading: AppAvatar(
                initials: _initials(_payerUserId ?? widget.expense.payerUserId),
                size: 40,
              ),
              label: 'Pagado por',
              value: _displayName(_payerUserId ?? widget.expense.payerUserId),
              trailing: _members.isEmpty
                  ? null
                  : const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppSemanticColors.slate400,
                    ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: AppTypography.bodySm(color: AppSemanticColors.negativeText),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          // ---- Categoría ----
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Categoría',
              style: AppTypography.bodySm(color: AppSemanticColors.slate600),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: ExpenseCategory.values.map((category) {
              return CategoryChip(
                category: category,
                selected: _category == category,
                onTap: () => setState(() => _category = category),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ---- Reparto ----
          AppSegmentedToggle(
            options: const ['Reparto igual', 'Montos personalizados'],
            selectedIndex: _splitType == SplitType.equal ? 0 : 1,
            onChanged: (index) => setState(() {
              _splitType = index == 0 ? SplitType.equal : SplitType.exactAmount;
            }),
          ),
          const SizedBox(height: AppSpacing.md),

          // Editar el reparto exige conocer a los miembros; sin ellos sólo
          // se puede cambiar título, monto, pagador y categoría.
          if (_members.isEmpty)
            Text(
              'Cargá los miembros del grupo para editar cómo se reparte este gasto.',
              style: AppTypography.bodySm(color: AppSemanticColors.slate600),
            )
          else ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 3.2,
              children: _members.map((member) {
                final selected = _selectedMemberIds.contains(member.userId);
                return SelectableParticipantChip(
                  avatar: AppAvatar(
                    initials: _initials(member.userId),
                    size: 24,
                  ),
                  name: _displayName(member.userId),
                  selected: selected,
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedMemberIds.remove(member.userId);
                    } else {
                      _selectedMemberIds.add(member.userId);
                      _customAmountControllers.putIfAbsent(
                        member.userId,
                        TextEditingController.new,
                      );
                    }
                  }),
                );
              }).toList(),
            ),
            if (_splitType == SplitType.exactAmount) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final id in _selectedMemberIds) ...[
                ParticipantAmountRow(
                  avatar: AppAvatar(initials: _initials(id), size: 40),
                  name: _displayName(id),
                  subtitle: '',
                  amountController: _customAmountControllers[id]!,
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Asignado: \$${_customAllocatedTotal().toStringAsFixed(2)} '
                'de \$${_totalAmount.toStringAsFixed(2)}',
                style: AppTypography.bodySm(
                  color: (_customAllocatedTotal() - _totalAmount).abs() <= 0.005
                      ? AppSemanticColors.slate600
                      : AppSemanticColors.negativeText,
                ),
              ),
            ],
          ],
        ],
      ),
      scrollable: true,
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, null),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _handleSave,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
