import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../catalogue/data/catalogue_remote_datasource.dart';
import '../../../catalogue/domain/catalogue_entities.dart';
import '../../../colis/domain/entities/demande_expedition.dart';
import '../../../expedition/presentation/pages/assistant_expedition_page.dart';
import '../../../expedition/presentation/widgets/carte_offre.dart';
import '../../../expedition/presentation/widgets/choix_categorie.dart';
import '../../../expedition/presentation/widgets/selecteur_articles.dart';
import '../../../expedition/presentation/widgets/selecteur_ville.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/utils/validateurs.dart';

/// Calculateur de tarif façon DHL « Obtenir un devis » : accessible sans
/// compte, il compare les offres (fret maritime, aérien) pour la catégorie,
/// le trajet et le contenu choisis, puis enchaîne sur l'expédition.
class DevisPage extends StatefulWidget {
  final String? categorie;
  const DevisPage({super.key, this.categorie});

  @override
  State<DevisPage> createState() => _DevisPageState();
}

class _DevisPageState extends State<DevisPage> {
  final _source = sl<CatalogueRemoteDataSource>();
  final _poids = TextEditingController();
  final _longueur = TextEditingController();
  final _largeur = TextEditingController();
  final _hauteur = TextEditingController();

  CategorieColis _categorie = CategorieColis.colisMoyen;
  bool _versSenegal = true;
  List<VilleDesservie> _villesFr = [];
  List<VilleDesservie> _villesSn = [];
  VilleDesservie? _depart;
  VilleDesservie? _arrivee;
  bool _chargement = true;

  List<ArticleTarif> _articles = [];
  final Map<String, int> _quantites = {};
  bool _parGrille = true;
  String _modeDepot = 'point_collecte';
  bool _fragile = false;
  bool _dangereuse = false;

  bool _calcul = false;
  String? _erreur;
  ResultatDevis? _resultat;

  VilleDesservie? get _villeSn => _versSenegal ? _arrivee : _depart;

  @override
  void initState() {
    super.initState();
    _categorie = CategorieColis.parCode(widget.categorie ?? CategorieColis.colisMoyen.code);
    _initialiser();
  }

