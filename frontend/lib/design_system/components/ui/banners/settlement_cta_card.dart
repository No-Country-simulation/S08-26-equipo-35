import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../buttons/app_button.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Banner oscuro de cierre con CTA principal + link secundario, tipo
/// "Simplified Settlement / Settle Up All Balances / Already paid in
/// cash?". Distinto de AppInfoBanner (que es siempre claro y sin botón
/// grande adentro) — este es la variante "oscura + acción" para el cierre
/// de un flujo importante.
class SettlementCtaCard extends StatelessWidget {
  const SettlementCtaCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onButtonTap,
    this.footerText,
    this.footerLinkText,
    this.onFooterLinkTap,
  });

  final Widget icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onButtonTap;
  final String? footerText;
  final String? footerLinkText;
  final VoidCallback? onFooterLinkTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppMd3Colors.primaryContainer,
        borderRadius: AppRadius.xlRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(child: icon),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMd(color: Colors.white)),
                    Text(
                      description,
                      style: AppTypography.bodySm(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: buttonLabel,
            backgroundOverride: Colors.white,
            foregroundOverride: AppMd3Colors.primaryContainer,
            trailingIcon: const Icon(Icons.arrow_forward, color: AppMd3Colors.primaryContainer, size: 18),
            onPressed: onButtonTap,
          ),
          if (footerText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text.rich(
                TextSpan(
                  style: AppTypography.bodySm(color: Colors.white.withValues(alpha: 0.85)),
                  children: [
                    TextSpan(text: '$footerText '),
                    if (footerLinkText != null)
                      TextSpan(
                        text: footerLinkText,
                        style: const TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: onFooterLinkTap != null
                            ? (TapGestureRecognizer()..onTap = onFooterLinkTap)
                            : null,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
