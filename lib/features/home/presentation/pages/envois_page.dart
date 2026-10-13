import 'package:flutter/material.dart';
import '../../../../core/theme/app_color.dart';
import '../../../colis/presentation/pages/colis_liste_page.dart';
import '../../../colis/presentation/pages/recus_colis_page.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/widgets/bouton_menu_ou_retour.dart';

/// Onglet « Mes envois » façon DHL : colis envoyés et colis reçus.
class EnvoisPage extends StatelessWidget {
  const EnvoisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColor.kBackground,
        appBar: AppBar(
          leading: const BoutonMenuOuRetour(),
          title: Text(tr('Mes envois')),
          bottom: TabBar(
            // Changer d'onglet ferme le clavier : la recherche des « Envoyés » n'est plus à l'écran
            onTap: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            indicatorColor: AppColor.kSecondary,
            indicatorWeight: 3,
            labelColor: AppColor.kPrimary,
            tabs: [
              Tab(text: tr('Envoyés')),
              Tab(text: tr('Reçus')),
            ],
          ),
        ),
        body: NotificationListener<ScrollStartNotification>(
          // Même chose quand on glisse d'un onglet à l'autre (défilement horizontal uniquement)
          onNotification: (n) {
            if (n.metrics.axis == Axis.horizontal) FocusManager.instance.primaryFocus?.unfocus();
            return false;
          },
          child: const TabBarView(children: [ColisListePage(integre: true), RecusColisPage(integre: true)]),
        ),
      ),
    );
  }
}
