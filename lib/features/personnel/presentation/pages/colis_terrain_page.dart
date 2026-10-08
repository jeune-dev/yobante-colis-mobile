import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/config/user_role.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/pastille_notifications.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../colis/presentation/widgets/statut_badge.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../notifications/presentation/widgets/apercu_notifications.dart';
import '../../data/personnel_remote_datasource.dart';
import '../widgets/ui_personnel.dart';

/// Regroupements de statuts proposés à chaque rôle, dans l'ordre de son travail
/// (liste vide = tous les colis du périmètre).
Map<String, (IconData, List<String>)> _filtresPour(UserRole role) => switch (role) {
      UserRole.coursier => {
          tr('À livrer'): (Icons.delivery_dining_outlined, ['arrive', 'disponible_retrait', 'en_livraison']),
          tr('À ramasser'): (Icons.move_to_inbox_outlined, ['en_attente', 'enlevement_planifie']),
          tr('Tous'): (Icons.inventory_2_outlined, <String>[]),
        },
      UserRole.agentPoint => {
          tr('À réceptionner'): (Icons.move_to_inbox_outlined, ['en_attente', 'enlevement_planifie', 'enleve']),
          tr('En stock'): (Icons.warehouse_outlined, ['receptionne', 'en_preparation', 'arrive']),
          tr('À retirer'): (Icons.how_to_reg_outlined, ['disponible_retrait']),
          tr('Tous'): (Icons.inventory_2_outlined, <String>[]),
        },
      _ => {
          tr('Incidents'): (Icons.report_outlined, ['incident']),
          tr('En livraison'): (Icons.delivery_dining_outlined, ['en_livraison']),
          tr('À retirer'): (Icons.how_to_reg_outlined, ['disponible_retrait']),
          tr('Tous'): (Icons.inventory_2_outlined, <String>[]),
        },
    };

Color _accent(ColisTerrain c) {
  if (c.enRetard || c.statut == 'incident') return AppColor.kErreur;
  if (const ['livre', 'recupere', 'disponible_retrait'].contains(c.statut)) return AppColor.kSucces;
  if (c.statut == 'en_livraison') return AppColor.kSecondaryDark;
  return AppColor.kPrimary;
}

/// Colis du périmètre du compte : livraisons du coursier, stock du point de l'agent.
class ColisTerrainPage extends StatefulWidget {
  final UserRole role;

  /// Premier onglet de l'espace : les dernières notifications sont affichées en tête.
  final bool afficherNotifications;
  const ColisTerrainPage({super.key, required this.role, this.afficherNotifications = false});

  @override
  State<ColisTerrainPage> createState() => _ColisTerrainPageState();
}

class _ColisTerrainPageState extends State<ColisTerrainPage> {
  final _source = sl<PersonnelRemoteDataSource>();
  late final _filtres = _filtresPour(widget.role);
  late String _filtre = _filtres.keys.first;
  List<ColisTerrain>? _tous;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  /// Un seul chargement du périmètre : les filtres et leurs compteurs en découlent.
  Future<void> _charger() async {
    setState(() => _erreur = null);
    try {
      final tous = await _source.getColis();
      if (mounted) setState(() => _tous = tous);
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    }
  }

  List<ColisTerrain> _liste(String filtre) {
    final statuts = _filtres[filtre]!.$2;
    final tous = _tous ?? const <ColisTerrain>[];
    return statuts.isEmpty ? tous : tous.where((c) => statuts.contains(c.statut)).toList();
  }

