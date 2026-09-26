import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../catalogue/domain/catalogue_entities.dart';
import '../../../reclamations/presentation/pages/nouvelle_reclamation_page.dart';
import '../../domain/entities/colis.dart';
import '../bloc/colis_bloc.dart';
import '../bloc/colis_event.dart';
import '../bloc/colis_state.dart';
import '../widgets/services_colis.dart';
import '../widgets/statut_badge.dart';
import '../../../../core/i18n/langue.dart';

class DetailColisPage extends StatelessWidget {
  final String colisId;
  const DetailColisPage({super.key, required this.colisId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ColisBloc>()..add(LoadColisDetail(colisId)),
      child: _DetailColisView(colisId: colisId),
    );
  }
}

class _DetailColisView extends StatelessWidget {
  final String colisId;
  const _DetailColisView({required this.colisId});

  void _recharger(BuildContext context) => context.read<ColisBloc>().add(LoadColisDetail(colisId));

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ColisBloc, ColisState>(
      listener: (ctx, state) {
        if (state is ColisAnnule) {
          showToast(ctx, tr('Demande annulée'), tr('Votre expédition a été annulée.'), ToastificationType.success);
          Navigator.of(ctx).pop(true);
        }
        if (state is PropositionAcceptee) {
          showToast(ctx, tr('Proposition acceptée'), state.resultat.message, ToastificationType.success);
          if (state.resultat.lienPaiement != null) ouvrirLien(ctx, state.resultat.lienPaiement);
          _recharger(ctx);
        }
        if (state is PropositionRefusee) {
          showToast(ctx, tr('Proposition déclinée'), tr('Votre demande est clôturée.'), ToastificationType.info);
          _recharger(ctx);
        }
        if (state is ColisModifie) {
          showToast(ctx, tr('Demande modifiée'), tr('Vos modifications sont enregistrées.'), ToastificationType.success);
          _recharger(ctx);
        }
        if (state is ColisFailure) showToast(ctx, tr('Erreur'), state.message, ToastificationType.error);
      },
      buildWhen: (_, s) => s is ColisLoading || s is ColisDetailLoaded || s is ColisFailure,
      builder: (context, state) {
        if (state is ColisDetailLoaded) return _Detail(colis: state.colis, onRecharger: () => _recharger(context));
        if (state is ColisFailure) {
          return Scaffold(
            appBar: AppBar(title: Text(tr('Détail de l\'envoi'))),
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(state.message, textAlign: TextAlign.center),
                TextButton(onPressed: () => _recharger(context), child: Text(tr('Réessayer'))),
              ]),
            ),
          );
        }
        return Scaffold(appBar: AppBar(title: Text(tr('Détail de l\'envoi'))), body: const ShimmerList());
      },
    );
  }
}

class _Detail extends StatelessWidget {
  final Colis colis;
  final VoidCallback onRecharger;
  const _Detail({required this.colis, required this.onRecharger});

  static const _annulables = ['brouillon', 'en_attente_validation', 'devis_propose', 'en_attente', 'enlevement_planifie'];

