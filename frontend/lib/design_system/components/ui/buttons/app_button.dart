import 'package:flutter/material.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';
import '../../../theme/app_theme.dart';

/// Variantes de botón de SplitFlow. Las 3 primeras vienen de
/// "Components > Buttons" en DESIGN.md; `outline` se agregó para el botón
/// de autenticación social ("Continue with Google"), que comparte la misma
/// geometría pero necesita fondo blanco + borde.
enum AppButtonVariant {
  /// Relleno sólido indigo (#4F46E5). CTAs principales: "Settle Up", "Add Expense".
  primary,

  /// Superficie tintada (#EEF2FF) + texto indigo. Sin borde.
  secondary,

  /// Transparente, texto slate. Se tinta en press.
  ghost,

  /// Fondo blanco + borde slate. Botones de autenticación social.
  outline,
}

/// Botón único de SplitFlow. Las 3 variantes de DESIGN.md comparten
/// geometría (48px alto, pill, padding 24px) y la animación de press
/// (scale 0.98) — por eso es un solo widget parametrizado por variante,
/// no tres clases separadas. Si mañana cambia el timing de la animación,
/// se edita en un solo lugar.
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

  ({Color background, Color foreground, Color? border}) _colorsFor(
    BuildContext context,
  ) {
    if (!_isEnabled) {
      return (
        background: AppSemanticColors.slate100,
        foreground: AppSemanticColors.slate400,
        border: null,
      );
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return (
          background: AppMd3Colors.primaryContainer, // indigo real de marca
          foreground: Colors.white,
          border: null,
        );
      case AppButtonVariant.secondary:
        return (
          background: context.semanticColors.secondaryActionSurface,
          foreground: AppMd3Colors.primaryContainer,
          border: null,
        );
      case AppButtonVariant.ghost:
        return (
          background: _pressed
              ? AppSemanticColors.slate100
              : Colors.transparent,
          foreground: AppSemanticColors.slate600,
          border: null,
        );
      case AppButtonVariant.outline:
        return (
          background: _pressed ? AppSemanticColors.slate50 : Colors.white,
          foreground: AppSemanticColors.slate900,
          border: AppSemanticColors.slate200,
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
            border: colors.border != null
                ? Border.all(color: colors.border!)
                : null,
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
