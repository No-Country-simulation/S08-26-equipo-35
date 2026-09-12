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

/// SOLO MAQUETA — sin lógica de cálculo, sin edición, sin navegación real.
/// Todo hardcodeado igual que en la captura de diseño.
class ExpenseDetails extends StatelessWidget {
  const ExpenseDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      appBar: AppTopBar(
        title: 'Expense Details',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppSemanticColors.slate900),
          onPressed: () {},
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
                      onPressed: () {},
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppCircleIconButton(
                      icon: Icons.delete_outline,
                      background: AppSemanticColors.negativeContainer,
                      iconColor: AppSemanticColors.negativeText,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Tarjeta principal: ícono, título, fecha, monto, atribución
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
                      Icons.restaurant,
                      color: AppMd3Colors.primaryContainer,
                      size: 28,
                    ),
                    background: AppMd3Colors.surfaceContainer,
                    size: 64,
                    radius: AppRadius.fullRadius,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Paella & Sangria at Can Solé',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineMd(
                      color: AppSemanticColors.slate900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs2),
                  const AppIconLabel(
                    icon: Icons.schedule,
                    text: 'Today, July 16, 2024 at 2:15 PM',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const AppStatCard(
                    label: 'Total Amount',
                    value: '\$124.00',
                    centered: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const AttributionChip(
                    avatar: AppAvatar(initials: 'A', size: 20),
                    prefix: 'Added by',
                    name: 'Alex (You)',
                    timeLabel: '3 hours ago',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Balance neto
            AppInfoBanner(
              icon: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppSemanticColors.positiveText,
              ),
              title: 'Your Net Balance',
              background: AppSemanticColors.positiveContainer,
              trailing: const BalanceBadge(
                amountLabel: '+\$94.00',
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
                      text: '\$124.00',
                      style: AppTypography.bodySm(
                        color: AppSemanticColors.slate900,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' and your share was '),
                    TextSpan(
                      text: '\$30.00',
                      style: AppTypography.bodySm(
                        color: AppSemanticColors.slate900,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: '. You are owed '),
                    TextSpan(
                      text: '\$94.00',
                      style: AppTypography.bodySm(
                        color: AppSemanticColors.slate900,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' from this expense.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Payment Summary
            Text(
              'PAYMENT SUMMARY',
              style: AppTypography.labelMd(color: AppSemanticColors.slate600),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppInfoRow(
              leading: const AppIconBox(
                icon: Icon(
                  Icons.credit_card,
                  color: AppMd3Colors.primaryContainer,
                  size: 20,
                ),
                background: AppMd3Colors.surfaceContainer,
                size: 40,
                radius: BorderRadius.all(Radius.circular(20)),
              ),
              label: 'Paid by',
              value: 'Alex (You)',
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$124.00',
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
              leading: const AppIconBox(
                icon: Icon(
                  Icons.pie_chart_outline,
                  color: AppMd3Colors.primaryContainer,
                  size: 20,
                ),
                background: AppMd3Colors.surfaceContainer,
                size: 40,
                radius: BorderRadius.all(Radius.circular(20)),
              ),
              label: 'Split Method',
              value: 'Custom / Unequal',
              trailing: AppTag(
                label: '4 People',
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
                    "Itemized per diner's order",
                    style: AppTypography.bodySm(
                      color: AppSemanticColors.slate600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const ParticipantSplitRow(
                    avatar: AppAvatar(initials: 'A', size: 36),
                    name: 'Alex (You)',
                    tagLabel: 'Payer',
                    subtitle: 'Personal share',
                    amountLabel: '\$30.00',
                    percentageLabel: '24.2%',
                  ),
                  ParticipantSplitRow(
                    avatar: const AppAvatar(
                      initials: 'MG',
                      size: 36,
                      backgroundColor: AppSemanticColors.slate600,
                    ),
                    name: 'María G.',
                    subtitle: 'Paella portion + wine',
                    amountLabel: '\$35.00',
                    percentageLabel: '28.2%',
                  ),
                  ParticipantSplitRow(
                    avatar: const AppAvatar(
                      initials: 'JP',
                      size: 36,
                      backgroundColor: AppSemanticColors.positive,
                    ),
                    name: 'Juan P.',
                    subtitle: 'Paella portion + beer',
                    amountLabel: '\$34.00',
                    percentageLabel: '27.4%',
                  ),
                  ParticipantSplitRow(
                    avatar: const AppAvatar(
                      initials: 'CL',
                      size: 36,
                      backgroundColor: Color(0xFFF9A8D4),
                    ),
                    name: 'Chloe L.',
                    subtitle: 'Vegetarian dish + dessert',
                    amountLabel: '\$25.00',
                    percentageLabel: '20.2%',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const SegmentedProgressBar(
                    segments: [
                      ProgressSegment(
                        color: AppMd3Colors.primaryContainer,
                        fraction: 0.242,
                      ),
                      ProgressSegment(
                        color: AppSemanticColors.slate600,
                        fraction: 0.282,
                      ),
                      ProgressSegment(
                        color: AppSemanticColors.positive,
                        fraction: 0.274,
                      ),
                      ProgressSegment(
                        color: Color(0xFFF9A8D4),
                        fraction: 0.202,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MetaRow(
                    icon: const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppSemanticColors.positiveText,
                    ),
                    text: 'Total split',
                    trailingText: '\$124.00 (100% matched)',
                    background: AppSemanticColors.positiveContainer,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Receipt & Proof
            SectionHeader(
              title: 'Receipt & Proof',
              trailing: Text(
                '1 photo attached',
                style: AppTypography.bodySm(color: AppSemanticColors.slate400),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AttachmentTile(
                    imageUrl: 'https://picsum.photos/seed/receipt/400/400',
                    caption: 'Receipt #408',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AttachmentTile(
                    addTitle: 'Add Photo',
                    addSubtitle: 'Card slip or item',
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            AppButton(
              label: 'Edit Expense',
              variant: AppButtonVariant.secondary,
              leadingIcon: const Icon(
                Icons.edit_note,
                color: AppMd3Colors.primaryContainer,
                size: 18,
              ),
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Request \$94.00 from Group',
              leadingIcon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
