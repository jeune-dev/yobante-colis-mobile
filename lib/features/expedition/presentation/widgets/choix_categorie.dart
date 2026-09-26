import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/theme/app_color.dart';

/// Cartes de choix de la catégorie de colis (1 documents, 2 colis moyen, 3 XXL).
class ChoixCategorie extends StatelessWidget {
  final String? selection;
  final ValueChanged<CategorieColis> onChanged;
  final bool compact;
  const ChoixCategorie({super.key, required this.selection, required this.onChanged, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: CategorieColis.toutes.map((c) {
        final actif = c.code == selection;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onChanged(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.all(compact ? 12 : 16),
              decoration: BoxDecoration(
                color: actif ? AppColor.kPrimary : AppColor.kWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: actif ? AppColor.kPrimary : AppColor.kLine, width: 1.5),
              ),
              child: Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: actif ? AppColor.kSecondary : AppColor.kSecondary.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(c.icone, color: AppColor.kPrimary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${c.numero}. ${c.libelle}',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: actif ? AppColor.kWhite : AppColor.kGrayscaleDark100)),
                    const SizedBox(height: 2),
                    Text(c.description,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: actif ? AppColor.kWhite.withValues(alpha: 0.85) : AppColor.kGrayscale40)),
                    if (!compact) ...[
                      const SizedBox(height: 6),
                      Text(c.parcours,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: actif ? AppColor.kSecondary : AppColor.kPrimary)),
                    ],
                  ]),
                ),
                Icon(actif ? Icons.check_circle : Icons.circle_outlined,
                    color: actif ? AppColor.kSecondary : AppColor.kLine),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}
