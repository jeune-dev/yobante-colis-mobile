import 'package:intl/intl.dart';
import '../i18n/langue.dart';

/// Montants et dates affichés dans l'application : l'euro garde ses centimes,
/// le franc CFA n'en a pas (« 40,00 € », « 26 238 FCFA »).
String formaterMontant(num? montant, String? devise) {
  final valeur = (montant ?? 0).toDouble();
  if (devise == 'EUR') {
    return '${NumberFormat.currency(locale: _locale, symbol: '', decimalDigits: 2).format(valeur).trim()} €';
  }
  return '${NumberFormat.decimalPattern(_locale).format(valeur.round())} FCFA';
}

/// Locale intl de la langue choisie (« fr_FR » ou « en_US »).
String get _locale => LangueApp.instance.value.localeIntl;

/// Formats de date dans la langue choisie : « 12 oct. 2026 à 14:30 » / « 12 Oct 2026, 14:30 ».
DateFormat formatDate() => DateFormat('dd MMM yyyy', _locale);
DateFormat formatDateHeure() =>
    DateFormat(LangueApp.instance.estAnglais ? 'dd MMM yyyy, HH:mm' : 'dd MMM yyyy à HH:mm', _locale);
DateFormat formatJourHeure() => DateFormat('dd MMM, HH:mm', _locale);
DateFormat formatDateCourte() => DateFormat(LangueApp.instance.estAnglais ? 'MM/dd/yyyy' : 'dd/MM/yyyy', _locale);

/// Date lisible à partir d'une chaîne ISO (ou d'un AAAA-MM-JJ) ; renvoie la
/// valeur brute si elle n'est pas interprétable.
String formaterDate(String? iso, {bool avecHeure = false}) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return (avecHeure ? formatDateHeure() : formatDate()).format(d.toLocal());
}

/// Numéro de téléphone débarrassé des espaces, tirets et points de saisie.
String nettoyerTelephone(String brut) => brut.trim().replaceAll(RegExp(r'[\s\-.()]'), '');

/// Numéro au format international exigé par le backend (France ou Sénégal) :
/// « 77 123 45 67 » → +221771234567, « 06 12 34 56 78 » → +33612345678,
/// « 0033… » → +33… ; un numéro déjà international est conservé.
String normaliserTelephone(String brut, {String paysParDefaut = 'SN'}) {
  var n = nettoyerTelephone(brut);
  if (n.startsWith('00')) n = '+${n.substring(2)}';
  if (n.startsWith('+')) return n;
  if (RegExp(r'^7\d{8}$').hasMatch(n) || RegExp(r'^3\d{8}$').hasMatch(n)) return '+221$n';
  if (RegExp(r'^0\d{9}$').hasMatch(n)) return '+33${n.substring(1)}';
  if (RegExp(r'^221\d{9}$').hasMatch(n) || RegExp(r'^33\d{9}$').hasMatch(n)) return '+$n';
  return paysParDefaut == 'FR' && RegExp(r'^\d{9}$').hasMatch(n) ? '+33$n' : n;
}

/// Contrôle de format côté application, avant l'appel au backend.
String? validerTelephone(String? v) {
  if (v == null || v.trim().isEmpty) return tr('Numéro requis');
  final n = normaliserTelephone(v);
  if (!RegExp(r'^\+(33\d{9}|221\d{9})$').hasMatch(n)) {
    return tr('Numéro français (+33) ou sénégalais (+221) attendu');
  }
  return null;
}
