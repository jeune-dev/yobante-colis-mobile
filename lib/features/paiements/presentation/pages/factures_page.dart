import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../bloc/paiements_bloc.dart';
import '../bloc/paiements_event.dart';
import '../bloc/paiements_state.dart';

class FacturesPage extends StatefulWidget {
  const FacturesPage({super.key});

  @override
  State<FacturesPage> createState() => _FacturesPageState();
}

class _FacturesPageState extends State<FacturesPage> {
  static final _dateFmt = DateFormat('dd/MM/yyyy', 'fr');

  @override
  void initState() {
    super.initState();
    context.read<PaiementsBloc>().add(const LoadFactures());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: const Text('Mes factures')),
      body: BlocBuilder<PaiementsBloc, PaiementsState>(
        builder: (context, state) {
          if (state is PaiementsLoading) return const ShimmerList();
          if (state is PaiementsFailure) return Center(child: Text(state.message));
          if (state is FacturesLoaded) {
            if (state.factures.isEmpty) {
              return const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Aucune facture',
                subtitle: 'Vos factures apparaîtront ici après création d\'un colis.',
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<PaiementsBloc>().add(const LoadFactures()),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.factures.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final f = state.factures[i];
                  final (label, color) = _statutInfo(f.statut);
                  final dateLabel = _formatDate(f.dateEmission);
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColor.kWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: Text(f.reference,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(label,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text('Transport : ${f.montantTransport.toStringAsFixed(0)} FCFA',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColor.kGrayscale40)),
                        if (f.remise > 0)
                          Text('Remise : -${f.remise.toStringAsFixed(0)} FCFA',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.green)),
                        const SizedBox(height: 4),
                        Text('Total : ${f.montantTotal.toStringAsFixed(0)} FCFA',
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('Émise le $dateLabel',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kGrayscale40)),
                      ],
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      return _dateFmt.format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  static (String, Color) _statutInfo(String s) => switch (s) {
    'payee'   => ('Payée', Colors.green),
    'annulee' => ('Annulée', Colors.red),
    _         => ('En attente', Colors.orange),
  };
}
