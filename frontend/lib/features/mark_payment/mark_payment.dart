import 'package:flutter/material.dart';
import '../../design_system/components/ui/avatars/avatar_badge.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/banners/app_notice_box.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/buttons/app_circle_icon_button.dart';
import '../../design_system/components/ui/cards/editable_amount_display.dart';
import '../../design_system/components/ui/cards/transfer_parties_card.dart';
import '../../design_system/components/ui/chips/app_filter_chip.dart';
import '../../design_system/components/ui/row/app_settings_row.dart';
import '../../design_system/components/ui/tags/app_tag.dart';
import '../../design_system/components/ui/text_fields/app_text_field.dart';
import '../../design_system/components/ui/titles/payment_method_tile.dart';
import '../../design_system/components/ui/titles/app_eyebrow_heading.dart';
import '../../design_system/components/ui/toggles/app_segmented_toggle.dart';
import '../../design_system/navigations/app_top_bar.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';

/// SOLO MAQUETA — sin cálculo de montos, sin selección real de método de
/// pago, sin lógica de confirmación. Todo hardcodeado igual que en la
/// captura de diseño.
class MarkPayment extends StatelessWidget {
  const MarkPayment({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      appBar: AppTopBar(
        title: 'Mark Payment',
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
                AppCircleIconButton(icon: Icons.close, onPressed: () {}),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            TransferPartiesCard(
              fromAvatar: const AvatarBadge(
                avatar: AppAvatar(
                  initials: 'JP',
                  size: 64,
                  backgroundColor: Color(0xFFEA580C),
                ),
                avatarSize: 64,
                text: 'JP',
                badgeColor: AppMd3Colors.primaryContainer,
              ),
              fromName: 'Juan P.',
              fromRole: 'Payer',
              toAvatar: const AvatarBadge(
                avatar: AppAvatar(
                  initials: 'A',
                  size: 64,
                  backgroundColor: AppMd3Colors.primaryContainer,
                ),
                avatarSize: 64,
                icon: Icons.check,
                badgeColor: AppSemanticColors.positive,
              ),
              toName: 'Alex (You)',
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
                        label: 'Owed: \$110.00',
                        background: AppSemanticColors.positiveContainer,
                        foreground: AppSemanticColors.positiveText,
                        uppercase: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  EditableAmountDisplay(
                    amount: '110.00',
                    editHint: 'Tap to edit custom sum',
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppFilterChip(
                          label: 'Full (\$110.00)',
                          selected: true,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: AppFilterChip(
                          label: 'Half (\$55.00)',
                          selected: false,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: AppFilterChip(
                          label: 'Custom',
                          selected: false,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
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
                PaymentMethodTile(
                  icon: Icons.bolt,
                  title: 'Bizum',
                  subtitle: 'Instant transfer',
                  selected: true,
                  onTap: () {},
                ),
                PaymentMethodTile(
                  icon: Icons.payments_outlined,
                  title: 'Cash',
                  subtitle: 'In person',
                  selected: false,
                  onTap: () {},
                ),
                PaymentMethodTile(
                  icon: Icons.account_balance,
                  title: 'Bank',
                  subtitle: 'Wire transfer',
                  selected: false,
                  onTap: () {},
                ),
                PaymentMethodTile(
                  icon: Icons.credit_card,
                  title: 'PayPal',
                  subtitle: 'Venmo / App',
                  selected: false,
                  onTap: () {},
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
                label: 'Today, Jul 16',
                background: AppMd3Colors.surfaceContainer,
                foreground: AppMd3Colors.primaryContainer,
                uppercase: false,
              ),
              onTap: () {},
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
              selectedIndex: 1,
              onChanged: (_) {},
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
                  style: AppTypography.bodySm(
                    color: AppSemanticColors.slate600,
                  ),
                  children: [
                    const TextSpan(
                      text:
                          "Recording this payment will adjust Juan's balance with you from ",
                    ),
                    TextSpan(
                      text: '\$110.00',
                      style: AppTypography.bodySm(
                        color: AppSemanticColors.slate900,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' to '),
                    TextSpan(
                      text: '\$0.00',
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
              label: 'Confirm & Mark as Paid (\$110.00)',
              leadingIcon: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Ask Juan for payment link',
              variant: AppButtonVariant.secondary,
              leadingIcon: const Icon(
                Icons.link,
                color: AppMd3Colors.primaryContainer,
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
