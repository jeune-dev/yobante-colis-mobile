import 'package:flutter/material.dart';

/// Palette tirée du pictogramme Yobante : bleu marine #053D8F et jaune #F6C537.
/// Les autres teintes en sont des déclinaisons (plus claires ou plus foncées),
/// à l'exception du rouge et du vert réservés aux erreurs et aux succès.
class AppColor {
  AppColor._();

  // ── Couleurs du pictogramme ────────────────────────────────────────────────
  static const Color kPrimary = Color(0xFF053D8F);
  static const Color kSecondary = Color(0xFFF6C537);

  // ── Déclinaisons du bleu ───────────────────────────────────────────────────
  static const Color kPrimaryDark = Color(0xFF032A63);
  static const Color kPrimaryMedium = Color(0xFF3A67A8);
  static const Color kPrimaryLight = Color(0xFFE7EDF6);

  // ── Déclinaisons du jaune ──────────────────────────────────────────────────
  static const Color kSecondaryDark = Color(0xFFB88A0C);
  static const Color kSecondaryLight = Color(0xFFFEF6DD);

  // ── États (messages, pastilles de statut) ──────────────────────────────────
  static const Color kSucces = Color(0xFF1E8E4E);
  static const Color kErreur = Color(0xFFC62828);

  /// Attente, action requise : jaune foncé de la marque (lisible sur fond blanc).
  static const Color kAlerte = kSecondaryDark;

  /// Information, étape en cours : bleu de la marque.
  static const Color kInfo = kPrimaryMedium;

  // ── Neutres ────────────────────────────────────────────────────────────────
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kGrayscale40 = Color.fromARGB(255, 97, 97, 97);
  static const Color kLine = Color(0xFFE3E8F0);
  static const Color kGrayscaleDark100 = Color(0xFF1C1C1E);

  /// Fond des écrans : blanc légèrement teinté de bleu.
  static const Color kBackground = Color(0xFFF5F7FB);
}
