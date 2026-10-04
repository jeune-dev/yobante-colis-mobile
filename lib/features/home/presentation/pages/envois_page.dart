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
            indicatorColor: AppColor.kSecondary,
            indicatorWeight: 3,
            labelColor: AppColor.kPrimary,
            tabs: [Tab(text: tr('Envoyés')), Tab(text: tr('Reçus'))],
          ),
        ),
        body: const TabBarView(children: [
          ColisListePage(integre: true),
          RecusColisPage(integre: true),
        ]),
      ),
    );
  }
}
