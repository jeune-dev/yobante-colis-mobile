import 'package:flutter/material.dart';
import '../../features/catalogue/presentation/pages/tournees_collecte_page.dart';
import '../../features/enlevements/presentation/pages/enlevements_page.dart';
import '../../features/paiements/presentation/pages/factures_page.dart';
import '../../features/reclamations/presentation/pages/detail_reclamation_page.dart';
import '../../features/reclamations/presentation/pages/reclamations_page.dart';
import '../routes/app_router.dart';

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
      Navigator.of(context).pushNamed(AppRouter.detailColisRoute, arguments: id);
      return true;
    case 'Facture':
      pousser(const FacturesPage());
      return true;
    case 'Reclamation':
      pousser(id.isEmpty ? const ReclamationsPage() : DetailReclamationPage(id: id));
      return true;
    case 'DemandeEnlevement':
      pousser(id.isEmpty ? const EnlevementsPage() : DetailEnlevementPage(id: id));
      return true;
    case 'TourneeCollecte':
      pousser(const TourneesCollectePage());
      return true;
    default:
      return false;
  }
}
