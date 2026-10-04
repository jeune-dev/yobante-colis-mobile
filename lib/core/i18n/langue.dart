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

/// Langue courante de l'application, mémorisée entre deux lancements.
///
/// Les textes de l'interface sont écrits en français dans le code et passent
/// par [tr] : en anglais, ils sont traduits via le dictionnaire
/// `traductions_en.dart` (un texte absent du dictionnaire reste en français).
class LangueApp extends ValueNotifier<Langue> {
  LangueApp._() : super(Langue.fr);
  static final LangueApp instance = LangueApp._();

  static const _cle = 'langue_app';
  SharedPreferences? _prefs;

  /// Enregistre la langue dans le profil du client connecté (branché au démarrage) :
  /// le serveur envoie alors les notifications push dans cette langue.
  Future<void> Function(Langue langue)? enregistrerDansProfil;

  /// À appeler après la connexion : la langue choisie avant de se connecter
  /// est reportée sur le compte. Sans effet en cas d'échec.
  Future<void> synchroniserProfil() async {
    try {
      await enregistrerDansProfil?.call(value);
    } catch (_) {}
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

  Future<void> changer(Langue langue) async {
    if (langue == value) return;
    value = langue;
    await _prefs?.setString(_cle, langue.code);
    synchroniserProfil();
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
