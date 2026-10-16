import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/statuts_remise.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../injection_container.dart';
import '../../../account/presentation/widgets/verification_telephone_dialog.dart';
import '../../../tracking/presentation/pages/tracking_page.dart';
import '../bloc/colis_bloc.dart';
import '../bloc/colis_event.dart';
import '../bloc/colis_state.dart';
import '../../domain/entities/filtres_colis.dart';
import '../widgets/filtres_colis_widgets.dart';
import '../widgets/carte_colis.dart';
import '../widgets/confirmer_remise.dart';
import '../../../avis/presentation/pages/avis_page.dart';
import '../../domain/entities/colis.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/widgets/bouton_menu_ou_retour.dart';

/// Onglet « Reçus » : expéditions dont l'utilisateur connecté est le
/// destinataire (rapprochées côté backend par numéro de téléphone).
/// Réservé aux comptes connectés — pas de notion de destinataire pour un invité.
class RecusColisPage extends StatelessWidget {
  /// Vrai quand la liste est affichée dans l'onglet « Mes envois ».
  final bool integre;
  const RecusColisPage({super.key, this.integre = false});

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
            if (isAuth) bloc.add(const LoadColisRecus());
            return bloc;
          },
          child: _RecusView(isAuth: isAuth, integre: integre),
        );
      },
    );
  }
}

class _RecusView extends StatefulWidget {
  final bool isAuth;
  final bool integre;
  const _RecusView({required this.isAuth, this.integre = false});

  @override
  State<_RecusView> createState() => _RecusViewState();
}

class _RecusViewState extends State<_RecusView> {
  String? _statut;
  FiltresColis _filtres = const FiltresColis();

  /// Avis déposés depuis l'affichage de la liste (avant son prochain chargement).
  final _evalues = <String>{};

  bool get isAuth => widget.isAuth;
  bool get integre => widget.integre;
  bool get _filtrage => _statut != null || _filtres.actif;

  LoadColisRecus get _chargement => LoadColisRecus(statut: _statut, filtres: _filtres);

  Future<void> _ouvrirFiltres() async {
    final choix = await choisirFiltresColis(context, statut: _statut, filtres: _filtres, recus: true);
    if (choix == null || !mounted) return;
    setState(() {
      _statut = choix.statut;
      _filtres = choix.filtres;
    });
    context.read<ColisBloc>().add(_chargement);
  }

  /// Remise à confirmer au guichet ou à la porte, puis avis une fois le colis reçu.
  Widget? _action(BuildContext context, Colis c) {
    if (kStatutsRemise.contains(c.statut)) {
      Future<void> confirmer() async {
        if (await confirmerRemise(context, c) && context.mounted) {
          context.read<ColisBloc>().add(_chargement);
        }
      }

      final label = Text(tr('Confirmer la réception'));
      const icone = Icon(Icons.pin_outlined, size: 18);
      // Au point de retrait, le colis attend : action principale. En livraison,
      // le coursier peut être encore loin : simple rappel, sans insister.
      return c.statut == 'disponible_retrait'
          ? FilledButton.icon(onPressed: confirmer, icon: icone, label: label)
          : OutlinedButton.icon(onPressed: confirmer, icon: icone, label: label);
    }
    if (kStatutsRemis.contains(c.statut) && !c.avisDonne && !_evalues.contains(c.id)) {
      return OutlinedButton.icon(
        onPressed: () async {
          if (await donnerAvis(context, colisId: c.id, colisReference: c.reference) && mounted) {
            setState(() => _evalues.add(c.id));
          }
        },
        icon: const Icon(Icons.star_outline_rounded, size: 18),
        label: Text(tr('Donner mon avis')),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: integre ? null : AppBar(leading: const BoutonMenuOuRetour(), title: Text(tr('Reçus'))),
      body: !isAuth
          ? EmptyState(
              icon: Icons.mark_email_read_outlined,
              title: tr('Cette fonctionnalité n\'est disponible que pour les clients connectés'),
              subtitle: tr('Connectez-vous pour retrouver les colis qui vous sont destinés.'),
              actionLabel: tr('Se connecter'),
              onAction: () => Navigator.of(context).pushNamed(AppRouter.loginRoute),
            )
          : Column(
              children: [
                BarreFiltresColis(recherche: false, filtresActifs: _filtrage, onFiltres: _ouvrirFiltres),
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
          // Le backend exige la preuve de possession du numéro (code WhatsApp).
          // Le texte n'est consulté que pour un backend antérieur aux codes d'erreur.
          if (state.code == 'TELEPHONE_NON_VERIFIE' || state.message.contains('numéro de téléphone')) {
            return EmptyState(
              icon: Icons.verified_user_outlined,
              title: tr('Vérifiez votre numéro'),
              subtitle: state.message,
              actionLabel: tr('Vérifier mon numéro'),
              onAction: () async {
                final bloc = context.read<ColisBloc>();
                if (await verifierTelephone(context) != null) bloc.add(_chargement);
              },
            );
          }
          return EmptyState(
            icon: Icons.error_outline,
            title: tr('Erreur'),
            subtitle: state.message,
            actionLabel: tr('Réessayer'),
            onAction: () => context.read<ColisBloc>().add(_chargement),
          );
        }
        if (state is ColisRecusLoaded) {
          if (state.colis.isEmpty && _filtrage) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              title: tr('Aucun résultat'),
              subtitle: tr('Aucun colis reçu ne correspond à ces critères.'),
              actionLabel: tr('Effacer les filtres'),
              onAction: () {
                setState(() {
                  _statut = null;
                  _filtres = const FiltresColis();
                });
                context.read<ColisBloc>().add(_chargement);
              },
            );
          }
          if (state.colis.isEmpty) {
            return EmptyState(
              icon: Icons.mark_email_read_outlined,
              title: tr('Aucun colis reçu'),
              subtitle: tr('Les colis dont vous êtes le destinataire apparaîtront ici.'),
            );
          }
          final hasMore = state.hasMore;
          final nextPage = state.currentPage + 1;
          return RefreshIndicator(
            onRefresh: () async => context.read<ColisBloc>().add(_chargement),
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
                          LoadMoreColisRecus(statut: _statut, filtres: _filtres, page: nextPage),
                        ),
                        child: Text(tr('Charger plus')),
                      ),
                    ),
                  );
                }
                return RepaintBoundary(
                  child: CarteColis(
                    recu: true,
                    colis: state.colis[i],
                    action: _action(context, state.colis[i]),
                    // Le détail complet est réservé à l'expéditeur : le destinataire
                    // suit son colis par le suivi public (numéro de suivi)
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => TrackingPage(reference: state.colis[i].reference))),
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
