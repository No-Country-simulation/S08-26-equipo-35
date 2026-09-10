import 'package:flutter/material.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/cards/feature_card.dart';
import '../../design_system/components/ui/dividers/app_divider.dart';
import '../../design_system/components/ui/tags/app_tag.dart';
import '../../design_system/components/ui/text_fields/app_text_field.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';

/// SOLO MAQUETA — sin controllers, sin onPressed reales, sin navegación.
/// Reemplaza los `() {}` y el placeholder de logo cuando conectes lógica.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            children: [
              _LogoMark(),
              const SizedBox(height: AppSpacing.lg),
              const AppTag(label: 'Effortless group math'),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Welcome to SplitFlow',
                textAlign: TextAlign.center,
                style: AppTypography.headlineLg(
                  color: AppSemanticColors.slate900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Split expenses with friends, no stress, no math.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLg(color: AppSemanticColors.slate600),
              ),
              const SizedBox(height: AppSpacing.xl),
              _AuthCard(),
              const SizedBox(height: AppSpacing.lg),
              _TrustedCommunityCard(),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: FeatureCard(
                      icon: const Icon(
                        Icons.receipt_long,
                        color: AppMd3Colors.primaryContainer,
                      ),
                      iconBackground: AppMd3Colors.surfaceContainer,
                      title: 'Smart Splitting',
                      description: 'Unequal, percentages, itemized bills',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FeatureCard(
                      icon: const Icon(
                        Icons.lock_open,
                        color: AppSemanticColors.positive,
                      ),
                      iconBackground: AppSemanticColors.positiveContainer,
                      title: 'Zero Passwords',
                      description: 'Instant one-tap login magic links',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder — reemplazar por el logo real (asset o Image.network).
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppSemanticColors.slate100,
            borderRadius: AppRadius.lgRadius,
          ),
          child: Center(
            child: Text(
              'img',
              style: AppTypography.bodySm(color: AppSemanticColors.slate400),
            ),
          ),
        ),
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppSemanticColors.positive,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppMd3Colors.surfaceContainerLowest,
        borderRadius: AppRadius.xlRadius,
        boxShadow: AppShadows.level1,
      ),
      child: Column(
        children: [
          AppButton(
            label: 'Continue with Google',
            variant: AppButtonVariant.outline,
            leadingIcon: const Icon(
              Icons.g_mobiledata,
              size: 24,
            ), // placeholder del logo de Google
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          const AppDividerWithLabel(label: 'or with email'),
          const SizedBox(height: AppSpacing.md),
          const AppTextField(
            label: 'Email address',
            hintText: 'alex@example.com',
            prefixIcon: Icon(Icons.mail_outline),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Continue',
            trailingIcon: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          Text.rich(
            TextSpan(
              style: AppTypography.bodySm(color: AppSemanticColors.slate400),
              children: [
                const TextSpan(text: 'By continuing, you agree to our '),
                TextSpan(
                  text: 'Terms',
                  style: AppTypography.bodySm(
                    color: AppMd3Colors.primaryContainer,
                  ),
                ),
                const TextSpan(text: ' & '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: AppTypography.bodySm(
                    color: AppMd3Colors.primaryContainer,
                  ),
                ),
                const TextSpan(
                  text: '. Passwordless login link will be sent to your inbox.',
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TrustedCommunityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppMd3Colors.surfaceContainerLow,
        borderRadius: AppRadius.lgRadius,
      ),
      child: Row(
        children: [
          AppAvatarStack(
            avatars: const [
              AppAvatar(initials: 'JD', backgroundColor: Color(0xFF006C49)),
              AppAvatar(
                initials: 'SR',
                backgroundColor: AppMd3Colors.primaryContainer,
              ),
              AppAvatar(
                initials: 'MK',
                backgroundColor: AppSemanticColors.negative,
              ),
            ],
            extraCountLabel: '+3k',
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trusted Community',
                  style: AppTypography.titleMd(
                    color: AppSemanticColors.slate900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs2),
                Text(
                  'Trusted by 120,000+ friends & roommates to split effortlessly.',
                  style: AppTypography.bodySm(
                    color: AppSemanticColors.slate600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