  Future<void> _ouvrir(ColisTerrain c) async {
    final change =
        await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => DetailColisTerrainPage(id: c.id)));
    if (change == true) _charger();
  }

  @override
  Widget build(BuildContext context) {
    final charge = _tous != null;
    final compteurs = {for (final f in _filtres.keys) f: _liste(f).length};
    final liste = _liste(_filtre);
    final coursier = widget.role == UserRole.coursier;

    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: barreEspace(
        switch (widget.role) {
          UserRole.coursier => tr('Mes livraisons'),
          UserRole.agentPoint => tr('Mon point'),
          _ => tr('Expéditions'),
        },
        actions: [
          IconButton(
            icon: const PastilleNotifications(child: Icon(Icons.notifications_none_rounded, color: AppColor.kWhite)),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsPage())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            EnteteEspace(
              role: widget.role,
              titre: switch (widget.role) {
                UserRole.coursier => tr('Vos colis du moment'),
                UserRole.agentPoint => tr('Activité de votre point'),
                _ => tr('Expéditions à suivre'),
              },
              indicateurs: [
                // Trois indicateurs au plus : « Tous » reste dans les pilules
                for (final f in _filtres.keys.where((k) => _filtres[k]!.$2.isNotEmpty).take(3))
                  Indicateur(
                    charge ? '${compteurs[f]}' : '–',
                    f,
                    _filtres[f]!.$1,
                    actif: f == _filtre,
                    onTap: () => setState(() => _filtre = f),
                  ),
              ],
            ),
            if (widget.afficherNotifications)
              const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 0), child: ApercuNotifications(nombre: 2)),
            TitreListe(tr('Colis')),
            FiltresPilules<String>(
              options: {for (final f in _filtres.keys) f: f},
              compteurs: charge ? compteurs : null,
              valeur: _filtre,
              onChanged: (f) => setState(() => _filtre = f),
            ),
            const SizedBox(height: 12),
            if (_erreur != null)
              EmptyState(
                icon: Icons.error_outline,
                title: tr('Erreur'),
                subtitle: _erreur!,
                actionLabel: tr('Réessayer'),
                onAction: _charger,
                scrollable: false,
              )
            else if (!charge)
              const SizedBox(height: 320, child: ShimmerList(itemCount: 3))
            else if (liste.isEmpty)
              EmptyState(
                icon: Icons.inventory_2_outlined,
                title: tr('Aucun colis'),
                subtitle: tr('Aucun colis ne correspond à ce filtre pour le moment.'),
                scrollable: false,
              )
            else
              for (final c in liste)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _CarteColis(colis: c, coursier: coursier, onTap: () => _ouvrir(c)),
                ),
          ],
        ),
      ),
    );
  }
}

class _CarteColis extends StatelessWidget {
  final ColisTerrain colis;
  final bool coursier;
  final VoidCallback onTap;
  const _CarteColis({required this.colis, required this.coursier, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = colis;
    final domicile = c.modeLivraison == 'livraison_domicile';
    final adresse = [c.adresseLivraison, c.villeArrivee].whereType<String>().where((v) => v.isNotEmpty).join(', ');
    return CarteMission(
      icone: domicile ? Icons.home_outlined : Icons.storefront_outlined,
      titre: c.reference,
      sousTitre: tr('Pour {nom}').replaceAll('{nom}', c.destinataireNom),
      statut: StatutBadge(statut: c.statut),
      accent: _accent(c),
      onTap: onTap,
      lignes: [
        (Icons.route_outlined, '${c.villeDepart ?? '—'} → ${c.villeArrivee ?? '—'}'),
        if (domicile && adresse.isNotEmpty)
          (Icons.place_outlined, adresse)
        else if (c.pointActuel != null)
          (Icons.storefront_outlined, tr('Actuellement : {p}').replaceAll('{p}', c.pointActuel!)),
        if (c.enRetard) (Icons.schedule_outlined, tr('En retard')),
      ],
      // Le coursier en tournée de livraison appelle et se fait guider depuis la liste
      pied: coursier && domicile && const ['arrive', 'en_livraison'].contains(c.statut)
          ? Row(children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => appeler(context, c.destinataireTelephone),
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: Text(tr('Appeler')),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => ouvrirItineraire(context, adresse),
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: Text(tr('Itinéraire')),
                ),
              ),
            ])
          : null,
    );
  }
}

/// Recherche d'un colis par son numéro de suivi (ou celui d'une pièce), au comptoir ou sur le terrain.
class RechercheColisTerrainPage extends StatefulWidget {
  const RechercheColisTerrainPage({super.key});

  @override
  State<RechercheColisTerrainPage> createState() => _RechercheColisTerrainPageState();
}

