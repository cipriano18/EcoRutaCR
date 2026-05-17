import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return _buildTheme(brightness: Brightness.light);
  }

  static ThemeData get darkTheme {
    return _buildTheme(brightness: Brightness.dark);
  }

  static ThemeData _buildTheme({required Brightness brightness}) {
    const brandGreen = Color(0xFF52B788);
    const deepGreen = Color(0xFF041710);
    const forestSurface = Color(0xFF0B261D);
    const tonalSurface = Color(0xFF132F25);
    const surfaceLift = Color(0xFF1B4332);
    const accentMint = Color(0xFF75DAA8);
    const accentOrange = Color(0xFFFF7043);
    final isDark = brightness == Brightness.dark;
    final scaffoldColor = isDark ? deepGreen : const Color(0xFFF6F7F4);
    final surfaceColor = isDark ? forestSurface : Colors.white;
    final softSurfaceColor = isDark ? tonalSurface : const Color(0xFFF1F4F0);
    final borderColor = isDark ? surfaceLift : const Color(0xFFD9E1DC);
    final headlineColor = isDark
        ? const Color(0xFFE8F5E9)
        : const Color(0xFF0D2B20);
    final bodyLargeColor = isDark
        ? const Color(0xFFD1DED6)
        : const Color(0xFF476056);
    final bodyMediumColor = isDark
        ? const Color(0xFFB6C7BE)
        : const Color(0xFF61786F);
    final labelColor = isDark ? accentMint : const Color(0xFF547065);
    final titleColor = isDark
        ? const Color(0xFFDDE9E1)
        : const Color(0xFF17392D);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: brandGreen,
          brightness: brightness,
        ).copyWith(
          primary: brandGreen,
          onPrimary: deepGreen,
          secondary: accentOrange,
          onSecondary: deepGreen,
          surface: surfaceColor,
          onSurface: headlineColor,
          outline: borderColor,
          shadow: isDark ? const Color(0x66020B08) : const Color(0x14012D1D),
        );
    final baseTextTheme = ThemeData(brightness: brightness).textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme).copyWith(
      headlineLarge: GoogleFonts.hankenGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: headlineColor,
      ),
      headlineMedium: GoogleFonts.hankenGrotesk(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: headlineColor,
      ),
      headlineSmall: GoogleFonts.hankenGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: headlineColor,
      ),
      titleMedium: GoogleFonts.hankenGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: titleColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: bodyLargeColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: bodyMediumColor,
      ),
      labelLarge: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: 0.7,
        color: labelColor,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldColor,
      colorScheme: scheme,
      dividerColor: borderColor,
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? deepGreen : softSurfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brandGreen, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE57373)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.4),
        ),
        labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentOrange,
          foregroundColor: deepGreen,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? accentMint : brandGreen,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? forestSurface : const Color(0xFFF4F7F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: borderColor),
        ),
      ),
    );
  }
}
