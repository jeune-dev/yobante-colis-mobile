import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/routes/app_shell_key.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../injection_container.dart';
import '../../../account/presentation/widgets/verification_telephone_dialog.dart';
import '../../../tracking/presentation/pages/tracking_page.dart';
import '../../domain/entities/colis.dart';
import '../bloc/colis_bloc.dart';
import '../bloc/colis_event.dart';
import '../bloc/colis_state.dart';
import '../widgets/statut_badge.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/utils/formatters.dart';

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

class _RecusView extends StatelessWidget {
  final bool isAuth;
  final bool integre;
  const _RecusView({required this.isAuth, this.integre = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: integre
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(tr('Reçus')),
            ),
      body: !isAuth
          ? EmptyState(
              icon: Icons.mark_email_read_outlined,
              title: tr('Cette fonctionnalité n\'est disponible que pour les clients connectés'),
              subtitle: tr('Connectez-vous pour retrouver les colis qui vous sont destinés.'),
              actionLabel: tr('Se connecter'),
              onAction: () => Navigator.of(context).pushNamed(AppRouter.loginRoute),
            )
          : BlocBuilder<ColisBloc, ColisState>(
              builder: (context, state) {
                if (state is ColisLoading) return const ShimmerList();
                if (state is ColisFailure) {
                  // Le backend exige la preuve de possession du numéro (code WhatsApp)
                  if (state.message.contains('numéro de téléphone')) {
                    return EmptyState(
                      icon: Icons.verified_user_outlined,
                      title: tr('Vérifiez votre numéro'),
                      subtitle: state.message,
                      actionLabel: tr('Vérifier mon numéro'),
                      onAction: () async {
                        final bloc = context.read<ColisBloc>();
                        if (await verifierTelephone(context)) bloc.add(const LoadColisRecus());
                      },
                    );
                  }
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: tr('Erreur'),
                    subtitle: state.message,
                    actionLabel: tr('Réessayer'),
                    onAction: () => context.read<ColisBloc>().add(const LoadColisRecus()),
                  );
                }
                if (state is ColisRecusLoaded) {
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
                    onRefresh: () async => context.read<ColisBloc>().add(const LoadColisRecus()),
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
                                onPressed: () => context.read<ColisBloc>().add(LoadMoreColisRecus(page: nextPage)),
                                child: Text(tr('Charger plus')),
                              ),
                            ),
                          );
                        }
                        return RepaintBoundary(
                          child: _RecuCard(
                            colis: state.colis[i],
                            // Le détail complet est réservé à l'expéditeur : le destinataire
                            // suit son colis par le suivi public (numéro de suivi)
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => TrackingPage(reference: state.colis[i].reference))),
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
}

class _RecuCard extends StatelessWidget {
  static DateFormat get _fmt => formatDate();

  final Colis colis;
  final VoidCallback onTap;
  const _RecuCard({required this.colis, required this.onTap});

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
            Row(children: [
              const Icon(Icons.person_outline, size: 14, color: AppColor.kGrayscale40),
              const SizedBox(width: 6),
              Text(tr('Expéditeur : '), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40)),
              Expanded(child: Text(colis.expediteurNom, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColor.kGrayscale40),
              const SizedBox(width: 6),
              Text('${colis.villeDepart?.nom ?? '—'} → ${colis.villeArrivee?.nom ?? '—'}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            Text(tr('Créé le ${_fmt.format(colis.createdAt)}'),
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kGrayscale40)),
          ],
        ),
      ),
    );
  }
}
