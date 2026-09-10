import 'package:flutter/material.dart';
import '../avatars/avatar_stack.dart';
import '../badges/balance_badge.dart';
import '../icon_boxes/app_icon_box.dart';
import '../../../components/ui/row/meta_row.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Tarjeta de grupo del listado de Home. Combina AppIconBox +
/// AppAvatarStack + BalanceBadge + MetaRow — no repitas esta estructura a
/// mano en otras pantallas, todos los datos entran por parámetros.
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.title,
    this.emoji,
    required this.memberAvatars,
    required this.memberCountLabel,
    required this.balanceAmountLabel,
    required this.balanceStatus,
    this.balanceCaption,
    required this.metaIcon,
    required this.metaText,
    this.metaTrailingText,
    this.onTap,
  });

  final Widget icon;
  final Color iconBackground;
  final String title;
  final String? emoji;
  final List<AppAvatar> memberAvatars;
  final String memberCountLabel; // ej. "4 members"
  final String balanceAmountLabel;
  final BalanceBadgeStatus balanceStatus;
  final String? balanceCaption;
  final Widget metaIcon;
  final String metaText;
  final String? metaTrailingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppMd3Colors.surfaceContainerLowest,
          borderRadius: AppRadius.lgRadius,
          boxShadow: AppShadows.level1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIconBox(icon: icon, background: iconBackground),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: AppTypography.headlineSm(
                            color: AppSemanticColors.slate900,
                          ),
                          children: [
                            TextSpan(text: title),
                            if (emoji != null) TextSpan(text: ' $emoji'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs2),
                      Row(
                        children: [
                          AppAvatarStack(avatars: memberAvatars, size: 24),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            memberCountLabel,
                            style: AppTypography.bodySm(
                              color: AppSemanticColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                BalanceBadge(
                  amountLabel: balanceAmountLabel,
                  status: balanceStatus,
                  caption: balanceCaption,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            MetaRow(
              icon: metaIcon,
              text: metaText,
              trailingText: metaTrailingText,
            ),
          ],
        ),
      ),
    );
  }
}
