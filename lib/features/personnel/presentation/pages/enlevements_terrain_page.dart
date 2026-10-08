import 'package:flutter/material.dart';
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
import '../../../enlevements/presentation/pages/enlevements_page.dart' show PastilleStatutEnlevement;
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../notifications/presentation/widgets/apercu_notifications.dart';
import '../../data/personnel_remote_datasource.dart';
import '../widgets/ui_personnel.dart';
import 'colis_terrain_page.dart';

/// Enlèvements à domicile côté personnel : la tournée du jour du coursier, les
/// demandes à venir et l'historique ; l'agent voit ceux déposés à son point.
class EnlevementsTerrainPage extends StatefulWidget {
  final UserRole role;

  /// Premier onglet de l'espace : les dernières notifications sont affichées en tête.
  final bool afficherNotifications;
  const EnlevementsTerrainPage({super.key, required this.role, this.afficherNotifications = false});

  @override
  State<EnlevementsTerrainPage> createState() => _EnlevementsTerrainPageState();
}

enum _Filtre { aujourdhui, aFaire, termines }

const _ouverts = ['demande', 'planifie', 'en_cours'];

/// Couleur du liseré des cartes, selon l'avancement.
Color _accent(String statut) => switch (statut) {
      'effectue' => AppColor.kSucces,
      'echoue' || 'annule' => AppColor.kErreur,
      'en_cours' => AppColor.kSecondaryDark,
      _ => AppColor.kPrimary,
    };

class _EnlevementsTerrainPageState extends State<EnlevementsTerrainPage> {
  final _source = sl<PersonnelRemoteDataSource>();
  late final bool _coursier = widget.role == UserRole.coursier;
  late _Filtre _filtre = _coursier ? _Filtre.aujourdhui : _Filtre.aFaire;
  List<EnlevementTerrain>? _tous;
  List<EnlevementTerrain> _jour = const [];
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);
    try {
      final resultats = await Future.wait([
        _source.getEnlevements(),
        if (_coursier) _source.getTourneeDuJour(),
      ]);
      if (!mounted) return;
      setState(() {
        _tous = resultats[0];
        _jour = _coursier ? resultats[1] : const [];
      });
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    }
  }

  List<EnlevementTerrain> _liste(_Filtre f) {
    final tous = _tous ?? const <EnlevementTerrain>[];
    return switch (f) {
      _Filtre.aujourdhui => _jour,
      _Filtre.aFaire => tous.where((e) => _ouverts.contains(e.demande.statut)).toList(),
      _Filtre.termines => tous.where((e) => !_ouverts.contains(e.demande.statut)).toList(),
    };
  }

  Future<void> _ouvrir(EnlevementTerrain e) async {
    final change = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => DetailEnlevementTerrainPage(id: e.demande.id)));
    if (change == true) _charger();
  }

  @override
  Widget build(BuildContext context) {
    final libelles = {
      if (_coursier) _Filtre.aujourdhui: tr('Aujourd\'hui'),
      _Filtre.aFaire: tr('À faire'),
      _Filtre.termines: tr('Terminés'),
    };
    final charge = _tous != null;
    final compteurs = {for (final f in libelles.keys) f: _liste(f).length};
    final icones = {
      _Filtre.aujourdhui: Icons.today_outlined,
      _Filtre.aFaire: Icons.pending_actions_outlined,
      _Filtre.termines: Icons.task_alt_outlined,
    };
    final liste = _liste(_filtre);

    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: barreEspace(
        _coursier ? tr('Ma tournée') : tr('Enlèvements'),
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
              titre: _coursier ? tr('Vos enlèvements') : tr('Enlèvements à suivre'),
              indicateurs: [
                for (final f in libelles.keys)
                  Indicateur(
                    charge ? '${compteurs[f]}' : '–',
                    libelles[f]!,
                    icones[f]!,
                    actif: f == _filtre,
                    onTap: () => setState(() => _filtre = f),
                  ),
              ],
            ),
            if (widget.afficherNotifications)
              const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 0), child: ApercuNotifications(nombre: 2)),
            TitreListe(tr('Missions')),
            FiltresPilules<_Filtre>(
              options: libelles,
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
                icon: Icons.local_shipping_outlined,
                title: _filtre == _Filtre.aujourdhui ? tr('Aucun passage prévu aujourd\'hui') : tr('Aucun enlèvement'),
                subtitle: tr('Les enlèvements qui vous sont confiés apparaissent ici.'),
                scrollable: false,
              )
            else
              for (final e in liste)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _CarteEnlevement(enlevement: e, onTap: () => _ouvrir(e)),
                ),
          ],
        ),
      ),
    );
  }
}

