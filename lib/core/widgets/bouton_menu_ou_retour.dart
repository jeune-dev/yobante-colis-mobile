import 'package:flutter/material.dart';
import '../routes/app_shell_key.dart';

/// Bouton de gauche des pages qui sont aussi des onglets de l'écran principal.
///
/// En onglet, il ouvre le menu latéral. Quand la page est ouverte par-dessus
/// une autre (menu latéral, raccourci de l'accueil), c'est une flèche retour :
/// sans elle, l'utilisateur n'aurait aucun moyen visible de revenir.
class BoutonMenuOuRetour extends StatelessWidget {
  const BoutonMenuOuRetour({super.key});

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context)?.canPop ?? false) return const BackButton();
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
    );
  }
}
