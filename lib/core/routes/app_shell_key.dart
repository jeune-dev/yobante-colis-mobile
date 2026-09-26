import 'package:flutter/material.dart';

/// Clé partagée du [Scaffold] racine (voir client_home_page.dart), pour que
/// chaque onglet puisse ouvrir le tiroir latéral depuis sa propre AppBar
/// sans imbriquer un second Scaffold autour du tiroir.
final GlobalKey<ScaffoldState> appShellScaffoldKey = GlobalKey<ScaffoldState>();
