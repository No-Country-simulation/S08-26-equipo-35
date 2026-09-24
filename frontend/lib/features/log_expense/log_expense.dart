import 'package:flutter/material.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/banners/split_status_banner.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/buttons/app_text_action.dart';
import '../../design_system/components/ui/chips/category_chip.dart';
import '../../design_system/components/ui/chips/selectable_participant_chip.dart';
import '../../design_system/components/ui/icon_boxes/app_icon_box.dart';
import '../../design_system/components/ui/row/app_info_row.dart';
import '../../design_system/components/ui/tags/app_tag.dart';
import '../../design_system/components/ui/text_fields/app_text_field.dart';
import '../../design_system/components/ui/toggles/app_segmented_toggle.dart';
import '../../design_system/navigations/app_top_bar.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../core/network/api_client.dart';
import '../auth/data/auth_session.dart';
import '../expenses/data/expense.dart';
import '../expenses/data/expense_repository.dart';
import '../groups/data/group_detail.dart';
import '../groups/data/group_repository.dart';

const Map<ExpenseCategory, String> _categoryApiLabel = {
  ExpenseCategory.food: 'Food & Drink',
  ExpenseCategory.transport: 'Transport',
  ExpenseCategory.stay: 'Stay',
  ExpenseCategory.activities: 'Activities',
};

/// Pantalla de registrar gasto, conectada a POST /groups/{id}/expenses.
///
/// Simplificaciones deliberadas, marcadas para cuando haya más endpoints:
/// - "Paid by" queda fijo en el usuario actual — sin un endpoint que
///   resuelva nombres de otros miembros, un selector de pagador solo
///   mostraría UUIDs, que es peor que no tenerlo.
/// - Los miembros de "For whom?" se muestran como "You" (vos) o
///   "Member ab12cd34" (los demás) — mismo motivo.
class LogExpense extends StatefulWidget {
  const LogExpense({super.key, required this.groupId});

  final String groupId;

  @override
  State<LogExpense> createState() => _LogExpenseState();
}

