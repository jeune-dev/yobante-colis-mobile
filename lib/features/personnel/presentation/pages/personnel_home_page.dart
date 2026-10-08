import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/user_role.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/i18n/selecteur_langue.dart';
import '../../../../core/services/compteur_notifications.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../account/domain/entities/account_user.dart';
import '../../../account/domain/repositories/account_repository.dart';
import '../../../account/presentation/pages/profil_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../../core/widgets/avatar_utilisateur.dart';
import '../../../../core/widgets/pastille_notifications.dart';
import '../widgets/ui_personnel.dart';
import 'colis_terrain_page.dart';
import 'enlevements_terrain_page.dart';

/// Espace de travail du personnel. Les onglets suivent la mission du rôle :
/// - coursier : tournée d'enlèvements, puis livraisons ;
/// - agent de point : colis du point, puis enlèvements déposés au point ;
/// - administrateur : expéditions et enlèvements (le reste se gère sur le back-office web).
class PersonnelHomePage extends StatefulWidget {
  final UserRole role;
  const PersonnelHomePage({super.key, required this.role});

  @override
  State<PersonnelHomePage> createState() => _PersonnelHomePageState();
}

class _PersonnelHomePageState extends State<PersonnelHomePage> {
  int _index = 0;
  final _visites = <int>{0};

  @override
  void initState() {
    super.initState();
    // Push des nouvelles missions (enlèvement planifié, colis affecté…)
    FcmService.init(context).catchError((_) {});
    CompteurNotifications.instance.demarrer();
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    final enlevements = (
      EnlevementsTerrainPage(role: role, afficherNotifications: role == UserRole.coursier),
      NavigationDestination(
        icon: const Icon(Icons.local_shipping_outlined),
        selectedIcon: const Icon(Icons.local_shipping),
        label: role == UserRole.coursier ? tr('Tournée') : tr('Enlèvements'),
      ),
    );
    final colis = (
      ColisTerrainPage(role: role, afficherNotifications: role != UserRole.coursier),
      NavigationDestination(
        icon: const Icon(Icons.inventory_2_outlined),
        selectedIcon: const Icon(Icons.inventory_2),
        label: switch (role) {
          UserRole.coursier => tr('Livraisons'),
          UserRole.agentPoint => tr('Mon point'),
          _ => tr('Colis'),
        },
      ),
    );
    final onglets = [
      ...(role == UserRole.coursier ? [enlevements, colis] : [colis, enlevements]),
      (
        const RechercheColisTerrainPage(),
        NavigationDestination(icon: const Icon(Icons.search), label: tr('Rechercher')),
      ),
      (
        ComptePersonnelPage(role: role),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: tr('Compte'),
        ),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < onglets.length; i++) _visites.contains(i) ? onglets[i].$1 : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          _visites.add(i);
          _index = i;
        }),
        destinations: [for (final o in onglets) o.$2],
      ),
    );
  }
}

/// Compte du membre du personnel : identité, rôle, notifications, langue, déconnexion.
class ComptePersonnelPage extends StatefulWidget {
  final UserRole role;
  const ComptePersonnelPage({super.key, required this.role});

  @override
  State<ComptePersonnelPage> createState() => _ComptePersonnelPageState();
}

class _ComptePersonnelPageState extends State<ComptePersonnelPage> {
  AccountUser? _utilisateur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final res = await sl<AccountRepository>().getMe();
    res.fold((_) {}, (u) {
      if (mounted) setState(() => _utilisateur = u);
    });
  }

  Future<void> _ouvrir(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Widget _entree(IconData icone, String libelle, VoidCallback onTap, {Widget? fin}) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: TuileIcone(icone, taille: 36),
        title: Text(libelle, style: titreSection(14)),
        trailing: fin ?? const Icon(Icons.chevron_right, color: AppColor.kGrayscale40),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final u = _utilisateur;
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: barreEspace(tr('Compte')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            decoration: const BoxDecoration(
              color: AppColor.kSecondary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(children: [
              // Photo de profil si le compte en a une, initiales sinon
              AvatarUtilisateur(
                prenom: u?.prenom,
                nom: u?.nom,
                photoUrl: u?.avatarUrl,
                rayon: 32,
                bordure: true,
                fond: AppColor.kPrimary,
                couleurTexte: AppColor.kSecondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u?.fullName ?? '…',
                      style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, color: AppColor.kPrimary)),
                  if (u?.email != null)
                    Text(u!.email!,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kPrimary.withValues(alpha: 0.75))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColor.kPrimary, borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        switch (widget.role) {
                          UserRole.coursier => Icons.delivery_dining_outlined,
                          UserRole.agentPoint => Icons.storefront_outlined,
                          _ => Icons.admin_panel_settings_outlined,
                        },
                        size: 14,
                        color: AppColor.kSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(widget.role.label,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColor.kWhite)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (widget.role.isAdmin) ...[
                Bandeau(
                  icone: Icons.desktop_windows_outlined,
                  titre: tr('Back-office web'),
                  message: tr('La validation des demandes, la planification et les réglages se font sur le back-office web.'),
                ),
                const SizedBox(height: 16),
              ],
              Text(tr('Mon espace'), style: titreSection(15)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(18), boxShadow: ombreCarte),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  color: Colors.transparent,
                  child: Column(children: [
                    _entree(Icons.person_outline, tr('Mon profil'), () => _ouvrir(const ProfilPage()).then((_) => _charger())),
                    const Divider(height: 1, indent: 64),
                    _entree(
                      Icons.notifications_none_rounded,
                      tr('Notifications'),
                      () => _ouvrir(const NotificationsPage()),
                      fin: const PastilleNotifications(child: Icon(Icons.chevron_right, color: AppColor.kGrayscale40)),
                    ),
                    const Divider(height: 1, indent: 64),
                    _entree(
                      Icons.translate,
                      tr('Langue'),
                      () => choisirLangue(context),
                      fin: Text(LangueApp.instance.value.libelle, style: texteDiscret(13)),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
                style: styleBoutonContour(AppColor.kErreur).copyWith(
                  backgroundColor: const WidgetStatePropertyAll(AppColor.kWhite),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text(tr('Se déconnecter')),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
