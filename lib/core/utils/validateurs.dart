import '../i18n/langue.dart';
import 'formatters.dart';

/// Contrôles de saisie alignés sur les schémas de validation du backend
/// (CONTRAT-API-MOBILE.md) : longueurs, formats et champs obligatoires. Un champ
/// refusé ici l'aurait été par l'API avec une erreur 400.

/// Texte libre : obligatoire ou non, bornes min / max en caractères.
String? Function(String?) texte({bool requis = false, int? min, int? max, String? message}) => (v) {
      final t = v?.trim() ?? '';
      if (t.isEmpty) return requis ? (message ?? tr('Champ requis')) : null;
      if (min != null && t.length < min) return tr('Au moins $min caractères');
      if (max != null && t.length > max) return tr('$max caractères maximum');
      return null;
    };

final _email = RegExp(r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$");

/// Adresse email (150 caractères au plus).
String? Function(String?) email({bool requis = true}) => (v) {
      final t = v?.trim() ?? '';
      if (t.isEmpty) return requis ? tr('Email requis') : null;
      if (t.length > 150) return tr('150 caractères maximum');
      if (!_email.hasMatch(t)) return tr('Email invalide');
      return null;
    };

/// Téléphone France ou Sénégal, obligatoire ou non.
String? Function(String?) telephone({bool requis = true}) => (v) {
      if ((v?.trim() ?? '').isEmpty) return requis ? tr('Numéro requis') : null;
      return validerTelephone(v);
    };

/// Règle de mot de passe du backend : 8 à 72 caractères, au moins une majuscule,
/// un chiffre et un caractère spécial (tout ce qui n'est ni lettre ni chiffre).
class RegleMotDePasse {
  static bool longueur(String v) => v.length >= 8 && v.length <= 72;
  static bool majuscule(String v) => v.contains(RegExp(r'[A-Z]'));
  static bool chiffre(String v) => v.contains(RegExp(r'[0-9]'));
  static bool special(String v) => v.contains(RegExp(r'[^A-Za-z0-9]'));
  static bool valide(String v) => longueur(v) && majuscule(v) && chiffre(v) && special(v);
}

String? motDePasse(String? v) {
  final t = v ?? '';
  if (t.isEmpty) return tr('Mot de passe requis');
  if (t.length > 72) return tr('72 caractères maximum');
  if (!RegleMotDePasse.valide(t)) {
    return tr('8 caractères minimum, avec une majuscule, un chiffre et un caractère spécial');
  }
  return null;
}

/// Code postal : 5 chiffres en France ; 10 caractères au plus ailleurs.
String? Function(String?) codePostal({String? pays, bool requis = false}) => (v) {
      final t = v?.trim() ?? '';
      if (t.isEmpty) return requis ? tr('Code postal requis') : null;
      if (pays == 'FR' && !RegExp(r'^\d{5}$').hasMatch(t)) return tr('Code postal à 5 chiffres');
      if (t.length > 10) return tr('10 caractères maximum');
      return null;
    };

/// Code à 6 chiffres (réinitialisation du mot de passe, vérification du numéro).
String? codeSixChiffres(String? v) =>
    RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '') ? null : tr('Code à 6 chiffres');

/// Nombre décimal (virgule acceptée) entre [min] et [max].
String? Function(String?) nombre({bool requis = false, double min = 0, double? max, bool strictementPositif = false}) =>
    (v) {
      final t = v?.trim() ?? '';
      if (t.isEmpty) return requis ? tr('Valeur requise') : null;
      final n = double.tryParse(t.replaceAll(',', '.'));
      if (n == null) return tr('Nombre invalide');
      if (strictementPositif ? n <= 0 : n < min) {
        return strictementPositif ? tr('Doit être supérieur à 0') : tr('Minimum $min');
      }
      if (max != null && n > max) return tr('Maximum ${max % 1 == 0 ? max.toInt() : max}');
      return null;
    };

/// Entier entre [min] et [max].
String? Function(String?) entier({bool requis = false, required int min, required int max}) => (v) {
      final t = v?.trim() ?? '';
      if (t.isEmpty) return requis ? tr('Valeur requise') : null;
      final n = int.tryParse(t);
      if (n == null) return tr('Nombre entier attendu');
      if (n < min || n > max) return tr('Entre $min et $max');
      return null;
    };

/// Combine plusieurs contrôles : le premier message d'erreur l'emporte.
String? Function(String?) tous(List<String? Function(String?)> controles) => (v) {
      for (final c in controles) {
        final m = c(v);
        if (m != null) return m;
      }
      return null;
    };
