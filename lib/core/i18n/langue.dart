import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'traductions_en.dart';

/// Langues proposées dans l'application.
enum Langue {
  fr('fr', 'Français'),
  en('en', 'English');

  const Langue(this.code, this.libelle);
  final String code;

  /// Nom de la langue dans sa propre langue (affiché dans le sélecteur).
  final String libelle;

  Locale get locale => Locale(code, code == 'fr' ? 'FR' : 'US');

  /// Locale des formats de dates et de nombres (package intl).
  String get localeIntl => code == 'fr' ? 'fr_FR' : 'en_US';
}

/// Langue courante de l'application, choisie par l'utilisateur (français ou anglais).
///
/// Le choix est mémorisé sur le téléphone (il survit à la déconnexion et au
/// redémarrage) et enregistré sur le compte, qui le retrouve à la connexion sur
/// un autre téléphone ou après réinstallation.
///
/// Les textes de l'interface sont écrits en français dans le code et passent
/// par [tr] : en anglais, ils sont traduits via le dictionnaire
/// `traductions_en.dart` (un texte absent du dictionnaire reste en français).
class LangueApp extends ValueNotifier<Langue> {
  LangueApp._() : super(Langue.fr);
  static final LangueApp instance = LangueApp._();

  static const _cle = 'langue_app';

  /// Choix fait sans pouvoir l'enregistrer sur le compte (hors connexion, réseau
  /// absent) : il sera reporté sur le compte à la prochaine connexion.
  static const _cleAEnregistrer = 'langue_a_enregistrer';
  SharedPreferences? _prefs;

  /// Enregistre la langue sur le compte connecté (branché au démarrage) ; renvoie
  /// false hors connexion. Le serveur envoie alors les push dans cette langue.
  Future<bool> Function(Langue langue)? enregistrerDansProfil;

  Future<void> _enregistrerSurLeCompte() async {
    var enregistre = false;
    try {
      enregistre = await enregistrerDansProfil?.call(value) ?? false;
    } catch (_) {}
    if (enregistre) {
      await _prefs?.remove(_cleAEnregistrer);
    } else {
      await _prefs?.setBool(_cleAEnregistrer, true);
    }
  }

  /// À la connexion : la langue du compte s'applique à l'application, sauf si
  /// l'utilisateur vient d'en choisir une autre sans être connecté (ce choix
  /// récent est alors enregistré sur le compte).
  Future<void> apresConnexion(String? langueDuCompte) async {
    if (_prefs?.getBool(_cleAEnregistrer) ?? false) return _enregistrerSurLeCompte();
    final langue = Langue.values.where((l) => l.code == langueDuCompte).firstOrNull;
    if (langue != null && langue != value) await _appliquer(langue);
  }

  /// Au premier lancement, la langue du téléphone est reprise si elle est proposée.
  void initialiser(SharedPreferences prefs) {
    _prefs = prefs;
    final memorisee = prefs.getString(_cle);
    final systeme = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    value = Langue.values.firstWhere(
      (l) => l.code == (memorisee ?? systeme),
      orElse: () => Langue.fr,
    );
  }

  /// Choix de l'utilisateur : appliqué tout de suite et enregistré sur le compte.
  Future<void> changer(Langue langue) async {
    if (langue == value) return;
    await _appliquer(langue);
    await _enregistrerSurLeCompte();
  }

  Future<void> _appliquer(Langue langue) async {
    value = langue;
    await _prefs?.setString(_cle, langue.code);
    // Tous les écrans ouverts sont redessinés dans la nouvelle langue, sans
    // perdre la navigation ni les saisies en cours.
    void reconstruire(Element e) {
      e.markNeedsBuild();
      e.visitChildren(reconstruire);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(reconstruire);
  }

  bool get estAnglais => value == Langue.en;
}

/// Motifs des traductions contenant des variables (`{}` dans la clé française).
List<(RegExp, String)>? _motifs;
final Map<String, String> _cacheMotifs = {};

List<(RegExp, String)> _compilerMotifs() => [
      for (final e in traductionsEn.entries)
        if (e.key.contains('{}'))
          (
            RegExp('^${e.key.split('{}').map(RegExp.escape).join(r'(.+?)')}\$', dotAll: true),
            e.value,
          ),
    ];

/// Traduit un texte de l'interface écrit en français.
///
/// Les textes avec variables sont reconnus par motif : la clé
/// `'Colis {}'` traduit aussi bien `'Colis PNCO01'` que `'Colis ABC'`.
String tr(String francais) {
  if (!LangueApp.instance.estAnglais || francais.isEmpty) return francais;
  final direct = traductionsEn[francais];
  if (direct != null) return direct;
  final cache = _cacheMotifs[francais];
  if (cache != null) return cache;
  for (final (motif, anglais) in _motifs ??= _compilerMotifs()) {
    final m = motif.firstMatch(francais);
    if (m == null) continue;
    var i = 0;
    final resultat = anglais.replaceAllMapped(RegExp(r'\{\}'), (_) {
      i++;
      return i <= m.groupCount ? tr(m.group(i)!) : '';
    });
    return _cacheMotifs[francais] = resultat;
  }
  return francais;
}