class _RechercheColisTerrainPageState extends State<RechercheColisTerrainPage> {
  final _numero = TextEditingController();
  bool _recherche = false;
  String? _erreur;

  @override
  void dispose() {
    _numero.dispose();
    super.dispose();
  }

  Future<void> _chercher() async {
    final numero = _numero.text.trim();
    if (numero.isEmpty) {
      setState(() => _erreur = tr('Saisissez un numéro de suivi.'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _recherche = true;
      _erreur = null;
    });
    try {
      final id = await sl<PersonnelRemoteDataSource>().rechercher(numero);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailColisTerrainPage(id: id)));
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _recherche = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: barreEspace(tr('Rechercher')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            decoration: const BoxDecoration(
              color: AppColor.kSecondary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('Retrouver un colis'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColor.kPrimary)),
              const SizedBox(height: 4),
              Text(tr('Saisissez le numéro inscrit sur l\'étiquette du colis.'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColor.kPrimary.withValues(alpha: 0.75))),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(16), boxShadow: ombreCarte),
                padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
                child: Row(children: [
                  const Icon(Icons.qr_code_2_rounded, color: AppColor.kPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _numero,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _chercher(),
                      onChanged: (_) {
                        if (_erreur != null) setState(() => _erreur = null);
                      },
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, letterSpacing: 0.6),
                      decoration: InputDecoration(
                        hintText: 'YC-FR-SN-10452',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: _recherche ? null : _chercher,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.kPrimary,
                      minimumSize: const Size(52, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _recherche
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.kWhite))
                        : const Icon(Icons.search),
                  ),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              if (_erreur != null) ...[
                Bandeau(icone: Icons.search_off, titre: _erreur!, couleur: AppColor.kErreur),
                const SizedBox(height: 16),
              ],
              SectionDetail(
                titre: tr('Où trouver le numéro ?'),
                icone: Icons.help_outline,
                children: [
                  InfoIcone(Icons.label_outline, tr('Étiquette'), tr('Sous le code-barres, sur chaque colis')),
                  InfoIcone(Icons.receipt_long_outlined, tr('Bordereau'), tr('En haut du bordereau remis au client')),
                  InfoIcone(Icons.layers_outlined, tr('Colis en plusieurs pièces'), tr('Le numéro d\'une pièce retrouve tout l\'envoi')),
                ],
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Pictogramme d'une étape de suivi dans le choix des étapes.
IconData _iconeEvenement(String code) => switch (code) {
      'ENL_OK' => Icons.move_to_inbox_outlined,
      'DEPOT' || 'RECEPTION' || 'ARR_AGENCE' => Icons.warehouse_outlined,
      'DISPO' => Icons.storefront_outlined,
      'EN_LIVRAISON' => Icons.delivery_dining_outlined,
      'LIVRE' || 'RETIRE' => Icons.how_to_reg_outlined,
      'ENL_ECHEC' || 'LIV_ECHEC' => Icons.event_busy_outlined,
      'REFUSE' => Icons.block_outlined,
      'AVARIE' => Icons.broken_image_outlined,
      'RETARD' => Icons.schedule_outlined,
      _ => Icons.info_outline,
    };

/// Détail d'un colis pour le personnel : contacts, acheminement, règlement,
/// et mise à jour du suivi limitée aux étapes de sa mission.
class DetailColisTerrainPage extends StatefulWidget {
  final String id;
  const DetailColisTerrainPage({super.key, required this.id});

  @override
  State<DetailColisTerrainPage> createState() => _DetailColisTerrainPageState();
}

class _DetailColisTerrainPageState extends State<DetailColisTerrainPage> {
  final _source = sl<PersonnelRemoteDataSource>();
  ColisTerrain? _c;
  String? _erreur;
  bool _change = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final c = await _source.getColisDetail(widget.id);
      if (mounted) setState(() => _c = c);
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    }
  }

  Future<void> _mettreAJour() async {
    final c = _c;
    if (c == null) return;
    final evenement = await showModalBottomSheet<EvenementPossible>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColor.kBackground,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.75),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(tr('Nouvelle étape'), style: titreSection(18)),
              const SizedBox(height: 4),
              Text(tr('Choisissez ce qui vient de se passer pour ce colis.'), style: texteDiscret(13)),
              const SizedBox(height: 14),
              for (final e in c.evenementsPossibles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: AppColor.kWhite,
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      leading: TuileIcone(
                        _iconeEvenement(e.code),
                        taille: 38,
                        fond: e.exigeMotif ? AppColor.kErreurLight : AppColor.kPrimaryLight,
                        couleur: e.exigeMotif ? AppColor.kErreur : AppColor.kPrimary,
                      ),
                      title: Text(tr(e.libelle), style: titreSection(14)),
                      subtitle: e.statutInduit == null
                          ? Text(tr('Information, sans changement de statut'), style: texteDiscret(12))
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(ctx).pop(e),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (evenement == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogueEvenement(colis: c, evenement: evenement),
    );
    if (ok == true && mounted) {
      _change = true;
      _charger();
    }
  }

  Future<void> _encaisser(FactureTerrain f) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => _DialogueEncaissement(facture: f));
    if (ok == true && mounted) {
      _change = true;
      _charger();
    }
  }

