import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../bloc/colis_bloc.dart';
import '../bloc/colis_event.dart';
import '../bloc/colis_state.dart';
import '../widgets/statut_badge.dart';

class SuiviColisPage extends StatefulWidget {
  final String colisId;
  const SuiviColisPage({super.key, required this.colisId});

  @override
  State<SuiviColisPage> createState() => _SuiviColisPageState();
}

class _SuiviColisPageState extends State<SuiviColisPage> {
  @override
  void initState() {
    super.initState();
    context.read<ColisBloc>().add(LoadSuiviColis(widget.colisId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: const Text('Suivi du colis')),
      body: BlocBuilder<ColisBloc, ColisState>(
        builder: (context, state) {
          if (state is ColisLoading) return const ShimmerList();
          if (state is SuiviColisLoaded) {
            if (state.historique.isEmpty) {
              return const Center(child: Text('Aucun suivi disponible pour ce colis.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.historique.length,
              itemBuilder: (_, i) {
                final s = state.historique[i];
                final isLast = i == state.historique.length - 1;
                final fmt = DateFormat('dd MMM yyyy HH:mm', 'fr_FR');
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: i == 0 ? AppColor.kPrimary : AppColor.kGrayscale40,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (!isLast)
                            Expanded(child: Container(width: 2, color: AppColor.kLine)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatutBadge(statut: s.statut),
                              const SizedBox(height: 6),
                              if (s.localisation != null)
                                Text(s.localisation!,
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                              if (s.commentaire != null)
                                Text(s.commentaire!,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40)),
                              const SizedBox(height: 4),
                              Text(fmt.format(s.createdAt),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kGrayscale40)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
          if (state is ColisFailure) return Center(child: Text(state.message));
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
