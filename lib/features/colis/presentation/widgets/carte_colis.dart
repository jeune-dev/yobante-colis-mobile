import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/colis.dart';
import 'statut_badge.dart';

/// Carte d'une expédition dans les listes « Envoyés » et « Reçus » : catégorie,
/// référence et statut, trajet départ → arrivée, puis l'autre partie et le montant.
class CarteColis extends StatelessWidget {
  final Colis colis;
  final VoidCallback onTap;

  /// Colis reçu : on affiche l'expéditeur (et non le destinataire), sans montant.
  final bool recu;
  const CarteColis({super.key, required this.colis, required this.onTap, this.recu = false});

  @override
  Widget build(BuildContext context) {
    final categorie = CategorieColis.parCode(colis.categorie);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColor.kPrimary.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Catégorie, référence, date et statut
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: AppColor.kPrimaryLight, borderRadius: BorderRadius.circular(12)),
                      child: Icon(categorie.icone, size: 20, color: AppColor.kPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            colis.reference,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.3,
                              color: AppColor.kGrayscaleDark100,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${categorie.libelle} · ${formatDate().format(colis.createdAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kGrayscale40),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatutBadge(statut: colis.statut),
                  ],
                ),
                const SizedBox(height: 14),
                _Trajet(depart: colis.villeDepart?.nom ?? '—', arrivee: colis.villeArrivee?.nom ?? '—'),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                // Autre partie et montant
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: AppColor.kGrayscale40),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: recu ? tr('De ') : tr('Pour ')),
                            TextSpan(
                              text: recu ? colis.expediteurNom : colis.destinataireNom,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColor.kGrayscaleDark100),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40),
                      ),
                    ),
                    if (!recu)
                      Text(
                        colis.montantEnAttente
                            ? tr('Proposé après étude')
                            : formaterMontant(colis.montantTotal, colis.devise),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: colis.montantEnAttente ? 12 : 14,
                          fontWeight: FontWeight.w700,
                          color: colis.montantEnAttente ? AppColor.kAlerte : AppColor.kPrimary,
                        ),
                      ),
                    if (colis.enRetard) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: tr('En retard'),
                        child: const Icon(Icons.schedule_rounded, size: 16, color: AppColor.kErreur),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Trajet visuel : ●──🚚──● avec la ville de départ et d'arrivée en dessous.
class _Trajet extends StatelessWidget {
  final String depart;
  final String arrivee;
  const _Trajet({required this.depart, required this.arrivee});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColor.kGrayscaleDark100,
    );
    Widget point(Color couleur) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
    );
    // Trait sur toute la largeur, villes en dessous : les noms longs restent lisibles
    return Column(
      children: [
        Row(
          children: [
            point(AppColor.kPrimary),
            const Expanded(child: Divider(color: AppColor.kLine, thickness: 1.5)),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppColor.kSecondaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.local_shipping_rounded, size: 14, color: AppColor.kSecondaryDark),
            ),
            const Expanded(child: Divider(color: AppColor.kLine, thickness: 1.5)),
            point(AppColor.kSecondary),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(depart, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(arrivee, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: style),
            ),
          ],
        ),
      ],
    );
  }
}