  Widget _puce(IconData icone, String texte, {Color fond = AppColor.kPrimaryDark, Color couleur = AppColor.kWhite}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 14, color: couleur),
          const SizedBox(width: 5),
          Text(texte, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: couleur)),
        ]),
      );

  Widget _ville(String libelle, String? ville, CrossAxisAlignment alignement) => Column(
        crossAxisAlignment: alignement,
        children: [
          Text(libelle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kWhite.withValues(alpha: 0.7))),
          Text(ville ?? '—',
              style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppColor.kWhite)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final f = c?.facture;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_change);
      },
      child: Scaffold(
        backgroundColor: AppColor.kBackground,
        appBar: barreEspace(tr('Expédition')),
        bottomNavigationBar: c == null || c.evenementsPossibles.isEmpty
            ? null
            : BarreActions(children: [
                FilledButton.icon(
                  onPressed: _mettreAJour,
                  icon: const Icon(Icons.update),
                  label: Text(tr('Mettre à jour le suivi')),
                  style: styleBoutonPlein(AppColor.kPrimary),
                ),
              ]),
        body: _erreur != null
            ? EmptyState(icon: Icons.error_outline, title: tr('Erreur'), subtitle: _erreur!)
            : c == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _charger,
                    child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
                      HeroDetail(
                        surTitre: tr('Expédition'),
                        reference: c.reference,
                        statut: StatutBadge(statut: c.statut),
                        contenu: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: _ville(tr('Départ'), c.villeDepart, CrossAxisAlignment.start)),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: AppColor.kSecondary, shape: BoxShape.circle),
                              child: const Icon(Icons.flight_takeoff_rounded, size: 18, color: AppColor.kPrimary),
                            ),
                            Expanded(child: _ville(tr('Arrivée'), c.villeArrivee, CrossAxisAlignment.end)),
                          ]),
                          const SizedBox(height: 14),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            _puce(Icons.all_inbox_outlined, tr('{n} colis').replaceAll('{n}', '${c.nbPieces}')),
                            if (c.poidsKg != null) _puce(Icons.scale_outlined, '${c.poidsKg!.toStringAsFixed(1)} kg'),
                            _puce(
                              c.modeLivraison == 'livraison_domicile' ? Icons.home_outlined : Icons.storefront_outlined,
                              c.modeLivraison == 'livraison_domicile' ? tr('Livraison à domicile') : tr('Retrait en point'),
                            ),
                            if (c.fragile)
                              _puce(Icons.wine_bar_outlined, tr('Fragile'), fond: AppColor.kSecondary, couleur: AppColor.kPrimary),
                            if (c.enRetard)
                              _puce(Icons.schedule_outlined, tr('En retard'), fond: AppColor.kErreur),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      CarteContact(
                        role: tr('Destinataire'),
                        nom: c.destinataireNom,
                        telephone: c.destinataireTelephone,
                        adresse: c.modeLivraison == 'livraison_domicile'
                            ? [c.adresseLivraison, c.villeArrivee].whereType<String>().where((v) => v.isNotEmpty).join(', ')
                            : null,
                        details: [
                          if (c.instructionsLivraison != null && c.instructionsLivraison!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColor.kSecondaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Icon(Icons.sticky_note_2_outlined, size: 18, color: AppColor.kSecondaryDark),
                                const SizedBox(width: 8),
                                Expanded(child: Text(c.instructionsLivraison!)),
                              ]),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      CarteContact(role: tr('Expéditeur'), nom: c.expediteurNom, telephone: c.expediteurTelephone),
                      const SizedBox(height: 14),
                      SectionDetail(
                        titre: tr('Acheminement'),
                        icone: Icons.route_outlined,
                        children: [
                          InfoIcone(Icons.my_location_outlined, tr('Point actuel'), c.pointActuel ?? '—'),
                          if (c.pointRetrait != null) InfoIcone(Icons.storefront_outlined, tr('Point de retrait'), c.pointRetrait!),
                          if (c.description != null && c.description!.isNotEmpty)
                            InfoIcone(Icons.category_outlined, tr('Contenu'), c.description!),
                        ],
                      ),
                      if (f != null) ...[
                        const SizedBox(height: 14),
                        SectionDetail(
                          titre: tr('Règlement'),
                          icone: Icons.payments_outlined,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(tr('Reste à payer'), style: texteDiscret(12)),
                                  Text(
                                    formaterMontant(f.reste, f.devise),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: f.reste > 0 ? AppColor.kPrimary : AppColor.kSucces,
                                    ),
                                  ),
                                ]),
                              ),
                              Text(f.reference, style: texteDiscret(12)),
                            ]),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: f.montantTotal <= 0 ? 1 : (f.montantPaye / f.montantTotal).clamp(0, 1).toDouble(),
                                minHeight: 8,
                                backgroundColor: AppColor.kPrimaryLight,
                                color: AppColor.kSucces,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tr('{p} payés sur {t}')
                                  .replaceAll('{p}', formaterMontant(f.montantPaye, f.devise))
                                  .replaceAll('{t}', formaterMontant(f.montantTotal, f.devise)),
                              style: texteDiscret(12),
                            ),
                            if (f.aEncaisser) ...[
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: () => _encaisser(f),
                                icon: const Icon(Icons.point_of_sale_outlined),
                                label: Text(tr('Encaisser')),
                                style: styleBoutonPlein(AppColor.kSucces),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (c.historique.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SectionDetail(
                          titre: tr('Historique'),
                          icone: Icons.history,
                          children: [
                            Chronologie(etapes: [
                              for (final etape in c.historique)
                                (
                                  tr(etape.libelle),
                                  [formaterDate(etape.date, avecHeure: true), etape.lieu]
                                      .whereType<String>()
                                      .where((v) => v.isNotEmpty)
                                      .join(' · '),
                                  etape.commentaire,
                                ),
                            ]),
                          ],
                        ),
                      ],
                    ]),
                  ),
      ),
    );
  }
}

