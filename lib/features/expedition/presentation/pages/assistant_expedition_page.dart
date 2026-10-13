import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/constants/categories.dart';
import '../../../adresses/data/adresses_remote_datasource.dart';
import '../../../adresses/presentation/pages/adresses_page.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/widgets/champ_telephone.dart';
import '../../../../injection_container.dart';
import '../../../account/data/datasources/account_remote_datasource.dart';
import '../../../catalogue/data/catalogue_remote_datasource.dart';
import '../../../catalogue/domain/catalogue_entities.dart';
import '../../../colis/domain/entities/demande_expedition.dart';
import '../../../colis/presentation/bloc/colis_bloc.dart';
import '../../../colis/presentation/bloc/colis_event.dart';
import '../../../colis/presentation/bloc/colis_state.dart';
import '../widgets/carte_offre.dart';
import '../widgets/choix_categorie.dart';
import '../widgets/prise_photos.dart';
import '../widgets/selecteur_articles.dart';
import '../widgets/selecteur_ville.dart';
import 'confirmation_expedition_page.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/utils/validateurs.dart';

/// Valeurs de départ de l'assistant, transmises depuis le calculateur de tarif
/// ou une tournée de collecte.
class PreremplissageExpedition {
  final String? categorie;
  final bool versSenegal;
  final String? villeDepartId;
  final String? villeArriveeId;
  final Map<String, int> articles;
  final double? poidsKg;
  final String? modeDepot;
  final String? tourneeId;
  final bool fragile;
  final bool marchandiseDangereuse;
  const PreremplissageExpedition({
    this.categorie,
    this.versSenegal = true,
    this.villeDepartId,
    this.villeArriveeId,
    this.articles = const {},
    this.poidsKg,
    this.modeDepot,
    this.tourneeId,
    this.fragile = false,
    this.marchandiseDangereuse = false,
  });
}

/// Assistant d'expédition façon DHL « Expédier » : cinq étapes courtes, le
/// prix affiché avant validation, et un parcours adapté à la catégorie.
class AssistantExpeditionPage extends StatelessWidget {
  final PreremplissageExpedition preremplissage;
  const AssistantExpeditionPage({super.key, this.preremplissage = const PreremplissageExpedition()});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ColisBloc>(),
      child: _Assistant(preremplissage: preremplissage),
    );
  }
}

class _PieceSaisie {
  final poids = TextEditingController();
  final longueur = TextEditingController();
  final largeur = TextEditingController();
  final hauteur = TextEditingController();
  String typeEmballage = 'carton';

  double? _n(TextEditingController c) => lireNombre(c.text);
  PieceDeclaree? versPiece() {
    final p = _n(poids);
    if (p == null || p <= 0) return null;
    return PieceDeclaree(
      poidsKg: p,
      longueurCm: _n(longueur),
      largeurCm: _n(largeur),
      hauteurCm: _n(hauteur),
      typeEmballage: typeEmballage,
    );
  }

  bool get dimensionsCompletes => _n(longueur) != null && _n(largeur) != null && _n(hauteur) != null;

  /// Limites de l'API : 1000 kg par colis, 500 cm par dimension.
  String? get erreurLimites {
    if ((_n(poids) ?? 0) > 1000) return tr('Le poids d\'un colis ne peut pas dépasser 1000 kg.');
    if ([longueur, largeur, hauteur].any((c) => (_n(c) ?? 0) > 500)) {
      return tr('Chaque dimension doit rester sous 500 cm.');
    }
    if ([poids, longueur, largeur, hauteur].any((c) => c.text.trim().isNotEmpty && _n(c) == null)) {
      return tr('Poids ou dimension invalide : saisissez un nombre.');
    }
    // La longueur est le plus grand côté ; égalité admise pour une base carrée.
    final l = _n(longueur), w = _n(largeur);
    if (l != null && w != null && w > l) return tr('La largeur ne peut pas être supérieure à la longueur.');
    return null;
  }

  void dispose() {
    poids.dispose();
    longueur.dispose();
    largeur.dispose();
    hauteur.dispose();
  }
}

/// Ligne de l'inventaire douanier en cours de saisie.
class _LigneDouaneSaisie {
  final designation = TextEditingController();
  final quantite = TextEditingController(text: '1');
  final valeurUnitaire = TextEditingController();
  final codeSh = TextEditingController();
  final poidsNet = TextEditingController();
  final paysOrigine = TextEditingController();
  final marque = TextEditingController();
  String unite = 'piece';

  double? _n(TextEditingController c) => lireNombre(c.text);

  bool get vide =>
      [designation, valeurUnitaire, codeSh, poidsNet, paysOrigine, marque].every((c) => c.text.trim().isEmpty);

  /// Mêmes règles que le schéma `articlesDouane` du backend.
  String? get erreur {
    if (vide) return null;
    if (designation.text.trim().length < 2) return tr('Inventaire : précisez la désignation de chaque article.');
    if ((_n(quantite) ?? 0) <= 0) return tr('Inventaire : quantité invalide.');
    if ((_n(valeurUnitaire) ?? -1) < 0) return tr('Inventaire : indiquez la valeur unitaire de chaque article.');
    final sh = codeSh.text.trim();
    if (sh.isNotEmpty && !RegExp(r'^\d{6,10}$').hasMatch(sh)) {
      return tr('Inventaire : le code SH compte 6 à 10 chiffres.');
    }
    if (poidsNet.text.trim().isNotEmpty && (_n(poidsNet) ?? -1) < 0) return tr('Inventaire : poids net invalide.');
    final pays = paysOrigine.text.trim();
    if (pays.isNotEmpty && !RegExp(r'^[A-Za-z]{2}$').hasMatch(pays)) {
      return tr('Inventaire : le pays d\'origine s\'écrit en deux lettres (FR, CN…).');
    }
    return null;
  }

  ContenuDeclare? versContenu(String? etat) {
    if (vide || erreur != null) return null;
    return ContenuDeclare(
      designation: designation.text.trim(),
      quantite: _n(quantite) ?? 1,
      unite: unite,
      valeurUnitaire: _n(valeurUnitaire) ?? 0,
      etat: etat,
      codeSh: codeSh.text.trim(),
      poidsNetKg: _n(poidsNet),
      paysOrigine: paysOrigine.text.trim(),
      marque: marque.text.trim(),
    );
  }

  void dispose() {
    for (final c in [designation, quantite, valeurUnitaire, codeSh, poidsNet, paysOrigine, marque]) {
      c.dispose();
    }
  }
}

class _Assistant extends StatefulWidget {
  final PreremplissageExpedition preremplissage;
  const _Assistant({required this.preremplissage});

  @override
  State<_Assistant> createState() => _AssistantState();
}

class _AssistantState extends State<_Assistant> {
  /// Natures d'envoi acceptées par le backend (hors « document », réservé à la catégorie 1).
  static const _naturesEnvoi = {
    'marchandise': 'Marchandise',
    'cadeau': 'Cadeau',
    'effets_personnels': 'Effets personnels',
    'echantillon': 'Échantillon',
    'retour': 'Retour de marchandise',
  };
  static List<String> get _titres => [
    tr('Trajet'),
    tr('Contenu'),
    tr('Remise du colis'),
    tr('Coordonnées'),
    tr('Validation'),
  ];
  final _catalogue = sl<CatalogueRemoteDataSource>();
  int _etape = 0;
  ConfigurationPublique? _config;

  // ── Étape 1 : trajet et catégorie ──────────────────────────────────────────
  CategorieColis _categorie = CategorieColis.colisMoyen;
  // Faux quand l'utilisateur désélectionne la carte : il doit en rechoisir une pour continuer
  bool _categorieChoisie = true;
  bool _versSenegal = true;
  List<VilleDesservie> _villesFr = [];
  List<VilleDesservie> _villesSn = [];
  bool _chargementVilles = true;
  VilleDesservie? _villeDepart;
  VilleDesservie? _villeArrivee;

  // ── Étape 2 : contenu ─────────────────────────────────────────────────────
  List<ArticleTarif> _articles = [];
  final Map<String, int> _quantites = {};
  bool _parGrille = true;
  final List<_PieceSaisie> _pieces = [_PieceSaisie()];
  final _typeDocument = TextEditingController();
  final _description = TextEditingController();
  final _valeur = TextEditingController();
  String? _etat;
  List<String?> _photos = [];
  List<Emballage> _emballages = [];
  final Map<String, int> _qtesEmballages = {};
  String _typeContenu = 'marchandise';
  bool _fragile = false;
  bool _dangereuse = false;
  bool _assurance = false;
  final List<_LigneDouaneSaisie> _inventaire = [];

