import 'package:flutter/gestures.dart';
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
import '../../core/network/api_client.dart';
import '../../core/network/api_error_ui.dart';
import '../auth/data/auth_repository.dart';
import '../../router/app_router.dart';

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
              const AppTag(label: 'Cuentas en grupo sin esfuerzo'),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Te damos la bienvenida a SplitFlow',
                textAlign: TextAlign.center,
                style: AppTypography.headlineLg(color: AppSemanticColors.slate900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Reparte gastos con amigos: sin estrés y sin cuentas.',
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
                      icon: const Icon(Icons.receipt_long, color: AppMd3Colors.primaryContainer),
                      iconBackground: AppMd3Colors.surfaceContainer,
                      title: 'Reparto inteligente',
                      description: 'Desigual, por porcentaje o por concepto',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FeatureCard(
                      icon: const Icon(Icons.lock_open, color: AppSemanticColors.positive),
                      iconBackground: AppSemanticColors.positiveContainer,
                      title: 'Sin contraseñas',
                      description: 'Acceso instantáneo con enlaces mágicos',
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
            child: Text('imagen', style: AppTypography.bodySm(color: AppSemanticColors.slate400)),
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

class _AuthCard extends StatefulWidget {
  @override
  State<_AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<_AuthCard> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);
    try {
      await AuthRepository.instance.register(name: name, email: email, password: password);
      // El registro no devuelve sesión (solo email + created_at), así que
      // logueamos con las mismas credenciales para obtener el access_token
      // antes de entrar a Home.
      await AuthRepository.instance.login(email: email, password: password);
      await AuthRepository.instance.fetchProfile();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on ApiException catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            label: 'Continuar con Google',
            variant: AppButtonVariant.outline,
            leadingIcon: const Icon(Icons.g_mobiledata, size: 24), // placeholder del logo de Google
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          const AppDividerWithLabel(label: 'o con email'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Nombre completo',
            hintText: 'Ana Rivera',
            controller: _nameController,
            prefixIcon: const Icon(Icons.person_outline),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Email',
            hintText: 'alex@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.mail_outline),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Contraseña',
            hintText: '••••••••',
            controller: _passwordController,
            obscureText: true,
            prefixIcon: const Icon(Icons.lock_outline),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Continuar',
            isLoading: _isLoading,
            trailingIcon: _isLoading
                ? null
                : const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            onPressed: _isLoading ? null : _handleRegister,
          ),
          const SizedBox(height: AppSpacing.md),
          Text.rich(
            TextSpan(
              style: AppTypography.bodySm(color: AppSemanticColors.slate400),
              children: [
                const TextSpan(text: 'Al continuar, aceptas nuestros '),
                TextSpan(
                  text: 'Términos',
                  style: AppTypography.bodySm(color: AppMd3Colors.primaryContainer),
                ),
                const TextSpan(text: ' & '),
                TextSpan(
                  text: 'Política de privacidad',
                  style: AppTypography.bodySm(color: AppMd3Colors.primaryContainer),
                ),
                const TextSpan(
                  text: '. Passwordless login link will be sent to your inbox.',
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text.rich(
            TextSpan(
              style: AppTypography.bodySm(color: AppSemanticColors.slate600),
              children: [
                const TextSpan(text: '¿Ya tienes una cuenta? '),
                TextSpan(
                  text: 'Inicia sesión',
                  style: AppTypography.bodySm(color: AppMd3Colors.primaryContainer)
                      .copyWith(fontWeight: FontWeight.w600),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => Navigator.pushReplacementNamed(context, AppRoutes.login),
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
              AppAvatar(initials: 'SR', backgroundColor: AppMd3Colors.primaryContainer),
              AppAvatar(initials: 'MK', backgroundColor: AppSemanticColors.negative),
            ],
            extraCountLabel: '+3k',
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comunidad de confianza', style: AppTypography.titleMd(color: AppSemanticColors.slate900)),
                const SizedBox(height: AppSpacing.xs2),
                Text(
                  '120.000+ amigos y compañeros de casa ya reparten gastos sin esfuerzo.',
                  style: AppTypography.bodySm(color: AppSemanticColors.slate600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
