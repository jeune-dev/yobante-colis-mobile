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
        backgroundColor: AppColor.kBackground,
        foregroundColor: AppColor.kPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColor.kPrimary.withValues(alpha: 0.15),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColor.kPrimary, size: 22),
        actionsIconTheme: const IconThemeData(color: AppColor.kPrimary, size: 22),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColor.kPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),

      // Onglets : texte bleu, trait jaune
      tabBarTheme: TabBarThemeData(
        labelColor: AppColor.kPrimary,
        unselectedLabelColor: AppColor.kGrayscale40,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColor.kSecondary, width: 3),
          borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
        ),
        indicatorSize: TabBarIndicatorSize.label,
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
        selectedColor: AppColor.kPrimary,
        backgroundColor: AppColor.kWhite,
        side: WidgetStateBorderSide.resolveWith((s) =>
            BorderSide(color: s.contains(WidgetState.selected) ? AppColor.kPrimary : AppColor.kLine)),
        checkmarkColor: AppColor.kWhite,
        showCheckmark: false,
        // Couleur dépendant de l'état dans un style ordinaire : la puce la résout
        // elle-même (un WidgetStateTextStyle est perdu lors de la fusion avec les
        // styles par défaut, et le libellé devenait invisible).
        labelStyle: GoogleFonts.plusJakartaSans(
          color: WidgetStateColor.resolveWith(
              (s) => s.contains(WidgetState.selected) ? AppColor.kWhite : AppColor.kPrimary),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Boutons segmentés : segment choisi en jaune
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? AppColor.kPrimary : AppColor.kWhite),
          foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? AppColor.kWhite : AppColor.kPrimary),
          iconColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? AppColor.kSecondary : AppColor.kPrimary),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColor.kLine)),
          textStyle: WidgetStatePropertyAll(GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

      listTileTheme: ListTileThemeData(
        iconColor: AppColor.kPrimary,
        titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.kGrayscaleDark100),
        subtitleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      cardTheme: CardThemeData(
        color: AppColor.kWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColor.kLine),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColor.kWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColor.kGrayscaleDark100),
        contentTextStyle: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5, color: AppColor.kGrayscaleDark100),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColor.kWhite,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColor.kLine,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColor.kWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColor.kGrayscaleDark100),
      ),

      drawerTheme: const DrawerThemeData(backgroundColor: AppColor.kWhite),

      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.kPrimary,
          foregroundColor: AppColor.kWhite,
          disabledBackgroundColor: AppColor.kPrimary.withValues(alpha: 0.4),
          disabledForegroundColor: AppColor.kWhite,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          elevation: 0,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.kPrimary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          side: const BorderSide(color: AppColor.kPrimary, width: 1.3),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.kPrimary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        prefixIconColor: AppColor.kPrimary,
        suffixIconColor: AppColor.kGrayscale40,
        floatingLabelStyle: GoogleFonts.plusJakartaSans(color: AppColor.kPrimary, fontWeight: FontWeight.w600),
        errorStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kErreur),
        errorMaxLines: 2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColor.kLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColor.kPrimary, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColor.kLine),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColor.kErreur),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColor.kErreur, width: 1.5),
        ),
      ),

      // SnackBar stylé
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColor.kPrimaryDark,
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
        backgroundColor: AppColor.kWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColor.kPrimary.withValues(alpha: 0.1),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

