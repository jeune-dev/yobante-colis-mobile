import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/i18n/langue.dart';

class StatutBadge extends StatelessWidget {
  final String statut;
  const StatutBadge({super.key, required this.statut});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _info(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      // Pastille de couleur devant le libellé : statut lisible d'un coup d'œil
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  static (String, Color) _info(String s) {
    switch (s) {
      case 'brouillon':
        return (tr('Brouillon'), Colors.grey);
      case 'en_attente_validation':
        return (tr("En cours d'étude"), AppColor.kAlerte);
      case 'devis_propose':
        return (tr('Proposition reçue'), AppColor.kInfo);
      case 'refuse':
        return (tr('Refusé'), AppColor.kErreur);
      case 'en_attente':
        return (tr('En attente de remise'), AppColor.kAlerte);
      case 'enlevement_planifie':
        return (tr('Enlèvement planifié'), AppColor.kAlerte);
      case 'enleve':
        return (tr('Enlevé'), AppColor.kInfo);
      case 'receptionne':
        return (tr('Réceptionné'), AppColor.kInfo);
      case 'en_preparation':
        return (tr('En préparation'), AppColor.kInfo);
      case 'en_transit':
        return (tr('En transit'), AppColor.kInfo);
      case 'en_douane':
        return (tr('En douane'), AppColor.kAlerte);
      case 'arrive':
        return (tr('Arrivé'), AppColor.kInfo);
      case 'disponible_retrait':
        return (tr('Disponible au retrait'), AppColor.kInfo);
      case 'en_livraison':
        return (tr('En livraison'), AppColor.kPrimary);
      case 'recupere':
        return (tr('Récupéré'), AppColor.kInfo);
      case 'livre':
        return (tr('Livré'), AppColor.kSucces);
      case 'retourne':
        return (tr('Retourné'), AppColor.kAlerte);
      case 'incident':
        return (tr('Incident'), AppColor.kErreur);
      case 'annule':
        return (tr('Annulé'), AppColor.kErreur);
      default:
        return (s, Colors.grey);
    }
  }
}
