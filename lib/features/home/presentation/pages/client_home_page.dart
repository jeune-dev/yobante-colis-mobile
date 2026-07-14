import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../colis/presentation/pages/colis_liste_page.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../paiements/presentation/bloc/paiements_bloc.dart';
import '../../../paiements/presentation/pages/factures_page.dart';
import '../../../../features/account/presentation/pages/profil_page.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../injection_container.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  int _currentIndex = 0;

  final _pages = const [
    ColisListePage(),
    FacturesPage(),
    NotificationsPage(),
    ProfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NotificationsBloc(repo: sl())..add(const LoadNotifications())),
        BlocProvider(create: (_) => PaiementsBloc(dio: sl())),
      ],
      child: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, notifState) {
          final nonLues = notifState is NotificationsLoaded ? notifState.nonLues : 0;
          return Scaffold(
            body: IndexedStack(index: _currentIndex, children: _pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              backgroundColor: AppColor.kWhite,
              destinations: [
                const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Colis'),
                const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Factures'),
                NavigationDestination(
                  icon: Badge(isLabelVisible: nonLues > 0, label: Text('$nonLues'), child: const Icon(Icons.notifications_outlined)),
                  selectedIcon: Badge(isLabelVisible: nonLues > 0, label: Text('$nonLues'), child: const Icon(Icons.notifications)),
                  label: 'Alertes',
                ),
                const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
              ],
            ),
          );
        },
      ),
    );
  }
}
