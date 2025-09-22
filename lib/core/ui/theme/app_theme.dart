// lib/core/ui/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const _primary = Color(0xFF1F2931);
  static const _secondary = Colors.teal;
  static const _accent = Colors.tealAccent;
  static const _error = Colors.redAccent;

  // -------- DARK --------
  static const _surfaceDark = Color(0xFF344049);
  static const _scaffoldDark = Color(0xFF2A343C);

  static const ColorScheme _schemeDark = ColorScheme.dark(
    primary: _primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF2A343C),
    onPrimaryContainer: Colors.white,
    secondary: _secondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF004D40),
    onSecondaryContainer: Colors.white,
    surface: _surfaceDark,
    onSurface: Colors.white,
    surfaceVariant: Color(0xFF3A444D),
    onSurfaceVariant: Colors.white70,
    error: _error,
    onError: Colors.white,
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Colors.white,
    background: _scaffoldDark,
    onBackground: Colors.white,
    outline: Color(0xFF8D9199),
    outlineVariant: Color(0xFF43474E),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFE1E2E8),
    onInverseSurface: Color(0xFF1A1C1E),
    inversePrimary: _secondary,
    surfaceTint: Colors.transparent,
  );

  static ThemeData get dark {
    final baseTheme = ThemeData.dark();
    final textTheme =
    _buildTextTheme(baseTheme.textTheme, _schemeDark.onSurface);

    final OutlineInputBorder _commonBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0x3CFFFFFF),
        width: 1.2,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _schemeDark,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: textTheme.titleMedium,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: _schemeDark.surface,
        scrimColor: Colors.black54,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: _accent,
        unselectedItemColor: Colors.grey,
        selectedIconTheme: const IconThemeData(size: 28),
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400),
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _secondary,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
      ),
      cardTheme: const CardThemeData(
        color: _surfaceDark,
        shadowColor: Colors.black,
        elevation: 4,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Colors.white,
        ),
        contentTextStyle: GoogleFonts.inter(color: Colors.white70),
      ),
      listTileTheme: ListTileThemeData(
        textColor: _schemeDark.onSurface,
        iconColor: _schemeDark.secondary,
        tileColor: Colors.transparent,
        selectedTileColor: _schemeDark.primary.withOpacity(0.1),
        selectedColor: _schemeDark.secondary,
      ),
      dividerTheme: DividerThemeData(
        color: _schemeDark.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Colors.tealAccent,
        selectionColor: Colors.tealAccent.withOpacity(0.35),
        selectionHandleColor: Colors.tealAccent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: false,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white60),
        prefixIconColor: Colors.white70,
        suffixIconColor: Colors.white70,
        enabledBorder: _commonBorder,
        focusedBorder: _commonBorder,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const MaterialStatePropertyAll<Size>(Size.fromHeight(44)),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          backgroundColor: const MaterialStatePropertyAll<Color>(_secondary),
          foregroundColor: const MaterialStatePropertyAll<Color>(Colors.white),
          textStyle: MaterialStatePropertyAll(
              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          elevation: const MaterialStatePropertyAll<double>(2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const MaterialStatePropertyAll<Size>(Size.fromHeight(44)),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          backgroundColor: const MaterialStatePropertyAll<Color>(_secondary),
          foregroundColor: const MaterialStatePropertyAll<Color>(Colors.white),
          textStyle: MaterialStatePropertyAll(
              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          elevation: const MaterialStatePropertyAll<double>(2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor:
          const MaterialStatePropertyAll<Color>(Colors.tealAccent),
          textStyle: MaterialStatePropertyAll(
              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const MaterialStatePropertyAll<Size>(Size.fromHeight(44)),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          side: const MaterialStatePropertyAll(
            BorderSide(color: Color(0x5AFFFFFF), width: 1.2),
          ),
          foregroundColor: const MaterialStatePropertyAll<Color>(Colors.white),
          textStyle: MaterialStatePropertyAll(
              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: _primary,
        contentTextStyle: TextStyle(color: Colors.white),
        actionTextColor: Colors.tealAccent,
        behavior: SnackBarBehavior.floating,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // -------- LIGHT --------
  static const _backgroundLight = Color(0xFFF6F8FA);
  static const _surfaceLight = Colors.white;

  static const ColorScheme _schemeLight = ColorScheme.light(
    primary: _primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE2E8F0),
    onPrimaryContainer: _primary,
    secondary: _secondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFC8FFF4),
    onSecondaryContainer: Color(0xFF00332E),
    surface: _surfaceLight,
    onSurface: Color(0xFF1A1C1E),
    surfaceVariant: Color(0xFF3D4248),
    onSurfaceVariant: Color(0xFF3D4248),
    error: _error,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: _backgroundLight,
    onBackground: Color(0xFF111317),
    outline: Color(0xFFCBD5E1),
    outlineVariant: Color(0xFFE2E8F0),
    shadow: Colors.black12,
    scrim: Colors.black54,
    inverseSurface: Color(0xFF2B2F33),
    onInverseSurface: Colors.white,
    inversePrimary: _secondary,
    surfaceTint: Colors.transparent,
  );

  static ThemeData get light {
    final baseTheme = ThemeData.light();
    final textTheme =
    _buildTextTheme(baseTheme.textTheme, _schemeLight.onSurface);

    final OutlineInputBorder _enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
    );
    final OutlineInputBorder _focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primary, width: 1.6),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _schemeLight,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: textTheme.titleMedium,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: _surfaceLight,
        scrimColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: _accent,
        unselectedItemColor: _schemeLight.onSurfaceVariant,
        selectedIconTheme: const IconThemeData(size: 28),
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400),
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _secondary,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
      ),
      cardTheme: CardThemeData(
        color: _surfaceLight,
        shadowColor: Colors.black.withOpacity(0.08),
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: _schemeLight.outline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceLight,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _schemeLight.outline),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: _schemeLight.onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(color: _schemeLight.onSurfaceVariant),
      ),
      listTileTheme: ListTileThemeData(
        textColor: _schemeLight.onSurface,
        iconColor: _schemeLight.primary,
        tileColor: Colors.transparent,
        selectedTileColor: _schemeLight.primary.withOpacity(0.08),
        selectedColor: _schemeLight.primary,
      ),
      dividerTheme: DividerThemeData(
        color: _schemeLight.outline,
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: _secondary.shade400,
        selectionColor: _secondary.shade200.withOpacity(0.35),
        selectionHandleColor: _secondary.shade400,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: false,
        labelStyle: TextStyle(color: _schemeLight.onSurfaceVariant),
        hintStyle: TextStyle(color: _schemeLight.onSurfaceVariant.withOpacity(0.8)),
        prefixIconColor: _schemeLight.onSurfaceVariant,
        suffixIconColor: _schemeLight.onSurfaceVariant,
        enabledBorder: _enabledBorder,
        focusedBorder: _focusedBorder,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const MaterialStatePropertyAll<Size>(Size.fromHeight(44)),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          backgroundColor: const MaterialStatePropertyAll<Color>(_primary),
          foregroundColor: const MaterialStatePropertyAll<Color>(Colors.white),
          textStyle: MaterialStatePropertyAll(
              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          elevation: const MaterialStatePropertyAll<double>(2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const MaterialStatePropertyAll<Size>(Size.fromHeight(44)),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          backgroundColor: const MaterialStatePropertyAll<Color>(_primary),
          foregroundColor: const MaterialStatePropertyAll<Color>(Colors.white),
          textStyle: MaterialStatePropertyAll(
              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          elevation: const MaterialStatePropertyAll<double>(2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const MaterialStatePropertyAll<Color>(_primary),
          textStyle: MaterialStatePropertyAll(
              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const MaterialStatePropertyAll<Size>(Size.fromHeight(44)),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          side: const MaterialStatePropertyAll(
            BorderSide(color: _primary, width: 1.2),
          ),
          foregroundColor: const MaterialStatePropertyAll<Color>(_primary),
          textStyle: MaterialStatePropertyAll(
              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: _primary,
        contentTextStyle: TextStyle(color: Colors.white),
        actionTextColor: Colors.white,
        behavior: SnackBarBehavior.floating,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Color color) {
    var theme = GoogleFonts.poppinsTextTheme(base);
    theme = theme.copyWith(
      bodyLarge: GoogleFonts.inter(textStyle: theme.bodyLarge, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.inter(textStyle: theme.bodyMedium, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.inter(textStyle: theme.bodySmall, fontWeight: FontWeight.w400),
    );
    return theme.copyWith(
      headlineLarge: theme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: theme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: theme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: theme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: theme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: theme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: theme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ).apply(
      displayColor: color,
      bodyColor: color,
    );
  }
}