/// Saisie d'une étape de suivi : code de retrait à la remise, motif en cas d'échec.
class _DialogueEvenement extends StatefulWidget {
  final ColisTerrain colis;
  final EvenementPossible evenement;
  const _DialogueEvenement({required this.colis, required this.evenement});

  @override
  State<_DialogueEvenement> createState() => _DialogueEvenementState();
}

class _DialogueEvenementState extends State<_DialogueEvenement> {
  final _code = TextEditingController();
  final _motif = TextEditingController();
  final _commentaire = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _code.dispose();
    _motif.dispose();
    _commentaire.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final e = widget.evenement;
    if (e.exigeMotif && _motif.text.trim().isEmpty) {
      setState(() => _erreur = tr('Indiquez le motif.'));
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final message = await sl<PersonnelRemoteDataSource>().enregistrerEvenement(
        widget.colis.id,
        e.code,
        commentaire: _commentaire.text,
        motif: e.exigeMotif ? _motif.text : null,
        codeRetrait: e.exigeCodeRetrait(widget.colis) ? _code.text : null,
      );
      if (!mounted) return;
      showToast(context, tr('Suivi mis à jour'), message, ToastificationType.success);
      Navigator.of(context).pop(true);
    } on ServerException catch (err) {
      if (mounted) {
        setState(() {
          _envoi = false;
          _erreur = err.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.evenement;
    return AlertDialog(
      title: Text(tr(e.libelle)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (e.exigeCodeRetrait(widget.colis))
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: tr('Code de retrait'),
                helperText: tr('Demandez au destinataire le code de retrait qu\'il a reçu.'),
                helperMaxLines: 2,
              ),
            ),
          if (e.exigeMotif)
            TextField(
              controller: _motif,
              maxLength: 255,
              decoration: InputDecoration(labelText: tr('Motif')),
            ),
          TextField(
            controller: _commentaire,
            maxLength: 500,
            maxLines: 2,
            decoration: InputDecoration(labelText: tr('Commentaire (facultatif)')),
          ),
          if (_erreur != null) Text(_erreur!, style: TextStyle(color: AppColor.kErreur, fontSize: 13)),
        ]),
      ),
      actions: [
        TextButton(onPressed: _envoi ? null : () => Navigator.of(context).pop(false), child: Text(tr('Annuler'))),
        FilledButton(onPressed: _envoi ? null : _valider, child: Text(tr('Enregistrer'))),
      ],
    );
  }
}

