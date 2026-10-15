import 'package:flutter/material.dart';

class VaultColors {
  static const background = Color(0xFF0D0F17);
  static const sidebar = Color(0xFF11131D);
  static const surface = Color(0xFF171A25);
  static const surfaceRaised = Color(0xFF1C1F2B);
  static const outline = Color(0xFF292D3B);
  static const outlineSoft = Color(0xFF222632);
  static const text = Color(0xFFF0F1F8);
  static const muted = Color(0xFF9499AD);
  static const faint = Color(0xFF666C81);
  static const violet = Color(0xFF9B83FF);
  static const violetDeep = Color(0xFF775FE6);
  static const cyan = Color(0xFF54D8D0);
  static const blue = Color(0xFF78A9FF);
  static const green = Color(0xFF51D7A2);
  static const amber = Color(0xFFFFC56E);
  static const red = Color(0xFFFF777F);
  static const pink = Color(0xFFFF86B0);
}

Color accentFor(String accent) => switch (accent) {
  'cyan' => VaultColors.cyan,
  'rose' => VaultColors.pink,
  _ => VaultColors.violet,
};

ThemeData buildVaultTheme({required bool light, required String accent}) {
  final primary = accentFor(accent);
  final background = light ? const Color(0xFFF4F5F9) : VaultColors.background;
  final surface = light ? Colors.white : VaultColors.surface;
  final foreground = light ? const Color(0xFF171923) : VaultColors.text;
  final muted = light ? const Color(0xFF6D7182) : VaultColors.muted;
  final outline = light ? const Color(0xFFE3E5EE) : VaultColors.outline;
  final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: light ? Brightness.light : Brightness.dark).copyWith(
    primary: primary,
    secondary: VaultColors.cyan,
    surface: surface,
    onSurface: foreground,
    outline: outline,
    error: VaultColors.red,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: light ? Brightness.light : Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    dividerColor: outline,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    textTheme: ThemeData(brightness: light ? Brightness.light : Brightness.dark).textTheme.apply(bodyColor: foreground, displayColor: foreground).copyWith(
      bodyMedium: TextStyle(color: foreground, fontSize: 13, height: 1.45),
      bodySmall: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
      titleMedium: TextStyle(color: foreground, fontWeight: FontWeight.w700, fontSize: 15),
      titleLarge: TextStyle(color: foreground, fontWeight: FontWeight.w800, fontSize: 21, letterSpacing: -0.4),
      headlineSmall: TextStyle(color: foreground, fontWeight: FontWeight.w800, fontSize: 27, letterSpacing: -0.8),
    ),
    appBarTheme: AppBarTheme(backgroundColor: background, foregroundColor: foreground, elevation: 0, surfaceTintColor: Colors.transparent, titleTextStyle: TextStyle(color: foreground, fontSize: 15, fontWeight: FontWeight.w700)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: light ? const Color(0xFFF7F8FB) : const Color(0xFF11141D),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: TextStyle(color: muted.withValues(alpha: .72), fontSize: 13),
      labelStyle: TextStyle(color: muted, fontSize: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary, width: 1.2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VaultColors.red)),
    ),
    cardTheme: CardThemeData(color: surface, surfaceTintColor: Colors.transparent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: outline))),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: surface, indicatorColor: primary.withValues(alpha: .16), labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(fontSize: 10, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500, color: states.contains(WidgetState.selected) ? primary : muted))),
    snackBarTheme: SnackBarThemeData(backgroundColor: const Color(0xFF252938), contentTextStyle: const TextStyle(color: VaultColors.text), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
  );
}
