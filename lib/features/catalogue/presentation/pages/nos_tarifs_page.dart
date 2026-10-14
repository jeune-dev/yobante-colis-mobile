import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../data/catalogue_remote_datasource.dart';
import '../../domain/catalogue_entities.dart';
import '../../../../core/i18n/langue.dart';

/// Rubrique « Nos tarifs » : grille forfaitaire (Dakar / autres régions),
/// tarifs Colissimo et produits interdits. Accessible sans compte.
class NosTarifsPage extends StatefulWidget {
  const NosTarifsPage({super.key});

  @override
  State<NosTarifsPage> createState() => _NosTarifsPageState();
}

class _NosTarifsPageState extends State<NosTarifsPage> {
  final _source = sl<CatalogueRemoteDataSource>();
  String _mode = 'maritime';

  /// Devise d'affichage choisie par l'utilisateur (`EUR` ou `XOF`) ; les montants
  /// dans l'autre devise viennent du backend.
  String _devise = 'EUR';

  /// Colonne de la grille affichée : Dakar ou autres régions du Sénégal.
  bool _dakar = true;
  late Future<(List<ArticleTarif>, ConfigurationPublique)> _donnees;

  /// Services d'expédition (aérien, maritime…) et leurs délais (`GET /public/services`).
  late final Future<List<ServiceExpedition>> _services = _source.getServices();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _charger() {
    _donnees = Future.wait([
      _source.getTarifs(modeTransport: _mode, paysDepart: 'FR', paysArrivee: 'SN'),
      _source.getConfiguration(),
    ]).then((r) => (r[0] as List<ArticleTarif>, r[1] as ConfigurationPublique));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(tr('Nos tarifs'))),
      body: FutureBuilder<(List<ArticleTarif>, ConfigurationPublique)>(
        future: _donnees,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            final e = snap.error;
            return Center(child: Text(e is ServerException ? e.message : tr('Tarifs indisponibles')));
          }
          final (articles, config) = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'maritime',
                    label: Text(tr('Fret maritime')),
                    icon: Icon(Icons.directions_boat_outlined),
                  ),
                  ButtonSegment(value: 'aerien', label: Text(tr('Fret aérien')), icon: Icon(Icons.flight)),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() {
                  _mode = s.first;
                  _charger();
                }),
              ),
              const SizedBox(height: 12),
              CarteSection(
                children: [
                  _LigneFiltre(
                    icone: Icons.place_outlined,
                    libelle: tr('Livraison'),
                    filtre: _Bascule<bool>(
                      valeur: _dakar,
                      options: [(true, tr('Dakar')), (false, tr('Régions'))],
                      onChanged: (v) => setState(() => _dakar = v),
                    ),
                  ),
                  const Divider(height: 20),
                  _LigneFiltre(
                    icone: Icons.payments_outlined,
                    libelle: tr('Devise'),
                    filtre: _Bascule<String>(
                      valeur: _devise,
                      options: const [('EUR', '€'), ('XOF', 'FCFA')],
                      onChanged: (d) => setState(() => _devise = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(tr('Prix par article, livraison incluse. France → Sénégal.'), style: texteDiscret()),
              const SizedBox(height: 16),
              if (articles.isEmpty)
                Bandeau(
                  icone: Icons.info_outline,
                  titre: tr('Tarification sur devis'),
                  message: tr('Utilisez le calculateur de tarif pour obtenir un prix.'),
                ),
              ...CategorieColis.toutes.map((cat) {
                final liste = articles.where((a) => a.categorie == cat.code).toList();
                if (liste.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CarteSection(
                    titre: '${cat.numero}. ${cat.libelle}',
                    icone: cat.icone,
                    children: [
                      for (final (k, a) in liste.indexed) ...[
                        if (k > 0) const Divider(height: 1, color: AppColor.kLine),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  a.libelle,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.kGrayscaleDark100,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (a.prixAPartirDe) Text(tr('à partir de'), style: texteDiscret(10)),
                                  _Prix(
                                    montant: _dakar ? a.prixDakar : a.prixAutresRegions,
                                    devise: a.devise,
                                    equivalent: _dakar ? a.prixDakarEquivalent : a.prixAutresRegionsEquivalent,
                                    deviseEquivalente: a.deviseEquivalente,
                                    deviseAffichee: _devise,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColor.kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (cat.surDevis)
                        Text(tr('Prix définitif proposé après étude de votre demande.'), style: texteDiscret(11)),
                    ],
                  ),
                );
              }),
              FutureBuilder<List<ServiceExpedition>>(
                future: _services,
                builder: (context, snap) {
                  final services = snap.data ?? const <ServiceExpedition>[];
                  if (services.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CarteSection(
                      titre: tr('Nos services'),
                      icone: Icons.local_shipping_outlined,
                      children: services
                          .map(
                            (s) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                s.estAerien ? Icons.flight : Icons.directions_boat_outlined,
                                color: AppColor.kPrimary,
                              ),
                              title: Text(s.nom, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                [
                                  if (s.description != null && s.description!.isNotEmpty) s.description!,
                                  if (s.delaiMinJours != null || s.delaiMaxJours != null)
                                    tr(
                                      'Délai : ${s.delaiMinJours ?? s.delaiMaxJours}–${s.delaiMaxJours ?? s.delaiMinJours} jours',
                                    ),
                                ].join('\n'),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
              if (config.colissimoActive && config.grilleColissimo.isNotEmpty)
                CarteSection(
                  titre: tr('Étiquette Colissimo (HT)'),
                  icone: Icons.local_post_office_outlined,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: config.grilleColissimo
                          .map(
                            (p) => Chip(
                              label: Text(
                                tr(
                                  '≤ ${p.poidsMaxKg} kg : ${_devise == 'XOF' && p.prixHtXof != null ? formaterMontant(p.prixHtXof, 'XOF') : formaterMontant(p.prixHt, 'EUR')}',
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              if (config.produitsInterdits.isNotEmpty) ...[
                const SizedBox(height: 16),
                CarteSection(
                  titre: tr('Produits interdits'),
                  icone: Icons.block,
                  children: config.produitsInterdits
                      .map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.close, size: 16, color: AppColor.kErreur),
                              const SizedBox(width: 8),
                              Expanded(child: Text(p, style: GoogleFonts.plusJakartaSans(fontSize: 13))),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Prix de la grille dans la devise choisie : le montant d'origine, ou son
/// équivalent fourni par le backend (à défaut, le montant d'origine).
class _Prix extends StatelessWidget {
  final double montant;
  final String devise;
  final double? equivalent;
  final String? deviseEquivalente;
  final String deviseAffichee;
  final TextStyle style;
  const _Prix({
    required this.montant,
    required this.devise,
    required this.equivalent,
    required this.deviseEquivalente,
    required this.deviseAffichee,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final converti = devise != deviseAffichee && deviseEquivalente == deviseAffichee && equivalent != null;
    return Text(
      converti ? formaterMontant(equivalent, deviseEquivalente) : formaterMontant(montant, devise),
      style: style,
    );
  }
}

/// Ligne de la carte de filtres : libellé à gauche, bascule à droite.
class _LigneFiltre extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final Widget filtre;
  const _LigneFiltre({required this.icone, required this.libelle, required this.filtre});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 18, color: AppColor.kPrimary),
        const SizedBox(width: 8),
        Expanded(child: Text(libelle, style: titreSection(14))),
        filtre,
      ],
    );
  }
}

/// Bascule compacte en pastilles (Dakar / Régions, € / FCFA).
class _Bascule<T> extends StatelessWidget {
  final T valeur;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  const _Bascule({required this.valeur, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColor.kBackground, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [for (final (code, libelle) in options) _option(code, libelle)],
      ),
    );
  }

  Widget _option(T code, String libelle) {
    final actif = code == valeur;
    return GestureDetector(
      onTap: () => onChanged(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minWidth: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: actif ? AppColor.kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          libelle,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: actif ? AppColor.kWhite : AppColor.kPrimary,
          ),
        ),
      ),
    );
  }
}
