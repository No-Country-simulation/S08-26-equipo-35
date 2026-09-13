import 'package:flutter/material.dart';
import '../avatars/avatar_stack.dart';
import '../badges/balance_badge.dart';
import '../buttons/app_button.dart';
import '../buttons/app_text_action.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Tarjeta de settlement con acciones ("Juan P. owes you +$110.00" +
/// Remind/Record Payment). Para el caso de solo lectura entre otras
/// personas (sin acciones), usa PeerSettlementRow en vez de este.
class SettlementCard extends StatelessWidget {
  const SettlementCard({
    super.key,
    required this.fromAvatar,
    required this.toAvatar,
    required this.name,
    required this.subtitle,
    required this.amountLabel,
    required this.status,
    this.onDetailsTap,
    this.onRemindTap,
    this.onRecordPaymentTap,
  });

  final AppAvatar fromAvatar;
  final AppAvatar toAvatar; // normalmente el avatar de "You"
  final String name;
  final String subtitle; // ej. "owes you"
  final String amountLabel;
  final BalanceBadgeStatus status;
  final VoidCallback? onDetailsTap;
  final VoidCallback? onRemindTap;
  final VoidCallback? onRecordPaymentTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: [
              fromAvatar,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward, size: 16, color: AppSemanticColors.slate400),
              ),
              toAvatar,
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.titleMd(color: AppSemanticColors.slate900)),
                    Text(subtitle, style: AppTypography.bodySm(color: AppSemanticColors.slate600)),
                  ],
                ),
              ),
              BalanceBadge(amountLabel: amountLabel, status: status),
            ],
          ),
          if (onDetailsTap != null) ...[
            const SizedBox(height: AppSpacing.xs2),
            Align(
              alignment: Alignment.centerRight,
              child: AppTextAction(
                label: 'Details',
                emphasized: true,
                trailingIcon: const Icon(Icons.expand_more, size: 16, color: AppMd3Colors.primaryContainer),
                onPressed: onDetailsTap,
              ),
            ),
          ],
          if (onRemindTap != null || onRecordPaymentTap != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (onRemindTap != null)
                  Expanded(
                    child: AppButton(
                      label: 'Remind',
                      leadingIcon: const Icon(Icons.notifications_none, color: Colors.white, size: 18),
                      onPressed: onRemindTap,
                    ),
                  ),
                if (onRemindTap != null && onRecordPaymentTap != null)
                  const SizedBox(width: AppSpacing.xs),
                if (onRecordPaymentTap != null)
                  Expanded(
                    child: AppButton(
                      label: 'Record Payment',
                      variant: AppButtonVariant.secondary,
                      leadingIcon: const Icon(Icons.check, color: AppMd3Colors.primaryContainer, size: 18),
                      onPressed: onRecordPaymentTap,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
