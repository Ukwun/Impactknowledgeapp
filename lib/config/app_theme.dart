import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Primary palette (teal-green) ─────────────────────────────
  static const Color primary50 = Color(0xFFE8F5F1);
  static const Color primary100 = Color(0xFFC7E9E1);
  static const Color primary200 = Color(0xFFA5DDD0);
  static const Color primary300 = Color(0xFF6ECFC0);
  static const Color primary400 = Color(0xFF48C5B0);
  static const Color primary500 = Color(0xFF1FA774);
  static const Color primary600 = Color(0xFF1A926A);
  static const Color primary700 = Color(0xFF157D52);

  // ── Secondary palette (amber/gold) ───────────────────────────
  static const Color secondary500 = Color(0xFFF5B400);
  static const Color secondary400 = Color(0xFFFDE28D);
  static const Color secondary600 = Color(0xFFD99C00);

  // ── Dark palette (navy-dark background) ──────────────────────
  static const Color dark900 = Color(0xFF051E3B);
  static const Color dark800 = Color(0xFF082643);
  static const Color dark700 = Color(0xFF092E4B);
  static const Color dark600 = Color(0xFF0A3553);
  static const Color dark500 = Color(0xFF0B3C5D);
  static const Color dark400 = Color(0xFF8A97B8);
  static const Color dark300 = Color(0xFFB1B9CF);

  // ── Text ─────────────────────────────────────────────────────
  static const Color textMain = Color(0xFF1F2933);
  static const Color textLight = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textGray400 = Color(0xFFA3A8B3);

  // ── Danger ───────────────────────────────────────────────────
  static const Color danger500 = Color(0xFFD64545);

  // ── Gradients ────────────────────────────────────────────────
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [dark900, dark800, dark700],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary600, primary500],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5B041), Color(0xFFFCD34D), Color(0xFFF59E0B)],
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [dark600, dark700],
  );

  // ── Shared decorations ────────────────────────────────────────
  /// Standard dark card used throughout the app (mirrors web Card dark variant)
  static BoxDecoration darkCard({Color? borderColor, double radius = 16}) =>
      BoxDecoration(
        color: dark700.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? dark400.withValues(alpha: 0.4),
          width: 1.5,
        ),
      );

  /// Standard input decoration for dark-background forms
  static InputDecoration darkInput({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: textMuted, fontSize: 14),
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: dark600,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: dark400, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: dark400, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: primary500, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: danger500, width: 1.5),
    ),
  );

  static ThemeData darkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: dark800,
      colorScheme: const ColorScheme.dark(
        primary: primary500,
        secondary: secondary500,
        surface: dark700,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(
        base.textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: dark700,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark600,
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dark400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dark400, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary500, width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: dark700,
        selectedItemColor: primary500,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData lightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: dark800,
      colorScheme: const ColorScheme.dark(
        primary: primary500,
        secondary: secondary500,
        surface: dark700,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.sora(
          fontWeight: FontWeight.w700,
          fontSize: 64,
          height: 72 / 64,
          letterSpacing: -1.2,
        ),
        displayMedium: GoogleFonts.sora(
          fontWeight: FontWeight.w700,
          fontSize: 48,
          height: 56 / 48,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.sora(
          fontWeight: FontWeight.w700,
          fontSize: 32,
          height: 40 / 32,
        ),
        headlineLarge: GoogleFonts.sora(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          height: 32 / 24,
        ),
        headlineMedium: GoogleFonts.sora(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          height: 28 / 20,
        ),
        headlineSmall: GoogleFonts.sora(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          height: 24 / 16,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, height: 24 / 16),
        bodyMedium: GoogleFonts.inter(fontSize: 14, height: 20 / 14),
        bodySmall: GoogleFonts.inter(fontSize: 12, height: 16 / 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary500,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary500, width: 1.5),
        ),
      ),
    );
  }
}