class _CarteEnlevement extends StatelessWidget {
  final EnlevementTerrain enlevement;
  final VoidCallback onTap;
  const _CarteEnlevement({required this.enlevement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = enlevement.demande;
    final adresse = [d.adresse, d.villeNom].whereType<String>().where((v) => v.isNotEmpty).join(', ');
    return CarteMission(
      icone: Icons.local_shipping_outlined,
      titre: d.contactNom,
      sousTitre: '${formaterDate(d.datePlanifiee ?? d.dateSouhaitee)} · ${d.creneau.replaceAll('-', ' – ')}',
      statut: PastilleStatutEnlevement(statut: d.statut),
      accent: _accent(d.statut),
      onTap: onTap,
      lignes: [
        (Icons.place_outlined, adresse),
        (
          Icons.inventory_2_outlined,
          '${tr('{n} colis').replaceAll('{n}', '${d.nbColis}')}${d.poidsEstimeKg != null ? ' · ${d.poidsEstimeKg} kg' : ''} · ${d.reference}',
        ),
      ],
      pied: _ouverts.contains(d.statut)
          ? Row(children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => appeler(context, d.contactTelephone),
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

/// Détail d'un enlèvement : client, passage, puis démarrage et clôture sur place.
class DetailEnlevementTerrainPage extends StatefulWidget {
  final String id;
  const DetailEnlevementTerrainPage({super.key, required this.id});

  @override
  State<DetailEnlevementTerrainPage> createState() => _DetailEnlevementTerrainPageState();
}

class _DetailEnlevementTerrainPageState extends State<DetailEnlevementTerrainPage> {
  final _source = sl<PersonnelRemoteDataSource>();
  EnlevementTerrain? _e;
  String? _erreur;
  bool _change = false;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final e = await _source.getEnlevement(widget.id);
      if (mounted) setState(() => _e = e);
    } on ServerException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    }
  }

  Future<void> _executer(Future<String> Function() action) async {
    setState(() => _envoi = true);
    try {
      final message = await action();
      if (!mounted) return;
      _change = true;
      showToast(context, tr('C\'est fait'), message, ToastificationType.success);
      await _charger();
    } on ServerException catch (e) {
      if (mounted) showToast(context, tr('Erreur'), e.message, ToastificationType.error);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _cloturer({required bool effectue}) async {
    final saisie = TextEditingController();
    final valide = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          effectue ? Icons.check_circle_outline : Icons.report_gmailerrorred_outlined,
          color: effectue ? AppColor.kSucces : AppColor.kErreur,
          size: 36,
        ),
        title: Text(effectue ? tr('Colis récupérés ?') : tr('Enlèvement impossible')),
        content: TextField(
          controller: saisie,
          maxLength: effectue ? 500 : 255,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: effectue ? tr('Commentaire (facultatif)') : tr('Motif de l\'échec'),
            hintText: effectue ? null : tr('Client absent, adresse introuvable…'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr('Retour'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: effectue ? AppColor.kSucces : AppColor.kErreur),
            onPressed: () {
              if (!effectue && saisie.text.trim().isEmpty) return;
              Navigator.of(ctx).pop(true);
            },
            child: Text(tr('Confirmer')),
          ),
        ],
      ),
    );
    if (valide != true || !mounted) return;
    await _executer(() => _source.cloturerEnlevement(
          widget.id,
          effectue: effectue,
          motif: effectue ? null : saisie.text,
          commentaire: effectue ? saisie.text : null,
        ));
  }

  Widget? _barre(EnlevementTerrain e) {
    if (e.demarrable) {
      return BarreActions(children: [
        FilledButton.icon(
          onPressed: _envoi ? null : () => _executer(() => _source.demarrerEnlevement(widget.id)),
          icon: const Icon(Icons.navigation_outlined),
          label: Text(tr('Je suis en route')),
          style: styleBoutonPlein(AppColor.kPrimary),
        ),
      ]);
    }
    if (e.cloturable) {
      return BarreActions(children: [
        OutlinedButton(
          onPressed: _envoi ? null : () => _cloturer(effectue: false),
          style: styleBoutonContour(AppColor.kErreur),
          child: Text(tr('Échec')),
        ),
        FilledButton.icon(
          onPressed: _envoi ? null : () => _cloturer(effectue: true),
          icon: const Icon(Icons.check_rounded),
          label: Text(tr('Colis récupérés')),
          style: styleBoutonPlein(AppColor.kSucces),
        ),
      ]);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final e = _e;
    final d = e?.demande;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_change);
      },
      child: Scaffold(
        backgroundColor: AppColor.kBackground,
        appBar: barreEspace(tr('Enlèvement')),
        bottomNavigationBar: e == null ? null : _barre(e),
        body: _erreur != null
            ? EmptyState(icon: Icons.error_outline, title: tr('Erreur'), subtitle: _erreur!)
            : e == null || d == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _charger,
                    child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
                      HeroDetail(
                        surTitre: tr('Enlèvement à domicile'),
                        reference: d.reference,
                        statut: PastilleStatutEnlevement(statut: d.statut),
                        contenu: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.event_outlined, color: AppColor.kSecondary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${formaterDate(d.datePlanifiee ?? d.dateSouhaitee)} · ${d.creneau.replaceAll('-', ' – ')}',
                              style: titreSection(15).copyWith(color: AppColor.kWhite),
                            ),
                          ]),
                          const SizedBox(height: 18),
                          EtapesProgression(
                            etapes: [tr('Planifié'), tr('En route'), tr('Récupéré')],
                            courante: switch (d.statut) {
                              'en_cours' => 1,
                              'effectue' => 2,
                              'echoue' || 'annule' => -1,
                              _ => 0,
                            },
                          ),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      CarteContact(
                        role: tr('Client'),
                        nom: d.contactNom,
                        telephone: d.contactTelephone,
                        adresse: [d.adresse, d.complementAdresse, d.codePostal, d.villeNom]
                            .whereType<String>()
                            .where((v) => v.isNotEmpty)
                            .join(', '),
                        details: [
                          if (d.etage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${tr('Étage')} ${d.etage}${d.ascenseur == true ? tr(' (ascenseur)') : ''}',
                                style: titreSection(13).copyWith(color: AppColor.kGrayscale40),
                              ),
                            ),
                          if (d.instructions != null && d.instructions!.isNotEmpty)
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
                                Expanded(child: Text(d.instructions!)),
                              ]),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SectionDetail(
                        titre: tr('Ce qu\'il faut récupérer'),
                        icone: Icons.inventory_2_outlined,
                        children: [
                          InfoIcone(Icons.all_inbox_outlined, tr('Colis'),
                              '${d.nbColis}${d.poidsEstimeKg != null ? ' · ${d.poidsEstimeKg} kg' : ''}'),
                          if (d.emballageRequis)
                            InfoIcone(Icons.add_box_outlined, tr('Emballage'), tr('À prévoir par le coursier')),
                          if (e.pointDepotNom != null) InfoIcone(Icons.storefront_outlined, tr('Point de dépôt'), e.pointDepotNom!),
                          if (e.coursierNom != null && e.coursierNom!.isNotEmpty)
                            InfoIcone(Icons.delivery_dining_outlined, tr('Coursier'), e.coursierNom!),
                          if (d.motifEchec != null) InfoIcone(Icons.report_outlined, tr('Motif'), d.motifEchec!),
                          if (d.colisId != null)
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => DetailColisTerrainPage(id: d.colisId!)),
                              ),
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: Text(tr('Voir l\'expédition {ref}').replaceAll('{ref}', d.colisReference ?? '')),
                              style: styleBoutonContour(AppColor.kPrimary),
                            ),
                        ],
                      ),
                    ]),
                  ),
      ),
    );
  }
}