/// Encaissement d'un règlement reçu en main propre (comptoir ou livraison).
class _DialogueEncaissement extends StatefulWidget {
  final FactureTerrain facture;
  const _DialogueEncaissement({required this.facture});

  @override
  State<_DialogueEncaissement> createState() => _DialogueEncaissementState();
}

class _DialogueEncaissementState extends State<_DialogueEncaissement> {
  late final _montant = TextEditingController(
    text: widget.facture.devise == 'EUR'
        ? widget.facture.reste.toStringAsFixed(2)
        : widget.facture.reste.round().toString(),
  );
  final _reference = TextEditingController();
  String _methode = 'especes';
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _montant.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final f = widget.facture;
    final montant = double.tryParse(_montant.text.trim().replaceAll(',', '.'));
    if (montant == null || montant <= 0) {
      setState(() => _erreur = tr('Montant invalide.'));
      return;
    }
    if (montant > f.reste + 0.001) {
      setState(() => _erreur = tr('Le montant dépasse le reste à payer.'));
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final message = await sl<PersonnelRemoteDataSource>()
          .encaisser(f.id, methode: _methode, montant: montant, reference: _reference.text);
      if (!mounted) return;
      showToast(context, tr('Paiement enregistré'), message, ToastificationType.success);
      Navigator.of(context).pop(true);
    } on ServerException catch (err) {
      if (mounted) {
        setState(() {
          _envoi = false;
          _erreur = err.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.facture;
    return AlertDialog(
      title: Text(tr('Encaisser')),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('Reste à payer : {m}').replaceAll('{m}', formaterMontant(f.reste, f.devise)), style: texteDiscret(13)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _methode,
            decoration: InputDecoration(labelText: tr('Moyen de paiement')),
            items: [
              for (final m in f.methodes) DropdownMenuItem(value: m, child: Text(kMethodesPaiement[m] ?? m)),
            ],
            onChanged: (m) => setState(() => _methode = m ?? _methode),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _montant,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: tr('Montant reçu'), suffixText: f.devise == 'EUR' ? '€' : 'FCFA'),
          ),
          if (_methode != 'especes')
            TextField(
              controller: _reference,
              maxLength: 100,
              decoration: InputDecoration(labelText: tr('Référence de la transaction (facultatif)')),
            ),
          if (_erreur != null) Text(_erreur!, style: TextStyle(color: AppColor.kErreur, fontSize: 13)),
        ]),
      ),
      actions: [
        TextButton(onPressed: _envoi ? null : () => Navigator.of(context).pop(false), child: Text(tr('Annuler'))),
        FilledButton(onPressed: _envoi ? null : _valider, child: Text(tr('Enregistrer'))),
      ],
    );
  }
}
