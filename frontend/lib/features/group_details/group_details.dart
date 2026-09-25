import 'package:flutter/material.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/banners/app_info_banner.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/cards/app_stat_card.dart';
import '../../design_system/components/ui/cards/expense_list_row.dart';
import '../../design_system/components/ui/chips/app_filter_chip.dart';
import '../../design_system/components/ui/chips/member_chip.dart';
import '../../design_system/components/ui/headers/app_cover_header.dart';
import '../../design_system/components/ui/row/meta_row.dart';
import '../../design_system/components/ui/titles/app_quick_action_tile.dart';
import '../../design_system/components/ui/titles/app_editable_title.dart';
import '../../design_system/navigations/app_top_bar.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../core/utils/date_format.dart';
import '../../core/network/api_client.dart';
import '../../design_system/components/ui/text_fields/app_text_field.dart';
import '../../router/app_router.dart';
import '../auth/data/auth_session.dart';
import '../expenses/data/expense.dart';
import '../expenses/data/expense_repository.dart';
import '../groups/data/group_detail.dart';
import '../groups/data/group_repository.dart';
import '../groups/domain/balance_calculator.dart';

class _GroupDetailsData {
  const _GroupDetailsData({required this.detail, required this.expenses});
  final GroupDetail detail;
  final List<Expense> expenses;
}

/// Devuelve (ícono, color de fondo, color de acento) para una categoría.
/// Las 4 que reconoce son las que esta misma app manda desde Log Expense
/// (ver _categoryApiLabel ahí) — cualquier otro texto (de otro cliente,
/// u otro idioma) cae en el genérico.
(IconData, Color, Color) _categoryVisual(String category) {
  switch (category) {
    case 'Food & Drink':
      return (
        Icons.restaurant,
        const Color(0xFFFFF7ED),
        const Color(0xFFEA580C),
      );
    case 'Transport':
      return (
        Icons.directions_car,
        const Color(0xFFF0F9FF),
        const Color(0xFF0284C7),
      );
    case 'Stay':
      return (Icons.home, const Color(0xFFF5F3FF), const Color(0xFF7C3AED));
    case 'Activities':
      return (
        Icons.local_activity,
        const Color(0xFFFEFCE8),
        const Color(0xFFCA8A04),
      );
    default:
      return (
        Icons.receipt_long,
        AppMd3Colors.surfaceContainer,
        AppMd3Colors.primaryContainer,
      );
  }
}

/// Group Details conectado a GET /detail/{id} + GET /groups/{id}/expenses.
///
/// Sin conectar, por falta de endpoint: código/link de invitación
/// ("Crew & Friends" no tiene el chip de código), "Share Link" y
/// "Summary" (quick actions sin acción real), y editar el nombre del
/// grupo (el lápiz no hace nada — existe PATCH /{id_group} pero no lo
/// conecté en este paso para no mezclar lectura con edición).
class GroupDetails extends StatefulWidget {
  const GroupDetails({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupDetails> createState() => _GroupDetailsState();
}

class _GroupDetailsState extends State<GroupDetails> {
  late Future<_GroupDetailsData> _future;
  String _categoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_GroupDetailsData> _load() async {
    final results = await Future.wait([
      GroupRepository.instance.groupDetail(widget.groupId),
      ExpenseRepository.instance.listGroupExpenses(widget.groupId),
    ]);
    return _GroupDetailsData(
      detail: results[0] as GroupDetail,
      expenses: results[1] as List<Expense>,
    );
  }

  void _retry() => setState(() => _future = _load());

  Future<void> _showRenameDialog(GroupDetail detail) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _RenameGroupDialog(detail: detail),
    );

    if (saved == true && mounted) {
      _retry();
    }
  }

  String _displayName(String userId) {
    if (userId == AuthSession.instance.userId)
      return AuthSession.instance.userName ?? 'You';
    return 'Member ${userId.substring(0, userId.length >= 8 ? 8 : userId.length)}';
  }

