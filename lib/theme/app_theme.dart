import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1B8D4B),
      brightness: brightness,
      surface: dark ? const Color(0xFF1A211E) : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF101713)
          : const Color(0xFFF5F7F6),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(color: scheme.surface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: scheme.surface),
      dialogTheme: DialogThemeData(backgroundColor: scheme.surface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
      ),
    );
  }
}

/// Adapt legacy decorative colours without altering images, videos or brand hues.
abstract final class AdaptiveColors {
  static Color surface(BuildContext context, Color? color) =>
      _map(context, color ?? Colors.transparent, true);
  static Color foreground(BuildContext context, Color? color) =>
      _map(context, color ?? Colors.transparent, false);
  static Color border(BuildContext context, Color? value) {
    final color = value ?? Colors.transparent;
    if (Theme.of(context).brightness != Brightness.dark) return color;
    final hsl = HSLColor.fromColor(color);
    if (hsl.saturation >= .18 && hsl.lightness < .8) {
      return foreground(context, color);
    }
    return Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: color.a);
  }

  static Color _map(BuildContext context, Color color, bool surface) {
    final theme = Theme.of(context);
    if (theme.brightness != Brightness.dark) return color;
    final hsl = HSLColor.fromColor(color);
    Color result = color;
    if (surface) {
      if (hsl.saturation < .18 && hsl.lightness > .30) {
        result = hsl.lightness >= .97
            ? theme.colorScheme.surface
            : hsl.lightness >= .85
            ? theme.colorScheme.surfaceContainerLow
            : hsl.lightness >= .65
            ? theme.colorScheme.surfaceContainer
            : theme.colorScheme.surfaceContainerHigh;
      } else if (hsl.lightness > .75) {
        result = Color.alphaBlend(
          color.withValues(alpha: .12),
          theme.colorScheme.surface,
        );
      }
    } else {
      // Explicit white remains white for labels on brand buttons and media overlays.
      if (hsl.saturation < .18 && hsl.lightness < .85) {
        result = hsl.lightness < .30
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurfaceVariant;
      } else if (hsl.saturation >= .18 && hsl.lightness < .53) {
        result = hsl.withLightness(.72).toColor();
      }
    }
    return result.withValues(alpha: color.a);
  }
}
