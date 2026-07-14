import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_color.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColor.kPrimary,
      primary: AppColor.kPrimary,
      surface: AppColor.kWhite,
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: AppColor.kPrimary,
      scaffoldBackgroundColor: AppColor.kWhite,

      // ðŸŒ¤ï¸ AppBar minimaliste
      appBarTheme: AppBarTheme(
        backgroundColor: AppColor.kWhite,
        foregroundColor: AppColor.kGrayscaleDark100,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColor.kGrayscaleDark100,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),

      // ðŸ§­ Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.kPrimary,
          foregroundColor: AppColor.kWhite,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          elevation: 5,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.kPrimary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          side: BorderSide(color: AppColor.kPrimary),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.kPrimary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),

      // âœï¸ TextField & FormField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.kBackground,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColor.kGrayscale40,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColor.kGrayscaleDark100,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColor.kLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColor.kPrimary, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColor.kLine),
        ),
      ),

      // ðŸ’¬ SnackBar stylÃ©
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColor.kGrayscaleDark100,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ðŸ“„ Typographie gÃ©nÃ©rale
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: AppColor.kGrayscaleDark100,
        displayColor: AppColor.kGrayscaleDark100,
      ),
    );
  }
}

