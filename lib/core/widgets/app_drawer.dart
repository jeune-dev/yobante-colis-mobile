import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/account/presentation/pages/parrainage_page.dart';
import '../../features/account/presentation/pages/profil_page.dart';
import '../../features/catalogue/data/catalogue_remote_datasource.dart';
import '../../features/catalogue/domain/catalogue_entities.dart';
import '../../features/catalogue/presentation/pages/nos_tarifs_page.dart';
import '../../features/catalogue/presentation/pages/tournees_collecte_page.dart';
import '../../injection_container.dart';
import 'ui_kit.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/devis/presentation/pages/devis_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/paiements/presentation/pages/factures_page.dart';
import '../../features/points_collecte/presentation/pages/point_de_service_page.dart';
import '../../features/tracking/presentation/pages/tracking_page.dart';
import '../routes/app_router.dart';
import '../services/auth_status.dart';
import '../theme/app_color.dart';
import 'static_info_page.dart';
import '../../features/adresses/presentation/pages/adresses_page.dart';
import '../../features/avis/presentation/pages/avis_page.dart';
import '../../features/enlevements/presentation/pages/enlevements_page.dart';
import '../../features/faq/presentation/pages/faq_page.dart';
import '../../features/reclamations/presentation/pages/reclamations_page.dart';
import '../i18n/langue.dart';
import '../i18n/selecteur_langue.dart';

/// Tiroir latéral de navigation, façon DHL Express : compte, raccourcis
/// commerciaux (devis, suivi, point de service), pages d'information et
/// sélecteurs pays/langue.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: FutureBuilder<bool>(
          future: isUserAuthenticated(),
          builder: (context, snap) {
            final isAuth = snap.data == true;
            return Column(
              children: [
                _Header(isAuth: isAuth),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _MenuTile(
                        icon: Icons.send_outlined,
                        label: tr('Expédier un colis'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(isAuth ? AppRouter.creationColisRoute : AppRouter.loginRoute);
                        },
                      ),
                      _MenuTile(
                        icon: Icons.calculate_outlined,
                        label: tr('Calculer un tarif'),
                        onTap: () => _push(context, const DevisPage()),
                      ),
                      _MenuTile(
                        icon: Icons.sell_outlined,
                        label: tr('Nos tarifs'),
                        onTap: () => _push(context, const NosTarifsPage()),
                      ),
                      _MenuTile(
                        icon: Icons.home_work_outlined,
                        label: tr('Collecte à domicile'),
                        onTap: () => _push(context, const TourneesCollectePage()),
                      ),
                      _MenuTile(
                        icon: Icons.search_rounded,
                        label: tr('Suivre'),
                        onTap: () => _push(context, const TrackingPage()),
                      ),
                      _MenuTile(
                        icon: Icons.receipt_long_outlined,
                        label: tr('Mes factures'),
                        onTap: () => _push(context, const FacturesPage()),
                      ),
                      _MenuTile(
                        icon: Icons.notifications_outlined,
                        label: tr('Notifications'),
                        onTap: () => _push(context, const NotificationsPage()),
                      ),
                      if (isAuth)
                        _MenuTile(
                          icon: Icons.local_shipping_outlined,
                          label: tr('Mes enlèvements'),
                          onTap: () => _push(context, const EnlevementsPage()),
                        ),
                      if (isAuth)
                        _MenuTile(
                          icon: Icons.contacts_outlined,
                          label: tr("Carnet d'adresses"),
                          onTap: () => _push(context, const AdressesPage()),
                        ),
                      if (isAuth)
                        _MenuTile(
                          icon: Icons.support_agent_outlined,
                          label: tr('Mes réclamations'),
                          onTap: () => _push(context, const ReclamationsPage()),
                        ),
                      if (isAuth)
                        _MenuTile(
                          icon: Icons.card_giftcard_outlined,
                          label: tr('Parrainage'),
                          onTap: () => _push(context, const ParrainagePage()),
                        ),
                      const Divider(),
                      _MenuTile(
                        icon: Icons.gavel_outlined,
                        label: tr('Légal'),
                        onTap: () => _push(context, StaticInfoPage(title: tr('Légal'), sections: _legal)),
                      ),
                      _MenuTile(
                        icon: Icons.star_outline_rounded,
                        label: tr('Avis clients'),
                        onTap: () => _push(context, const AvisPage()),
                      ),
                      _MenuTile(
                        icon: Icons.location_on_outlined,
                        label: tr('Trouver un point de service'),
                        onTap: () => _push(context, const PointDeServicePage()),
                      ),
                      _MenuTile(
                        icon: Icons.chat_outlined,
                        label: tr('Support WhatsApp'),
                        onTap: () async {
                          Navigator.of(context).pop();
                          final config = await sl<CatalogueRemoteDataSource>().getConfiguration().catchError(
                                (_) => const ConfigurationPublique(),
                              );
                          if (context.mounted) {
                            ouvrirWhatsapp(context, numero: config.whatsappContact, message: tr('Bonjour Yobante,'));
                          }
                        },
                      ),
                      _MenuTile(
                        icon: Icons.support_agent_outlined,
                        label: tr('Aide'),
                        onTap: () => _push(context, FaqPage(secours: _support)),
                      ),
                      _MenuTile(
                        icon: Icons.shield_outlined,
                        label: tr('Degré de sensibilisation à la fraude'),
                        onTap: () => _push(
                          context,
                          StaticInfoPage(title: tr('Sensibilisation à la fraude'), sections: _fraude),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const _Footer(),
              ],
            );
          },
        ),
      ),
    );
  }

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).pop(); // ferme le tiroir
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _Header extends StatelessWidget {
  final bool isAuth;
  const _Header({required this.isAuth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: AppColor.kSecondary, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: AppColor.kPrimary),
              ),
              const SizedBox(width: 12),
              Text(isAuth ? tr('Mon compte') : tr('Client'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isAuth
                ? tr('Gérez votre profil, vos factures et vos envois.')
                : tr('Inscrivez-vous pour déverrouiller d\'autres fonctionnalités de l\'application'),
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColor.kGrayscale40),
          ),
          const SizedBox(height: 14),
          if (isAuth)
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilPage()));
                  },
                  child: Text(tr('Mon profil')),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.read<AuthBloc>().add(LogoutRequested());
                  },
                  child: Text(tr('Se déconnecter'), style: TextStyle(color: AppColor.kErreur)),
                ),
              ],
            )
          else
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(AppRouter.loginRoute);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.kSecondary,
                    foregroundColor: AppColor.kPrimary,
                  ),
                  child: Text(tr('Connexion')),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(AppRouter.registerRoute);
                  },
                  child: Text(tr('S\'inscrire')),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColor.kGrayscaleDark100),
      title: Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColor.kGrayscale40),
      onTap: onTap,
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.public, size: 18, color: AppColor.kGrayscale40),
            SizedBox(width: 10),
            Text(tr('Sénégal'), style: TextStyle(fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          // Choix de la langue (français / anglais)
          const TuileLangue(compacte: true),
          const SizedBox(height: 14),
          Text(tr('Yobante Colis'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12)),
          Text(tr('© ${DateTime.now().year} Yobante Colis. Tous droits réservés.'),
              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColor.kGrayscale40)),
        ],
      ),
    );
  }
}

