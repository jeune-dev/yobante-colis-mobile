import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../injection_container.dart';
import '../bloc/colis_bloc.dart';
import '../bloc/colis_event.dart';
import '../bloc/colis_state.dart';
import '../../domain/entities/filtres_colis.dart';
import '../widgets/filtres_colis_widgets.dart';
import '../widgets/carte_colis.dart';
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
  FiltresColis _filtres = const FiltresColis();

  bool get _filtrage => _filtreStatut != null || _filtres.actif;

  void _recharger() {
    if (!widget.isAuth) return;
    context.read<ColisBloc>().add(LoadColis(statut: _filtreStatut, filtres: _filtres));
  }

  Future<void> _ouvrirFiltres() async {
    final choix = await choisirFiltresColis(context, statut: _filtreStatut, filtres: _filtres);
    if (choix == null || !mounted) return;
    setState(() {
      _filtreStatut = choix.statut;
      _filtres = choix.filtres;
    });
    _recharger();
  }

  void _rechercher(String reference) {
    setState(() => _filtres = _filtres.copyWith(reference: reference));
    _recharger();
  }

  void _effacerFiltres() {
    setState(() {
      _filtreStatut = null;
      _filtres = const FiltresColis();
    });
    _recharger();
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
          : Column(
              children: [
                BarreFiltresColis(filtresActifs: _filtrage, onRecherche: _rechercher, onFiltres: _ouvrirFiltres),
                Expanded(child: _liste()),
              ],
            ),
    );
  }

  Widget _liste() {
    return BlocBuilder<ColisBloc, ColisState>(
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
            if (state.colis.isEmpty && _filtrage) {
              return EmptyState(
                icon: Icons.search_off_rounded,
                title: tr('Aucun résultat'),
                subtitle: tr('Aucune expédition ne correspond à ces critères.'),
                actionLabel: tr('Effacer les filtres'),
                onAction: _effacerFiltres,
              );
            }
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
                            LoadMoreColis(statut: _filtreStatut, filtres: _filtres, page: nextPage),
                          ),
                          child: Text(tr('Charger plus')),
                        ),
                      ),
                    );
                  }
                  return RepaintBoundary(
                    child: CarteColis(
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
      );
  }
}
