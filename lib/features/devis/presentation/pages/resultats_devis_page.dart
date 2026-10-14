import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../catalogue/domain/catalogue_entities.dart';
import '../../../expedition/presentation/widgets/carte_offre.dart';
import '../../../../core/i18n/langue.dart';

/// Tarifs obtenus par le calculateur, sur un écran à part pour que les prix
/// soient visibles sans avoir à défiler sous le formulaire.
class ResultatsDevisPage extends StatelessWidget {
  final ResultatDevis resultat;
  final CategorieColis categorie;
  final String villeDepart;
  final String villeArrivee;
  final String modeDepot;
  final bool fragile;
  final bool dangereuse;

  /// Enchaîne sur l'assistant d'expédition (ou la connexion).
  final VoidCallback onExpedier;

  const ResultatsDevisPage({
    super.key,
    required this.resultat,
    required this.categorie,
    required this.villeDepart,
    required this.villeArrivee,
    required this.modeDepot,
    required this.onExpedier,
    this.fragile = false,
    this.dangereuse = false,
  });

  @override
  Widget build(BuildContext context) {
    final offres = resultat.offres;
    final moinsChere = offres.reduce((a, b) => b.total < a.total ? b : a);
    final datees = offres.where((o) => o.delaiJours != null).toList();
    final plusRapide = datees.isEmpty ? null : datees.reduce((a, b) => b.delaiJours! < a.delaiJours! ? b : a);

    String? badge(OffreDevis o) {
      if (offres.length < 2) return null;
      if (identical(o, moinsChere)) return tr('Meilleur prix');
      if (identical(o, plusRapide)) return tr('Plus rapide');
      return null;
    }

    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(tr('Vos tarifs'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          _Recapitulatif(
            categorie: categorie,
            villeDepart: villeDepart,
            villeArrivee: villeArrivee,
            modeDepot: modeDepot,
            fragile: fragile,
            dangereuse: dangereuse,
          ),
          const SizedBox(height: 22),
          Text(tr('${offres.length} offre(s) disponible(s)'), style: titreSection(16)),
          const SizedBox(height: 2),
          Text(tr('Choisissez l\'offre qui vous convient pour expédier votre colis.'), style: texteDiscret(12)),
          if (resultat.remiseParrainagePourcent > 0) ...[
            const SizedBox(height: 6),
            Text(
              tr('Bonus filleul de ${resultat.remiseParrainagePourcent.toStringAsFixed(0)} % inclus.'),
              style: GoogleFonts.plusJakartaSans(color: AppColor.kSucces, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 14),
          ...offres.map(
            (o) => CarteOffre(
              offre: o,
              badge: badge(o),
              action: SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: onExpedier, child: Text(tr('Expédier avec cette offre'))),
              ),
            ),
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.tune, size: 18),
            label: Text(tr('Modifier ma simulation')),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: AppColor.kPrimary,
              side: const BorderSide(color: AppColor.kPrimary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau bleu rappelant le trajet et les options simulées.
class _Recapitulatif extends StatelessWidget {
  final CategorieColis categorie;
  final String villeDepart;
  final String villeArrivee;
  final String modeDepot;
  final bool fragile;
  final bool dangereuse;
  const _Recapitulatif({
    required this.categorie,
    required this.villeDepart,
    required this.villeArrivee,
    required this.modeDepot,
    required this.fragile,
    required this.dangereuse,
  });

  @override
  Widget build(BuildContext context) {
    final ville = GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColor.kWhite);
    final legende = GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kWhite.withValues(alpha: 0.7));
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColor.kPrimary, AppColor.kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColor.kSecondary, shape: BoxShape.circle),
                child: Icon(categorie.icone, size: 18, color: AppColor.kPrimaryDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  categorie.libelle,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.kWhite),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Départ'), style: legende),
                    Text(villeDepart, style: ville, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded, color: AppColor.kSecondary),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(tr('Arrivée'), style: legende),
                    Text(villeArrivee, style: ville, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _pastille(
                iconesModeDepot[modeDepot] ?? Icons.local_shipping_outlined,
                libellesModeDepot[modeDepot] ?? modeDepot,
              ),
              if (fragile) _pastille(Icons.wine_bar_outlined, tr('Colis fragile')),
              if (dangereuse) _pastille(Icons.warning_amber_rounded, tr('Marchandise dangereuse')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pastille(IconData icone, String libelle) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: AppColor.kWhite.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 14, color: AppColor.kWhite),
        const SizedBox(width: 6),
        Text(libelle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kWhite)),
      ],
    ),
  );
}
