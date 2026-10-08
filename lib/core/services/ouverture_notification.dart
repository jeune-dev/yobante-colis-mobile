import 'package:flutter/material.dart';
import '../config/user_role.dart';
import '../../features/catalogue/presentation/pages/tournees_collecte_page.dart';
import '../../features/enlevements/presentation/pages/enlevements_page.dart';
import '../../features/personnel/presentation/pages/colis_terrain_page.dart';
import '../../features/personnel/presentation/pages/enlevements_terrain_page.dart';
import '../../features/paiements/presentation/pages/factures_page.dart';
import '../../features/reclamations/presentation/pages/detail_reclamation_page.dart';
import '../../features/reclamations/presentation/pages/reclamations_page.dart';
import '../routes/app_router.dart';
import 'auth_status.dart';

/// Ouvre l'écran de l'entité liée à une notification (push ou liste interne).
///
/// Le backend renseigne `entite` / `entiteId` : Colis, Facture, Reclamation,
/// DemandeEnlevement, TourneeCollecte. Renvoie `false` si rien n'est à ouvrir.
bool ouvrirEntiteNotification(BuildContext context, String? entite, String? entiteId) {
  final id = (entiteId ?? '').trim();
  void pousser(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  switch (entite) {
    case 'Colis':
      if (id.isEmpty) return false;
      pousser(_SelonRole(
        client: (ctx) => _OuvrirRoute(AppRouter.detailColisRoute, id),
        personnel: (_) => DetailColisTerrainPage(id: id),
      ));
      return true;
    case 'Facture':
      pousser(const FacturesPage());
      return true;
    case 'Reclamation':
      pousser(id.isEmpty ? const ReclamationsPage() : DetailReclamationPage(id: id));
      return true;
    case 'DemandeEnlevement':
      if (id.isEmpty) {
        pousser(const EnlevementsPage());
      } else {
        // Coursiers et admins sont aussi notifiés : chacun ouvre la demande dans son espace
        pousser(_SelonRole(
          client: (_) => DetailEnlevementPage(id: id),
          personnel: (_) => DetailEnlevementTerrainPage(id: id),
        ));
      }
      return true;
    case 'TourneeCollecte':
      pousser(const TourneesCollectePage());
      return true;
    default:
      return false;
  }
}

/// Page de l'espace client ou de l'espace du personnel, selon le compte connecté.
class _SelonRole extends StatelessWidget {
  final WidgetBuilder client;
  final WidgetBuilder personnel;
  const _SelonRole({required this.client, required this.personnel});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: roleCourant(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return snap.data!.estPersonnel ? personnel(ctx) : client(ctx);
      },
    );
  }
}

/// Remplace l'écran d'attente par une route nommée (détail colis côté client).
class _OuvrirRoute extends StatefulWidget {
  final String route;
  final Object argument;
  const _OuvrirRoute(this.route, this.argument);

  @override
  State<_OuvrirRoute> createState() => _OuvrirRouteState();
}

class _OuvrirRouteState extends State<_OuvrirRoute> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pushReplacementNamed(widget.route, arguments: widget.argument);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
