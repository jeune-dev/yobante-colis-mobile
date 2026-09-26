import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_color.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    // Schéma construit sur les deux couleurs du pictogramme
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColor.kPrimary,
      primary: AppColor.kPrimary,
      onPrimary: AppColor.kWhite,
      primaryContainer: AppColor.kPrimaryLight,
      onPrimaryContainer: AppColor.kPrimaryDark,
      secondary: AppColor.kSecondary,
      onSecondary: AppColor.kPrimary,
      secondaryContainer: AppColor.kSecondaryLight,
      onSecondaryContainer: AppColor.kPrimaryDark,
      error: AppColor.kErreur,
      surface: AppColor.kWhite,
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: AppColor.kPrimary,
      scaffoldBackgroundColor: AppColor.kBackground,

      // AppBar blanche, titre et icônes au bleu de la marque
      appBarTheme: AppBarTheme(
        backgroundColor: AppColor.kWhite,
        foregroundColor: AppColor.kPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColor.kPrimary.withValues(alpha: 0.12),
        iconTheme: const IconThemeData(color: AppColor.kPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColor.kPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),

      // Onglets : texte bleu, trait jaune
      tabBarTheme: TabBarThemeData(
        labelColor: AppColor.kPrimary,
        unselectedLabelColor: AppColor.kGrayscale40,
        indicatorColor: AppColor.kSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColor.kLine,
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 14),
      ),

      // Bouton flottant jaune, icône bleue (comme le carré jaune du pictogramme)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColor.kSecondary,
        foregroundColor: AppColor.kPrimary,
      ),

      // Puces de choix : sélection en jaune clair, texte bleu
      chipTheme: ChipThemeData(
        selectedColor: AppColor.kSecondaryLight,
        backgroundColor: AppColor.kWhite,
        side: const BorderSide(color: AppColor.kLine),
        checkmarkColor: AppColor.kPrimary,
        labelStyle: GoogleFonts.plusJakartaSans(color: AppColor.kPrimary, fontWeight: FontWeight.w600, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Boutons segmentés : segment choisi en jaune
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? AppColor.kSecondary : AppColor.kWhite),
          foregroundColor: const WidgetStatePropertyAll(AppColor.kPrimary),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColor.kPrimary)),
        ),
      ),

      // Interrupteurs : piste bleue, pastille jaune
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColor.kSecondary : AppColor.kWhite),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColor.kPrimary : AppColor.kLine),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColor.kPrimary : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(AppColor.kSecondary),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColor.kPrimary,
        linearTrackColor: AppColor.kSecondaryLight,
      ),

      dividerTheme: const DividerThemeData(color: AppColor.kLine, space: 1),

      listTileTheme: const ListTileThemeData(iconColor: AppColor.kPrimary),

      drawerTheme: const DrawerThemeData(backgroundColor: AppColor.kWhite),

      // Boutons
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

      // Champs de saisie
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

      // SnackBar stylé
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColor.kGrayscaleDark100,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Typographie générale
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: AppColor.kGrayscaleDark100,
        displayColor: AppColor.kGrayscaleDark100,
      ),

      // Barre de navigation : indicateur jaune façon transporteur express
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColor.kSecondary.withValues(alpha: 0.35),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? AppColor.kPrimary : AppColor.kGrayscale40,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? AppColor.kPrimary : AppColor.kGrayscale40,
            )),
      ),
    );
  }
}

