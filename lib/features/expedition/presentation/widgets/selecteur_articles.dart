import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../catalogue/domain/catalogue_entities.dart';
import '../../../../core/i18n/langue.dart';

/// Grille « Nature du colis » : le client choisit ses articles (valise, sac,
/// barigot, télévision…) et leur quantité. Le prix affiché dépend de la zone
/// sénégalaise desservie (Dakar ou autres régions).
class SelecteurArticles extends StatelessWidget {
  final List<ArticleTarif> articles;
  final Map<String, int> quantites;
  final bool zoneDakar;
  final void Function(ArticleTarif article, int quantite) onChanged;
  const SelecteurArticles({
    super.key,
    required this.articles,
    required this.quantites,
    required this.zoneDakar,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return Text(tr('Aucun article disponible pour cette catégorie.'), style: texteDiscret(13));
    }
    return Column(
      children: articles.map((a) {
        final prix = zoneDakar ? a.prixDakar : a.prixAutresRegions;
        final quantite = quantites[a.id] ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColor.kWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: quantite > 0 ? AppColor.kSecondary : AppColor.kLine, width: quantite > 0 ? 2 : 1),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: a.photoUrl != null
                  ? CachedNetworkImage(imageUrl: a.photoUrl!, width: 44, height: 44, fit: BoxFit.cover)
                  : Container(
                      width: 44,
                      height: 44,
                      color: AppColor.kPrimary.withValues(alpha: 0.07),
                      child: const Icon(Icons.luggage_outlined, color: AppColor.kPrimary),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.libelle, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('${a.prixAPartirDe ? tr('à partir de ') : ''}${formaterMontant(prix, a.devise)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColor.kPrimary)),
              ]),
            ),
            CompteurQuantite(valeur: quantite, onChanged: (q) => onChanged(a, q)),
          ]),
        );
      }).toList(),
    );
  }
}
