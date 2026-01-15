import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- PREMIUM LIGHT-ONLY PALETTE ---
class AppColors {
  // Brand Base
  static const Color primaryBrand = Color(0xFF2563EB); // Royal Blue (Intellectual)
  static const Color primaryAccent = Color(0xFF4F46E5); // Indigo
  
  // Pastel Accents (for gradients & buttons)
  static const Color accentSoftBlue = Color(0xFFE0F2FE);
  static const Color accentSoftPurple = Color(0xFFF3E8FF);
  static const Color accentSoftTeal = Color(0xFFCCFBF1);
  static const Color accentSoftPink = Color(0xFFFCE7F3);
  
  // Functional
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);

  // Surface & Backgrounds (High White-Space)
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  
  // Text & Content - High Contrast & Clarity
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400

  // Legacy/Backward Compat
  static const Color primaryLight = primaryBrand;
  static const Color primaryDark = primaryBrand;
  static const Color primary = primaryBrand;
  static const Color accent = primaryAccent;

  // Missing Legacy
  static const Color backgroundLight = background;
  static const Color info = primaryBrand;
  static const Color secondary = primaryAccent;
}

class AppTheme {
  
  // --- TYPOGRAPHY (Outfit + Inter) ---
  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -1.0, height: 1.1,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -0.5, height: 1.2,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.2,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.2,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryBrand, letterSpacing: 0.5,
      ),
    );
  }

  // --- LIGHT THEME ONLY ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Colors
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBrand,
      primary: AppColors.primaryBrand,
      secondary: AppColors.primaryAccent,
      background: AppColors.background,
      surface: AppColors.surface,
      error: AppColors.error,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
    
    // Typography
    textTheme: _buildTextTheme(),
    
    // AppBar - Transparent & Clean
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    
    // Cards - Soft Elevation & Clean
    cardTheme: CardTheme(
      color: Colors.white,
      shadowColor: const Color(0xFF64748B).withOpacity(0.08),
      elevation: 10,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    
    // Inputs - Pill/Box Hybrid
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      hintStyle: GoogleFonts.inter(color: AppColors.textTertiary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.primaryBrand, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
    ),

    // Buttons - Tactile & Vibrant
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBrand,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: AppColors.primaryBrand.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryBrand,
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      ),
    ),

    // FAB - Floating Jewel
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryBrand,
      foregroundColor: Colors.white,
      elevation: 8,
      focusElevation: 10,
      hoverElevation: 10,
      splashColor: Colors.white.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    
    dividerTheme: DividerThemeData(
      color: Colors.grey[200],
      thickness: 1,
    ),
    
    iconTheme: const IconThemeData(
      color: AppColors.textPrimary,
      size: 24,
    ),
  );

  // --- FORCE LIGHT (No Dark Mode) ---
  static final ThemeData darkTheme = lightTheme; 
}
