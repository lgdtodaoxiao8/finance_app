import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central colour tokens for the whole app. Prefer these over hardcoded hex
/// values so the palette stays consistent and is easy to retune.
class AppColors {
  AppColors._();

  static const background = Color(0xFFF4F5F7);
  static const surface = Color(0xFFFFFFFF);

  static const primary = Color(0xFF3B82F6);
  static const primaryDark = Color(0xFF1B50B8);
  static const onPrimary = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF1A1C1E);
  static const textSecondary = Color(0xFF6B7178);
  static const textTertiary = Color(0xFF9AA0A6);

  static const positive = Color(0xFF1FB574);
  static const negative = Color(0xFFF04E5E);

  static const divider = Color(0xFFEBEDF0);
  static const field = Color(0xFFEFF1F3);
  static const iconMuted = Color(0xFF40434A);
}

/// Corner radius scale.
const double kRadiusSm = 12;
const double kRadiusMd = 16;
const double kRadiusLg = 22;

/// Standard soft card shadow.
const List<BoxShadow> kCardShadow = [
  BoxShadow(color: Color(0x0F1A1C1E), blurRadius: 16, offset: Offset(0, 6)),
];

final ColorScheme _scheme =
    ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryFixedDim: AppColors.primaryDark,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.negative,
    );

final TextTheme _textTheme = GoogleFonts.manropeTextTheme().apply(
  bodyColor: AppColors.textPrimary,
  displayColor: AppColors.textPrimary,
);

final ThemeData themeFromSeed = ThemeData(
  useMaterial3: true,
  colorScheme: _scheme,
  scaffoldBackgroundColor: AppColors.background,
  textTheme: _textTheme,
  dividerColor: AppColors.divider,
  splashFactory: InkSparkle.splashFactory,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    iconTheme: IconThemeData(color: AppColors.textPrimary),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.surface,
    selectedColor: const Color(0x1F3B82F6), // primary @ 12%
    disabledColor: AppColors.field,
    side: const BorderSide(color: AppColors.divider),
    showCheckmark: false,
    labelStyle: _textTheme.labelLarge,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadiusSm),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: _textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusSm),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.textSecondary,
      textStyle: _textTheme.labelLarge,
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.textPrimary,
    contentTextStyle: _textTheme.bodyMedium?.copyWith(color: Colors.white),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadiusSm),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadiusMd),
    ),
  ),
);

/// Base text style kept for backwards compatibility with existing widgets.
/// Manrope with NO baked-in colour, so text inherits the ambient theme colour
/// (dark-on-light in light mode, light-on-dark in dark mode). Widgets that need
/// a specific colour still override via `.copyWith(color: …)`.
// overflow: visible — text is always drawn in FULL, never truncated with "…",
// clipped, or faded anywhere in the app. Removing overflow entirely was wrong:
// text then inherited the ancestor DefaultTextStyle (clip for most widgets,
// FADE for Material chips), which still cut it off. `visible` overrides those.
// Widgets that genuinely must fit a fixed box handle it locally (amount
// formatters; the fixed-size widget preview).
final TextStyle kTextStyle = GoogleFonts.manrope(
  textStyle: const TextStyle(overflow: TextOverflow.visible),
);

// --------------------------------------------------------------------- dark --
// Dark colour tokens. Widgets that already read Theme.of(context) / Material
// component themes adapt automatically; ones with hardcoded light colours are
// migrated to these tokens incrementally.
class AppColorsDark {
  AppColorsDark._();

  static const background = Color(0xFF0E1116);
  static const surface = Color(0xFF181C22);
  static const surfaceHigh = Color(0xFF20252E);

  static const textPrimary = Color(0xFFF2F4F7);
  static const textSecondary = Color(0xFF9BA3AF);
  static const textTertiary = Color(0xFF6B7480);

  static const divider = Color(0xFF262B33);
}

final ColorScheme _schemeDark =
    ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryFixedDim: AppColors.primaryDark,
      surface: AppColorsDark.surface,
      onSurface: AppColorsDark.textPrimary,
      error: AppColors.negative,
    );

final TextTheme _textThemeDark = GoogleFonts.manropeTextTheme().apply(
  bodyColor: AppColorsDark.textPrimary,
  displayColor: AppColorsDark.textPrimary,
);

final ThemeData darkThemeFromSeed = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: _schemeDark,
  scaffoldBackgroundColor: AppColorsDark.background,
  textTheme: _textThemeDark,
  dividerColor: AppColorsDark.divider,
  splashFactory: InkSparkle.splashFactory,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColorsDark.background,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: AppColorsDark.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    iconTheme: IconThemeData(color: AppColorsDark.textPrimary),
  ),
  cardColor: AppColorsDark.surface,
  chipTheme: ChipThemeData(
    backgroundColor: AppColorsDark.surfaceHigh,
    selectedColor: const Color(0x333B82F6),
    disabledColor: AppColorsDark.surface,
    side: const BorderSide(color: AppColorsDark.divider),
    showCheckmark: false,
    labelStyle: _textThemeDark.labelLarge,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadiusSm),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: _textThemeDark.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusSm),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColorsDark.textSecondary,
      textStyle: _textThemeDark.labelLarge,
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColorsDark.surfaceHigh,
    contentTextStyle: _textThemeDark.bodyMedium?.copyWith(
      color: AppColorsDark.textPrimary,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadiusSm),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColorsDark.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadiusMd),
    ),
  ),
);
