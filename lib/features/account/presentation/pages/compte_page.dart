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
import '../../domain/entities/account_user.dart';
import '../../domain/repositories/account_repository.dart';
import '../../../../core/widgets/avatar_utilisateur.dart';
import '../../../../core/widgets/pastille_notifications.dart';

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
  AccountUser? _utilisateur;

  @override
  void initState() {
    super.initState();
    isUserAuthenticated().then((c) {
      if (mounted) setState(() => _connecte = c);
      if (c) _chargerUtilisateur();
    });
    sl<CatalogueRemoteDataSource>()
        .getConfiguration()
        .then((c) {
          if (mounted) setState(() => _whatsapp = c.whatsappContact);
        })
        .catchError((_) {});
  }

  /// Nom, email et photo pour l'en-tête ; rechargés au retour du profil.
  Future<void> _chargerUtilisateur() async {
    final res = await sl<AccountRepository>().getMe();
    res.fold((_) {}, (u) {
      if (mounted) setState(() => _utilisateur = u);
    });
  }

  Future<void> _ouvrir(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final connecte = _connecte == true;
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(leading: const BoutonMenuOuRetour(), title: Text(tr('Compte'))),
      body: _connecte == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (connecte)
                  _EnteteProfil(
                    utilisateur: _utilisateur,
                    onTap: () => _ouvrir(const ProfilPage()).then((_) => _chargerUtilisateur()),
                  )
                else
                  const _CarteBienvenue(),
                const SizedBox(height: 24),
                if (connecte) ...[
                  _Groupe(tr('Mon espace'), [
                    _Entree(
                      Icons.person_outline,
                      tr('Mon profil'),
                      () => _ouvrir(const ProfilPage()).then((_) => _chargerUtilisateur()),
                    ),
                    _Entree(Icons.receipt_long_outlined, tr('Mes factures'), () => _ouvrir(const FacturesPage())),
                    _Entree(Icons.notifications_none_rounded, tr('Notifications'), () => _ouvrir(const NotificationsPage()),
                      compteur: true),
                    _Entree(
                      Icons.local_shipping_outlined,
                      tr('Mes enlèvements'),
                      () => _ouvrir(const EnlevementsPage()),
                    ),
                    _Entree(Icons.contacts_outlined, tr("Carnet d'adresses"), () => _ouvrir(const AdressesPage())),
                    _Entree(
                      Icons.support_agent_outlined,
                      tr('Mes réclamations'),
                      () => _ouvrir(const ReclamationsPage()),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _Groupe(tr('Avantages et réglages'), [
                    _Entree(
                      Icons.card_giftcard_outlined,
                      tr('Parrainage'),
                      () => _ouvrir(const ParrainagePage()),
                      accent: true,
                    ),
                    _Entree(Icons.tune, tr('Réglages et tarif pro'), () => _ouvrir(const ReglagesComptePage())),
                    _Entree(
                      Icons.translate,
                      tr('Langue'),
                      () => choisirLangue(context),
                      valeur: LangueApp.instance.value.libelle,
                    ),
                  ]),
                  const SizedBox(height: 20),
                ],
                _Groupe(tr('Services'), [
                  _Entree(Icons.sell_outlined, tr('Nos tarifs'), () => _ouvrir(const NosTarifsPage())),
                  _Entree(
                    Icons.home_work_outlined,
                    tr('Collecte à domicile'),
                    () => _ouvrir(const TourneesCollectePage()),
                  ),
                  _Entree(Icons.star_outline_rounded, tr('Avis clients'), () => _ouvrir(const AvisPage())),
                  if (!connecte)
                    _Entree(
                      Icons.translate,
                      tr('Langue'),
                      () => choisirLangue(context),
                      valeur: LangueApp.instance.value.libelle,
                    ),
                  _Entree(
                    Icons.chat_outlined,
                    tr('Nous écrire sur WhatsApp'),
                    () => ouvrirWhatsapp(context, numero: _whatsapp, message: tr('Bonjour Yobante Colis,')),
                  ),
                ]),
                if (connecte) ...[
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(const LogoutRequested());
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.kErreur,
                      side: BorderSide(color: AppColor.kErreur.withValues(alpha: 0.4)),
                      backgroundColor: AppColor.kWhite,
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text(tr('Se déconnecter')),
                  ),
                ],
              ],
            ),
    );
  }
}

/// En-tête du compte connecté : photo ou initiales, nom et email, accès au profil.
class _EnteteProfil extends StatelessWidget {
  final AccountUser? utilisateur;
  final VoidCallback onTap;
  const _EnteteProfil({required this.utilisateur, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final u = utilisateur;
    final photo = u?.avatarUrl;
    return Material(
      color: AppColor.kPrimary,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Carré jaune du pictogramme, en filigrane
            Positioned(
              right: -22,
              top: -22,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColor.kSecondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  AvatarUtilisateur(prenom: u?.prenom, nom: u?.nom, photoUrl: photo, rayon: 28, bordure: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u?.fullName ?? tr('Mon compte'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColor.kWhite,
                          ),
                        ),
                        if ((u?.email ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            u!.email!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColor.kWhite.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          tr('Voir mon profil'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColor.kSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColor.kWhite),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Visiteur non connecté : présentation et accès à la connexion ou à l'inscription.
class _CarteBienvenue extends StatelessWidget {
  const _CarteBienvenue();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColor.kPrimary, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(14)),
            child: Image.asset('assets/images/logo_yobante_icon.png', width: 32, height: 32),
          ),
          const SizedBox(height: 14),
          Text(
            tr('Bienvenue sur Yobante Colis'),
            style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w700, color: AppColor.kWhite),
          ),
          const SizedBox(height: 6),
          Text(
            tr('Connectez-vous pour expédier, suivre et payer vos envois.'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.4,
              color: AppColor.kWhite.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRouter.loginRoute),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.kSecondary,
                    foregroundColor: AppColor.kPrimary,
                  ),
                  child: Text(tr('Se connecter')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRouter.registerRoute),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.kWhite,
                    side: BorderSide(color: AppColor.kWhite.withValues(alpha: 0.6)),
                  ),
                  child: Text(tr('Créer un compte')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Groupe extends StatelessWidget {
  final String titre;
  final List<_Entree> entrees;
  const _Groupe(this.titre, this.entrees);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            titre,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.kGrayscale40),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: AppColor.kPrimary.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Material(
            color: AppColor.kWhite,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < entrees.length; i++) ...[
                  entrees[i],
                  if (i < entrees.length - 1) const Divider(height: 1, indent: 64, endIndent: 16),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Entree extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final VoidCallback onTap;

  /// Valeur affichée à droite (langue choisie…).
  final String? valeur;

  /// Entrée mise en avant (fond jaune) : parrainage.
  final bool accent;

  /// Nombre de notifications non lues affiché avant la flèche.
  final bool compteur;
  const _Entree(this.icone, this.libelle, this.onTap, {this.valeur, this.accent = false, this.compteur = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: accent ? AppColor.kSecondaryLight : AppColor.kPrimaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icone, size: 19, color: accent ? AppColor.kSecondaryDark : AppColor.kPrimary),
      ),
      title: Text(libelle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (compteur) const CompteurNotificationsLigne(),
        if (valeur != null)
            Text(valeur!, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColor.kGrayscale40)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColor.kGrayscale40),
        ],
      ),
      onTap: onTap,
    );
  }
}
