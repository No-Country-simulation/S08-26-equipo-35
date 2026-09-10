import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/app_tokens.dart';

/// Colores que no encajan en los roles de Material (positive/negative de
/// balance, tintes de categoría) — se agregan al Theme como extensión para
/// que se lean igual de fácil que colorScheme: `context.semanticColors.positive`.
@immutable
class AppSemanticTheme extends ThemeExtension<AppSemanticTheme> {
  const AppSemanticTheme({
    required this.positive,
    required this.positiveContainer,
    required this.positiveText,
    required this.negative,
    required this.negativeContainer,
    required this.negativeText,
    required this.secondaryActionSurface,
    required this.foodTint,
    required this.foodText,
    required this.transportTint,
    required this.transportText,
    required this.stayTint,
    required this.stayText,
    required this.activitiesTint,
    required this.activitiesText,
  });

  final Color positive;
  final Color positiveContainer;
  final Color positiveText;
  final Color negative;
  final Color negativeContainer;
  final Color negativeText;
  final Color secondaryActionSurface;
  final Color foodTint;
  final Color foodText;
  final Color transportTint;
  final Color transportText;
  final Color stayTint;
  final Color stayText;
  final Color activitiesTint;
  final Color activitiesText;

  static const light = AppSemanticTheme(
    positive: AppSemanticColors.positive,
    positiveContainer: AppSemanticColors.positiveContainer,
    positiveText: AppSemanticColors.positiveText,
    negative: AppSemanticColors.negative,
    negativeContainer: AppSemanticColors.negativeContainer,
    negativeText: AppSemanticColors.negativeText,
    secondaryActionSurface: AppSemanticColors.secondaryActionSurface,
    foodTint: AppSemanticColors.foodTint,
    foodText: AppSemanticColors.foodText,
    transportTint: AppSemanticColors.transportTint,
    transportText: AppSemanticColors.transportText,
    stayTint: AppSemanticColors.stayTint,
    stayText: AppSemanticColors.stayText,
    activitiesTint: AppSemanticColors.activitiesTint,
    activitiesText: AppSemanticColors.activitiesText,
  );

  @override
  AppSemanticTheme copyWith({
    Color? positive,
    Color? positiveContainer,
    Color? positiveText,
    Color? negative,
    Color? negativeContainer,
    Color? negativeText,
    Color? secondaryActionSurface,
    Color? foodTint,
    Color? foodText,
    Color? transportTint,
    Color? transportText,
    Color? stayTint,
    Color? stayText,
    Color? activitiesTint,
    Color? activitiesText,
  }) {
    return AppSemanticTheme(
      positive: positive ?? this.positive,
      positiveContainer: positiveContainer ?? this.positiveContainer,
      positiveText: positiveText ?? this.positiveText,
      negative: negative ?? this.negative,
      negativeContainer: negativeContainer ?? this.negativeContainer,
      negativeText: negativeText ?? this.negativeText,
      secondaryActionSurface:
          secondaryActionSurface ?? this.secondaryActionSurface,
      foodTint: foodTint ?? this.foodTint,
      foodText: foodText ?? this.foodText,
      transportTint: transportTint ?? this.transportTint,
      transportText: transportText ?? this.transportText,
      stayTint: stayTint ?? this.stayTint,
      stayText: stayText ?? this.stayText,
      activitiesTint: activitiesTint ?? this.activitiesTint,
      activitiesText: activitiesText ?? this.activitiesText,
    );
  }

