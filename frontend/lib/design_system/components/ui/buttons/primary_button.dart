import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';
import '../../../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool isLoading;

  /// true = ancho completo (como "Continue", "Save Expense" en las capturas).
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  ({Color background, Color foreground}) _colorsFor(BuildContext context) {
    if (!_isEnabled) {
      return (
        background: AppSemanticColors.slate100,
        foreground: AppSemanticColors.slate400,
      );
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return (
          background: AppMd3Colors.primaryContainer, // indigo real de marca
          foreground: Colors.white,
        );
      case AppButtonVariant.secondary:
        return (
          background: context.semanticColors.secondaryActionSurface,
          foreground: AppMd3Colors.primaryContainer,
        );
      case AppButtonVariant.ghost:
        return (
          background: _pressed
              ? AppSemanticColors.slate100
              : Colors.transparent,
          foreground: AppSemanticColors.slate600,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(context);
    final textStyle = AppTypography.titleMd(color: colors.foreground);

    final content = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(colors.foreground),
            ),
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leadingIcon != null) ...[
                widget.leadingIcon!,
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(widget.label, style: textStyle),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.xs),
                widget.trailingIcon!,
              ],
            ],
          );

    return GestureDetector(
      onTapDown: _isEnabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _isEnabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: _isEnabled ? () => setState(() => _pressed = false) : null,
      onTap: _isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 48,
          width: widget.expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: AppRadius.fullRadius,
            boxShadow: widget.variant == AppButtonVariant.primary && _isEnabled
                ? AppShadows.level2
                : null,
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}