// Coordonnées publiques du support (identiques aux pages yobanterek.com).
const _emailSupport = 'ballabeye.dev04@gmail.com';
const _telephoneSupport = '+221 77 307 16 39';
const _urlConfidentialite = 'https://yobanterek.com/regle-confidentialite';
const _urlSuppressionCompte = 'https://yobanterek.com/suppression-compte';

List<LienInfo> get _liensContact => [
  LienInfo(_emailSupport, 'mailto:$_emailSupport', icone: Icons.mail_outline_rounded),
  LienInfo(_telephoneSupport, 'tel:+221773071639', icone: Icons.phone_outlined),
  LienInfo(tr('WhatsApp'), 'https://wa.me/221773071639', icone: Icons.chat_outlined),
];

List<StaticInfoSection> get _legal => [
  StaticInfoSection(
    titre: tr('Confidentialité des données'),
    corps: tr('Les données personnelles collectées (identité, coordonnées, adresses, '
        'contenu des expéditions) sont utilisées pour l\'exécution du contrat de '
        'transport. Elles ne sont ni vendues ni utilisées à des fins publicitaires.'),
    liens: [LienInfo(tr('Lire les règles de confidentialité'), _urlConfidentialite)],
  ),
  StaticInfoSection(
    titre: tr('Suppression de votre compte'),
    corps: tr('Vous pouvez supprimer votre compte depuis Réglages du compte, '
        'ou en suivant la procédure décrite sur notre site.'),
    liens: [LienInfo(tr('Procédure de suppression du compte'), _urlSuppressionCompte)],
  ),
];

List<StaticInfoSection> get _support => [
  StaticInfoSection(
    titre: tr('Nous contacter'),
    corps: tr('Pour toute question sur une expédition, une facture ou votre compte, '
        'contactez le support Yobante Colis.'),
    liens: _liensContact,
  ),
];

List<StaticInfoSection> get _fraude => [
  StaticInfoSection(
    titre: tr('Restez vigilant'),
    corps: tr('Yobante Colis ne vous demandera jamais vos identifiants, code de '
        'retrait ou informations bancaires par téléphone, SMS ou email non sollicité. '
        'Ne communiquez votre code de retrait qu\'à un agent Yobante Colis en point '
        'de service, et vérifiez toujours l\'expéditeur d\'un message avant d\'y répondre.'),
  ),
  StaticInfoSection(
    titre: tr('Signaler une tentative de fraude'),
    corps: tr('Si vous recevez une communication suspecte se présentant comme émanant '
        'de Yobante Colis, signalez-la au support avant toute action.'),
    liens: _liensContact,
  ),
];
