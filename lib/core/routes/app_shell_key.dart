import 'package:flutter/material.dart';

/// Clé du [Scaffold] racine (voir client_home_page.dart), transmise aux onglets
/// pour qu'ils ouvrent le tiroir latéral depuis leur propre AppBar sans
/// imbriquer un second Scaffold autour du tiroir.
///
/// Chaque écran principal a sa propre clé : une clé globale unique ferait
/// reprendre au nouvel écran (après une déconnexion par exemple) l'état de
/// l'ancien, encore affiché pendant la transition, avec les données du compte.
class CoquilleScaffold extends InheritedWidget {
  final GlobalKey<ScaffoldState> cle;

  const CoquilleScaffold({super.key, required this.cle, required super.child});

  static GlobalKey<ScaffoldState>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CoquilleScaffold>()?.cle;

  @override
  bool updateShouldNotify(CoquilleScaffold ancien) => cle != ancien.cle;
}