  @override
  AppSemanticTheme lerp(ThemeExtension<AppSemanticTheme>? other, double t) {
    if (other is! AppSemanticTheme) return this;
    return AppSemanticTheme(
      positive: Color.lerp(positive, other.positive, t)!,
      positiveContainer: Color.lerp(positiveContainer, other.positiveContainer, t)!,
      positiveText: Color.lerp(positiveText, other.positiveText, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      negativeContainer: Color.lerp(negativeContainer, other.negativeContainer, t)!,
      negativeText: Color.lerp(negativeText, other.negativeText, t)!,
      secondaryActionSurface:
          Color.lerp(secondaryActionSurface, other.secondaryActionSurface, t)!,
      foodTint: Color.lerp(foodTint, other.foodTint, t)!,
      foodText: Color.lerp(foodText, other.foodText, t)!,
      transportTint: Color.lerp(transportTint, other.transportTint, t)!,
      transportText: Color.lerp(transportText, other.transportText, t)!,
      stayTint: Color.lerp(stayTint, other.stayTint, t)!,
      stayText: Color.lerp(stayText, other.stayText, t)!,
      activitiesTint: Color.lerp(activitiesTint, other.activitiesTint, t)!,
      activitiesText: Color.lerp(activitiesText, other.activitiesText, t)!,
    );
  }
}

extension AppSemanticThemeX on BuildContext {
  AppSemanticTheme get semanticColors =>
      Theme.of(this).extension<AppSemanticTheme>()!;
}

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppMd3Colors.primary,
    onPrimary: AppMd3Colors.onPrimary,
    primaryContainer: AppMd3Colors.primaryContainer,
    onPrimaryContainer: AppMd3Colors.onPrimaryContainer,
    secondary: AppMd3Colors.secondary,
    onSecondary: AppMd3Colors.onSecondary,
    secondaryContainer: AppMd3Colors.secondaryContainer,
    onSecondaryContainer: AppMd3Colors.onSecondaryContainer,
    tertiary: AppMd3Colors.tertiary,
    onTertiary: AppMd3Colors.onTertiary,
    tertiaryContainer: AppMd3Colors.tertiaryContainer,
    onTertiaryContainer: AppMd3Colors.onTertiaryContainer,
    error: AppMd3Colors.error,
    onError: AppMd3Colors.onError,
    errorContainer: AppMd3Colors.errorContainer,
    onErrorContainer: AppMd3Colors.onErrorContainer,
    surface: AppMd3Colors.surface,
    onSurface: AppMd3Colors.onSurface,
    surfaceContainerLowest: AppMd3Colors.surfaceContainerLowest,
    surfaceContainerLow: AppMd3Colors.surfaceContainerLow,
    surfaceContainer: AppMd3Colors.surfaceContainer,
    surfaceContainerHigh: AppMd3Colors.surfaceContainerHigh,
    surfaceContainerHighest: AppMd3Colors.surfaceContainerHighest,
    onSurfaceVariant: AppMd3Colors.onSurfaceVariant,
    outline: AppMd3Colors.outline,
    outlineVariant: AppMd3Colors.outlineVariant,
    inverseSurface: AppMd3Colors.inverseSurface,
    onInverseSurface: AppMd3Colors.inverseOnSurface,
    inversePrimary: AppMd3Colors.inversePrimary,
    surfaceTint: AppMd3Colors.surfaceTint,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppMd3Colors.background,
    extensions: const [AppSemanticTheme.light],
    textTheme: TextTheme(
      displayLarge: AppTypography.displayCurrency(color: AppMd3Colors.onSurface),
      headlineLarge: AppTypography.headlineLg(color: AppMd3Colors.onSurface),
      headlineMedium: AppTypography.headlineMd(color: AppMd3Colors.onSurface),
      headlineSmall: AppTypography.headlineSm(color: AppMd3Colors.onSurface),
      titleMedium: AppTypography.titleMd(color: AppMd3Colors.onSurface),
      bodyLarge: AppTypography.bodyLg(color: AppMd3Colors.onSurface),
      bodyMedium: AppTypography.bodyMd(color: AppMd3Colors.onSurfaceVariant),
      bodySmall: AppTypography.bodySm(color: AppMd3Colors.onSurfaceVariant),
      labelMedium: AppTypography.labelMd(color: AppMd3Colors.onSurfaceVariant),
      labelSmall: AppTypography.labelSm(color: AppMd3Colors.onSurfaceVariant),
    ),
    // Botón primario: usa `primaryContainer` (#4F46E5, el indigo de marca real)
    // por indicación explícita de "Components > Buttons" en DESIGN.md — NO
    // uses `colorScheme.primary` aquí, saldría más oscuro de lo diseñado.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppMd3Colors.primaryContainer,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
        elevation: 0,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppMd3Colors.surfaceContainerLowest,
      elevation: 0, // sombras se aplican manualmente con AppShadows
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgRadius,
        side: const BorderSide(color: AppSemanticColors.slate200),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: const BorderSide(color: AppSemanticColors.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: const BorderSide(
          color: AppMd3Colors.primaryContainer,
          width: 2,
        ),
      ),
    ),
  );
}