  // ── Étape 3 : remise du colis ──────────────────────────────────────────────
  String? _modeDepot;
  List<PointService> _pointsDepot = [];
  String? _pointDepotId;
  final _adresseDepart = TextEditingController();
  final _codePostal = TextEditingController();
  List<TourneeCollecte> _tournees = [];
  String? _tourneeId;
  DateTime? _dateCollecte;
  TimeOfDay? _heureCollecte;
  final _etage = TextEditingController();
  bool _ascenseur = false;
  bool _emballageSurPlace = false;
  final _instructionsCollecte = TextEditingController();
  bool _colissimo = false;

  // ── Étape 4 : coordonnées ──────────────────────────────────────────────────
  final _expNom = TextEditingController();
  final _expTel = TextEditingController();
  final _expEmail = TextEditingController();
  final _expEntreprise = TextEditingController();
  final _destEntreprise = TextEditingController();
  final _codePostalArrivee = TextEditingController();
  final _referenceClient = TextEditingController();
  final _numeroEori = TextEditingController();
  final _numeroNinea = TextEditingController();
  final _destNom = TextEditingController();
  final _destTel = TextEditingController();
  final _destEmail = TextEditingController();
  // Dernière recherche de destinataire (texte et requête en cours). Le clavier signale aussi
  // des changements sans nouveau texte (mot en cours de saisie, curseur) : ils réutilisent
  // la même recherche au lieu d'en lancer une autre qui rendrait la première « périmée »
  String? _texteRecherche;
  Future<Iterable<AdresseCarnet>>? _rechercheEnCours;
  String _modeLivraison = 'livraison_domicile';
  List<PointService> _pointsRetrait = [];
  String? _pointRetraitId;
  final _adresseLivraison = TextEditingController();
  final _quartier = TextEditingController();
  final _arrondissement = TextEditingController();
  final _departement = TextEditingController();
  final _pointRepere = TextEditingController();
  final _instructionsLivraison = TextEditingController();

  // ── Étape 5 : offre et validation ──────────────────────────────────────────
  ResultatDevis? _devis;
  bool _calcul = false;
  String? _erreurDevis;
  OffreDevis? _offre;
  bool _conditions = false;
  String _payeur = 'expediteur';
  String _incoterm = 'DAP';

  String get _paysDepart => _versSenegal ? 'FR' : 'SN';
  String get _paysArrivee => _versSenegal ? 'SN' : 'FR';
  VilleDesservie? get _villeSn => _versSenegal ? _villeArrivee : _villeDepart;
  bool get _zoneDakar => _villeSn?.zoneTarifDakar ?? false;
  bool get _adresseSnObligatoire => _categorie.adresseSenegalDetaillee && _paysArrivee == 'SN';

  @override
  void initState() {
    super.initState();
    final p = widget.preremplissage;
    _categorie = CategorieColis.parCode(p.categorie ?? CategorieColis.colisMoyen.code);
    _versSenegal = p.versSenegal;
    _quantites.addAll(p.articles);
    if (p.poidsKg != null) {
      _parGrille = false;
      _pieces.first.poids.text = p.poidsKg!.toString();
    }
    _modeDepot = p.modeDepot;
    _tourneeId = p.tourneeId;
    _fragile = p.fragile;
    _dangereuse = p.marchandiseDangereuse;
    _initialiser();
  }

  Future<void> _initialiser() async {
    try {
      final resultats = await Future.wait([
        _catalogue.getConfiguration(),
        _catalogue.getVilles(pays: 'FR'),
        _catalogue.getVilles(pays: 'SN'),
      ]);
      if (!mounted) return;
      setState(() {
        _config = resultats[0] as ConfigurationPublique;
        _villesFr = resultats[1] as List<VilleDesservie>;
        _villesSn = resultats[2] as List<VilleDesservie>;
        _chargementVilles = false;
        final p = widget.preremplissage;
        final toutes = [..._villesFr, ..._villesSn];
        _villeDepart = toutes.where((v) => v.id == p.villeDepartId).firstOrNull;
        _villeArrivee = toutes.where((v) => v.id == p.villeArriveeId).firstOrNull;
      });
    } on ServerException catch (e) {
      if (mounted) {
        setState(() => _chargementVilles = false);
        showToast(context, tr('Erreur'), e.message, ToastificationType.error);
      }
    }
    _chargerCatalogueCategorie();
    _prerenplirExpediteur();
  }

