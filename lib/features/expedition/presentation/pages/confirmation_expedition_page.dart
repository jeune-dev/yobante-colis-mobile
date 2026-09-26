import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/toast_notif.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../catalogue/domain/catalogue_entities.dart';
import '../../../colis/domain/entities/demande_expedition.dart';
import '../../../../core/i18n/langue.dart';

/// Écran de fin du parcours « Expédier » : numéro de suivi, prochaine étape
/// selon la catégorie, paiement et adresse de réception le cas échéant.
class ConfirmationExpeditionPage extends StatelessWidget {
  final ResultatDeclaration resultat;
  final CategorieColis categorie;
  const ConfirmationExpeditionPage({super.key, required this.resultat, required this.categorie});

  @override
  Widget build(BuildContext context) {
    final colis = resultat.colis;
    final adresse = resultat.adresseReception == null ? null : AdresseReception.fromJson(resultat.adresseReception);
    final (icone, titre, message) = switch (categorie.paiement) {
      'a_la_commande' => (
          Icons.check_circle_rounded,
          tr('Expédition enregistrée'),
          tr('Réglez votre facture puis remettez votre enveloppe selon le mode choisi.'),
        ),
      'a_la_reception' => (
          Icons.manage_search_rounded,
          tr('Demande reçue'),
          tr('Nos équipes étudient votre demande sous 24 h. Un accusé de réception vous a été envoyé par email. '
              'Vous paierez à la réception de votre colis.'),
        ),
      _ => (
          Icons.request_quote_outlined,
          tr('Demande de devis reçue'),
          tr('Nous vous envoyons une proposition de prix sous 24 h, par notification et par email. '
              'Vous pourrez l\'accepter depuis le suivi de votre colis.'),
        ),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.clientRoute, (_) => false);
      },
      child: Scaffold(
        backgroundColor: AppColor.kBackground,
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(color: AppColor.kSecondary, shape: BoxShape.circle),
                child: Icon(icone, size: 48, color: AppColor.kPrimary),
              ),
            ),
            const SizedBox(height: 20),
            Text(titre, textAlign: TextAlign.center, style: titreSection(22)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: texteDiscret(14)),
            const SizedBox(height: 24),
            CarteSection(children: [
              Text(tr('Numéro de suivi'), style: texteDiscret(12)),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: SelectableText(colis.reference,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColor.kPrimary)),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: colis.reference));
                    showToast(context, tr('Copié'), tr('Numéro de suivi copié.'), ToastificationType.success);
                  },
                ),
              ]),
              const Divider(),
              LigneInfo(tr('Catégorie'), '${categorie.numero}. ${categorie.libelle}'),
              LigneInfo(tr('Trajet'), '${colis.villeDepart?.nom ?? '—'} → ${colis.villeArrivee?.nom ?? '—'}'),
              if (colis.montantTotal > 0)
                LigneInfo(tr('Montant'), formaterMontant(colis.montantTotal, colis.devise), fort: true)
              else
                LigneInfo(tr('Montant'), tr('Proposé après étude')),
              if (resultat.factureReference != null) LigneInfo(tr('Facture'), resultat.factureReference!),
            ]),
            if (resultat.lienPaiement != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ouvrirLien(context, resultat.lienPaiement),
                icon: const Icon(Icons.lock_outline),
                label: Text(tr('Payer maintenant')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.kSecondary,
                  foregroundColor: AppColor.kPrimary,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
            if (adresse != null && adresse.estRenseignee) ...[
              const SizedBox(height: 16),
              Bandeau(
                icone: Icons.place_outlined,
                titre: colis.modeDepot == 'envoi_postal' ? tr('Adresse d\'envoi') : tr('Adresse de dépôt'),
                message: tr('${adresse.lignes}\nIndiquez le numéro ${colis.reference} sur le colis.'),
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.detailColisRoute,
                (route) => route.settings.name == AppRouter.clientRoute,
                arguments: colis.id,
              ),
              icon: const Icon(Icons.track_changes_outlined),
              label: Text(tr('Suivre ma demande')),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.clientRoute, (_) => false),
              child: Text(tr('Retour à l\'accueil')),
            ),
          ]),
        ),
      ),
    );
  }
}
