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
  final _visited = <int>{0};

  static const _pages = [
    ColisListePage(),
    FacturesPage(),
    NotificationsPage(),
    ProfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<NotificationsBloc>()..add(const LoadNotifications())),
        BlocProvider(create: (_) => sl<PaiementsBloc>()),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(
            _pages.length,
            (i) => _visited.contains(i) ? _pages[i] : const SizedBox.shrink(),
          ),
        ),
        bottomNavigationBar: BlocBuilder<NotificationsBloc, NotificationsState>(
          buildWhen: (p, c) {
            final pCount = p is NotificationsLoaded ? p.nonLues : 0;
            final cCount = c is NotificationsLoaded ? c.nonLues : 0;
            return pCount != cCount;
          },
          builder: (context, notifState) {
            final nonLues = notifState is NotificationsLoaded ? notifState.nonLues : 0;
            return NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() {
                _visited.add(i);
                _currentIndex = i;
              }),
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
            );
          },
        ),
      ),
    );
  }
}
