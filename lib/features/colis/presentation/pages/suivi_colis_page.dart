import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../injection_container.dart';
import '../bloc/colis_bloc.dart';
import '../bloc/colis_event.dart';
import '../bloc/colis_state.dart';
import '../widgets/statut_badge.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/utils/formatters.dart';

class SuiviColisPage extends StatelessWidget {
  final String colisId;
  const SuiviColisPage({super.key, required this.colisId});

  static DateFormat get _fmtCourt => formatDateHeure();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ColisBloc>()..add(LoadSuiviColis(colisId)),
      child: Scaffold(
        backgroundColor: AppColor.kBackground,
        appBar: AppBar(title: Text(tr('Suivi du colis'))),
        body: BlocBuilder<ColisBloc, ColisState>(
          builder: (context, state) {
            if (state is ColisLoading) return const ShimmerList();
            if (state is SuiviColisLoaded) {
              if (state.historique.isEmpty) {
                return Center(child: Text(tr('Aucun suivi disponible pour ce colis.')));
              }
              final actuel = state.historique.first;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _StatutActuelCard(statut: actuel.statut, quand: _fmtCourt.format(actuel.date)),
                  const SizedBox(height: 28),
                  Text(tr('Historique'),
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  ...List.generate(state.historique.length, (i) {
                    final s = state.historique[i];
                    final isLast = i == state.historique.length - 1;
                    final isCurrent = i == 0;
                    final couleur = _StatutVisuel.couleur(s.statut);
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: isCurrent ? 36 : 28,
                                height: isCurrent ? 36 : 28,
                                decoration: BoxDecoration(
                                  color: isCurrent ? couleur : couleur.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _StatutVisuel.icone(s.statut),
                                  size: isCurrent ? 18 : 14,
                                  color: isCurrent ? AppColor.kWhite : couleur,
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(width: 2, color: couleur.withValues(alpha: 0.35)),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24, top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  StatutBadge(statut: s.statut),
                                  const SizedBox(height: 6),
                                  if (s.libelle.isNotEmpty)
                                    Text(tr(s.libelle),
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                                  if (s.lieu != null)
                                    Text(s.lieu!,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40)),
                                  if (s.commentaire != null)
                                    Text(s.commentaire!,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40)),
                                  const SizedBox(height: 4),
                                  Text(_fmtCourt.format(s.date),
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kGrayscale40)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            }
            if (state is ColisFailure) return Center(child: Text(state.message));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

/// Bandeau de statut courant, mis en avant façon "tracking" DHL.
class _StatutActuelCard extends StatelessWidget {
  final String statut;
  final String quand;
  const _StatutActuelCard({required this.statut, required this.quand});

  @override
  Widget build(BuildContext context) {
    final couleur = _StatutVisuel.couleur(statut);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.kPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColor.kPrimary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
            child: Icon(_StatutVisuel.icone(statut), color: AppColor.kWhite, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Statut actuel'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kWhite.withValues(alpha: 0.75))),
                const SizedBox(height: 2),
                Text(_StatutVisuel.label(statut),
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColor.kWhite)),
                const SizedBox(height: 4),
                Text(quand,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kWhite.withValues(alpha: 0.75))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Icônes et couleurs par statut — mêmes valeurs que [StatutBadge], factorisées ici
/// pour la timeline et le bandeau de statut actuel.
class _StatutVisuel {
  static IconData icone(String s) {
    switch (s) {
      case 'brouillon':            return Icons.edit_note_outlined;
      case 'en_attente_validation': return Icons.manage_search_rounded;
      case 'devis_propose':        return Icons.request_quote_outlined;
      case 'refuse':               return Icons.block_outlined;
      case 'en_attente':           return Icons.hourglass_top_rounded;
      case 'enlevement_planifie':  return Icons.event_available_outlined;
      case 'enleve':                return Icons.directions_car_filled_outlined;
      case 'receptionne':           return Icons.inventory_outlined;
      case 'en_preparation':       return Icons.inventory_2_outlined;
      case 'en_transit':           return Icons.local_shipping_outlined;
      case 'en_douane':            return Icons.gavel_outlined;
      case 'arrive':               return Icons.flag_outlined;
      case 'disponible_retrait':  return Icons.store_outlined;
      case 'en_livraison':         return Icons.delivery_dining_outlined;
      case 'recupere':              return Icons.move_to_inbox_outlined;
      case 'livre':                 return Icons.check_circle_outline;
      case 'retourne':              return Icons.u_turn_left_outlined;
      case 'incident':              return Icons.warning_amber_outlined;
      case 'annule':                return Icons.cancel_outlined;
      default:                      return Icons.circle_outlined;
    }
  }

  static Color couleur(String s) {
    switch (s) {
      case 'brouillon':            return Colors.grey;
      case 'en_attente_validation': return AppColor.kAlerte;
      case 'devis_propose':        return AppColor.kInfo;
      case 'refuse':               return AppColor.kErreur;
      case 'en_attente':           return AppColor.kAlerte;
      case 'enlevement_planifie':  return AppColor.kAlerte;
      case 'enleve':                return AppColor.kInfo;
      case 'receptionne':           return AppColor.kInfo;
      case 'en_preparation':       return AppColor.kInfo;
      case 'en_transit':           return AppColor.kInfo;
      case 'en_douane':            return AppColor.kAlerte;
      case 'arrive':               return AppColor.kInfo;
      case 'disponible_retrait':  return AppColor.kInfo;
      case 'en_livraison':         return AppColor.kPrimary;
      case 'recupere':              return AppColor.kInfo;
      case 'livre':                 return AppColor.kSucces;
      case 'retourne':              return AppColor.kAlerte;
      case 'incident':              return AppColor.kErreur;
      case 'annule':                return AppColor.kErreur;
      default:                      return Colors.grey;
    }
  }

  static String label(String s) {
    switch (s) {
      case 'brouillon':            return tr('Brouillon');
      case 'en_attente_validation': return tr("En cours d'étude");
      case 'devis_propose':        return tr('Proposition reçue');
      case 'refuse':               return tr('Refusé');
      case 'en_attente':           return tr('En attente');
      case 'enlevement_planifie':  return tr('Enlèvement planifié');
      case 'enleve':                return tr('Enlevé');
      case 'receptionne':           return tr('Réceptionné');
      case 'en_preparation':       return tr('En préparation');
      case 'en_transit':           return tr('En transit');
      case 'en_douane':            return tr('En douane');
      case 'arrive':               return tr('Arrivé');
      case 'disponible_retrait':  return tr('Disponible au retrait');
      case 'en_livraison':         return tr('En livraison');
      case 'recupere':              return tr('Récupéré');
      case 'livre':                 return tr('Livré');
      case 'retourne':              return tr('Retourné');
      case 'incident':              return tr('Incident');
      case 'annule':                return tr('Annulé');
      default:                      return s;
    }
  }
}
