import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../expedition/presentation/pages/assistant_expedition_page.dart';
import '../../data/catalogue_remote_datasource.dart';
import '../../domain/catalogue_entities.dart';
import '../../../../core/i18n/langue.dart';

/// Tournées de collecte à domicile ouvertes par l'administrateur, filtrables
/// par code postal. Réserver une tournée ouvre le parcours d'expédition.
class TourneesCollectePage extends StatefulWidget {
  final String? codePostal;
  const TourneesCollectePage({super.key, this.codePostal});

  @override
  State<TourneesCollectePage> createState() => _TourneesCollectePageState();
}

class _TourneesCollectePageState extends State<TourneesCollectePage> {
  final _codePostal = TextEditingController();
  late Future<List<TourneeCollecte>> _tournees;

  @override
  void initState() {
    super.initState();
    _codePostal.text = widget.codePostal ?? '';
    _rechercher();
  }

  @override
  void dispose() {
    _codePostal.dispose();
    super.dispose();
  }

  void _rechercher() {
    setState(() {
      _tournees = sl<CatalogueRemoteDataSource>().getTournees(
        codePostal: _codePostal.text.trim().isEmpty ? null : _codePostal.text.trim(),
      );
    });
  }

  Future<void> _reserver(TourneeCollecte t) async {
    final connecte = await isUserAuthenticated();
    if (!mounted) return;
    if (!connecte) {
      Navigator.of(context).pushNamed(AppRouter.loginRoute);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AssistantExpeditionPage(
        preremplissage: PreremplissageExpedition(
          versSenegal: t.pays == 'FR',
          modeDepot: 'enlevement_domicile',
          tourneeId: t.id,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: Text(tr('Collecte à domicile'))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(tr('Nous passons chez vous'), style: titreSection(18)),
        const SizedBox(height: 4),
        Text(tr('Consultez les prochaines tournées de collecte dans votre secteur.'), style: texteDiscret(13)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _codePostal,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _rechercher(),
              decoration: InputDecoration(labelText: tr('Votre code postal'), prefixIcon: Icon(Icons.search)),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(onPressed: _rechercher, child: Text(tr('Filtrer'))),
        ]),
        const SizedBox(height: 16),
        FutureBuilder<List<TourneeCollecte>>(
          future: _tournees,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError) {
              final e = snap.error;
              return Text(e is ServerException ? e.message : tr('Tournées indisponibles'));
            }
            final tournees = snap.data!;
            if (tournees.isEmpty) {
              return Bandeau(
                icone: Icons.event_busy_outlined,
                titre: tr('Aucune tournée ouverte pour le moment'),
                message: tr('Vous pouvez tout de même demander une collecte en indiquant la date souhaitée lors de votre envoi.'),
              );
            }
            return Column(
              children: tournees
                  .map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CarteSection(
                          titre: t.titre,
                          icone: Icons.local_shipping_outlined,
                          children: [
                            LigneInfo(tr('Date'), formaterDate(t.dateCollecte), fort: true),
                            if (t.horaires != null) LigneInfo(tr('Horaires'), t.horaires!),
                            if (t.codesPostaux.isNotEmpty) LigneInfo(tr('Secteur'), t.codesPostaux.join(', ')),
                            if (t.dateLimiteInscription != null)
                              LigneInfo(tr('Inscription avant le'), formaterDate(t.dateLimiteInscription)),
                            if (t.placesRestantes != null) LigneInfo(tr('Places restantes'), '${t.placesRestantes}'),
                            if (t.messageBanniere != null)
                              Text(t.messageBanniere!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kPrimary)),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _reserver(t),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColor.kSecondary, foregroundColor: AppColor.kPrimary),
                                child: Text(tr('Réserver ma collecte')),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ]),
    );
  }
}
