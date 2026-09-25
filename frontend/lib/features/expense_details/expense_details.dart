import 'package:flutter/material.dart';
import '../../design_system/components/ui/attachments/attachment_tile.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/badges/balance_badge.dart';
import '../../design_system/components/ui/banners/app_info_banner.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/buttons/app_circle_icon_button.dart';
import '../../design_system/components/ui/cards/app_stat_card.dart';
import '../../design_system/components/ui/chips/attribution_chip.dart';
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
import '../../core/network/api_client.dart';
import '../../design_system/components/ui/text_fields/app_text_field.dart';
import '../expenses/data/expense.dart';
import '../expenses/data/expense_repository.dart';
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
      throw Exception('No expense ID provided');
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
      return AuthSession.instance.userName ?? 'You';
    }
    return 'Member ${userId.substring(0, userId.length >= 8 ? 8 : userId.length)}';
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
        title: 'Expense Details',
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
                      label: 'Settlement Active',
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
                        label: 'Total Amount',
                        value: '\$${expense.totalAmount.toStringAsFixed(2)}',
                        centered: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AttributionChip(
                        avatar: AppAvatar(
                          initials: _initials(expense.payerUserId),
                          size: 20,
                        ),
                        prefix: 'Added by',
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
                  'PAYMENT SUMMARY',
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
                  label: 'Paid by',
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
                        'In full',
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
                  label: 'Split Method',
                  value: expense.splitType == SplitType.equal
                      ? 'Split Equally'
                      : 'Custom / Unequal',
                  trailing: AppTag(
                    label: '${expense.splits.length} People',
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
                            'Split Breakdown',
                            style: AppTypography.titleMd(
                              color: AppSemanticColors.slate900,
                            ),
                          ),
                          AppTag(
                            label: 'Verified',
                            background: AppSemanticColors.positiveContainer,
                            foreground: AppSemanticColors.positiveText,
                            uppercase: false,
                          ),
                        ],
                      ),
                      Text(
                        expense.splitType == SplitType.equal
                            ? 'Equal split among participants'
                            : 'Itemized per person',
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
                              ? 'Payer'
                              : 'Participant',
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
                        text: 'Total split',
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
                  title: 'Receipt & Proof',
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
                        addTitle: 'Add Photo',
                        addSubtitle: 'Card slip or item',
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
                  label: 'Edit Expense',
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
                      'Request \$${_getNetAmount(expense, myUserId).toStringAsFixed(2)} from Group',
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
        title: 'Your Net Balance',
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
              const TextSpan(text: 'You paid '),
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
        title: 'Your Net Balance',
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
              const TextSpan(text: 'You owe '),
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
        description: 'No pending balance for this expense.',
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
        _error = e.message;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo conectar con el servidor.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete expense'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete "${widget.expenseTitle}"? This cannot be undone.',
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
          child: const Text('Cancel'),
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
              : const Text('Delete'),
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController = TextEditingController(
      text: widget.expense.totalAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newTitle = _titleController.text.trim();
    final newAmount = double.tryParse(_amountController.text.replaceAll(',', '.'));

    if (newTitle.isEmpty || newAmount == null || newAmount <= 0) {
      setState(() => _error = 'Please enter a valid description and amount.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final updated = await ExpenseRepository.instance.updateExpense(
        expenseId: widget.expense.expenseId,
        title: newTitle,
        totalAmount: newAmount,
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo conectar con el servidor.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit expense'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'Description',
            controller: _titleController,
            prefixIcon: const Icon(Icons.receipt_long),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
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
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _handleSave,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
