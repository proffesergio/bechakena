import 'package:flutter/material.dart';

/// Brand green with a warm amber secondary — vibrant but still Material 3.
const _seed = Color(0xFF00A86B);
const _tertiarySeed = Color(0xFFFFB300);

ThemeData lightTheme() => _base(Brightness.light);

ThemeData darkTheme() => _base(Brightness.dark);

ThemeData _base(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    tertiary: _tertiarySeed,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
  );
  final light = brightness == Brightness.light;
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.comfortable,
    scaffoldBackgroundColor:
        light ? const Color(0xFFF4F7F4) : scheme.surfaceContainerLowest,
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: light ? Colors.white : scheme.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
      selectedLabelTextStyle: TextStyle(
          color: scheme.primary, fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelTextStyle: const TextStyle(fontSize: 12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
      filled: true,
      fillColor: light ? Colors.white : scheme.surfaceContainerHigh,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
