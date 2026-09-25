import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/dividers/app_divider.dart';
import '../../design_system/components/ui/icon_boxes/app_icon_box.dart';
import '../../design_system/components/ui/text_fields/app_text_field.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../core/network/api_client.dart';
import '../../router/app_router.dart';
import 'data/auth_repository.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            children: [
              const AppIconBox(
                icon: Icon(Icons.call_split, color: Colors.white, size: 28),
                background: AppMd3Colors.primaryContainer,
                size: 56,
                radius: BorderRadius.all(Radius.circular(16)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Welcome back',
                textAlign: TextAlign.center,
                style: AppTypography.headlineLg(color: AppSemanticColors.slate900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Log in to keep splitting expenses with your crew.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLg(color: AppSemanticColors.slate600),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _LoginCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  const _LoginCard();

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      await AuthRepository.instance.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await AuthRepository.instance.fetchProfile();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo conectar con el servidor.')),
      );
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
            label: 'Continue with Google',
            variant: AppButtonVariant.outline,
            leadingIcon: const Icon(Icons.g_mobiledata, size: 24), // placeholder del logo de Google
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          const AppDividerWithLabel(label: 'or with email'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Email address',
            hintText: 'alex@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.mail_outline),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Password',
            hintText: '••••••••',
            controller: _passwordController,
            obscureText: true,
            prefixIcon: const Icon(Icons.lock_outline),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Log In',
            isLoading: _isLoading,
            trailingIcon: _isLoading
                ? null
                : const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            onPressed: _isLoading ? null : _handleLogin,
          ),
          const SizedBox(height: AppSpacing.md),
          Text.rich(
            TextSpan(
              style: AppTypography.bodySm(color: AppSemanticColors.slate600),
              children: [
                const TextSpan(text: "Don't have an account? "),
                TextSpan(
                  text: 'Sign up',
                  style: AppTypography.bodySm(color: AppMd3Colors.primaryContainer)
                      .copyWith(fontWeight: FontWeight.w600),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => Navigator.pushReplacementNamed(context, AppRoutes.onboarding),
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
