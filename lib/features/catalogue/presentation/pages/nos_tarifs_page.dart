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
          return ListView(padding: const EdgeInsets.all(20), children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'maritime', label: Text(tr('Fret maritime')), icon: Icon(Icons.directions_boat_outlined)),
                ButtonSegment(value: 'aerien', label: Text(tr('Fret aérien')), icon: Icon(Icons.flight)),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() {
                _mode = s.first;
                _charger();
              }),
            ),
            const SizedBox(height: 8),
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
                    Row(children: [
                      const Expanded(child: SizedBox()),
                      SizedBox(width: 78, child: Text(tr('Dakar'), textAlign: TextAlign.end, style: _entete())),
                      SizedBox(width: 90, child: Text(tr('Autres régions'), textAlign: TextAlign.end, style: _entete())),
                    ]),
                    const Divider(),
                    ...liste.map((a) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [
                            Expanded(
                              child: Text('${a.libelle}${a.prixAPartirDe ? tr(' (à partir de)') : ''}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                            SizedBox(width: 78, child: Text(formaterMontant(a.prixDakar, a.devise), textAlign: TextAlign.end, style: _prix())),
                            SizedBox(
                                width: 90,
                                child: Text(formaterMontant(a.prixAutresRegions, a.devise), textAlign: TextAlign.end, style: _prix())),
                          ]),
                        )),
                    if (cat.surDevis) Text(tr('Prix définitif proposé après étude de votre demande.'), style: texteDiscret(11)),
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
                        .map((s) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(s.estAerien ? Icons.flight : Icons.directions_boat_outlined,
                                  color: AppColor.kPrimary),
                              title: Text(s.nom, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                              subtitle: Text([
                                if (s.description != null && s.description!.isNotEmpty) s.description!,
                                if (s.delaiMinJours != null || s.delaiMaxJours != null)
                                  tr('Délai : ${s.delaiMinJours ?? s.delaiMaxJours}–${s.delaiMaxJours ?? s.delaiMinJours} jours'),
                              ].join('\n')),
                            ))
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
                        .map((p) => Chip(label: Text(tr('≤ ${p.poidsMaxKg} kg : ${formaterMontant(p.prixHt, 'EUR')}'))))
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
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            const Icon(Icons.close, size: 16, color: AppColor.kErreur),
                            const SizedBox(width: 8),
                            Expanded(child: Text(p, style: GoogleFonts.plusJakartaSans(fontSize: 13))),
                          ]),
                        ))
                    .toList(),
              ),
            ],
          ]);
        },
      ),
    );
  }

  TextStyle _entete() => GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.kGrayscale40);
  TextStyle _prix() => GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.kPrimary);
}
