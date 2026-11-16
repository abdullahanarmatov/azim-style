import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static const radius = 16.0;
  static const gutter = 16.0;

  static ThemeData light() => _build(
        ColorScheme.fromSeed(
          seedColor: AppColors.camel,
          brightness: Brightness.light,
          primary: AppColors.ink,
          onPrimary: AppColors.paper,
          secondary: AppColors.camel,
          surface: AppColors.paper,
          onSurface: AppColors.ink,
          error: AppColors.danger,
        ),
      );

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(
          seedColor: AppColors.camel,
          brightness: Brightness.dark,
          primary: AppColors.paper,
          onPrimary: AppColors.ink,
          secondary: AppColors.camelDark,
          surface: AppColors.night,
          onSurface: AppColors.paper,
        ),
      );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final body = _safeFont(() => GoogleFonts.interTextTheme(base.textTheme),
        base.textTheme);
    final text = body.copyWith(
      displaySmall: _display(body.displaySmall),
      headlineMedium: _display(body.headlineMedium),
      headlineSmall: _display(body.headlineSmall),
      titleLarge: _display(body.titleLarge),
    );
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: shape,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: shape,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondary.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  static TextStyle? _display(TextStyle? style) => style == null
      ? null
      : _safeFont(() => GoogleFonts.playfairDisplay(textStyle: style),
          style.copyWith(fontWeight: FontWeight.w600));

  /// google_fonts needs network or bundled assets; fall back silently
  /// (e.g. in tests or offline first launch).
  static T _safeFont<T>(T Function() load, T fallback) {
    if (!GoogleFonts.config.allowRuntimeFetching) return fallback;
    try {
      return load();
    } catch (_) {
      return fallback;
    }
  }
}