  @override
  void dispose() {
    for (final c in [_poids, _longueur, _largeur, _hauteur]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _initialiser() async {
    try {
      final r = await Future.wait([_source.getVilles(pays: 'FR'), _source.getVilles(pays: 'SN')]);
      if (!mounted) return;
      setState(() {
        _villesFr = r[0];
        _villesSn = r[1];
      });
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
    _chargerArticles();
  }

  Future<void> _chargerArticles() async {
    if (_categorie.code == 'documents') {
      setState(() => _articles = []);
      return;
    }
    try {
      final articles = await _source.getTarifs(
          categorie: _categorie.code, paysDepart: _versSenegal ? 'FR' : 'SN', paysArrivee: _versSenegal ? 'SN' : 'FR');
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _quantites.clear();
        _parGrille = _categorie.code == 'colis_moyen' && articles.isNotEmpty;
      });
    } on ServerException catch (_) {
      if (mounted) setState(() => _parGrille = false);
    }
  }

  double? _n(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  DemandeExpedition? _besoin() {
    if (_depart == null || _arrivee == null) return null;
    final articles = _articles
        .where((a) => (_quantites[a.id] ?? 0) > 0)
        .map((a) => ArticleChoisi(articleTarifId: a.id, libelle: a.libelle, quantite: _quantites[a.id]!))
        .toList();
    final poids = _n(_poids);
    final avecPiece = !_parGrille && _categorie.code != 'documents' && poids != null && poids > 0;
    return DemandeExpedition(
      categorie: _categorie.code,
      villeDepartId: _depart!.id,
      villeArriveeId: _arrivee!.id,
      articles: _parGrille || _categorie.code == 'colis_xxl' ? articles : const [],
      pieces: avecPiece
          ? [PieceDeclaree(poidsKg: poids, longueurCm: _n(_longueur), largeurCm: _n(_largeur), hauteurCm: _n(_hauteur))]
          : const [],
      modeDepot: _modeDepot,
      fragile: _categorie.code != 'documents' && _fragile,
      marchandiseDangereuse: _categorie.code != 'documents' && _dangereuse,
    );
  }

  Future<void> _calculer() async {
    final besoin = _besoin();
    if (besoin == null) {
      setState(() => _erreur = tr('Choisissez la ville de départ et d\'arrivée.'));
      return;
    }
    if (_categorie.code != 'documents' && besoin.articles.isEmpty && besoin.pieces.isEmpty) {
      setState(() => _erreur = tr('Choisissez un article ou indiquez le poids de votre colis.'));
      return;
    }
    // Limites de l'API : 1000 kg, 500 cm par dimension
    final erreurMesure = nombre(max: 1000)(_poids.text) ??
        [_longueur, _largeur, _hauteur].map((c) => nombre(max: 500)(c.text)).whereType<String>().firstOrNull;
    if (erreurMesure != null) {
      setState(() => _erreur = tr('Poids ou dimensions : $erreurMesure'));
      return;
    }
    // La longueur est le plus grand côté ; égalité admise pour une base carrée.
    final longueur = _n(_longueur), largeur = _n(_largeur);
    if (longueur != null && largeur != null && largeur > longueur) {
      setState(() => _erreur = tr('La largeur ne peut pas être supérieure à la longueur.'));
      return;
    }
    setState(() {
      _calcul = true;
      _erreur = null;
      _resultat = null;
    });
    try {
      final connecte = await isUserAuthenticated();
      final resultat = await _source.devis(besoin.versDevis(), connecte: connecte);
      if (!mounted) return;
      setState(() {
        _resultat = resultat;
        if (resultat.offres.isEmpty) {
          _erreur = resultat.indisponibles.map((i) => '${i.serviceNom} : ${i.motif}').join('\n');
        }
      });
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _calcul = false);
    }
  }

  Future<void> _expedier() async {
    final connecte = await isUserAuthenticated();
    if (!mounted) return;
    if (!connecte) {
      Navigator.of(context).pushNamed(AppRouter.loginRoute);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AssistantExpeditionPage(
        preremplissage: PreremplissageExpedition(
          categorie: _categorie.code,
          versSenegal: _versSenegal,
          villeDepartId: _depart?.id,
          villeArriveeId: _arrivee?.id,
          articles: Map.of(_quantites)..removeWhere((_, q) => q == 0),
          poidsKg: _parGrille ? null : _n(_poids),
          modeDepot: _modeDepot,
          fragile: _fragile,
          marchandiseDangereuse: _dangereuse,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(tr('Calculer un tarif'))),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: [
              Text(tr('Simulez votre envoi, sans compte.'), style: texteDiscret(13)),
              const SizedBox(height: 14),
              ChoixCategorie(
                selection: _categorie.code,
                compact: true,
                onChanged: (c) {
                  setState(() {
                    _categorie = c;
                    _resultat = null;
                    if (!c.modesDepot.contains(_modeDepot)) _modeDepot = c.modesDepot.first;
                  });
                  _chargerArticles();
                },
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(tr('France → Sénégal'))),
                  ButtonSegment(value: false, label: Text(tr('Sénégal → France'))),
                ],
                selected: {_versSenegal},
                onSelectionChanged: (s) {
                  setState(() {
                    _versSenegal = s.first;
                    _depart = null;
                    _arrivee = null;
                    _resultat = null;
                  });
                  _chargerArticles();
                },
              ),
              const SizedBox(height: 12),
              SelecteurVille(
                label: tr('Ville de départ'),
                villes: _versSenegal ? _villesFr : _villesSn,
                valeur: _depart,
                onChanged: (v) => setState(() => _depart = v),
              ),
              const SizedBox(height: 10),
              SelecteurVille(
                label: tr('Ville de destination'),
                villes: _versSenegal ? _villesSn : _villesFr,
                valeur: _arrivee,
                onChanged: (v) => setState(() => _arrivee = v),
              ),
              const SizedBox(height: 16),
              if (_categorie.code == 'colis_moyen' && _articles.isNotEmpty) ...[
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text(tr('Grille tarifaire'))),
                    ButtonSegment(value: false, label: Text(tr('Au poids'))),
                  ],
                  selected: {_parGrille},
                  onSelectionChanged: (s) => setState(() => _parGrille = s.first),
                ),
                const SizedBox(height: 12),
              ],
              if ((_parGrille || _categorie.code == 'colis_xxl') && _articles.isNotEmpty)
                SelecteurArticles(
                  articles: _articles,
                  quantites: _quantites,
                  zoneDakar: _villeSn?.zoneTarifDakar ?? false,
                  onChanged: (a, q) => setState(() => _quantites[a.id] = q),
                ),
              if (!_parGrille && _categorie.code != 'documents') ...[
                ChampTexte(
                  controller: _poids,
                  label: _categorie.code == 'colis_xxl' ? tr('Poids estimé (kg)') : tr('Poids (kg)'),
                  clavier: const TextInputType.numberWithOptions(decimal: true),
                  icone: Icons.scale_outlined,
                ),
                Row(children: [
                  Expanded(child: ChampTexte(controller: _longueur, label: tr('Longueur'), hint: 'cm', clavier: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: ChampTexte(controller: _largeur, label: tr('Largeur'), hint: 'cm', clavier: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: ChampTexte(controller: _hauteur, label: tr('Hauteur'), hint: 'cm', clavier: TextInputType.number)),
                ]),
              ],
              const SizedBox(height: 8),
              Text(tr('Remise du colis'), style: titreSection(14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categorie.modesDepot
                    .map((m) => ChoiceChip(
                          avatar: Icon(iconesModeDepot[m],
                              size: 18, color: _modeDepot == m ? AppColor.kWhite : AppColor.kPrimary),
                          label: Text(libellesModeDepot[m] ?? m),
                          selected: _modeDepot == m,
                          onSelected: (_) => setState(() => _modeDepot = m),
                        ))
                    .toList(),
              ),
              if (_categorie.code != 'documents') ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('Colis fragile')),
                  value: _fragile,
                  onChanged: (v) => setState(() => _fragile = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('Marchandise dangereuse')),
                  value: _dangereuse,
                  onChanged: (v) => setState(() => _dangereuse = v),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _calcul ? null : _calculer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.kSecondary,
                  foregroundColor: AppColor.kPrimary,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _calcul
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(tr('Comparer les offres')),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 16),
                Bandeau(icone: Icons.error_outline, titre: tr('Tarif indisponible'), message: _erreur, couleur: AppColor.kErreur),
              ],
              if (_resultat != null && _resultat!.offres.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(tr('${_resultat!.offres.length} offre(s) disponible(s)'), style: titreSection()),
                if (_resultat!.remiseParrainagePourcent > 0)
                  Text(tr('Bonus filleul de ${_resultat!.remiseParrainagePourcent.toStringAsFixed(0)} % inclus.'),
                      style: GoogleFonts.plusJakartaSans(color: AppColor.kSucces, fontSize: 12)),
                const SizedBox(height: 12),
                ..._resultat!.offres.map((o) => CarteOffre(
                      offre: o,
                      action: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(onPressed: _expedier, child: Text(tr('Expédier avec cette offre'))),
                      ),
                    )),
              ],
            ]),
    );
  }
}
