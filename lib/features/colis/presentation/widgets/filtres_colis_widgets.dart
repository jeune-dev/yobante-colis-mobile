import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/filtres_colis.dart';

/// Statuts proposés au filtre (null : tous).
Map<String?, String> get libellesFiltreStatut => {
      null: tr('Tous'),
      'en_attente_validation': tr('En cours d\'étude'),
      'devis_propose': tr('Proposition reçue'),
      'en_attente': tr('En attente de remise'),
      'en_transit': tr('En transit'),
      'en_douane': tr('En dédouanement'),
      'arrive': tr('Arrivé'),
      'livre': tr('Livré'),
      'annule': tr('Annulé'),
    };

typedef ChoixFiltresColis = ({String? statut, FiltresColis filtres});

/// Feuille de filtres : statut, catégorie, « en cours » et période. Pour les colis
/// reçus ([recus]), le backend n'accepte que le statut et la période.
Future<ChoixFiltresColis?> choisirFiltresColis(
  BuildContext context, {
  required String? statut,
  required FiltresColis filtres,
  bool recus = false,
}) =>
    showModalBottomSheet<ChoixFiltresColis>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FeuilleFiltres(statut: statut, filtres: filtres, recus: recus),
    );

class _FeuilleFiltres extends StatefulWidget {
  final String? statut;
  final FiltresColis filtres;
  final bool recus;
  const _FeuilleFiltres({required this.statut, required this.filtres, required this.recus});

  @override
  State<_FeuilleFiltres> createState() => _FeuilleFiltresState();
}

class _FeuilleFiltresState extends State<_FeuilleFiltres> {
  late String? _statut = widget.statut;
  late FiltresColis _filtres = widget.filtres;

  Future<void> _choisirPeriode() async {
    final maintenant = DateTime.now();
    final plage = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: maintenant,
      initialDateRange: _filtres.dateDebut != null && _filtres.dateFin != null
          ? DateTimeRange(start: _filtres.dateDebut!, end: _filtres.dateFin!)
          : null,
    );
    if (plage != null) setState(() => _filtres = _filtres.copyWith(dateDebut: plage.start, dateFin: plage.end));
  }

  @override
  Widget build(BuildContext context) {
    final fmt = formatDateCourte();
    final periode = _filtres.dateDebut == null
        ? tr('Toutes les dates')
        : '${fmt.format(_filtres.dateDebut!)} → ${fmt.format(_filtres.dateFin ?? _filtres.dateDebut!)}';
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('Filtrer'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 14),
            Text(tr('Statut'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: libellesFiltreStatut.entries
                  .map((e) => ChoiceChip(
                        label: Text(e.value),
                        selected: _statut == e.key,
                        onSelected: (_) => setState(() => _statut = e.key),
                      ))
                  .toList(),
            ),
            if (!widget.recus) ...[
              const SizedBox(height: 14),
              Text(tr('Catégorie'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: Text(tr('Toutes')),
                    selected: _filtres.categorie == null,
                    onSelected: (_) => setState(() => _filtres = _filtres.copyWith(effacerCategorie: true)),
                  ),
                  ...CategorieColis.toutes.map((c) => ChoiceChip(
                        // Icône blanche sur la puce choisie (fond bleu), bleue sinon
                        avatar: Icon(c.icone,
                            size: 16, color: _filtres.categorie == c.code ? AppColor.kWhite : AppColor.kPrimary),
                        label: Text(c.libelle),
                        selected: _filtres.categorie == c.code,
                        onSelected: (_) => setState(() => _filtres = _filtres.copyWith(categorie: c.code)),
                      )),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('Envois en cours uniquement')),
                value: _filtres.enCours,
                onChanged: (v) => setState(() => _filtres = _filtres.copyWith(enCours: v)),
              ),
            ],
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range_outlined),
              title: Text(tr('Période')),
              subtitle: Text(periode),
              trailing: _filtres.dateDebut == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _filtres = _filtres.copyWith(effacerPeriode: true)),
                    ),
              onTap: _choisirPeriode,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      (statut: null, filtres: FiltresColis(reference: widget.filtres.reference)),
                    ),
                    child: Text(tr('Réinitialiser')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.kSecondary,
                      foregroundColor: AppColor.kPrimary,
                    ),
                    onPressed: () => Navigator.pop(context, (statut: _statut, filtres: _filtres)),
                    child: Text(tr('Appliquer')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Barre au-dessus des listes : recherche par référence (envois) et accès aux filtres.
class BarreFiltresColis extends StatefulWidget {
  final bool recherche;
  final bool filtresActifs;
  final ValueChanged<String>? onRecherche;
  final VoidCallback onFiltres;
  const BarreFiltresColis({
    super.key,
    this.recherche = true,
    required this.filtresActifs,
    this.onRecherche,
    required this.onFiltres,
  });

  @override
  State<BarreFiltresColis> createState() => _BarreFiltresColisState();
}

class _BarreFiltresColisState extends State<BarreFiltresColis> {
  final _texte = TextEditingController();

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bouton = IconButton.filledTonal(
      tooltip: tr('Filtrer'),
      onPressed: widget.onFiltres,
      icon: Badge(isLabelVisible: widget.filtresActifs, child: const Icon(Icons.tune_rounded)),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          if (widget.recherche)
            Expanded(
              child: TextField(
                controller: _texte,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: tr('Rechercher une référence'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ValueListenableBuilder(
                    valueListenable: _texte,
                    builder: (_, v, _) => v.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _texte.clear();
                              widget.onRecherche?.call('');
                            },
                          ),
                  ),
                ),
                onSubmitted: (v) => widget.onRecherche?.call(v.trim()),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 8),
          bouton,
        ],
      ),
    );
  }
}