  String _initials(String userId) {
    if (userId == AuthSession.instance.userId) return 'Y';
    return userId.substring(0, 2).toUpperCase();
  }

  Future<void> _openAddExpense(BuildContext context) async {
    final created = await Navigator.pushNamed(
      context,
      AppRoutes.logExpense,
      arguments: widget.groupId,
    );
    if (created == true) _retry();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      appBar: AppTopBar(
        title: 'Group Details',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppSemanticColors.slate900),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: const AppAvatar(initials: 'AX', size: 36),
      ),
      body: FutureBuilder<_GroupDetailsData>(
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
                  Text(
                    'No pudimos cargar el grupo.',
                    style: AppTypography.bodyMd(
                      color: AppSemanticColors.slate600,
                    ),
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

          final data = snapshot.data!;
          final detail = data.detail;
          final expenses = data.expenses;
          final myUserId = AuthSession.instance.userId;
          final memberCount = detail.members.length;

          final netBalance = myUserId == null
              ? null
              : calculateNetBalance(
                  expenses: expenses,
                  myUserId: myUserId,
                  memberCount: memberCount,
                );
          final totalSpending = expenses.fold<double>(
            0,
            (sum, e) => sum + e.totalAmount,
          );

          final categories = <String>{
            'All',
            ...expenses.map((e) => e.expenseCategory),
          }.toList();
          final filtered = _categoryFilter == 'All'
              ? expenses
              : expenses
                    .where((e) => e.expenseCategory == _categoryFilter)
                    .toList();
          final sorted = [...filtered]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCoverHeader(
                      imageUrl:
                          'https://picsum.photos/seed/${widget.groupId}/800/400',
                      floatingAction: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        child: IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: AppSemanticColors.slate900,
                            size: 20,
                          ),
                          onPressed:
                              () {}, // Sin conectar: no hay pantalla de settings de grupo todavía.
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppEditableTitle(
                      title: detail.groupName,
                      onEdit: () => _showRenameDialog(detail),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Created ${formatShortDate(detail.createdAt)} · $memberCount member${memberCount == 1 ? '' : 's'}',
                      style: AppTypography.bodySm(
                        color: AppSemanticColors.slate600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppStatCard(
                      label: 'Total group spending',
                      value: '\$${totalSpending.toStringAsFixed(2)}',
                      icon: const Icon(
                        Icons.receipt_long,
                        color: AppMd3Colors.primaryContainer,
                        size: 20,
                      ),
                      iconBackground: AppSemanticColors.slate100,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    if (netBalance == null)
                      const AppInfoBanner(
                        icon: Icon(
                          Icons.help_outline,
                          color: AppSemanticColors.slate400,
                        ),
                        title: 'Balance not available',
                        description:
                            "We couldn't verify your session to calculate this.",
                        background: AppSemanticColors.slate100,
                      )
                    else if (netBalance > 0.005)
                      AppInfoBanner(
                        icon: const Icon(
                          Icons.trending_up,
                          color: AppSemanticColors.positiveText,
                        ),
                        title:
                            'You are owed \$${netBalance.toStringAsFixed(2)}',
                        description:
                            'Based on ${expenses.length} expense${expenses.length == 1 ? '' : 's'}',
                        background: AppSemanticColors.positiveContainer,
                      )
                    else if (netBalance < -0.005)
                      AppInfoBanner(
                        icon: const Icon(
                          Icons.trending_down,
                          color: AppSemanticColors.negativeText,
                        ),
                        title:
                            'You owe \$${netBalance.abs().toStringAsFixed(2)}',
                        description:
                            'Based on ${expenses.length} expense${expenses.length == 1 ? '' : 's'}',
                        background: AppSemanticColors.negativeContainer,
                      )
                    else
                      const AppInfoBanner(
                        icon: Icon(
                          Icons.check_circle,
                          color: AppSemanticColors.positiveText,
                        ),
                        title: "You're all settled up",
                        description: 'No pending balance in this group.',
                        background: AppSemanticColors.positiveContainer,
                      ),
                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      'Crew & Friends',
                      style: AppTypography.titleMd(
                        color: AppSemanticColors.slate900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final member in detail.members) ...[
                            MemberChip(
                              avatar: AppAvatar(
                                initials: _initials(member.userId),
                                size: 24,
                              ),
                              name: _displayName(member.userId),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                          ],
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
                            onTap:
                                () {}, // Sin conectar: no hay endpoint de invitación.
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
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.balances,
                            ),
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
                            onTap:
                                () {}, // Sin conectar: no hay endpoint de resumen/exportación.
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    SectionHeader(
                      title: 'Recent Expenses',
                      trailing: Text(
                        '${expenses.length} total',
                        style: AppTypography.bodySm(
                          color: AppSemanticColors.slate400,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final category in categories) ...[
                            AppFilterChip(
                              label: category,
                              selected: _categoryFilter == category,
                              dotColor: category == 'All'
                                  ? null
                                  : _categoryVisual(category).$3,
                              onTap: () =>
                                  setState(() => _categoryFilter = category),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (sorted.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          'No expenses yet.',
                          style: AppTypography.bodyMd(
                            color: AppSemanticColors.slate600,
                          ),
                        ),
                      )
                    else
                      for (final expense in sorted) ...[
                        _buildExpenseRow(
                          context,
                          expense,
                          myUserId,
                          memberCount,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              Positioned(
                right: AppSpacing.marginMobile,
                bottom: AppSpacing.md,
                child: AppButton(
                  label: 'Add expense',
                  leadingIcon: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 18,
                  ),
                  expand: false,
                  onPressed: () => _openAddExpense(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpenseRow(
    BuildContext context,
    Expense expense,
    String? myUserId,
    int memberCount,
  ) {
    final (icon, iconBg, _) = _categoryVisual(expense.expenseCategory);

    var status = ExpenseRowStatus.neutral;
    var statusLabel = '';
    if (myUserId != null) {
      final net = myNetForExpense(expense, myUserId, memberCount);
      if (net > 0.005) {
        status = ExpenseRowStatus.owed;
        statusLabel = '+\$${net.toStringAsFixed(2)} for you';
      } else if (net < -0.005) {
        status = ExpenseRowStatus.owe;
        statusLabel = 'You owe \$${net.abs().toStringAsFixed(2)}';
      } else {
        statusLabel = 'Settled';
      }
    }

    return ExpenseListRow(
      icon: Icon(
        icon,
        size: 20,
        color: _categoryVisual(expense.expenseCategory).$3,
      ),
      iconBackground: iconBg,
      title: expense.title,
      metaText:
          'Paid by ${_displayName(expense.payerUserId)} · ${expense.splitType == SplitType.equal ? 'Split equally' : 'Custom split'}',
      timeLabel: formatShortDate(expense.createdAt),
      totalAmountLabel: '\$${expense.totalAmount.toStringAsFixed(2)}',
      statusLabel: statusLabel,
      status: status,
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.expenseDetails,
          arguments: expense.expenseId,
        );
      },
    );
  }
}

class _RenameGroupDialog extends StatefulWidget {
  const _RenameGroupDialog({required this.detail});

  final GroupDetail detail;

  @override
  State<_RenameGroupDialog> createState() => _RenameGroupDialogState();
}

class _RenameGroupDialogState extends State<_RenameGroupDialog> {
  late final TextEditingController _nameController;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.detail.groupName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newName = _nameController.text.trim();

    if (newName.isEmpty || newName == widget.detail.groupName) {
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await GroupRepository.instance.updateGroupName(widget.detail.groupId, newName);
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
      title: const Text('Rename group'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'Group name',
            controller: _nameController,
            prefixIcon: const Icon(Icons.edit),
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
