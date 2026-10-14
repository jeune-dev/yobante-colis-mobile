import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_color.dart';
import '../i18n/langue.dart';

/// Champ de choix parmi une courte liste de valeurs (emballage, unité…), ouvrant
/// une grille de tuiles dans une feuille du bas plutôt que le menu déroulant
/// Material par défaut.
class SelecteurOptions extends StatelessWidget {
  final String label;

  /// Clé envoyée au backend → libellé (traduit à l'affichage).
  final Map<String, String> options;
  final String? valeur;
  final ValueChanged<String> onChanged;
  final IconData? icone;

  /// Icône propre à chaque option (facultative).
  final Map<String, IconData> icones;
  const SelecteurOptions({
    super.key,
    required this.label,
    required this.options,
    required this.valeur,
    required this.onChanged,
    this.icone,
    this.icones = const {},
  });

  Future<void> _ouvrir(BuildContext context) async {
    final choix = await showModalBottomSheet<String>(
      context: context,
      // Hauteur selon le contenu (sinon limitée à 9/16 de l'écran) ; la poignée vient du thème
      isScrollControlled: true,
      backgroundColor: AppColor.kWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _GrilleOptions(titre: label, options: options, valeur: valeur, icones: icones),
    );
    if (choix != null) onChanged(choix);
  }

  @override
  Widget build(BuildContext context) {
    final libelle = options[valeur];
    return InkWell(
      onTap: () => _ouvrir(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icones[valeur] ?? icone, size: 20),
          suffixIcon: const Icon(Icons.expand_more),
        ),
        child: Text(
          libelle == null ? tr('Sélectionner') : tr(libelle),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: libelle == null ? AppColor.kGrayscale40 : AppColor.kGrayscaleDark100,
          ),
        ),
      ),
    );
  }
}

class _GrilleOptions extends StatelessWidget {
  final String titre;
  final Map<String, String> options;
  final String? valeur;
  final Map<String, IconData> icones;
  const _GrilleOptions({required this.titre, required this.options, required this.valeur, required this.icones});

  @override
  Widget build(BuildContext context) {
    final entrees = options.entries.toList();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                titre,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kGrayscaleDark100,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Lignes de 3 tuiles à la hauteur de leur contenu : pas de débordement
            // quand la taille de texte du téléphone est agrandie.
            for (var i = 0; i < entrees.length; i += 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var j = i; j < i + 3; j++) ...[
                        if (j > i) const SizedBox(width: 10),
                        Expanded(
                          child: j < entrees.length
                              ? _Tuile(
                                  libelle: tr(entrees[j].value),
                                  icone: icones[entrees[j].key],
                                  choisie: entrees[j].key == valeur,
                                  onTap: () => Navigator.of(context).pop(entrees[j].key),
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tuile extends StatelessWidget {
  final String libelle;
  final IconData? icone;
  final bool choisie;
  final VoidCallback onTap;
  const _Tuile({required this.libelle, required this.icone, required this.choisie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final couleur = choisie ? AppColor.kPrimary : AppColor.kGrayscaleDark100;
    return Material(
      color: choisie ? AppColor.kPrimaryLight : AppColor.kBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: choisie ? AppColor.kPrimary : AppColor.kLine, width: choisie ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icone != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: choisie ? AppColor.kPrimary : AppColor.kWhite,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icone, size: 22, color: choisie ? AppColor.kWhite : AppColor.kPrimary),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    libelle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: choisie ? FontWeight.w700 : FontWeight.w500,
                      color: couleur,
                    ),
                  ),
                ],
              ),
            ),
            if (choisie)
              const Positioned(top: 6, right: 6, child: Icon(Icons.check_circle, size: 16, color: AppColor.kPrimary)),
          ],
        ),
      ),
    );
  }
}
