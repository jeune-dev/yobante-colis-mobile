/// normalisation_nom.dart — Forme d'écriture des noms de personnes.
///
/// Règle unique, la même que côté serveur (`utils/normaliserNom.js`) :
///
///   • le PRÉNOM porte une majuscule initiale à chaque élément — « awa » et
///     « AWA » deviennent « Awa », « jean-pierre » devient « Jean-Pierre » ;
///   • le NOM DE FAMILLE s'écrit intégralement en capitales — « diop »
///     devient « DIOP ».
///
/// C'est la convention administrative française et ouest-africaine : sur un
/// contrat, elle lève l'ambiguïté entre le nom et le prénom, y compris quand
/// les deux peuvent être l'un ou l'autre (« Fall Amadou » / « Amadou Fall »).
///
/// Le serveur reste l'autorité — il normalise à l'écriture, quel que soit le
/// client. Ici, la mise en forme est appliquée PENDANT LA FRAPPE : l'écran
/// montre alors ce qui sera réellement enregistré, au lieu de laisser
/// l'utilisateur découvrir après coup que son nom a changé d'allure.
///
/// ⚠️ Les séparateurs internes sont préservés : espace, trait d'union et
/// apostrophe séparent des éléments qui prennent chacun leur majuscule
/// (« n'diaye » → « N'Diaye » côté prénom), mais ne sont jamais ajoutés ni
/// retirés — un nom n'appartient qu'à celui qui le porte.
library;

import 'package:flutter/services.dart';

/// Séparateurs qui, à l'intérieur d'un nom, ouvrent un nouvel élément.
final RegExp _separateurs = RegExp(r"[\s\-'’]");

/// Prénom : majuscule initiale sur chaque élément, le reste en minuscules.
///
/// La saisie n'est pas rognée : couper les espaces pendant la frappe
/// empêcherait de taper un prénom composé, le doigt restant bloqué avant la
/// seconde partie. Le rognage se fait à l'envoi.
String normaliserPrenom(String valeur) {
  if (valeur.isEmpty) return valeur;

  final tampon = StringBuffer();
  var debutElement = true;

  for (final caractere in valeur.split('')) {
    if (_separateurs.hasMatch(caractere)) {
      tampon.write(caractere);
      debutElement = true;
      continue;
    }
    tampon.write(debutElement ? caractere.toUpperCase() : caractere.toLowerCase());
    debutElement = false;
  }

  return tampon.toString();
}

/// Nom de famille : tout en capitales.
String normaliserNomFamille(String valeur) => valeur.toUpperCase();

/// Met en forme un prénom au fil de la frappe.
///
/// La position du curseur est conservée : la longueur du texte ne change
/// jamais, seule la casse évolue, donc l'offset reste valable.
class FormateurPrenom extends TextInputFormatter {
  const FormateurPrenom();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue ancien,
    TextEditingValue nouveau,
  ) {
    final texte = normaliserPrenom(nouveau.text);
    if (texte == nouveau.text) return nouveau;
    return TextEditingValue(
      text: texte,
      selection: nouveau.selection,
      composing: TextRange.empty,
    );
  }
}

/// Met en forme un nom de famille au fil de la frappe.
class FormateurNomFamille extends TextInputFormatter {
  const FormateurNomFamille();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue ancien,
    TextEditingValue nouveau,
  ) {
    final texte = normaliserNomFamille(nouveau.text);
    if (texte == nouveau.text) return nouveau;
    return TextEditingValue(
      text: texte,
      selection: nouveau.selection,
      composing: TextRange.empty,
    );
  }
}