class _LogExpenseState extends State<LogExpense> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final Map<String, TextEditingController> _customAmountControllers = {};

  late Future<GroupDetail> _groupDetailFuture;
  List<GroupMember> _members = [];
  final Set<String> _selectedMemberIds = {};

  ExpenseCategory _category = ExpenseCategory.food;
  int _splitTypeIndex = 0; // 0 = equal, 1 = custom
  bool _isSubmitting = false;

  String? get _myUserId => AuthSession.instance.userId;

  @override
  void initState() {
    super.initState();
    _groupDetailFuture = _loadMembers();
    _amountController.addListener(() => setState(() {}));
  }

  Future<GroupDetail> _loadMembers() async {
    final detail = await GroupRepository.instance.groupDetail(widget.groupId);
    setState(() {
      _members = detail.members;
      _selectedMemberIds
        ..clear()
        ..addAll(detail.members.map((m) => m.userId));
      for (final member in detail.members) {
        _customAmountControllers.putIfAbsent(
          member.userId,
          () => TextEditingController(),
        );
      }
    });
    return detail;
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

  double get _totalAmount =>
      double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

  String _displayName(String userId) {
    if (userId == _myUserId) return AuthSession.instance.userName ?? 'You';
    return 'Member ${userId.substring(0, userId.length >= 8 ? 8 : userId.length)}';
  }

  String _initials(String userId) {
    if (userId == _myUserId) return 'Y';
    return userId.substring(0, 2).toUpperCase();
  }

  double _equalShare() {
    if (_selectedMemberIds.isEmpty) return 0;
    return _totalAmount / _selectedMemberIds.length;
  }

  double _customAllocatedTotal() {
    var sum = 0.0;
    for (final id in _selectedMemberIds) {
      sum += double.tryParse(_customAmountControllers[id]?.text ?? '') ?? 0;
    }
    return sum;
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final total = _totalAmount;
    final myUserId = _myUserId;

    if (title.isEmpty ||
        total <= 0 ||
        _selectedMemberIds.isEmpty ||
        myUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa descripción, monto y al menos un participante.',
          ),
        ),
      );
      return;
    }

    final splitType = _splitTypeIndex == 0
        ? SplitType.equal
        : SplitType.exactAmount;
    final List<({String userId, double amountOwed})> splits;

    if (splitType == SplitType.equal) {
      final share = _equalShare();
      splits = _selectedMemberIds
          .map((id) => (userId: id, amountOwed: share))
          .toList();
    } else {
      final allocated = _customAllocatedTotal();
      if ((allocated - total).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Los montos personalizados no suman el total.'),
          ),
        );
        return;
      }
      splits = _selectedMemberIds
          .map(
            (id) => (
              userId: id,
              amountOwed:
                  double.tryParse(_customAmountControllers[id]?.text ?? '') ??
                  0,
            ),
          )
          .toList();
    }

    setState(() => _isSubmitting = true);
    try {
      await ExpenseRepository.instance.createExpense(
        groupId: widget.groupId,
        payerUserId: myUserId,
        title: title,
        totalAmount: total,
        splitType: splitType,
        expenseCategory: _categoryApiLabel[_category]!,
        splits: splits,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      appBar: AppTopBar(
        title: 'Log Expense',
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppSemanticColors.slate900,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const AppIconBox(
              icon: Icon(Icons.call_split, color: Colors.white, size: 18),
              background: AppMd3Colors.primaryContainer,
              size: 32,
              radius: BorderRadius.all(Radius.circular(8)),
            ),
          ],
        ),
        trailing: const AppAvatar(initials: 'AX', size: 36),
      ),
      body: FutureBuilder<GroupDetail>(
        future: _groupDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No pudimos cargar los miembros del grupo.',
                style: AppTypography.bodyMd(color: AppSemanticColors.slate600),
              ),
            );
          }

          final allocated = _splitTypeIndex == 0
              ? _totalAmount
              : _customAllocatedTotal();
          final diff = _totalAmount - allocated;
          final isMatched = diff.abs() < 0.01;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMobile,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppTextAction(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                    AppTextAction(
                      label: 'Save',
                      emphasized: true,
                      onPressed: _isSubmitting ? null : _handleSave,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Save Expense (\$${_totalAmount.toStringAsFixed(2)})',
                  leadingIcon: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  ),
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _handleSave,
                ),
                const SizedBox(height: AppSpacing.xl),

                Center(
                  child: SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _amountController,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTypography.displayCurrency(
                        color: AppSemanticColors.slate900,
                      ),
                      decoration: const InputDecoration(
                        prefixText: '\$',
                        hintText: '0.00',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: AppTag(
                    icon: Icon(
                      isMatched ? Icons.check_circle : Icons.error_outline,
                      size: 14,
                      color: isMatched
                          ? AppSemanticColors.positiveText
                          : AppSemanticColors.negativeText,
                    ),
                    label: isMatched
                        ? 'Balances perfectly with group'
                        : 'Diff: \$${diff.toStringAsFixed(2)}',
                    background: isMatched
                        ? AppSemanticColors.positiveContainer
                        : AppSemanticColors.negativeContainer,
                    foreground: isMatched
                        ? AppSemanticColors.positiveText
                        : AppSemanticColors.negativeText,
                    uppercase: false,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                AppTextField(
                  label: 'Description',
                  hintText: 'What was this for?',
                  controller: _titleController,
                  prefixIcon: const Icon(
                    Icons.receipt_long,
                    color: AppSemanticColors.slate400,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Text(
                  'Category',
                  style: AppTypography.titleMd(
                    color: AppSemanticColors.slate900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ExpenseCategory.values.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: CategoryChip(
                          category: category,
                          selected: _category == category,
                          onTap: () => setState(() => _category = category),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                AppInfoRow(
                  leading: const AppAvatar(initials: 'Y', size: 40),
                  label: 'Paid by',
                  value: AuthSession.instance.userName ?? 'You',
                  trailing: AppTag(
                    label: 'Primary',
                    background: AppMd3Colors.surfaceContainer,
                    foreground: AppMd3Colors.primaryContainer,
                    uppercase: false,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Text(
                      'For whom?',
                      style: AppTypography.headlineSm(
                        color: AppSemanticColors.slate900,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppTag(
                      label: '${_selectedMemberIds.length} selected',
                      background: AppMd3Colors.surfaceContainer,
                      foreground: AppSemanticColors.slate600,
                      uppercase: false,
                    ),
                    const Spacer(),
                    AppTextAction(
                      label: 'Select all',
                      emphasized: true,
                      onPressed: () => setState(() {
                        _selectedMemberIds
                          ..clear()
                          ..addAll(_members.map((m) => m.userId));
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
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
                        }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                AppSegmentedToggle(
                  options: const ['Split equally', 'Custom amounts'],
                  selectedIndex: _splitTypeIndex,
                  onChanged: (index) => setState(() => _splitTypeIndex = index),
                ),
                const SizedBox(height: AppSpacing.md),
                SplitStatusBanner(
                  isMatched: isMatched,
                  title: isMatched ? 'Matches total' : 'Does not match total',
                  allocatedLabel:
                      'Allocated: \$${allocated.toStringAsFixed(2)}',
                  diffLabel: 'Diff: \$${diff.toStringAsFixed(2)}',
                ),
                if (_splitTypeIndex == 1) ...[
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
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}