  Future<void> _chargerCatalogueCategorie() async {
    try {
      final articles = _categorie.code == 'documents'
          ? <ArticleTarif>[]
          : await _catalogue.getTarifs(categorie: _categorie.code, paysDepart: _paysDepart, paysArrivee: _paysArrivee);
      final emballages = _categorie.code == 'documents'
          ? <Emballage>[]
          : await _catalogue.getEmballages(categorie: _categorie.code);
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _emballages = emballages.where((e) => e.disponible).toList();
        _quantites.removeWhere((id, _) => !articles.any((a) => a.id == id));
        if (_categorie.code == 'colis_moyen' && articles.isEmpty) _parGrille = false;
      });
    } on ServerException catch (_) {
      // Grille indisponible : le client peut toujours déclarer un colis au poids
      if (mounted) setState(() => _parGrille = false);
    }
  }

  Future<void> _prerenplirExpediteur() async {
    try {
      final moi = await sl<AccountRemoteDataSource>().getMe();
      if (!mounted) return;
      setState(() {
        if (_expNom.text.isEmpty) _expNom.text = moi.fullName;
        if (_expTel.text.isEmpty) _expTel.text = moi.telephone ?? '';
        if (_expEmail.text.isEmpty) _expEmail.text = moi.email ?? '';
      });
    } catch (_) {
      // Le préremplissage est un confort : la saisie manuelle reste possible
    }
  }

  Future<void> _chargerPoints() async {
    try {
      final depots = await _catalogue.getPoints(pays: _paysDepart, service: 'depot');
      final retraits = await _catalogue.getPoints(pays: _paysArrivee, service: 'retrait');
      if (!mounted) return;
      setState(() {
        _pointsDepot = depots;
        _pointsRetrait = retraits;
      });
    } on ServerException catch (_) {}
  }

  Future<void> _chargerTournees() async {
    try {
      final tournees = await _catalogue.getTournees(
        pays: _paysDepart,
        codePostal: _codePostal.text.trim().isEmpty ? null : _codePostal.text.trim(),
        villeId: _villeDepart?.id,
      );
      if (!mounted) return;
      setState(() {
        _tournees = tournees;
        if (!tournees.any((t) => t.id == _tourneeId)) _tourneeId = null;
      });
    } on ServerException catch (_) {}
  }

  @override
  void dispose() {
    for (final c in [
      _typeDocument,
      _description,
      _valeur,
      _adresseDepart,
      _codePostal,
      _etage,
      _instructionsCollecte,
      _expNom,
      _expTel,
      _expEmail,
      _destNom,
      _destTel,
      _destEmail,
      _adresseLivraison,
      _quartier,
      _arrondissement,
      _departement,
      _pointRepere,
      _instructionsLivraison,
      _expEntreprise,
      _destEntreprise,
      _codePostalArrivee,
      _referenceClient,
      _numeroEori,
      _numeroNinea,
    ]) {
      c.dispose();
    }
    for (final p in _pieces) {
      p.dispose();
    }
    for (final l in _inventaire) {
      l.dispose();
    }
    super.dispose();
  }

  // ── Construction de la demande ─────────────────────────────────────────────

  double? get _valeurSaisie => lireNombre(_valeur.text);

  DemandeExpedition _demande() {
    final articles = _parGrille || _categorie.code == 'colis_xxl'
        ? _articles
              .where((a) => (_quantites[a.id] ?? 0) > 0)
              .map((a) => ArticleChoisi(articleTarifId: a.id, libelle: a.libelle, quantite: _quantites[a.id]!))
              .toList()
        : <ArticleChoisi>[];
    final pieces = _categorie.code == 'documents' || (_parGrille && _categorie.code == 'colis_moyen')
        ? <PieceDeclaree>[]
        : _pieces.map((p) => p.versPiece()).whereType<PieceDeclaree>().toList();
    final heure = _heureCollecte == null
        ? null
        : '${_heureCollecte!.hour.toString().padLeft(2, '0')}:${_heureCollecte!.minute.toString().padLeft(2, '0')}';

    return DemandeExpedition(
      categorie: _categorie.code,
      villeDepartId: _villeDepart!.id,
      villeArriveeId: _villeArrivee!.id,
      serviceId: _offre?.service.id,
      simulationId: _devis?.simulationId,
      typeDocument: _typeDocument.text,
      etatMarchandise: _categorie.code == 'documents' ? null : _etat,
      description: _description.text,
      valeurDeclaree: _valeurSaisie ?? 0,
      deviseValeur: _paysDepart == 'FR' ? 'EUR' : 'XOF',
      articles: articles,
      pieces: pieces,
      contenu: _categorie.code == 'documents'
          ? const []
          : _inventaire.map((l) => l.versContenu(_etat)).whereType<ContenuDeclare>().toList(),
      emballages: Map.of(_qtesEmballages),
      typeContenu: _categorie.code == 'documents' ? 'document' : _typeContenu,
      fragile: _categorie.code != 'documents' && _fragile,
      marchandiseDangereuse: _categorie.code != 'documents' && _dangereuse,
      assuranceSouscrite: _categorie.code != 'documents' && _assurance,
      incoterm: _categorie.code == 'documents' ? 'DAP' : _incoterm,
      payeur: _categorie.code == 'documents' ? 'expediteur' : _payeur,
      referenceClient: _referenceClient.text,
      modeDepot: _modeDepot ?? _categorie.modesDepot.first,
      pointCollecteDepartId: _pointDepotId,
      adresseDepart: _adresseDepart.text,
      codePostalDepart: _codePostal.text,
      optionColissimo: _colissimo,
      tourneeCollecteId: _tourneeId,
      infosCollecte: {
        if (_tourneeId == null && _dateCollecte != null)
          'dateSouhaitee': _dateCollecte!.toIso8601String().substring(0, 10),
        'heureSouhaitee': ?heure,
        if (int.tryParse(_etage.text.trim()) != null) 'etage': int.parse(_etage.text.trim()),
        'ascenseur': _ascenseur,
        'emballageRequis': _emballageSurPlace,
        if (_instructionsCollecte.text.trim().isNotEmpty) 'instructions': _instructionsCollecte.text.trim(),
      },
      expediteurNom: _expNom.text,
      expediteurEntreprise: _expEntreprise.text,
      numeroEori: _numeroEori.text,
      numeroNinea: _numeroNinea.text,
      expediteurTelephone: normaliserTelephone(_expTel.text, paysParDefaut: _paysDepart),
      expediteurEmail: _expEmail.text,
      destinataireNom: _destNom.text,
      destinataireEntreprise: _destEntreprise.text,
      destinataireTelephone: normaliserTelephone(_destTel.text, paysParDefaut: _paysArrivee),
      destinataireEmail: _destEmail.text,
      modeLivraison: _modeLivraison,
      pointRetraitId: _pointRetraitId,
      adresseLivraison: _adresseLivraison.text,
      codePostalArrivee: _codePostalArrivee.text,
      instructionsLivraison: _instructionsLivraison.text,
      destinataireQuartier: _quartier.text,
      destinataireArrondissement: _arrondissement.text,
      destinataireDepartement: _departement.text,
      destinatairePointRepere: _pointRepere.text,
      conditionsAcceptees: _conditions,
    );
  }

  // ── Contrôles par étape ────────────────────────────────────────────────────

  // Repères des champs contrôlés à chaque étape : une erreur fait défiler la page jusqu'au
  // champ concerné, en plus du message, pour le corriger sans le chercher
  final _reperes = <String, GlobalKey>{};
  GlobalKey _repere(String champ) => _reperes.putIfAbsent(champ, GlobalKey.new);
  String? _champEnErreur;

  /// Erreur de l'étape [message], rattachée au [champ] à afficher.
  String _manque(String champ, String message) {
    _champEnErreur = champ;
    return message;
  }

  String? _erreurEtape() {
    _champEnErreur = null;
    switch (_etape) {
      case 0:
        if (!_categorieChoisie) return _manque('categorie', tr('Choisissez un type d\'envoi.'));
        if (_villeDepart == null || _villeArrivee == null) {
          return _manque('villes', tr('Choisissez la ville de départ et d\'arrivée.'));
        }
        return null;
      case 1:
        if (_categorie.code == 'documents' && _typeDocument.text.trim().isEmpty) {
          return _manque('typeDocument', tr('Précisez le type de document envoyé.'));
        }
        final limitePiece = _pieces.map((p) => p.erreurLimites).whereType<String>().firstOrNull;
        if (limitePiece != null) return _manque('pieces', limitePiece);
        if (_categorie.code != 'documents') {
          final erreurInventaire = _inventaire.map((l) => l.erreur).whereType<String>().firstOrNull;
          if (erreurInventaire != null) return _manque('inventaire', erreurInventaire);
          if (_inventaire.where((l) => !l.vide).length > 50) {
            return _manque('inventaire', tr('Inventaire : 50 articles au maximum.'));
          }
        }
        if (_valeur.text.trim().isNotEmpty && _valeurSaisie == null) {
          return _manque('valeur', tr('Valeur estimée invalide.'));
        }
        if ((_valeurSaisie ?? 0) > 50000000) return _manque('valeur', tr('Valeur estimée trop élevée.'));
        if (_categorie.code != 'documents' && _assurance && (_valeurSaisie ?? 0) <= 0) {
          return _manque('valeur', tr('Indiquez la valeur estimée du contenu pour l\'assurer.'));
        }
        if (_categorie.code == 'colis_moyen') {
          if (_parGrille && !_quantites.values.any((q) => q > 0)) {
            return _manque('articles', tr('Choisissez au moins un article.'));
          }
          if (!_parGrille && _pieces.every((p) => p.versPiece() == null)) {
            return _manque('pieces', tr('Indiquez le poids de votre colis.'));
          }
          if (_etat == null) return _manque('etat', tr('Précisez l\'état de la marchandise (neuf ou occasion).'));
          if ((_valeurSaisie ?? 0) <= 0) return _manque('valeur', tr('Indiquez la valeur estimée du contenu.'));
        }
        if (_categorie.code == 'colis_xxl') {
          if (_pieces.any((p) => p.versPiece() == null || !p.dimensionsCompletes)) {
            return _manque('pieces', tr('Indiquez le poids estimé et les dimensions (L × l × h) de chaque colis.'));
          }
          if (_description.text.trim().isEmpty) {
            return _manque('description', tr('Décrivez le contenu de votre colis.'));
          }
        }
        final nbPhotos = _photos.whereType<String>().length;
        if (nbPhotos < _categorie.photosMin) {
          return _manque(
            'photos',
            _categorie.photosMin > 1
                ? tr('Ajoutez ${_categorie.photosMin} photos du colis (trois angles).')
                : tr('Ajoutez une photo de votre envoi.'),
          );
        }
        return null;
      case 2:
        final mode = _modeDepot;
        if (mode == null) return _manque('modeDepot', tr('Choisissez comment vous remettez votre colis.'));
        if (mode == 'point_collecte' && _pointDepotId == null) {
          return _manque('pointDepot', tr('Choisissez un point de dépôt.'));
        }
        if (mode == 'enlevement_domicile' || mode == 'boite_aux_lettres') {
          if (_adresseDepart.text.trim().length < 3 || _codePostal.text.trim().isEmpty) {
            return _manque(
              _adresseDepart.text.trim().length < 3 ? 'adresseDepart' : 'codePostal',
              tr(
                'Si vous optez pour une collecte, veuillez indiquer les informations nécessaires : adresse et code postal.',
              ),
            );
          }
        }
        if (mode == 'enlevement_domicile' && _tourneeId == null && _dateCollecte == null) {
          return _manque('tournee', tr('Choisissez une tournée de collecte ou une date souhaitée.'));
        }
        if (mode != 'point_collecte') {
          final cp = codePostal(pays: _villeDepart?.pays)(_codePostal.text);
          if (cp != null) return _manque('codePostal', cp);
        }
        if (mode == 'enlevement_domicile') {
          final etage = entier(min: -5, max: 60)(_etage.text);
          if (etage != null) return _manque('etage', tr('Étage : $etage'));
        }
        return null;
      case 3:
        if (_expNom.text.trim().length < 2) return _manque('expNom', tr('Nom de l\'expéditeur requis.'));
        final emailExp = email(requis: false)(_expEmail.text);
        if (emailExp != null) return _manque('expEmail', tr('Email de l\'expéditeur : $emailExp'));
        final emailDest = email(requis: false)(_destEmail.text);
        if (emailDest != null) return _manque('destEmail', tr('Email du destinataire : $emailDest'));
        if (validerTelephone(_expTel.text) != null) {
          return _manque('expTel', tr('Téléphone de l\'expéditeur : ${validerTelephone(_expTel.text)}'));
        }
        if (_destNom.text.trim().length < 2) return _manque('destNom', tr('Nom du destinataire requis.'));
        if (validerTelephone(_destTel.text) != null) {
          return _manque('destTel', tr('Téléphone du destinataire : ${validerTelephone(_destTel.text)}'));
        }
        if (_modeLivraison == 'livraison_domicile' && _adresseLivraison.text.trim().length < 3) {
          return _manque('adresseLivraison', tr('Adresse de livraison requise.'));
        }
        if (_modeLivraison == 'point_retrait' && _pointRetraitId == null) {
          return _manque('pointRetrait', tr('Choisissez un point de retrait.'));
        }
        if (_modeLivraison == 'livraison_domicile' && _codePostalArrivee.text.trim().isNotEmpty) {
          final cp = codePostal(pays: _paysArrivee)(_codePostalArrivee.text);
          if (cp != null) return _manque('codePostalArrivee', tr('Code postal du destinataire : $cp'));
        }
        if (_adresseSnObligatoire &&
            [_quartier, _arrondissement, _departement, _pointRepere].any((c) => c.text.trim().isEmpty)) {
          return _manque(
            'precisionsSn',
            tr('Quartier, arrondissement, département et point de repère sont obligatoires au Sénégal.'),
          );
        }
        return null;
      default:
        if (_offre == null) return _manque('offres', tr('Choisissez une offre de transport.'));
        if (!_conditions) return _manque('conditions', tr('Vous devez accepter les conditions générales.'));
        return null;
    }
  }

  void _suivant() {
    final erreur = _erreurEtape();
    if (erreur != null) {
      showToast(context, tr('Information manquante'), erreur, ToastificationType.warning);
      final cible = _reperes[_champEnErreur]?.currentContext;
      if (cible != null) montrerElement(cible);
      return;
    }
    if (_etape == 4) {
      final demande = _demande();
      context.read<ColisBloc>().add(CreerColisRequested(demande, photosPaths: _photos.whereType<String>().toList()));
      return;
    }
    setState(() => _etape += 1);
    if (_etape == 2 && _pointsDepot.isEmpty) _chargerPoints();
    if (_etape == 2) _chargerTournees();
    if (_etape == 4) _calculerDevis();
  }

  /// Recherche du destinataire sur le serveur, à chaque saisie (après une courte pause).
  /// « en France », « au Sénégal » : pays d'une adresse du carnet, avec sa préposition.
  String _auPays(String code) => code == 'FR' ? 'en France' : (code == 'SN' ? 'au Sénégal' : code);

  Future<Iterable<AdresseCarnet>> _chercherDestinataires(String saisie) {
    final q = saisie.trim();
    final enCours = _rechercheEnCours;
    if (q == _texteRecherche && enCours != null) return enCours;
    _texteRecherche = q;
    return _rechercheEnCours = _interrogerCarnet(q);
  }

  Future<Iterable<AdresseCarnet>> _interrogerCarnet(String q) async {
    // Champ vide : tout le carnet, dès qu'on touche le champ. Ensuite chaque lettre
    // affine la liste, après une courte pause pour ne pas interroger à chaque touche.
    if (q.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (q != _texteRecherche) return const [];
    }
    try {
      // Tout le carnet : les adresses d'un autre pays que l'arrivée sont listées après,
      // grisées, pour que l'utilisateur comprenne pourquoi elles ne peuvent pas servir
      final resultats = await sl<AdressesRemoteDataSource>().rechercher(
        q,
        type: 'destinataire',
        limit: q.isEmpty ? 50 : 20,
      );
      if (q != _texteRecherche) return const [];
      // Le serveur de production ne garde pas le filtre « destinataire » pendant une
      // recherche : les contacts uniquement expéditeurs sont écartés ici
      final destinataires = resultats.where((a) => a.estDestinataire);
      return [
        ...destinataires.where((a) => a.pays == _paysArrivee),
        ...destinataires.where((a) => a.pays != _paysArrivee),
      ];
    } catch (_) {
      // Recherche indisponible : la saisie manuelle et le bouton « Carnet » restent possibles
      return const [];
    }
  }

  /// Abandon du parcours depuis n'importe quelle étape, après confirmation :
  /// sans cela, il fallait revenir étape par étape jusqu'à la première.
  Future<void> _quitter() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Quitter l\'expédition ?')),
        content: Text(tr('Les informations saisies seront perdues.')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr('Continuer la saisie'))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColor.kErreur),
            child: Text(tr('Quitter')),
          ),
        ],
      ),
    );
    if (confirme == true && mounted) Navigator.of(context).pop();
  }

  void _precedent() {
    if (_etape == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _etape -= 1);
    }
  }

  Future<void> _calculerDevis() async {
    setState(() {
      _calcul = true;
      _erreurDevis = null;
      _devis = null;
      _offre = null;
    });
    try {
      final devis = await _catalogue.devis(_demande().versDevis(), connecte: true);
      if (!mounted) return;
      setState(() {
        _devis = devis;
        _offre = devis.offres.isNotEmpty ? devis.offres.first : null;
        if (devis.offres.isEmpty) {
          _erreurDevis = devis.indisponibles.isNotEmpty
              ? devis.indisponibles.map((i) => '${i.serviceNom} : ${i.motif}').join('\n')
              : tr('Aucune offre disponible pour ce trajet.');
        }
      });
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreurDevis = e.message);
    } finally {
      if (mounted) setState(() => _calcul = false);
    }
  }

  // ── Interface ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ColisBloc, ColisState>(
      listener: (ctx, state) {
        if (state is ColisCreated) {
          Navigator.of(ctx).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ConfirmationExpeditionPage(resultat: state.resultat, categorie: _categorie),
            ),
          );
        }
        if (state is ColisFailure) showToast(ctx, tr('Envoi impossible'), state.message, ToastificationType.error);
      },
      builder: (ctx, state) {
        final envoi = state is ColisLoading || state is ColisUploadProgress;
        return PopScope(
          canPop: _etape == 0 && !envoi,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !envoi) _precedent();
          },
          child: Scaffold(
            backgroundColor: AppColor.kBackground,
            appBar: AppBar(
              title: Text(tr('Expédier un colis')),
              actions: [
                if (_etape > 0 && !envoi)
                  IconButton(icon: const Icon(Icons.close), tooltip: tr('Quitter'), onPressed: _quitter),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(38),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Étape ${_etape + 1} sur 5 · ${_titres[_etape]}'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColor.kPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_etape + 1) / 5,
                          minHeight: 5,
                          backgroundColor: AppColor.kLine,
                          color: AppColor.kSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: _chargementVilles
                ? const Center(child: CircularProgressIndicator())
                // Colonne entière (et non ListView paresseuse) : les champs hors écran existent,
                // la page peut donc défiler jusqu'à celui qui est en erreur
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...switch (_etape) {
                          0 => _etapeTrajet(),
                          1 => _etapeContenu(),
                          2 => _etapeRemise(),
                          3 => _etapeCoordonnees(),
                          _ => _etapeValidation(),
                        },
                        if (state is ColisUploadProgress) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(value: state.progress),
                        ],
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
            bottomNavigationBar: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                decoration: BoxDecoration(
                  color: AppColor.kWhite,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: envoi ? null : _precedent,
                        child: Text(_etape == 0 ? tr('Annuler') : tr('Retour')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: envoi || (_etape == 4 && _calcul) ? null : _suivant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.kSecondary,
                          foregroundColor: AppColor.kPrimary,
                        ),
                        child: envoi
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.kPrimary),
                              )
                            : Text(
                                _etape == 4
                                    ? (_categorie.validationAdmin ? tr('Envoyer ma demande') : tr('Valider et payer'))
                                    : tr('Continuer'),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _etapeTrajet() => [
    Text(tr('Que souhaitez-vous envoyer ?'), style: titreSection(17)),
    const SizedBox(height: 12),
    ChoixCategorie(
      key: _repere('categorie'),
      selection: _categorieChoisie ? _categorie.code : null,
      onDeselectionne: () => setState(() => _categorieChoisie = false),
      onChanged: (c) {
        setState(() {
          _categorie = c;
          _categorieChoisie = true;
          _photos = [];
          if (!c.modesDepot.contains(_modeDepot)) _modeDepot = null;
        });
        _chargerCatalogueCategorie();
      },
    ),
    const SizedBox(height: 16),
    Text(tr('Trajet'), style: titreSection()),
    const SizedBox(height: 10),
    SegmentedButton<bool>(
      segments: [
        ButtonSegment(value: true, label: Text(tr('France → Sénégal')), icon: Icon(Icons.flight_land)),
        ButtonSegment(value: false, label: Text(tr('Sénégal → France')), icon: Icon(Icons.flight_takeoff)),
      ],
      selected: {_versSenegal},
      onSelectionChanged: (s) {
        setState(() {
          _versSenegal = s.first;
          _villeDepart = null;
          _villeArrivee = null;
          _pointsDepot = [];
          _pointDepotId = null;
          _pointRetraitId = null;
        });
        _chargerCatalogueCategorie();
      },
    ),
    const SizedBox(height: 14),
    SelecteurVille(
      key: _repere('villes'),
      label: tr('Ville de départ'),
      villes: _versSenegal ? _villesFr : _villesSn,
      valeur: _villeDepart,
      onChanged: (v) => setState(() => _villeDepart = v),
    ),
    const SizedBox(height: 12),
    SelecteurVille(
      label: tr('Ville de destination'),
      villes: _versSenegal ? _villesSn : _villesFr,
      valeur: _villeArrivee,
      onChanged: (v) => setState(() => _villeArrivee = v),
    ),
    if (_villeSn != null) ...[
      const SizedBox(height: 10),
      Text(
        _zoneDakar
            ? tr('Tarif « Dakar » appliqué, livraison incluse.')
            : tr('Tarif « autres régions » appliqué, livraison incluse.'),
        style: texteDiscret(12),
      ),
    ],
  ];

  List<Widget> _etapeContenu() {
    final c = _categorie.code;
    return [
      if (c == 'documents') ...[
        Text(tr('Vos documents'), style: titreSection(17)),
        const SizedBox(height: 12),
        ChampTexte(
          key: _repere('typeDocument'),
          controller: _typeDocument,
          label: tr('Type de document'),
          maxLength: 100,
          hint: tr('Acte de naissance, diplôme, courrier…'),
          icone: Icons.description_outlined,
        ),
        ChampTexte(controller: _description, label: tr('Précisions (facultatif)'), maxLines: 2, maxLength: 500),
      ],
      if (c == 'colis_moyen') ...[
        Text(tr('Votre colis'), style: titreSection(17)),
        const SizedBox(height: 10),
        if (_articles.isNotEmpty)
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(tr('Grille tarifaire'))),
              ButtonSegment(value: false, label: Text(tr('Carton au poids'))),
            ],
            selected: {_parGrille},
            onSelectionChanged: (s) => setState(() => _parGrille = s.first),
          ),
        const SizedBox(height: 12),
        SizedBox.shrink(key: _repere('articles')),
        if (_parGrille && _articles.isNotEmpty)
          SelecteurArticles(
            articles: _articles,
            quantites: _quantites,
            zoneDakar: _zoneDakar,
            onChanged: (a, q) => setState(() => _quantites[a.id] = q),
          )
        else
          ..._saisiePieces(dimensionsObligatoires: false),
      ],
      if (c == 'colis_xxl') ...[
        Text(tr('Votre colis XXL'), style: titreSection(17)),
        const SizedBox(height: 6),
        Text(
          tr('Le prix vous sera proposé sous ${_config?.delaiEtudeHeures ?? 24} h après étude de votre demande.'),
          style: texteDiscret(12),
        ),
        const SizedBox(height: 12),
        ..._saisiePieces(dimensionsObligatoires: true),
        if (_articles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(tr('Il s\'agit de… (facultatif, pour estimer le prix)'), style: texteDiscret(12)),
          const SizedBox(height: 8),
          SelecteurArticles(
            articles: _articles,
            quantites: _quantites,
            zoneDakar: _zoneDakar,
            onChanged: (a, q) => setState(() => _quantites[a.id] = q),
          ),
        ],
      ],
      if (c != 'documents') ...[
        const SizedBox(height: 8),
        ChampTexte(
          key: _repere('description'),
          controller: _description,
          label: c == 'colis_xxl' ? tr('Description du contenu') : tr('Description du contenu (facultatif)'),
          maxLength: 500,
          maxLines: 2,
        ),
        Row(
          children: [
            Expanded(
              child: ChampTexte(
                key: _repere('valeur'),
                controller: _valeur,
                // Obligatoire pour un colis moyen, et dès que l'assurance est demandée
                label: c == 'colis_moyen' || _assurance ? tr('Valeur estimée') : tr('Valeur estimée (facultatif)'),
                clavier: const TextInputType.numberWithOptions(decimal: true),
                icone: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_paysDepart == 'FR' ? '€' : 'FCFA', style: titreSection()),
            ),
          ],
        ),
        // Explication : le libellé seul n'indique pas à quoi sert ce montant
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            tr(
              'Prix approximatif de ce que contient le colis (ex. le prix d\'achat de l\'ordinateur envoyé). '
              'Il sert à la déclaration en douane et, si vous l\'assurez, au remboursement en cas de perte.',
            ),
            style: texteDiscret(11),
          ),
        ),
        SizedBox.shrink(key: _repere('etat')),
        Text(tr('État de la marchandise'), style: texteDiscret(13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(tr('Neuf')),
              selected: _etat == 'neuf',
              onSelected: (_) => setState(() => _etat = 'neuf'),
            ),
            ChoiceChip(
              label: Text(tr('Occasion')),
              selected: _etat == 'occasion',
              onSelected: (_) => setState(() => _etat = 'occasion'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(tr('Nature de l\'envoi'), style: texteDiscret(13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _naturesEnvoi.entries
              .map(
                (n) => ChoiceChip(
                  label: Text(tr(n.value)),
                  selected: _typeContenu == n.key,
                  onSelected: (_) => setState(() => _typeContenu = n.key),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tr('Colis fragile')),
          subtitle: Text(tr('Manutention adaptée (supplément éventuel)')),
          value: _fragile,
          onChanged: (v) => setState(() => _fragile = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tr('Marchandise dangereuse')),
          subtitle: Text(tr('Batteries, parfums, aérosols, produits inflammables… (contrôle et supplément éventuels)')),
          value: _dangereuse,
          onChanged: (v) => setState(() => _dangereuse = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tr('Assurer mon envoi')),
          subtitle: Text(tr('Calculée sur la valeur estimée, ajoutée au devis')),
          value: _assurance,
          onChanged: (v) => setState(() => _assurance = v),
        ),
        const SizedBox(height: 12),
        ..._saisieInventaire(),
      ],
      const SizedBox(height: 20),
      Text(c == 'documents' ? tr('Photo de l\'enveloppe') : tr('Photos du colis'), style: titreSection()),
      const SizedBox(height: 8),
      PrisePhotos(
        key: _repere('photos'),
        minimum: _categorie.photosMin,
        libellesAngles: c == 'colis_moyen' ? ['Face', tr('Côté'), tr('Dessus')] : const [],
        photos: _photos,
        onChanged: (p) => setState(() => _photos = p),
      ),
      if (_emballages.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text(tr('Besoin d\'un emballage ?'), style: titreSection()),
        const SizedBox(height: 4),
        Text(tr('Barigots, cartons ou emballage par nos équipes (option payante).'), style: texteDiscret(12)),
        const SizedBox(height: 10),
        ..._emballages.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CarteSection(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.libelle, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                          if (e.dimensions != null) Text(e.dimensions!, style: texteDiscret()),
                          Text(
                            formaterMontant(e.prix, e.devise),
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColor.kPrimary),
                          ),
                        ],
                      ),
                    ),
                    CompteurQuantite(
                      valeur: _qtesEmballages[e.id] ?? 0,
                      max: 20,
                      onChanged: (q) => setState(() => _qtesEmballages[e.id] = q),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _saisiePieces({required bool dimensionsObligatoires}) => [
    SizedBox.shrink(key: _repere('pieces')),
    ...List.generate(_pieces.length, (i) {
      final p = _pieces[i];
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: CarteSection(
          titre: tr('Colis ${i + 1}'),
          icone: Icons.inventory_2_outlined,
          action: _pieces.length > 1
              ? IconButton(
                  tooltip: tr('Retirer ce colis'),
                  icon: const Icon(Icons.delete_outline, color: AppColor.kErreur),
                  onPressed: () => setState(() => _pieces.removeAt(i).dispose()),
                )
              : null,
          children: [
            ChampTexte(
              controller: p.poids,
              label: dimensionsObligatoires ? tr('Poids estimé (kg)') : tr('Poids (kg)'),
              clavier: const TextInputType.numberWithOptions(decimal: true),
              icone: Icons.scale_outlined,
            ),
            Text(tr('Dimensions du colis (en cm)'), style: texteDiscret(13)),
            const SizedBox(height: 6),
            ChampsSerres(
              child: Row(
                children: [
                  Expanded(
                    child: ChampTexte(
                      controller: p.longueur,
                      label: tr('Longueur'),
                      hint: 'cm',
                      clavier: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChampTexte(
                      controller: p.largeur,
                      label: tr('Largeur'),
                      hint: 'cm',
                      clavier: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChampTexte(
                      controller: p.hauteur,
                      label: tr('Hauteur'),
                      hint: 'cm',
                      clavier: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ),
            if (!dimensionsObligatoires) Text(tr('Dimensions facultatives'), style: texteDiscret(11)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: p.typeEmballage,
              decoration: InputDecoration(labelText: tr('Emballage'), prefixIcon: const Icon(Icons.all_inbox_outlined)),
              items: kTypesEmballage.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(tr(e.value))))
                  .toList(),
              onChanged: (v) => setState(() => p.typeEmballage = v ?? 'carton'),
            ),
          ],
        ),
      );
    }),
    Row(
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _pieces.add(_PieceSaisie())),
          icon: const Icon(Icons.add),
          label: Text(tr('Ajouter un colis')),
        ),
        const Spacer(),
        if (_config?.lien('applicationMesure') != null)
          TextButton.icon(
            onPressed: () => ouvrirLien(context, _config!.lien('applicationMesure')),
            icon: const Icon(Icons.straighten),
            label: Text(tr('Mesurer')),
          ),
      ],
    ),
  ];

  /// Inventaire détaillé du contenu, repris dans la déclaration en douane et la
  /// facture commerciale (facultatif : le backend se contente sinon de la description).
  List<Widget> _saisieInventaire() => [
    SizedBox.shrink(key: _repere('inventaire')),
    Text(tr('Inventaire du contenu (douane)'), style: titreSection()),
    const SizedBox(height: 4),
    Text(
      tr('Facultatif : détaillez les articles pour accélérer le dédouanement et la facture commerciale.'),
      style: texteDiscret(12),
    ),
    const SizedBox(height: 8),
    ...List.generate(_inventaire.length, (i) {
      final l = _inventaire[i];
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: CarteSection(
          titre: tr('Article ${i + 1}'),
          icone: Icons.list_alt_outlined,
          action: IconButton(
            tooltip: tr('Retirer cet article'),
            icon: const Icon(Icons.delete_outline, color: AppColor.kErreur),
            onPressed: () => setState(() => _inventaire.removeAt(i).dispose()),
          ),
          children: [
            ChampTexte(controller: l.designation, label: tr('Désignation'), maxLength: 255),
            Row(
              children: [
                Expanded(
                  child: ChampTexte(
                    controller: l.quantite,
                    label: tr('Quantité'),
                    clavier: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      initialValue: l.unite,
                      decoration: InputDecoration(labelText: tr('Unité')),
                      items: kUnitesDouane.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(tr(e.value))))
                          .toList(),
                      onChanged: (v) => setState(() => l.unite = v ?? 'piece'),
                    ),
                  ),
                ),
              ],
            ),
            ChampTexte(
              controller: l.valeurUnitaire,
              label: tr('Valeur unitaire (${_paysDepart == 'FR' ? '€' : 'FCFA'})'),
              clavier: const TextInputType.numberWithOptions(decimal: true),
            ),
            Row(
              children: [
                Expanded(
                  child: ChampTexte(
                    controller: l.codeSh,
                    label: tr('Code SH (facultatif)'),
                    clavier: TextInputType.number,
                    maxLength: 10,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChampTexte(
                    controller: l.poidsNet,
                    label: tr('Poids net kg (facultatif)'),
                    clavier: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ChampTexte(controller: l.paysOrigine, label: tr('Pays d\'origine (FR, CN…)'), maxLength: 2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChampTexte(controller: l.marque, label: tr('Marque (facultatif)'), maxLength: 80),
                ),
              ],
            ),
          ],
        ),
      );
    }),
    if (_inventaire.length < 50)
      TextButton.icon(
        onPressed: () => setState(() => _inventaire.add(_LigneDouaneSaisie())),
        icon: const Icon(Icons.add),
        label: Text(tr('Ajouter un article')),
      ),
  ];

  List<Widget> _etapeRemise() {
    final modes = _categorie.modesDepot.where((m) {
      if (m == 'enlevement_domicile' && _config?.collecteActive == false) return false;
      return true;
    }).toList();
    final adresse = _config?.adresseReception[_paysDepart];
    return [
      Text(tr('Comment remettez-vous votre colis ?'), key: _repere('modeDepot'), style: titreSection(17)),
      const SizedBox(height: 12),
      ...modes.map(
        (m) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() => _modeDepot = m);
              if (m == 'point_collecte' && _pointsDepot.isEmpty) _chargerPoints();
              if (m == 'enlevement_domicile') _chargerTournees();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColor.kWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _modeDepot == m ? AppColor.kPrimary : AppColor.kLine,
                  width: _modeDepot == m ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(iconesModeDepot[m], color: AppColor.kPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      libellesModeDepot[m] ?? m,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(_modeDepot == m ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColor.kPrimary),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (_modeDepot == 'point_collecte') ...[
        if (adresse != null && adresse.estRenseignee)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Bandeau(icone: Icons.place_outlined, titre: tr('Adresse de réception'), message: adresse.lignes),
          ),
        DropdownButtonFormField<String>(
          key: _repere('pointDepot'),
          initialValue: _pointDepotId,
          isExpanded: true,
          decoration: InputDecoration(labelText: tr('Point de dépôt'), prefixIcon: Icon(Icons.storefront_outlined)),
          items: _pointsDepot
              .map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(
                    '${p.nom}${p.villeNom != null ? ' — ${p.villeNom}' : ''}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _pointDepotId = v),
        ),
      ],
      if (_modeDepot == 'enlevement_domicile' || _modeDepot == 'boite_aux_lettres') ...[
        Bandeau(
          icone: Icons.info_outline,
          titre: tr('Si vous optez pour une collecte, veuillez indiquer les informations nécessaires.'),
        ),
        const SizedBox(height: 12),
        ChampTexte(
          key: _repere('adresseDepart'),
          controller: _adresseDepart,
          label: tr('Adresse de collecte'),
          icone: Icons.home_outlined,
          maxLength: 255,
        ),
        ChampTexte(
          key: _repere('codePostal'),
          controller: _codePostal,
          label: tr('Code postal'),
          clavier: TextInputType.number,
          maxLength: 10,
          icone: Icons.markunread_mailbox_outlined,
          onChanged: (v) {
            if (v.trim().length >= 2 && _modeDepot == 'enlevement_domicile') _chargerTournees();
          },
        ),
      ],
      if (_modeDepot == 'enlevement_domicile') ...[
        Text(tr('Tournées de collecte dans votre secteur'), style: titreSection(14)),
        const SizedBox(height: 8),
        if (_tournees.isEmpty)
          Text(
            tr(
              'Aucune tournée ouverte pour le moment : indiquez la date souhaitée, nous vous confirmerons le passage.',
            ),
            style: texteDiscret(12),
          )
        else
          RadioGroup<String>(
            key: _repere('tournee'),
            groupValue: _tourneeId,
            onChanged: (v) => setState(() => _tourneeId = v),
            child: Column(
              children: _tournees
                  .map(
                    (t) => RadioListTile<String>(
                      value: t.id,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${formaterDate(t.dateCollecte)} ${t.horaires ?? ''}'),
                      subtitle: Text(t.titre),
                    ),
                  )
                  .toList(),
            ),
          ),
        if (_tourneeId != null)
          TextButton(onPressed: () => setState(() => _tourneeId = null), child: Text(tr('Choisir une autre date'))),
        if (_tourneeId == null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(_dateCollecte == null ? tr('Date souhaitée') : formaterDate(_dateCollecte!.toIso8601String())),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime.now().add(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                initialDate: _dateCollecte ?? DateTime.now().add(const Duration(days: 1)),
              );
              if (d != null) setState(() => _dateCollecte = d);
            },
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule_outlined),
          title: Text(_heureCollecte == null ? tr('Heure souhaitée (facultatif)') : _heureCollecte!.format(context)),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () async {
            final h = await showTimePicker(
              context: context,
              initialTime: _heureCollecte ?? const TimeOfDay(hour: 10, minute: 0),
            );
            if (h != null) setState(() => _heureCollecte = h);
          },
        ),
        Row(
          children: [
            Expanded(
              child: ChampTexte(
                key: _repere('etage'),
                controller: _etage,
                label: tr('Étage'),
                clavier: const TextInputType.numberWithOptions(signed: true),
                maxLength: 3,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('Ascenseur')),
                value: _ascenseur,
                onChanged: (v) => setState(() => _ascenseur = v),
              ),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tr('Emballage à prévoir par nos équipes')),
          subtitle: Text(tr('Option payante')),
          value: _emballageSurPlace,
          onChanged: (v) => setState(() => _emballageSurPlace = v),
        ),
        ChampTexte(
          controller: _instructionsCollecte,
          label: tr('Instructions (digicode, accès…)'),
          maxLines: 2,
          maxLength: 500,
        ),
      ],
      if (_modeDepot == 'envoi_postal') ...[
        Bandeau(
          icone: Icons.local_post_office_outlined,
          titre: tr('Envoyez votre colis à notre adresse de réception'),
          message: adresse?.estRenseignee == true
              ? '${adresse!.lignes}${adresse.instructions != null ? '\n${adresse.instructions}' : ''}'
              : tr('L\'adresse vous sera communiquée après validation.'),
        ),
        const SizedBox(height: 10),
        if (_config?.colissimoActive == true && _paysDepart == 'FR')
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Acheter l\'étiquette Colissimo avec Yobante Colis')),
            subtitle: Text(tr('Tarif selon le poids, ajouté au devis')),
            value: _colissimo,
            onChanged: (v) => setState(() => _colissimo = v),
          ),
        if (_config?.lien('chronopost') != null)
          TextButton.icon(
            onPressed: () => ouvrirLien(context, _config!.lien('chronopost')),
            icon: const Icon(Icons.open_in_new),
            label: Text(tr('Imprimer un bon d\'envoi Chronopost')),
          ),
      ],
    ];
  }

  /// Pré-remplissage depuis le carnet d'adresses du client.
  Widget _boutonCarnet(String usage) => TextButton.icon(
    onPressed: () async {
      final a = await AdressesPage.choisir(context, usage: usage);
      if (a == null || !mounted) return;
      _appliquerAdresse(a, usage);
    },
    icon: const Icon(Icons.contacts_outlined, size: 18),
    label: Text(tr('Carnet')),
  );

  void _appliquerAdresse(AdresseCarnet a, String usage) => setState(() {
    if (usage == 'expediteur') {
      _expNom.text = a.nom;
      _expTel.text = a.telephone;
      _expEmail.text = a.email ?? '';
    } else {
      _destNom.text = a.nom;
      _destEntreprise.text = a.entreprise ?? '';
      _destTel.text = a.telephone;
      _destEmail.text = a.email ?? '';
      _adresseLivraison.text = [
        a.adresse,
        a.complementAdresse,
      ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
      if ((a.quartier ?? '').isNotEmpty) _quartier.text = a.quartier!;
      if ((a.arrondissement ?? '').isNotEmpty) _arrondissement.text = a.arrondissement!;
      if ((a.departement ?? '').isNotEmpty) _departement.text = a.departement!;
      if ((a.pointRepere ?? '').isNotEmpty) _pointRepere.text = a.pointRepere!;
      if ((a.codePostal ?? '').isNotEmpty) _codePostalArrivee.text = a.codePostal!;
      if (a.pointRetraitPrefereId != null && _pointsRetrait.any((p) => p.id == a.pointRetraitPrefereId)) {
        _pointRetraitId = a.pointRetraitPrefereId;
      }
    }
  });

  /// Recherche d'un destinataire du carnet (nom, libellé, entreprise, téléphone) :
  /// le choix pré-remplit la section, sinon l'utilisateur saisit lui-même.
  Widget _champRechercheDestinataire() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Autocomplete<AdresseCarnet>(
        displayStringForOption: (a) => a.nom,
        optionsBuilder: (saisie) => _chercherDestinataires(saisie.text),
        onSelected: (a) {
          _appliquerAdresse(a, 'destinataire');
          FocusManager.instance.primaryFocus?.unfocus();
        },
        fieldViewBuilder: (context, controle, focus, _) => TextFormField(
          controller: controle,
          focusNode: focus,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            labelText: tr('Rechercher dans mon carnet'),
            // Recherche du serveur de production : nom et libellé du contact
            hintText: tr('Nom ou libellé du contact'),
            prefixIcon: const Icon(Icons.search, size: 20, color: AppColor.kPrimary),
          ),
        ),
        optionsViewBuilder: (context, choisir, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 280, maxWidth: MediaQuery.sizeOf(context).width - 72),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final a in options)
                    // La ville d'arrivée est fixée à l'étape 1 : une adresse d'un autre pays
                    // est affichée grisée et ne remplit pas le formulaire
                    if (a.pays == _paysArrivee)
                      ListTile(
                        leading: const Icon(Icons.person_outline, color: AppColor.kPrimary),
                        title: Text(a.nom, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          [a.telephone, a.resume].where((e) => e.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => choisir(a),
                      )
                    else
                      ListTile(
                        leading: const Icon(Icons.person_off_outlined, color: AppColor.kGrayscale40),
                        title: Text(
                          a.nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColor.kGrayscale40),
                        ),
                        subtitle: Text(
                          tr('Adresse ${_auPays(a.pays)} : hors de ce trajet'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => showToast(
                          context,
                          tr('Adresse hors trajet'),
                          tr(
                            'Ce contact habite ${_auPays(a.pays)}. Pour lui envoyer un colis, changez le trajet à l\'étape 1.',
                          ),
                          ToastificationType.info,
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _etapeCoordonnees() => [
    CarteSection(
      titre: tr('Expéditeur'),
      icone: Icons.person_outline,
      action: _boutonCarnet('expediteur'),
      children: [
        ChampTexte(key: _repere('expNom'), controller: _expNom, label: tr('Nom complet'), maxLength: 120),
        ChampTexte(controller: _expEntreprise, label: tr('Entreprise (facultatif)'), maxLength: 120),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ChampTelephone(
            key: _repere('expTel'),
            controller: _expTel,
            label: tr('Téléphone'),
            paysInitial: _paysDepart,
          ),
        ),
        ChampTexte(
          key: _repere('expEmail'),
          controller: _expEmail,
          label: tr('Email (facultatif)'),
          clavier: TextInputType.emailAddress,
          maxLength: 150,
        ),
      ],
    ),
    const SizedBox(height: 14),
    CarteSection(
      titre: tr('Destinataire'),
      icone: Icons.person_pin_circle_outlined,
      action: _boutonCarnet('destinataire'),
      children: [
        _champRechercheDestinataire(),
        ChampTexte(key: _repere('destNom'), controller: _destNom, label: tr('Nom complet'), maxLength: 120),
        ChampTexte(controller: _destEntreprise, label: tr('Entreprise (facultatif)'), maxLength: 120),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ChampTelephone(
            key: _repere('destTel'),
            controller: _destTel,
            label: tr('Téléphone'),
            paysInitial: _paysArrivee,
          ),
        ),
        ChampTexte(
          key: _repere('destEmail'),
          controller: _destEmail,
          label: tr('Email (facultatif)'),
          clavier: TextInputType.emailAddress,
          maxLength: 150,
        ),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'livraison_domicile', label: Text(tr('Livraison'))),
            ButtonSegment(value: 'point_retrait', label: Text(tr('Point de retrait'))),
          ],
          selected: {_modeLivraison},
          onSelectionChanged: (s) {
            setState(() => _modeLivraison = s.first);
            if (s.first == 'point_retrait' && _pointsRetrait.isEmpty) _chargerPoints();
          },
        ),
        const SizedBox(height: 12),
        if (_modeLivraison == 'point_retrait')
          DropdownButtonFormField<String>(
            key: _repere('pointRetrait'),
            initialValue: _pointRetraitId,
            isExpanded: true,
            decoration: InputDecoration(labelText: tr('Point de retrait')),
            items: _pointsRetrait
                .map(
                  (p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.nom, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _pointRetraitId = v),
          )
        else ...[
          ChampTexte(
            key: _repere('adresseLivraison'),
            controller: _adresseLivraison,
            label: tr('Adresse de livraison'),
            icone: Icons.home_outlined,
            maxLength: 255,
          ),
          ChampTexte(
            key: _repere('codePostalArrivee'),
            controller: _codePostalArrivee,
            label: tr('Code postal (facultatif)'),
            clavier: TextInputType.number,
            maxLength: 10,
            icone: Icons.markunread_mailbox_outlined,
          ),
        ],
        if (_paysArrivee == 'SN') ...[
          const SizedBox(height: 4),
          Text(
            _adresseSnObligatoire ? tr('Précisions obligatoires au Sénégal') : tr('Précisions (recommandées)'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _adresseSnObligatoire ? AppColor.kErreur : AppColor.kGrayscale40,
            ),
          ),
          const SizedBox(height: 8),
          ChampTexte(key: _repere('precisionsSn'), controller: _quartier, label: tr('Quartier'), maxLength: 100),
          ChampTexte(controller: _arrondissement, label: tr('Arrondissement'), maxLength: 100),
          ChampTexte(controller: _departement, label: tr('Département'), maxLength: 100),
          ChampTexte(
            controller: _pointRepere,
            label: tr('Point de repère'),
            hint: tr('Ex : face à la grande mosquée'),
            maxLength: 255,
          ),
        ],
        ChampTexte(
          controller: _instructionsLivraison,
          label: tr('Instructions de livraison (facultatif)'),
          maxLines: 2,
          maxLength: 500,
        ),
      ],
    ),
    const SizedBox(height: 14),
    ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        tr('Informations complémentaires (facultatif)'),
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(tr('Votre référence, numéros EORI / NINEA pour la douane'), style: texteDiscret(12)),
      children: [
        ChampTexte(controller: _referenceClient, label: tr('Votre référence'), maxLength: 50),
        ChampTexte(controller: _numeroEori, label: tr('Numéro EORI'), maxLength: 20),
        ChampTexte(controller: _numeroNinea, label: tr('Numéro NINEA'), maxLength: 20),
      ],
    ),
  ];

  List<Widget> _etapeValidation() {
    final demande = _villeDepart != null && _villeArrivee != null ? _demande() : null;
    return [
      if (_categorie.code != 'documents') ...[
        Text(tr('Qui règle l\'expédition ?'), style: texteDiscret(13)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'expediteur', label: Text(tr('Moi (expéditeur)'))),
            ButtonSegment(value: 'destinataire', label: Text(tr('Le destinataire'))),
          ],
          selected: {_payeur},
          onSelectionChanged: _calcul
              ? null
              : (v) {
                  setState(() => _payeur = v.first);
                  _calculerDevis();
                },
        ),
        const SizedBox(height: 12),
        Text(tr('Droits et taxes de douane'), style: texteDiscret(13)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'DAP', label: Text(tr('Payés à l\'arrivée'))),
            ButtonSegment(value: 'DDP', label: Text(tr('Inclus au devis'))),
          ],
          selected: {_incoterm},
          onSelectionChanged: _calcul
              ? null
              : (v) {
                  setState(() => _incoterm = v.first);
                  _calculerDevis();
                },
        ),
        const SizedBox(height: 18),
      ],
      Text(tr('Choisissez votre transport'), style: titreSection(17)),
      const SizedBox(height: 12),
      if (_calcul)
        const Center(
          child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
        ),
      if (_erreurDevis != null)
        Bandeau(
          icone: Icons.error_outline,
          titre: tr('Tarif indisponible'),
          message: _erreurDevis,
          couleur: AppColor.kErreur,
          action: TextButton(onPressed: _calculerDevis, child: Text(tr('Réessayer'))),
        ),
      SizedBox.shrink(key: _repere('offres')),
      ...?_devis?.offres.map(
        (o) => CarteOffre(
          offre: o,
          selectionnee: _offre?.service.id == o.service.id,
          onTap: () => setState(() => _offre = o),
        ),
      ),
      if (demande != null) ...[
        const SizedBox(height: 8),
        CarteSection(
          titre: tr('Récapitulatif'),
          icone: Icons.fact_check_outlined,
          children: [
            LigneInfo(tr('Catégorie'), '${_categorie.numero}. ${_categorie.libelle}'),
            LigneInfo(tr('Trajet'), '${_villeDepart?.nom} → ${_villeArrivee?.nom}'),
            LigneInfo(tr('Remise'), libellesModeDepot[demande.modeDepot] ?? demande.modeDepot),
            LigneInfo(tr('Destinataire'), demande.destinataireNom),
            LigneInfo(
              tr('Livraison'),
              demande.modeLivraison == 'point_retrait' ? tr('Point de retrait') : demande.adresseLivraison ?? '',
            ),
            LigneInfo(tr('Photos'), '${_photos.whereType<String>().length}'),
            if (_categorie.code != 'documents') ...[
              LigneInfo(tr('Nature'), tr(_naturesEnvoi[demande.typeContenu] ?? demande.typeContenu)),
              if (demande.fragile) LigneInfo(tr('Fragile'), tr('Oui')),
              if (demande.marchandiseDangereuse) LigneInfo(tr('Marchandise dangereuse'), tr('Oui')),
              if (demande.contenu.isNotEmpty)
                LigneInfo(tr('Inventaire douane'), tr('${demande.contenu.length} article(s)')),
              LigneInfo(tr('Assurance'), demande.assuranceSouscrite ? tr('Oui') : tr('Non')),
              LigneInfo(tr('Payé par'), demande.payeur == 'destinataire' ? tr('Le destinataire') : tr('L\'expéditeur')),
            ],
            if (_offre != null)
              LigneInfo(
                _offre!.surDevis ? tr('Estimation') : tr('Total'),
                formaterMontant(_offre!.total, _offre!.devise),
                fort: true,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Bandeau(
          icone: Icons.route_outlined,
          titre: tr('La suite'),
          message: switch (_categorie.paiement) {
            'a_la_commande' => tr(
              'Dès l\'envoi de votre demande, votre facture est émise et le lien de paiement s\'ouvre.',
            ),
            'a_la_reception' => tr(
              'Nos équipes valident votre demande sous ${_config?.delaiEtudeHeures ?? 24} h. Vous paierez à la réception de votre colis.',
            ),
            _ => tr(
              'Nous étudions votre demande et vous envoyons une proposition de prix sous ${_config?.delaiEtudeHeures ?? 24} h, à accepter avant paiement.',
            ),
          },
        ),
      ],
      const SizedBox(height: 8),
      CheckboxListTile(
        key: _repere('conditions'),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: _conditions,
        onChanged: (v) => setState(() => _conditions = v ?? false),
        title: Text(tr('J\'accepte les conditions générales de vente et de transport')),
        subtitle: _config?.lien('cgv') == null
            ? null
            : GestureDetector(
                onTap: () => ouvrirLien(context, _config!.lien('cgv')),
                child: Text(tr('Lire les conditions'), style: TextStyle(decoration: TextDecoration.underline)),
              ),
      ),
      if (_config?.produitsInterdits.isNotEmpty == true)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            tr('Produits interdits'),
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          children: _config!.produitsInterdits
              .map(
                (p) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.block, size: 18, color: AppColor.kErreur),
                  title: Text(p),
                ),
              )
              .toList(),
        ),
    ];
  }
}
