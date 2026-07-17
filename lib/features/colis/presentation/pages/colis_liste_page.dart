import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/colis.dart';
import '../bloc/colis_bloc.dart';
import '../bloc/colis_event.dart';
import '../bloc/colis_state.dart';
import '../widgets/statut_badge.dart';

class ColisListePage extends StatelessWidget {
  const ColisListePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ColisBloc>()..add(const LoadColis()),
      child: const _ColisListeView(),
    );
  }
}

class _ColisListeView extends StatefulWidget {
  const _ColisListeView();

  @override
  State<_ColisListeView> createState() => _ColisListeViewState();
}

class _ColisListeViewState extends State<_ColisListeView> {
  String? _filtreStatut;

  void _recharger() {
    context.read<ColisBloc>().add(LoadColis(statut: _filtreStatut));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        title: const Text('Mes colis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFiltreDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .pushNamed(AppRouter.creationColisRoute)
            .then((created) { if (created == true) _recharger(); }),
        backgroundColor: AppColor.kPrimary,
        foregroundColor: AppColor.kWhite,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau colis'),
      ),
      body: BlocBuilder<ColisBloc, ColisState>(
        builder: (context, state) {
          if (state is ColisLoading) return const ShimmerList();
          if (state is ColisFailure) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Erreur',
              subtitle: state.message,
              actionLabel: 'Réessayer',
              onAction: _recharger,
            );
          }
          if (state is ColisListLoaded) {
            if (state.colis.isEmpty) {
              return EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Aucun colis',
                subtitle: 'Vous n\'avez pas encore de colis enregistré.',
                actionLabel: 'Envoyer un colis',
                onAction: () => Navigator.of(context)
                    .pushNamed(AppRouter.creationColisRoute)
                    .then((created) { if (created == true) _recharger(); }),
              );
            }
            final hasMore = state.hasMore;
            final nextPage = state.currentPage + 1;
            return RefreshIndicator(
              onRefresh: () async => _recharger(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.colis.length + (hasMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (i == state.colis.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: OutlinedButton(
                          onPressed: () => context.read<ColisBloc>().add(
                            LoadMoreColis(statut: _filtreStatut, page: nextPage),
                          ),
                          child: const Text('Charger plus'),
                        ),
                      ),
                    );
                  }
                  return RepaintBoundary(
                    child: _ColisCard(
                      colis: state.colis[i],
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRouter.detailColisRoute,
                        arguments: state.colis[i].id,
                      ).then((annule) { if (annule == true) _recharger(); }),
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

  void _showFiltreDialog() {
    final statuts = [null, 'en_attente', 'en_preparation', 'en_transit', 'arrive', 'recupere', 'livre', 'annule'];
    final labels  = ['Tous', 'En attente', 'En préparation', 'En transit', 'Arrivé', 'Récupéré', 'Livré', 'Annulé'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text('Filtrer par statut', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          ...List.generate(statuts.length, (i) => ListTile(
            title: Text(labels[i]),
            trailing: _filtreStatut == statuts[i] ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              Navigator.pop(context);
              setState(() => _filtreStatut = statuts[i]);
              context.read<ColisBloc>().add(LoadColis(statut: statuts[i]));
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ColisCard extends StatelessWidget {
  static final _fmt = DateFormat('dd MMM yyyy', 'fr_FR');

  final Colis colis;
  final VoidCallback onTap;
  const _ColisCard({required this.colis, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(colis.reference,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                StatutBadge(statut: colis.statut),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.person_outline, label: 'Destinataire', value: colis.destinataireNom),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Trajet',
              value: '${colis.villeDepartNom ?? '—'} → ${colis.villeArriveeNom ?? '—'}',
            ),
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.scale_outlined, label: 'Poids', value: '${colis.poids} kg'),
            if (colis.montant != null) ...[
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.payments_outlined, label: 'Montant', value: '${colis.montant!.toStringAsFixed(0)} FCFA'),
            ],
            const SizedBox(height: 8),
            Text(
              'Créé le ${_fmt.format(colis.createdAt)}',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kGrayscale40),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColor.kGrayscale40),
        const SizedBox(width: 6),
        Text('$label : ', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40)),
        Expanded(child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600))),
      ],
    );
  }
}
