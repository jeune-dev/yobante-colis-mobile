import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../adresses/presentation/pages/adresses_page.dart';
import '../../../avis/presentation/pages/avis_page.dart';
import '../../../catalogue/data/catalogue_remote_datasource.dart';
import '../../../enlevements/presentation/pages/enlevements_page.dart';
import '../../../catalogue/presentation/pages/nos_tarifs_page.dart';
import '../../../catalogue/presentation/pages/tournees_collecte_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../paiements/presentation/pages/factures_page.dart';
import '../../../reclamations/presentation/pages/reclamations_page.dart';
import 'parrainage_page.dart';
import 'profil_page.dart';
import 'reglages_compte_page.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/i18n/selecteur_langue.dart';
import '../../../../core/widgets/bouton_menu_ou_retour.dart';

/// Onglet « Compte » : espace personnel (profil, factures, parrainage,
/// réglages) et services (tarifs, collecte, contact WhatsApp).
class ComptePage extends StatefulWidget {
  const ComptePage({super.key});

  @override
  State<ComptePage> createState() => _ComptePageState();
}

class _ComptePageState extends State<ComptePage> {
  bool? _connecte;
  String? _whatsapp;

  @override
  void initState() {
    super.initState();
    isUserAuthenticated().then((c) {
      if (mounted) setState(() => _connecte = c);
    });
    sl<CatalogueRemoteDataSource>().getConfiguration().then((c) {
      if (mounted) setState(() => _whatsapp = c.whatsappContact);
    }).catchError((_) {});
  }

  void _ouvrir(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final connecte = _connecte == true;
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        leading: const BoutonMenuOuRetour(),
        title: Text(tr('Compte')),
      ),
      body: _connecte == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: [
              if (!connecte)
                CarteSection(children: [
                  Text(tr('Bienvenue sur Yobante'), style: titreSection(17)),
                  const SizedBox(height: 6),
                  Text(tr('Connectez-vous pour expédier, suivre et payer vos envois.'), style: texteDiscret(13)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pushNamed(AppRouter.loginRoute),
                        child: Text(tr('Se connecter')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pushNamed(AppRouter.registerRoute),
                        child: Text(tr('Créer un compte')),
                      ),
                    ),
                  ]),
                ]),
              if (connecte) ...[
                _Groupe(tr('Mon espace'), [
                  _Entree(Icons.person_outline, tr('Mon profil'), () => _ouvrir(const ProfilPage())),
                  _Entree(Icons.receipt_long_outlined, tr('Mes factures'), () => _ouvrir(const FacturesPage())),
                  _Entree(Icons.card_giftcard_outlined, tr('Parrainage'), () => _ouvrir(const ParrainagePage())),
                  _Entree(Icons.notifications_none_rounded, tr('Notifications'), () => _ouvrir(const NotificationsPage())),
                  _Entree(Icons.support_agent_outlined, tr('Mes réclamations'), () => _ouvrir(const ReclamationsPage())),
                  _Entree(Icons.contacts_outlined, tr("Carnet d'adresses"), () => _ouvrir(const AdressesPage())),
                  _Entree(Icons.local_shipping_outlined, tr('Mes enlèvements'), () => _ouvrir(const EnlevementsPage())),
                  _Entree(Icons.tune, tr('Réglages et tarif pro'), () => _ouvrir(const ReglagesComptePage())),
                ]),
              ],
              const SizedBox(height: 16),
              _Groupe(tr('Services'), [
                _Entree(Icons.sell_outlined, tr('Nos tarifs'), () => _ouvrir(const NosTarifsPage())),
                _Entree(Icons.home_work_outlined, tr('Collecte à domicile'), () => _ouvrir(const TourneesCollectePage())),
                _Entree(Icons.star_outline_rounded, tr('Avis clients'), () => _ouvrir(const AvisPage())),
                _Entree(Icons.translate, '${tr('Langue')} · ${LangueApp.instance.value.libelle}',
                    () => choisirLangue(context)),
                _Entree(Icons.chat_outlined, tr('Nous écrire sur WhatsApp'),
                    () => ouvrirWhatsapp(context, numero: _whatsapp, message: tr('Bonjour Yobante,'))),
              ]),
              if (connecte) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () {
                    context.read<AuthBloc>().add(LogoutRequested());
                    Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.clientRoute, (_) => false);
                  },
                  icon: const Icon(Icons.logout, color: AppColor.kErreur),
                  label: Text(tr('Se déconnecter'), style: TextStyle(color: AppColor.kErreur)),
                ),
              ],
            ]),
    );
  }
}

class _Groupe extends StatelessWidget {
  final String titre;
  final List<_Entree> entrees;
  const _Groupe(this.titre, this.entrees);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(titre.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColor.kGrayscale40)),
      ),
      Material(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < entrees.length; i++) ...[
            entrees[i],
            if (i < entrees.length - 1) const Divider(height: 1, indent: 56),
          ],
        ]),
      ),
    ]);
  }
}

class _Entree extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final VoidCallback onTap;
  const _Entree(this.icone, this.libelle, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icone, color: AppColor.kPrimary),
      title: Text(libelle, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
