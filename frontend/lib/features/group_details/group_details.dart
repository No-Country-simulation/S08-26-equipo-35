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
import '../../core/utils/category_visual.dart';
import '../../core/utils/date_format.dart';
import '../../core/network/api_client.dart';
import '../../design_system/components/ui/text_fields/app_text_field.dart';
import '../../router/app_router.dart';
import '../auth/data/auth_session.dart';
import '../auth/data/user_profile.dart';
import '../expenses/data/expense.dart';
import '../expenses/data/expense_repository.dart';
import '../groups/data/group_detail.dart';
import '../groups/data/group_repository.dart';
import '../groups/domain/balance_calculator.dart';

class _GroupDetailsData {
  const _GroupDetailsData({
    required this.detail,
    required this.expenses,
    required this.balances,
    required this.debts,
    required this.settlementStatus,
    this.userProfiles = const {},
  });
  final GroupDetail detail;
  final List<Expense> expenses;
  final List<BalanceResponse> balances;
  final List<DebtResponse> debts;
  final GroupSettlementStatus settlementStatus;
  final Map<String, UserProfile> userProfiles; // userId -> Profile cache
}

/// Group Details conectado a GET /groups/detail/{id}, GET /groups/{id}/expenses,
/// GET /groups/{id}/settlements (nombres + deudas), PATCH /groups/{id}
/// (renombrar) y DELETE /groups/{id} (borrar).
///
/// Sin conectar, por falta de endpoint: código/link de invitación
/// ("Crew & Friends" no tiene el chip de código), "Share Link" y
/// "Summary" (quick actions sin acción real).
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
      GroupRepository.instance.getSettlements(widget.groupId),
      GroupRepository.instance.getSettlementStatus(widget.groupId),
    ]);
    final detail = results[0] as GroupDetail;
    final expenses = results[1] as List<Expense>;
    final bundle = results[2] as GroupDebtsBundle;
    final settlementStatus = results[3] as GroupSettlementStatus;

    // Nombres de los miembros: GET /balances (vía /settlements) trae
    // {user_id, name} de cada uno — GET /users/{id} no existe en la API.
    final Map<String, UserProfile> userProfiles = {
      for (final b in bundle.balances)
        b.userId: UserProfile(userId: b.userId, name: b.name, email: ''),
    };

    return _GroupDetailsData(
      detail: detail,
      expenses: expenses,
      balances: bundle.balances,
      debts: bundle.debts,
      settlementStatus: settlementStatus,
      userProfiles: userProfiles,
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

  Future<void> _showDeleteDialog(GroupDetail detail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteGroupDialog(detail: detail),
    );

    if (confirmed == true && mounted) {
      _retry();
    }
  }

  String _displayName(String userId, [Map<String, UserProfile>? userProfiles]) {
    // Buscar en cache de perfiles de usuario si fue proporcionado
    if (userProfiles != null) {
      final cached = userProfiles[userId];
      if (cached != null) {
        return cached.name;
      }
    }
    // Fallback: si es el usuario actual
    if (userId == AuthSession.instance.userId) {
      return AuthSession.instance.userName ?? 'You';
    }
    // Fallback final: placeholder con UUID
    return 'Member ${userId.substring(0, userId.length >= 8 ? 8 : userId.length)}';
  }

  String _initials(String userId, [Map<String, UserProfile>? userProfiles]) {
    // Buscar en cache de perfiles de usuario usando operador nulo-safe
    final cached = userProfiles?[userId];
    
    if (cached != null) {
      return cached.name.isNotEmpty ? cached.name.substring(0, 1).toUpperCase() : 'U';
    }
    // Si es el usuario actual
    if (userId == AuthSession.instance.userId) return 'Y';
    // Fallback: iniciales del UUID
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
          final settlementStatus = data.settlementStatus;

          final totalSpending = expenses.fold<double>(
            0,
            (sum, e) => sum + e.totalAmount,
          );

          // Determinar estado del balance usando datos de la API.
          // Deuda = el DEBTOR le debe al CREDITOR: si soy debtor debo yo,
          // si soy creditor me deben a mí.
          String apiBalanceLabel;
          String? apiBalanceAmount;
          Color apiBalanceBackground;
          Color apiBalanceTextColor;

          if (myUserId != null) {
            final myDebts = data.debts
                .where((d) =>
                    d.status.toUpperCase() != 'PAID' &&
                    d.debtorUserId == myUserId)
                .toList();
            final myCredits = data.debts
                .where((d) =>
                    d.status.toUpperCase() != 'PAID' &&
                    d.creditorUserId == myUserId)
                .toList();

            if (myDebts.isNotEmpty) {
              final totalOwedByMe = myDebts.fold<double>(
                0,
                (sum, d) => sum + double.parse(d.amount),
              );
              apiBalanceLabel = 'You owe';
              apiBalanceAmount = '\$${totalOwedByMe.toStringAsFixed(2)}';
              apiBalanceBackground = AppSemanticColors.negativeContainer;
              apiBalanceTextColor = AppSemanticColors.negativeText;
            } else if (myCredits.isNotEmpty) {
              final totalOwedToMe = myCredits.fold<double>(
                0,
                (sum, d) => sum + double.parse(d.amount),
              );
              apiBalanceLabel = 'You are owed';
              apiBalanceAmount = '\$${totalOwedToMe.toStringAsFixed(2)}';
              apiBalanceBackground = AppSemanticColors.positiveContainer;
              apiBalanceTextColor = AppSemanticColors.positiveText;
            } else {
              apiBalanceLabel = "You're all settled up";
              apiBalanceBackground = AppSemanticColors.positiveContainer;
              apiBalanceTextColor = AppSemanticColors.positiveText;
            }
          } else {
            apiBalanceLabel = "You're all settled up";
            apiBalanceBackground = AppSemanticColors.positiveContainer;
            apiBalanceTextColor = AppSemanticColors.positiveText;
          }

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

                    // Balance state from API settlement data
                    if (myUserId == null)
                      const AppInfoBanner(
                        icon: Icon(
                          Icons.help_outline,
                          color: AppSemanticColors.slate400,
                        ),
                        title: 'Balance unavailable',
                        description: 'No active session user to show balance.',
                        background: AppSemanticColors.slate100,
                      )
                    else if (apiBalanceAmount != null)
                      _BalanceBanner(
                        label: apiBalanceLabel,
                        amount: apiBalanceAmount,
                        background: apiBalanceBackground,
                        textColor: apiBalanceTextColor,
                      )
                    else
                      AppInfoBanner(
                        icon: const Icon(
                          Icons.check_circle,
                          color: AppSemanticColors.positiveText,
                        ),
                        title: apiBalanceLabel,
                        description: 'No pending settlements in this group.',
                        background: apiBalanceBackground,
                      ),
                    const SizedBox(height: AppSpacing.sm),

                    // Settlement status badge
                    _SettlementStatusBadge(settlementStatus: settlementStatus),

                    // Debt list visualization (bundle de /settlements, que
                    // siempre trae la lista; settlementStatus.debts puede
                    // venir vacío por default en el schema)
                    if (myUserId != null && data.debts.isNotEmpty)
                      _DebtListViewer(debts: data.debts)
                    else
                      Text(
                        'No debts found.',
                        style: AppTypography.bodyMd(
                          color: AppSemanticColors.slate600,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),

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
                                initials: _initials(member.userId, data.userProfiles),
                                size: 24,
                              ),
                              name: _displayName(member.userId, data.userProfiles),
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
                              arguments: widget.groupId,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppQuickActionTile(
                            icon: const Icon(
                              Icons.delete,
                              color: AppSemanticColors.negativeText,
                              size: 20,
                            ),
                            iconBackground: AppSemanticColors.negativeContainer,
                            label: 'Eliminar grupo',
                            onTap: () => _showDeleteDialog(detail),
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
                                  : categoryVisual(category).$3,
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
    final (icon, iconBg, _) = categoryVisual(expense.expenseCategory);

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
        color: categoryVisual(expense.expenseCategory).$3,
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

class _BalanceBanner extends StatelessWidget {
  const _BalanceBanner({
    required this.label,
    required this.amount,
    required this.background,
    required this.textColor,
  });

  final String label;
  final String amount;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return AppInfoBanner(
      icon: const Icon(
        Icons.trending_up,
        color: AppSemanticColors.positiveText,
      ),
      title: '$label $amount',
      description: 'Based on settlement data from API',
      background: background,
    );
  }
}

class _DeleteGroupDialog extends StatefulWidget {
  const _DeleteGroupDialog({required this.detail});

  final GroupDetail detail;

  @override
  State<_DeleteGroupDialog> createState() => _DeleteGroupDialogState();
}

class _DeleteGroupDialogState extends State<_DeleteGroupDialog> {
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

  Future<void> _handleDelete() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await GroupRepository.instance.deleteGroup(widget.detail.groupId);
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
      title: const Text('Eliminar grupo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '¿Estás seguro de que quieres eliminar el grupo "${widget.detail.groupName}"?',
            style: AppTypography.bodySm(
              color: AppSemanticColors.slate600,
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
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _handleDelete,
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

class _SettlementStatusBadge extends StatelessWidget {
  const _SettlementStatusBadge({
    required this.settlementStatus,
  });

  final GroupSettlementStatus settlementStatus;

  @override
  Widget build(BuildContext context) {
    final isSettled = settlementStatus.isSettled;
    final pendingCount = settlementStatus.pendingCount;
    final totalPendingAmount = settlementStatus.totalPendingAmount;

    // Use positive colors for settled, warning colors for pending
    final Color backgroundColor = isSettled
        ? AppSemanticColors.positiveContainer
        : AppSemanticColors.negativeContainer;
    final Color textColor = isSettled
        ? AppSemanticColors.positiveText
        : AppSemanticColors.negativeText;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSettled ? Icons.check_circle : Icons.remove,
            color: textColor,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isSettled
              ? 'Settled up'
              : '$pendingCount pending${pendingCount == 1 ? '' : 's'}',
            style: AppTypography.bodySm(
              color: textColor,
            ),
          ),
          if (totalPendingAmount.isNotEmpty)
            Text(
              ' \$$totalPendingAmount',
              style: AppTypography.bodySm(
                color: textColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _DebtListViewer extends StatelessWidget {
  const _DebtListViewer({
    required this.debts,
  });

  final List<DebtResponse> debts;

  @override
  Widget build(BuildContext context) {
    final myUserId = AuthSession.instance.userId;
    // Deuda = el DEBTOR le debe al CREDITOR. Si soy debtor, debo yo;
    // si soy creditor, me deben a mí. PAID ya no está pendiente.
    final owe = debts
        .where((d) =>
            d.status.toUpperCase() != 'PAID' && d.debtorUserId == myUserId)
        .toList();
    final owed = debts
        .where((d) =>
            d.status.toUpperCase() != 'PAID' && d.creditorUserId == myUserId)
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (owe.isEmpty && owed.isEmpty)
              Text(
                'No pending debts.',
                style: AppTypography.bodySm(color: AppSemanticColors.slate600),
              ),
            if (owe.isNotEmpty)
              _debtSection(
                context: context,
                label: 'You owe',
                items: owe,
                icon: Icons.arrow_upward,
                color: AppSemanticColors.negativeText,
              ),
            if (owed.isNotEmpty)
              _debtSection(
                context: context,
                label: 'You are owed',
                items: owed,
                icon: Icons.arrow_downward,
                color: AppSemanticColors.positiveText,
              ),
          ],
        ),
      ),
    );
  }

  Widget _debtSection({
    required BuildContext context,
    required String label,
    required List<DebtResponse> items,
    required IconData icon,
    required Color color,
  }) {
    final total = items.fold<double>(0, (s, d) => s + double.parse(d.amount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodySm(color: color),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(
              '${items.length} ${items.length == 1 ? 'debt' : 'debts'}',
              style: AppTypography.bodySm(color: AppSemanticColors.slate600),
            ),
            const Spacer(),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: AppTypography.bodySm(color: color),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((debt) => _DebtTile(
              debtorName: debt.debtorName,
              creditorName: debt.creditorName,
              amount: debt.amount,
              status: debt.status,
            )),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({
    required this.debtorName,
    required this.creditorName,
    required this.amount,
    required this.status,
  });

  final String debtorName;
  final String creditorName;
  final String amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(debtorName.isNotEmpty ? debtorName[0].toUpperCase() : '?'),
      ),
      title: Text(debtorName),
      subtitle: Text(creditorName),
      trailing: Text(amount),
      onTap: () {
        // Navigate to debt details or show expense breakdown
      },
    );
  }
}
