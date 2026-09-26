import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_color.dart';
import '../../../catalogue/domain/catalogue_entities.dart';
import '../../../../core/i18n/langue.dart';

/// Champ de sélection d'une ville, ouvrant une liste avec recherche (la France
/// compte une centaine de villes desservies : un menu déroulant serait illisible).
class SelecteurVille extends StatelessWidget {
  final String label;
  final List<VilleDesservie> villes;
  final VilleDesservie? valeur;
  final ValueChanged<VilleDesservie> onChanged;
  final bool chargement;
  const SelecteurVille({
    super.key,
    required this.label,
    required this.villes,
    required this.valeur,
    required this.onChanged,
    this.chargement = false,
  });

  Future<void> _ouvrir(BuildContext context) async {
    final choix = await showModalBottomSheet<VilleDesservie>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ListeVilles(titre: label, villes: villes),
    );
    if (choix != null) onChanged(choix);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: chargement || villes.isEmpty ? null : () => _ouvrir(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
          suffixIcon: chargement
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
              : const Icon(Icons.expand_more),
        ),
        child: Text(
          valeur == null ? tr('Sélectionner') : '${valeur!.nom}${valeur!.zoneTarifDakar ? tr('  ·  zone Dakar') : ''}',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: valeur == null ? AppColor.kGrayscale40 : AppColor.kGrayscaleDark100),
        ),
      ),
    );
  }
}

class _ListeVilles extends StatefulWidget {
  final String titre;
  final List<VilleDesservie> villes;
  const _ListeVilles({required this.titre, required this.villes});

  @override
  State<_ListeVilles> createState() => _ListeVillesState();
}

class _ListeVillesState extends State<_ListeVilles> {
  String _filtre = '';

  String _sansAccent(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c');

  @override
  Widget build(BuildContext context) {
    final filtrees =
        widget.villes.where((v) => _sansAccent(v.nom).contains(_sansAccent(_filtre))).toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColor.kLine, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _filtre = v),
                decoration: InputDecoration(hintText: tr('Rechercher — ${widget.titre}'), prefixIcon: const Icon(Icons.search)),
              ),
            ),
            Expanded(
              child: filtrees.isEmpty
                  ? Center(child: Text(tr('Aucune ville trouvée'), style: GoogleFonts.plusJakartaSans(color: AppColor.kGrayscale40)))
                  : ListView.builder(
                      itemCount: filtrees.length,
                      itemBuilder: (_, i) {
                        final v = filtrees[i];
                        return ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: Text(v.nom),
                          subtitle: v.pays == 'SN' ? Text(v.zoneTarifDakar ? tr('Tarif Dakar') : tr('Tarif autres régions')) : null,
                          onTap: () => Navigator.of(context).pop(v),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}