  @override
  Widget build(BuildContext context) {
    final c = colis;
    final categorie = CategorieColis.parCode(c.categorie);
    final adresse = c.adresseReception == null ? null : AdresseReception.fromJson(c.adresseReception);

    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        title: Text(tr('Détail de l\'envoi')),
        actions: [
          if (c.modifiable)
            IconButton(
              tooltip: tr('Modifier'),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _modifier(context),
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'annuler') _confirmerAnnulation(context);
              if (v == 'reclamation') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => NouvelleReclamationPage(colis: c)));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'reclamation', child: Text(tr('Signaler un problème'))),
              if (_annulables.contains(c.statut))
                PopupMenuItem(value: 'annuler', child: Text(tr('Annuler l\'envoi'), style: TextStyle(color: AppColor.kErreur))),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => onRecharger(),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _EnTete(colis: c, categorie: categorie),
          const SizedBox(height: 14),
          ..._actions(context, categorie),
          ServicesColis(colis: c, onRecharger: onRecharger),
          if (adresse != null && adresse.estRenseignee && ['en_attente', 'enlevement_planifie'].contains(c.statut)) ...[
            Bandeau(
              icone: Icons.place_outlined,
              titre: c.modeDepot == 'envoi_postal' ? tr('Envoyez votre colis à') : tr('Déposez votre colis à'),
              message: tr('${adresse.lignes}\nNuméro à indiquer : ${c.reference}'),
            ),
            const SizedBox(height: 14),
          ],
          CarteSection(titre: tr('Contenu'), icone: categorie.icone, children: [
            LigneInfo(tr('Catégorie'), '${categorie.numero}. ${categorie.libelle}'),
            if (c.typeDocument != null) LigneInfo(tr('Document'), c.typeDocument!),
            ...c.lignesForfait.map((l) => LigneInfo(
                l.quantite > 1 ? tr('${l.libelle} × ${l.quantite}') : l.libelle, formaterMontant(l.montant, l.devise))),
            if (c.description != null && c.description!.isNotEmpty) LigneInfo(tr('Description'), c.description!),
            if (c.etatMarchandise != null) LigneInfo(tr('État'), c.etatMarchandise == 'neuf' ? tr('Neuf') : tr('Occasion')),
            if (c.valeurDeclaree > 0) LigneInfo(tr('Valeur estimée'), formaterMontant(c.valeurDeclaree, c.deviseValeur)),
            if (c.poidsFactureKg > 0) LigneInfo(tr('Poids'), '${c.poidsFactureKg} kg'),
            LigneInfo(tr('Nombre de colis'), '${c.nbPieces}'),
          ]),
          const SizedBox(height: 14),
          CarteSection(titre: tr('Remise du colis'), icone: iconesModeDepot[c.modeDepot] ?? Icons.inventory, children: [
            LigneInfo(tr('Mode'), libellesModeDepot[c.modeDepot] ?? c.modeDepot),
            if (c.pointCollecteDepart != null) LigneInfo(tr('Point de dépôt'), c.pointCollecteDepart!.nom),
            if (c.adresseDepart != null && c.adresseDepart!.isNotEmpty) LigneInfo(tr('Adresse'), c.adresseDepart!),
            if (c.tourneeTitre != null) LigneInfo(tr('Tournée'), c.tourneeTitre!),
            if (c.dateCollecte != null) LigneInfo(tr('Date de collecte'), formaterDate(c.dateCollecte)),
            if (c.infosCollecte['etage'] != null) LigneInfo(tr('Étage'), '${c.infosCollecte['etage']}'),
            if (c.infosCollecte['ascenseur'] != null)
              LigneInfo(tr('Ascenseur'), c.infosCollecte['ascenseur'] == true ? tr('Oui') : tr('Non')),
            if (c.optionColissimo) LigneInfo(tr('Colissimo'), tr('Étiquette achetée')),
          ]),
          const SizedBox(height: 14),
          CarteSection(titre: tr('Destinataire'), icone: Icons.person_pin_circle_outlined, children: [
            LigneInfo(tr('Nom'), c.destinataireNom),
            LigneInfo(tr('Téléphone'), c.destinataireTelephone),
            LigneInfo(tr('Ville'), c.villeArrivee?.nom ?? '—'),
            if (c.pointRetrait != null) LigneInfo(tr('Point de retrait'), c.pointRetrait!.nom),
            if (c.adresseLivraison != null && c.adresseLivraison!.isNotEmpty) LigneInfo(tr('Adresse'), c.adresseLivraison!),
            if (c.destinataireQuartier != null) LigneInfo(tr('Quartier'), c.destinataireQuartier!),
            if (c.destinataireArrondissement != null) LigneInfo(tr('Arrondissement'), c.destinataireArrondissement!),
            if (c.destinataireDepartement != null) LigneInfo(tr('Département'), c.destinataireDepartement!),
            if (c.destinatairePointRepere != null) LigneInfo(tr('Point de repère'), c.destinatairePointRepere!),
            if (c.codeRetrait != null) LigneInfo(tr('Code de retrait'), c.codeRetrait!, fort: true),
          ]),
          const SizedBox(height: 14),
          CarteSection(titre: tr('Expéditeur'), icone: Icons.person_outline, children: [
            LigneInfo(tr('Nom'), c.expediteurNom),
            LigneInfo(tr('Téléphone'), c.expediteurTelephone),
            LigneInfo(tr('Ville'), c.villeDepart?.nom ?? '—'),
          ]),
          const SizedBox(height: 14),
          CarteSection(titre: tr('Paiement'), icone: Icons.payments_outlined, children: [
            if (c.montantEnAttente)
              LigneInfo(tr('Montant'), tr('Proposé après étude'))
            else
              LigneInfo(tr('Montant'), formaterMontant(c.montantTotal, c.devise), fort: true),
            if (c.factureReference != null) LigneInfo(tr('Facture'), c.factureReference!),
            if (c.factureStatut != null) LigneInfo(tr('Statut'), _libelleFacture(c.factureStatut!)),
            if (c.factureReference == null && !c.montantEnAttente)
              LigneInfo(
                tr('Facturation'),
                categorie.paiement == 'a_la_reception' ? tr('À la réception de votre colis') : tr('À venir'),
              ),
          ]),
          if (c.photos.isNotEmpty) ...[
            const SizedBox(height: 14),
            CarteSection(titre: tr('Photos'), icone: Icons.photo_library_outlined, children: [
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: c.photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(child: InteractiveViewer(child: CachedNetworkImage(imageUrl: c.photos[i]))),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(imageUrl: c.photos[i], width: 96, height: 96, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ]),
          ],
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, CategorieColis categorie) {
    final c = colis;
    final actions = <Widget>[];
    void ajouter(Widget w) => actions.addAll([w, const SizedBox(height: 14)]);

    if (c.statut == 'en_attente_validation') {
      ajouter(Bandeau(
        icone: Icons.manage_search_rounded,
        titre: tr('Demande en cours d\'étude'),
        message: c.dateLimiteEtude != null
            ? tr('Réponse attendue avant le ${formaterDate(c.dateLimiteEtude, avecHeure: true)}.')
            : tr('Nos équipes reviennent vers vous sous 24 h.'),
        couleur: AppColor.kAlerte,
      ));
    }
    if (c.statut == 'devis_propose') {
      ajouter(Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColor.kPrimary, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('Notre proposition'),
              style: GoogleFonts.plusJakartaSans(color: AppColor.kWhite.withValues(alpha: 0.8), fontSize: 12)),
          const SizedBox(height: 4),
          Text(formaterMontant(c.montantPropose ?? c.montantTotal, c.devise),
              style: GoogleFonts.plusJakartaSans(color: AppColor.kSecondary, fontSize: 26, fontWeight: FontWeight.w700)),
          if (c.propositionCommentaire != null && c.propositionCommentaire!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(c.propositionCommentaire!, style: GoogleFonts.plusJakartaSans(color: AppColor.kWhite, fontSize: 13)),
          ],
          if (c.propositionExpireAt != null) ...[
            const SizedBox(height: 6),
            Text(tr('Valable jusqu\'au ${formaterDate(c.propositionExpireAt)}'),
                style: GoogleFonts.plusJakartaSans(color: AppColor.kWhite.withValues(alpha: 0.75), fontSize: 12)),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.kWhite, side: const BorderSide(color: AppColor.kWhite)),
                onPressed: () => _refuser(context),
                child: Text(tr('Refuser')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColor.kSecondary, foregroundColor: AppColor.kPrimary),
                onPressed: () => context.read<ColisBloc>().add(AccepterPropositionRequested(c.id)),
                child: Text(tr('Accepter')),
              ),
            ),
          ]),
        ]),
      ));
    }
    if (c.statut == 'refuse' && c.motifRefus != null) {
      ajouter(Bandeau(icone: Icons.block, titre: tr('Demande non retenue'), message: c.motifRefus, couleur: AppColor.kErreur));
    }
    if (c.lienPaiement != null) {
      ajouter(Bandeau(
        icone: Icons.payments_outlined,
        titre: tr('Paiement en attente'),
        message: tr('Facture ${c.factureReference ?? ''} — ${formaterMontant(c.montantTotal, c.devise)}'),
        couleur: AppColor.kAlerte,
        action: ElevatedButton.icon(
          onPressed: () => ouvrirLien(context, c.lienPaiement),
          icon: const Icon(Icons.lock_outline, size: 18),
          label: Text(tr('Payer maintenant')),
          style: ElevatedButton.styleFrom(backgroundColor: AppColor.kSecondary, foregroundColor: AppColor.kPrimary),
        ),
      ));
    }
    return actions;
  }

  static String _libelleFacture(String s) => switch (s) {
        'payee' => tr('Payée'),
        'partiellement_payee' => tr('Partiellement payée'),
        'annulee' => tr('Annulée'),
        _ => tr('En attente de paiement'),
      };

  void _refuser(BuildContext context) {
    final motif = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Refuser la proposition ?')),
        content: TextField(
          controller: motif,
          maxLines: 2,
          decoration: InputDecoration(hintText: tr('Motif (facultatif)')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Retour'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.kErreur),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ColisBloc>().add(RefuserPropositionRequested(
                    colis.id,
                    motif: motif.text.trim().isEmpty ? null : motif.text.trim(),
                  ));
            },
            child: Text(tr('Refuser')),
          ),
        ],
      ),
    );
  }

  /// Modification du destinataire et de l'adresse, possible jusqu'à l'arrivée au Sénégal.
  void _modifier(BuildContext context) {
    final c = colis;
    final champs = {
      'destinataireNom': TextEditingController(text: c.destinataireNom),
      'destinataireTelephone': TextEditingController(text: c.destinataireTelephone),
      'adresseLivraison': TextEditingController(text: c.adresseLivraison ?? ''),
      'destinataireQuartier': TextEditingController(text: c.destinataireQuartier ?? ''),
      'destinataireArrondissement': TextEditingController(text: c.destinataireArrondissement ?? ''),
      'destinataireDepartement': TextEditingController(text: c.destinataireDepartement ?? ''),
      'destinatairePointRepere': TextEditingController(text: c.destinatairePointRepere ?? ''),
      'instructionsLivraison': TextEditingController(text: c.instructionsLivraison ?? ''),
    };
    final libelles = {
      'destinataireNom': tr('Nom du destinataire'),
      'destinataireTelephone': tr('Téléphone du destinataire'),
      'adresseLivraison': tr('Adresse de livraison'),
      'destinataireQuartier': tr('Quartier'),
      'destinataireArrondissement': tr('Arrondissement'),
      'destinataireDepartement': tr('Département'),
      'destinatairePointRepere': tr('Point de repère'),
      'instructionsLivraison': tr('Instructions de livraison'),
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('Modifier ma demande'), style: titreSection(17)),
            const SizedBox(height: 4),
            Text(tr('Possible jusqu\'à l\'arrivée de la marchandise au Sénégal.'), style: texteDiscret()),
            const SizedBox(height: 16),
            ...champs.entries.map((e) => ChampTexte(controller: e.value, label: libelles[e.key]!)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final modifs = <String, dynamic>{};
                  champs.forEach((cle, ctrl) {
                    final valeur = ctrl.text.trim();
                    if (cle == 'destinataireTelephone') {
                      if (valeur.isNotEmpty) modifs[cle] = normaliserTelephone(valeur);
                    } else if (cle == 'destinataireNom') {
                      if (valeur.isNotEmpty) modifs[cle] = valeur;
                    } else {
                      modifs[cle] = valeur;
                    }
                  });
                  Navigator.pop(ctx);
                  context.read<ColisBloc>().add(ModifierColisRequested(c.id, modifs));
                },
                child: Text(tr('Enregistrer')),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _confirmerAnnulation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Annuler cet envoi ?')),
        content: Text(tr('Cette action est définitive.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Non'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.kErreur),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ColisBloc>().add(AnnulerColisRequested(colis.id));
            },
            child: Text(tr('Annuler l\'envoi')),
          ),
        ],
      ),
    );
  }
}

