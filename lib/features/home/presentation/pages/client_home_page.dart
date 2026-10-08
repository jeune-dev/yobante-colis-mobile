import 'package:flutter/material.dart';
import 'accueil_page.dart';
import 'envois_page.dart';
import '../../../account/presentation/pages/compte_page.dart';
import '../../../expedition/presentation/pages/expedier_page.dart';
import '../../../points_collecte/presentation/pages/point_de_service_page.dart';
import '../../../personnel/presentation/pages/personnel_home_page.dart';
import '../../../../core/config/user_role.dart';
import '../../../../core/demo/demo_config.dart';
import '../../../../core/routes/app_shell_key.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/services/compteur_notifications.dart';
import '../../../../core/widgets/pastille_notifications.dart';

/// Coquille de navigation principale, façon DHL Express : tiroir latéral et
/// cinq onglets (Accueil, Mes envois, Expédier, Points de service, Compte).
class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  static const _ongletExpedier = 2;
  int _currentIndex = 0;
  final _visited = <int>{0};
  bool? _isAuth;
  UserRole _role = UserRole.client;

  @override
  void initState() {
    super.initState();
    isUserAuthenticated().then((auth) async {
      final role = auth ? await roleCourant() : UserRole.client;
      if (!mounted) return;
      setState(() {
        _isAuth = auth;
        _role = role;
      });
      // Le personnel a son propre espace, qui gère ses notifications
      if (role.estPersonnel) return;
      // Notifications push : permissions, jeton d'appareil et ouverture sur tap
      if (auth && !kDemoMode) FcmService.init(context).catchError((_) {});
      // Compteur de notifications non lues, tenu à jour automatiquement
      if (auth) CompteurNotifications.instance.demarrer();
    });
  }

  void _selectionner(int i) => setState(() {
        _visited.add(i);
        _currentIndex = i;
      });

  @override
  Widget build(BuildContext context) {
    if (_isAuth == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_role.estPersonnel) return PersonnelHomePage(role: _role);

    final pages = [
      AccueilPage(onExpedier: () => _selectionner(_ongletExpedier)),
      const EnvoisPage(),
      const ExpedierPage(),
      const PointDeServicePage(),
      const ComptePage(),
    ];

    return Scaffold(
      key: appShellScaffoldKey,
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          pages.length,
          (i) => _visited.contains(i) ? pages[i] : const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectionner,
        destinations: [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: tr('Accueil')),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: tr('Mes envois')),
          NavigationDestination(icon: Icon(Icons.send_outlined), selectedIcon: Icon(Icons.send), label: tr('Expédier')),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: tr('Points')),
          NavigationDestination(
              icon: const PastilleNotifications(child: Icon(Icons.person_outline)),
              selectedIcon: const PastilleNotifications(child: Icon(Icons.person)),
              label: tr('Compte')),
        ],
      ),
    );
  }
}
