import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/colis.dart';
import '../bloc/colis_bloc.dart';
import '../bloc/colis_event.dart';
import '../bloc/colis_state.dart';
import '../widgets/statut_badge.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/widgets/bouton_menu_ou_retour.dart';

class ColisListePage extends StatelessWidget {
  /// Vrai quand la liste est affichée dans l'onglet « Mes envois » (sans barre d'application propre).
  final bool integre;
  const ColisListePage({super.key, this.integre = false});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isUserAuthenticated(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final isAuth = snap.data == true;
        return BlocProvider(
          create: (_) {
            final bloc = sl<ColisBloc>();
            if (isAuth) bloc.add(const LoadColis());
            return bloc;
          },
          child: _ColisListeView(isAuth: isAuth, integre: integre),
        );
      },
    );
  }
}

class _ColisListeView extends StatefulWidget {
  final bool isAuth;
  final bool integre;
  const _ColisListeView({required this.isAuth, this.integre = false});

  @override
  State<_ColisListeView> createState() => _ColisListeViewState();
}

class _ColisListeViewState extends State<_ColisListeView> {
  String? _filtreStatut;

  void _recharger() {
    if (!widget.isAuth) return;
    context.read<ColisBloc>().add(LoadColis(statut: _filtreStatut));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: widget.integre
          ? null
          : AppBar(
              leading: const BoutonMenuOuRetour(),
              title: Text(tr('Envoyés')),
              actions: [
                if (widget.isAuth)
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
        backgroundColor: AppColor.kSecondary,
        foregroundColor: AppColor.kPrimary,
        icon: const Icon(Icons.add),
        label: Text(tr('Expédier')),
      ),
      body: !widget.isAuth
          ? EmptyState(
              icon: Icons.inventory_2_outlined,
              title: tr('Aucun colis'),
              subtitle: tr('Connectez-vous pour créer et suivre vos colis.'),
              actionLabel: tr('Se connecter'),
              onAction: () => Navigator.of(context).pushNamed(AppRouter.loginRoute),
            )
          : BlocBuilder<ColisBloc, ColisState>(
        builder: (context, state) {
          if (state is ColisLoading) return const ShimmerList();
          if (state is ColisFailure) {
            return EmptyState(
              icon: Icons.error_outline,
              title: tr('Erreur'),
              subtitle: state.message,
              actionLabel: tr('Réessayer'),
              onAction: _recharger,
            );
          }
          if (state is ColisListLoaded) {
            if (state.colis.isEmpty) {
              return EmptyState(
                icon: Icons.inventory_2_outlined,
                title: tr('Aucun colis'),
                subtitle: tr('Vous n\'avez pas encore de colis enregistré.'),
                actionLabel: tr('Envoyer un colis'),
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
                          child: Text(tr('Charger plus')),
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
    final statuts = [null, 'en_attente_validation', 'devis_propose', 'en_attente', 'en_transit', 'en_douane', 'arrive', 'livre', 'annule'];
    final labels  = ['Tous', tr('En cours d\'étude'), tr('Proposition reçue'), tr('En attente de remise'), tr('En transit'), tr('En dédouanement'), tr('Arrivé'), tr('Livré'), tr('Annulé')];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(tr('Filtrer par statut'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          ...List.generate(statuts.length, (i) => ListTile(
            title: Text(labels[i]),
            trailing: _filtreStatut == statuts[i] ? const Icon(Icons.check, color: AppColor.kSucces) : null,
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
  static DateFormat get _fmt => formatDate();

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
            _InfoRow(icon: Icons.person_outline, label: tr('Destinataire'), value: colis.destinataireNom),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: tr('Trajet'),
              value: '${colis.villeDepart?.nom ?? '—'} → ${colis.villeArrivee?.nom ?? '—'}',
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: CategorieColis.parCode(colis.categorie).icone,
              label: tr('Catégorie'),
              value: CategorieColis.parCode(colis.categorie).libelle,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: tr('Montant'),
              value: colis.montantEnAttente ? tr('Proposé après étude') : formaterMontant(colis.montantTotal, colis.devise),
            ),
            const SizedBox(height: 8),
            Text(
              tr('Créé le ${_fmt.format(colis.createdAt)}'),
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