/// En-tête façon suivi DHL : numéro, statut, trajet et accès à l'historique.
class _EnTete extends StatelessWidget {
  final Colis colis;
  final CategorieColis categorie;
  const _EnTete({required this.colis, required this.categorie});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          PastilleCategorie(numero: categorie.numero, libelle: categorie.libelle),
          const Spacer(),
          StatutBadge(statut: colis.statut),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: SelectableText(colis.reference,
                style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: colis.reference));
              showToast(context, tr('Copié'), tr('Numéro de suivi copié.'), ToastificationType.success);
            },
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.trip_origin, size: 16, color: AppColor.kPrimary),
          const SizedBox(width: 6),
          Expanded(child: Text(colis.villeDepart?.nom ?? '—', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600))),
          const Icon(Icons.arrow_forward, size: 16, color: AppColor.kGrayscale40),
          const SizedBox(width: 6),
          Expanded(
            child: Text(colis.villeArrivee?.nom ?? '—',
                textAlign: TextAlign.end, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ]),
        if (colis.dateLivraisonEstimee != null) ...[
          const SizedBox(height: 8),
          Text(tr('Livraison estimée : ${formaterDate(colis.dateLivraisonEstimee)}'), style: texteDiscret()),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(AppRouter.suiviColisRoute, arguments: colis.id),
            icon: const Icon(Icons.timeline),
            label: Text(tr('Voir toutes les étapes')),
          ),
        ),
      ]),
    );
  }
}
