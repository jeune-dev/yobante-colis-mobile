import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../catalogue/domain/catalogue_entities.dart';
import '../../../../core/i18n/langue.dart';

/// Offre de transport (fret maritime ou aérien) avec le détail du prix.
class CarteOffre extends StatelessWidget {
  final OffreDevis offre;
  final bool selectionnee;
  final VoidCallback? onTap;
  final Widget? action;
  const CarteOffre({super.key, required this.offre, this.selectionnee = false, this.onTap, this.action});

  @override
  Widget build(BuildContext context) {
    final aerien = offre.service.estAerien;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selectionnee ? AppColor.kPrimary : AppColor.kLine, width: selectionnee ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColor.kSecondary.withValues(alpha: 0.3), shape: BoxShape.circle),
              child: Icon(aerien ? Icons.flight_takeoff : Icons.directions_boat_outlined, color: AppColor.kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${tr(offre.service.nom)} · ${aerien ? tr('fret aérien') : tr('fret maritime')}',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                if (offre.dateLivraisonEstimee != null)
                  Text(tr('Livraison estimée le ${formaterDate(offre.dateLivraisonEstimee)}'), style: texteDiscret()),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (offre.surDevis) Text('estimation', style: texteDiscret(10)),
              Text(formaterMontant(offre.total, offre.devise),
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16, color: AppColor.kPrimary)),
            ]),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(selectionnee ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selectionnee ? AppColor.kPrimary : AppColor.kGrayscale40),
            ],
          ]),
          if (offre.lignesForfait.isNotEmpty || offre.annexes.isNotEmpty || offre.remise > 0) ...[
            const Divider(height: 22),
            ...offre.lignesForfait.map((l) => _ligne(
                '${l.libelle}${l.quantite > 1 ? ' × ${l.quantite}' : ''}${l.prixAPartirDe ? tr(' (à partir de)') : ''}',
                formaterMontant(l.montant, l.devise ?? offre.devise))),
            ...offre.annexes.map((l) => _ligne(tr('${l.libelle} (HT)'), formaterMontant(l.montant, offre.devise))),
            if (offre.remise > 0) _ligne(tr('Remise'), '− ${formaterMontant(offre.remise, offre.devise)}', vert: true),
            if (offre.creditParrainage > 0)
              _ligne(tr('Crédit parrainage'), '− ${formaterMontant(offre.creditParrainage, offre.devise)}', vert: true),
          ],
          if (offre.message != null) ...[
            const SizedBox(height: 8),
            Text(offre.message!,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.kPrimary)),
          ],
          if (action != null) ...[const SizedBox(height: 12), action!],
        ]),
      ),
    );
  }

  Widget _ligne(String libelle, String montant, {bool vert = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Expanded(child: Text(libelle, style: texteDiscret(12))),
          Text(montant,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w600, color: vert ? AppColor.kSucces : AppColor.kGrayscaleDark100)),
        ]),
      );
}
