import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../account/data/datasources/espace_client_remote_datasource.dart';
import '../../../catalogue/data/catalogue_remote_datasource.dart';
import '../../../catalogue/domain/catalogue_entities.dart';
import '../../../catalogue/presentation/pages/nos_tarifs_page.dart';
import '../../../catalogue/presentation/pages/tournees_collecte_page.dart';
import '../../../colis/domain/entities/colis.dart';
import '../../../colis/domain/usecases/colis_usecases.dart';
import '../../../colis/presentation/widgets/statut_badge.dart';
import '../../../devis/presentation/pages/devis_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../points_collecte/presentation/pages/point_de_service_page.dart';
import '../../../tracking/presentation/pages/tracking_page.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/widgets/bouton_menu_ou_retour.dart';

/// Onglet d'accueil façon DHL : suivi en accès libre, messages de
/// l'administrateur (annonces, prochaine collecte), raccourcis et envois en cours.
class AccueilPage extends StatefulWidget {
  final VoidCallback? onExpedier;
  const AccueilPage({super.key, this.onExpedier});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  final _catalogue = sl<CatalogueRemoteDataSource>();
  bool _connecte = false;
  ContenuAccueil _contenu = const ContenuAccueil();
  ConfigurationPublique? _config;
  List<Colis> _enCours = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    _connecte = await isUserAuthenticated();
    String? codePostal;
    if (_connecte) {
      try {
        codePostal = (await sl<EspaceClientRemoteDataSource>().getProfil()).codePostal;
      } catch (_) {}
    }
    try {
      final contenu = await _catalogue.getAccueil(codePostal: codePostal);
      final config = await _catalogue.getConfiguration();
      if (mounted) {
        setState(() {
          _contenu = contenu;
          _config = config;
        });
      }
    } catch (_) {
      // Accueil dégradé : le suivi et les raccourcis restent disponibles
    }
    if (_connecte) {
      final resultat = await sl<GetColis>()(limit: 5);
      resultat.fold((_) {}, (data) {
        final liste = (data['colis'] as List).cast<Colis>();
        if (mounted) {
          setState(() => _enCours = liste
              .where((c) => !['livre', 'recupere', 'retourne', 'annule', 'refuse'].contains(c.statut))
              .take(3)
              .toList());
        }
      });
    }
  }

  void _ouvrir(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        leading: const BoutonMenuOuRetour(),
        actions: [
          if (_connecte)
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () => _ouvrir(const NotificationsPage()),
            ),
          // Pictogramme de la marque, aligné à droite de la barre
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 16),
            child: Image.asset(
              'assets/images/logo_yobante_icon.png',
              height: 32,
              semanticLabel: 'Yobante',
              errorBuilder: (_, _, _) =>
                  Text('Yobante', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: ListView(padding: EdgeInsets.zero, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            decoration: const BoxDecoration(
              color: AppColor.kSecondary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('Suivez votre envoi'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: AppColor.kPrimary)),
              const SizedBox(height: 4),
              Text(tr('France ⇄ Sénégal, étape par étape.'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColor.kPrimary.withValues(alpha: 0.75))),
              const SizedBox(height: 14),
              const TrackingSearch(),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ..._contenu.tournees.map(_banniereTournee),
              ..._contenu.annonces.map(_banniereAnnonce),
              Text(tr('Que souhaitez-vous faire ?'), style: titreSection()),
              const SizedBox(height: 12),
              // Hauteur des tuiles suivant la taille du texte (réglage d'accessibilité),
              // 2 colonnes sur les très petits écrans
              LayoutBuilder(builder: (context, contraintes) => GridView.count(
                crossAxisCount: contraintes.maxWidth < 330 ? 2 : 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: (contraintes.maxWidth < 330 ? 1.35 : 0.95) /
                    MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3),
                children: [
                  _Raccourci(Icons.send_rounded, tr('Expédier'), widget.onExpedier ?? () {}, principal: true),
                  _Raccourci(Icons.calculate_outlined, tr('Calculer\nun tarif'), () => _ouvrir(const DevisPage())),
                  _Raccourci(Icons.sell_outlined, tr('Nos tarifs'), () => _ouvrir(const NosTarifsPage())),
                  _Raccourci(Icons.home_work_outlined, tr('Collecte\nà domicile'), () => _ouvrir(const TourneesCollectePage())),
                  _Raccourci(Icons.storefront_outlined, tr('Points de\nservice'), () => _ouvrir(const PointDeServicePage())),
                  _Raccourci(Icons.chat_outlined, tr('WhatsApp'),
                      () => ouvrirWhatsapp(context, numero: _config?.whatsappContact, message: tr('Bonjour Yobante,'))),
                ],
              )),
              if (_enCours.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: Text(tr('Mes envois en cours'), style: titreSection())),
                ]),
                const SizedBox(height: 10),
                ..._enCours.map((c) => _EnvoiEnCours(colis: c)),
              ],
              if (_config?.lien('boutique') != null) ...[
                const SizedBox(height: 24),
                InkWell(
                  onTap: () => ouvrirLien(context, _config!.lien('boutique')),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColor.kPrimary, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      const Icon(Icons.shopping_bag_outlined, color: AppColor.kSecondary, size: 30),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(tr('Découvrez la boutique Yobante'),
                            style: GoogleFonts.plusJakartaSans(color: AppColor.kWhite, fontWeight: FontWeight.w700)),
                      ),
                      const Icon(Icons.open_in_new, color: AppColor.kWhite),
                    ]),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _banniereTournee(TourneeCollecte t) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: InkWell(
          onTap: () => _ouvrir(const TourneesCollectePage()),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColor.kPrimary, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.local_shipping, color: AppColor.kSecondary, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('Prochaine collecte le ${formaterDate(t.dateCollecte)}'),
                      style: GoogleFonts.plusJakartaSans(color: AppColor.kSecondary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(t.messageBanniere ?? t.titre,
                      style: GoogleFonts.plusJakartaSans(color: AppColor.kWhite, fontSize: 12)),
                ]),
              ),
              const Icon(Icons.chevron_right, color: AppColor.kWhite),
            ]),
          ),
        ),
      );

  Widget _banniereAnnonce(Annonce a) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Bandeau(
          icone: switch (a.niveau) {
            'alerte' => Icons.warning_amber_rounded,
            'succes' => Icons.celebration_outlined,
            _ => Icons.campaign_outlined,
          },
          titre: a.titre,
          message: a.message,
          couleur: switch (a.niveau) {
            'alerte' => AppColor.kAlerte,
            'succes' => AppColor.kSucces,
            _ => AppColor.kPrimary,
          },
          action: a.lienUrl == null
              ? null
              : TextButton(onPressed: () => ouvrirLien(context, a.lienUrl), child: Text(a.lienLibelle ?? tr('En savoir plus'))),
        ),
      );
}

class _Raccourci extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final VoidCallback onTap;
  final bool principal;
  const _Raccourci(this.icone, this.libelle, this.onTap, {this.principal = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: principal ? AppColor.kPrimary : AppColor.kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icone, color: principal ? AppColor.kSecondary : AppColor.kPrimary, size: 28),
          const SizedBox(height: 8),
          Text(libelle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w700, color: principal ? AppColor.kWhite : AppColor.kGrayscaleDark100)),
        ]),
      ),
    );
  }
}

class _EnvoiEnCours extends StatelessWidget {
  final Colis colis;
  const _EnvoiEnCours({required this.colis});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).pushNamed(AppRouter.detailColisRoute, arguments: colis.id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const Icon(Icons.inventory_2_outlined, color: AppColor.kPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(colis.reference, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('${colis.villeDepart?.nom ?? '—'} → ${colis.villeArrivee?.nom ?? '—'}', style: texteDiscret()),
              ]),
            ),
            StatutBadge(statut: colis.statut),
          ]),
        ),
      ),
    );
  }
}
