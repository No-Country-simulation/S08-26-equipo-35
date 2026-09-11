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
import '../../design_system/components/ui/toggles/app_segmented_toggle.dart';
import '../../design_system/navigations/app_top_bar.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';

/// SOLO MAQUETA — sin controllers reales conectados a estado, sin validación,
/// sin navegación. Todo hardcodeado igual que en la captura de diseño.
class LogExpense extends StatelessWidget {
  LogExpense({super.key});

  // Controllers solo para mostrar los montos precargados — no hay lógica
  // de suma/validación conectada.
  final _amounts = {
    'You (Alex)': TextEditingController(text: '30.00'),
    'Maria G.': TextEditingController(text: '35.00'),
    'Juan P.': TextEditingController(text: '30.00'),
    'Chloe L.': TextEditingController(text: '25.00'),
  };

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
              onPressed: () {},
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cancel / grupo / Save
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppTextAction(label: 'Cancel', onPressed: () {}),
                AppTag(
                  icon: const Icon(
                    Icons.card_travel,
                    size: 14,
                    color: AppSemanticColors.positiveText,
                  ),
                  label: 'Barcelona Summer Trip',
                  background: AppSemanticColors.positiveContainer,
                  foreground: AppSemanticColors.positiveText,
                  uppercase: false,
                ),
                AppTextAction(
                  label: 'Save',
                  emphasized: true,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Save Expense (sticky-looking CTA)
            AppButton(
              label: 'Save Expense (\$120.00)',
              leadingIcon: const Icon(
                Icons.check,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.xl),

            // Monto grande + estado de balance
            Center(
              child: Text(
                '\$120.00',
                style: AppTypography.displayCurrency(
                  color: AppSemanticColors.slate900,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: AppTag(
                icon: const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppSemanticColors.positiveText,
                ),
                label: 'Balances perfectly with group',
                background: AppSemanticColors.positiveContainer,
                foreground: AppSemanticColors.positiveText,
                uppercase: false,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Description
            AppInfoRow(
              leading: const AppIconBox(
                icon: Icon(
                  Icons.receipt_long,
                  color: AppMd3Colors.primaryContainer,
                  size: 20,
                ),
                background: AppMd3Colors.surfaceContainer,
                size: 40,
                radius: BorderRadius.all(Radius.circular(20)),
              ),
              label: 'Description',
              value: 'Tapas & Drinks at El Born',
              trailing: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppSemanticColors.slate400,
                ),
                onPressed: () {},
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Category
            Text(
              'Category',
              style: AppTypography.titleMd(color: AppSemanticColors.slate900),
            ),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CategoryChip(
                    category: ExpenseCategory.food,
                    selected: true,
                    onTap: () {},
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  CategoryChip(
                    category: ExpenseCategory.transport,
                    selected: false,
                    onTap: () {},
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  CategoryChip(
                    category: ExpenseCategory.stay,
                    selected: false,
                    onTap: () {},
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  CategoryChip(
                    category: ExpenseCategory.activities,
                    selected: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Paid by
            AppInfoRow(
              leading: const AppAvatar(initials: 'A', size: 40),
              label: 'Paid by',
              value: 'You (Alex)',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTag(
                    label: 'Primary',
                    background: AppMd3Colors.surfaceContainer,
                    foreground: AppMd3Colors.primaryContainer,
                    uppercase: false,
                  ),
                  const Icon(
                    Icons.expand_more,
                    color: AppSemanticColors.slate400,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // For whom?
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                      label: '4 selected',
                      background: AppMd3Colors.surfaceContainer,
                      foreground: AppSemanticColors.slate600,
                      uppercase: false,
                    ),
                  ],
                ),
                AppTextAction(
                  label: 'Deselect all',
                  emphasized: true,
                  onPressed: () {},
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
              children: [
                SelectableParticipantChip(
                  avatar: const AppAvatar(initials: 'A', size: 24),
                  name: 'You (Alex)',
                  selected: true,
                  onTap: () {},
                ),
                SelectableParticipantChip(
                  avatar: const AppAvatar(
                    initials: 'M',
                    size: 24,
                    backgroundColor: Color(0xFFEA580C),
                  ),
                  name: 'Maria G.',
                  selected: true,
                  onTap: () {},
                ),
                SelectableParticipantChip(
                  avatar: const AppAvatar(
                    initials: 'J',
                    size: 24,
                    backgroundColor: Color(0xFF0284C7),
                  ),
                  name: 'Juan P.',
                  selected: true,
                  onTap: () {},
                ),
                SelectableParticipantChip(
                  avatar: const AppAvatar(
                    initials: 'C',
                    size: 24,
                    backgroundColor: Color(0xFF7C3AED),
                  ),
                  name: 'Chloe L.',
                  selected: true,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Split method
            AppSegmentedToggle(
              options: const ['Split equally', 'Custom amounts'],
              selectedIndex: 1,
              onChanged: (_) {},
            ),
            const SizedBox(height: AppSpacing.md),
            const SplitStatusBanner(
              isMatched: true,
              title: 'Matches total',
              allocatedLabel: 'Allocated: \$120.00',
              diffLabel: 'Diff: \$0.00',
            ),
            const SizedBox(height: AppSpacing.sm),

            ParticipantAmountRow(
              avatar: const AppAvatar(initials: 'A', size: 40),
              name: 'You (Alex)',
              subtitle: 'Tapas sampler & beer',
              amountController: _amounts['You (Alex)']!,
            ),
            const SizedBox(height: AppSpacing.xs),
            ParticipantAmountRow(
              avatar: const AppAvatar(
                initials: 'M',
                size: 40,
                backgroundColor: Color(0xFFEA580C),
              ),
              name: 'Maria G.',
              subtitle: 'Paella portion & wine',
              amountController: _amounts['Maria G.']!,
            ),
            const SizedBox(height: AppSpacing.xs),
            ParticipantAmountRow(
              avatar: const AppAvatar(
                initials: 'J',
                size: 40,
                backgroundColor: Color(0xFF0284C7),
              ),
              name: 'Juan P.',
              subtitle: 'Patatas bravas & cider',
              amountController: _amounts['Juan P.']!,
            ),
            const SizedBox(height: AppSpacing.xs),
            ParticipantAmountRow(
              avatar: const AppAvatar(
                initials: 'C',
                size: 40,
                backgroundColor: Color(0xFF7C3AED),
              ),
              name: 'Chloe L.',
              subtitle: 'Dessert churros',
              amountController: _amounts['Chloe L.']!,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
