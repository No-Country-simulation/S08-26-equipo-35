import 'package:flutter/material.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/icon_boxes/app_icon_box.dart';
import '../../design_system/components/ui/text_fields/app_text_field.dart';
import '../../design_system/navigations/app_bottom_nav_bar.dart';
import '../../design_system/navigations/app_top_bar.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../core/network/api_client.dart';
import '../../router/app_router.dart';
import '../auth/data/auth_repository.dart';
import '../auth/data/auth_session.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isSavingPassword = false;

  @override
  void initState() {
    super.initState();
    final profile = AuthSession.instance.profile;
    _nameController.text = profile?.name ?? '';
    _emailController.text = profile?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  String _initials() {
    final name = AuthSession.instance.userName;
    if (name == null || name.isEmpty) return 'U';
    return name.substring(0, 1).toUpperCase();
  }

  Future<void> _handleSaveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email cannot be empty.')),
      );
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      await AuthRepository.instance.updateProfile(name: name, email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo conectar con el servidor.')),
      );
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _handleChangePassword() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both password fields are required.')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters.')),
      );
      return;
    }

    setState(() => _isSavingPassword = true);
    try {
      await AuthRepository.instance.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      _oldPasswordController.clear();
      _newPasswordController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo conectar con el servidor.')),
      );
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );

    if (confirmed == true && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.onboarding,
        (route) => false,
      );
    }
  }

  void _handleLogout() {
    AuthSession.instance.clear();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.onboarding,
      (route) => false,
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.history);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.balances);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = AuthSession.instance.profile;

    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      appBar: AppTopBar(
        title: 'Profile',
        leading: const AppIconBox(
          icon: Icon(Icons.call_split, color: Colors.white, size: 18),
          background: AppMd3Colors.primaryContainer,
          size: 32,
          radius: BorderRadius.all(Radius.circular(8)),
        ),
        trailing: AppAvatar(initials: _initials(), size: 36),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
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
                  AppAvatar(initials: _initials(), size: 64),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    profile?.name ?? 'User',
                    style: AppTypography.headlineMd(
                      color: AppSemanticColors.slate900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs2),
                  Text(
                    profile?.email ?? '',
                    style: AppTypography.bodySm(
                      color: AppSemanticColors.slate600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Edit Profile
            Text(
              'EDIT PROFILE',
              style: AppTypography.labelMd(color: AppSemanticColors.slate600),
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
                  AppTextField(
                    label: 'Name',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.mail_outline),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Save Changes',
                    isLoading: _isSavingProfile,
                    onPressed: _isSavingProfile ? null : _handleSaveProfile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Change Password
            Text(
              'CHANGE PASSWORD',
              style: AppTypography.labelMd(color: AppSemanticColors.slate600),
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
                  AppTextField(
                    label: 'Current password',
                    controller: _oldPasswordController,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'New password',
                    controller: _newPasswordController,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_reset),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Update Password',
                    variant: AppButtonVariant.secondary,
                    isLoading: _isSavingPassword,
                    onPressed: _isSavingPassword ? null : _handleChangePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Danger Zone
            Text(
              'ACCOUNT',
              style: AppTypography.labelMd(color: AppSemanticColors.slate600),
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
                  AppButton(
                    label: 'Log Out',
                    variant: AppButtonVariant.outline,
                    leadingIcon: const Icon(
                      Icons.logout,
                      size: 18,
                    ),
                    onPressed: _handleLogout,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Delete Account',
                    variant: AppButtonVariant.ghost,
                    leadingIcon: const Icon(
                      Icons.delete_outline,
                      color: AppSemanticColors.negativeText,
                      size: 18,
                    ),
                    onPressed: _handleDeleteAccount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        items: const [
          AppBottomNavItem(icon: Icons.groups, label: 'Groups'),
          AppBottomNavItem(icon: Icons.receipt_long, label: 'Activity'),
          AppBottomNavItem(
            icon: Icons.account_balance_wallet,
            label: 'Balances',
          ),
          AppBottomNavItem(icon: Icons.person, label: 'Profile'),
        ],
        currentIndex: 3,
        onTap: _onNavTap,
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _isSubmitting = false;
  String? _error;

  Future<void> _handleDelete() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await AuthRepository.instance.deleteAccount();
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo conectar con el servidor.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: AppTypography.bodySm(color: AppSemanticColors.negativeText),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _handleDelete,
          style: TextButton.styleFrom(
            foregroundColor: AppSemanticColors.negativeText,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }
}
