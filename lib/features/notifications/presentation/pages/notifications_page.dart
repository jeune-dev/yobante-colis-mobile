import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/auth_status.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../injection_container.dart';
import '../bloc/notifications_bloc.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/services/ouverture_notification.dart';

/// Page autonome (fournit son propre [NotificationsBloc]) — accessible depuis
/// le tiroir latéral, indépendamment des onglets de la coquille principale.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsBloc>(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  static DateFormat get _fmt => formatJourHeure();
  bool? _isAuth;

  @override
  void initState() {
    super.initState();
    isUserAuthenticated().then((auth) {
      if (!mounted) return;
      setState(() => _isAuth = auth);
      if (auth && context.read<NotificationsBloc>().state is! NotificationsLoaded) {
        context.read<NotificationsBloc>().add(const LoadNotifications());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        title: Text(tr('Notifications')),
        actions: [
          if (_isAuth == true)
            TextButton(
              onPressed: () => context.read<NotificationsBloc>().add(const MarquerToutesLues()),
              child: Text(tr('Tout lire'), style: GoogleFonts.plusJakartaSans(fontSize: 13)),
            ),
        ],
      ),
      body: _isAuth == null
          ? const Center(child: CircularProgressIndicator())
          : _isAuth == false
              ? EmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: tr('Aucune notification'),
                  subtitle: tr('Connectez-vous pour recevoir vos notifications.'),
                  actionLabel: tr('Se connecter'),
                  onAction: () => Navigator.of(context).pushNamed(AppRouter.loginRoute),
                )
              : BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) return const ShimmerList();
          if (state is NotificationsFailure) return Center(child: Text(state.message));
          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return EmptyState(icon: Icons.notifications_none_outlined, title: tr('Aucune notification'), subtitle: tr('Vous n\'avez pas encore de notifications.'));
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<NotificationsBloc>().add(const LoadNotifications()),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: state.notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final n = state.notifications[i];
                  final bloc = context.read<NotificationsBloc>();
                  // Carte par notification : non lue = liseré jaune et titre en gras
                  return Dismissible(
                    key: ValueKey(n.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(color: AppColor.kErreur, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColor.kWhite),
                    ),
                    onDismissed: (_) => bloc.add(SupprimerNotification(n.id)),
                    child: Material(
                      color: n.isRead ? AppColor.kWhite : AppColor.kPrimaryLight,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          if (!n.isRead) bloc.add(MarquerLue(n.id));
                          // Colis, facture, réclamation, enlèvement… : ouverture de l'écran concerné
                          ouvrirEntiteNotification(context, n.entite, n.entiteId);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: n.isRead ? Colors.transparent : AppColor.kSecondary, width: 4),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: n.isRead ? AppColor.kBackground : AppColor.kWhite,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(iconeTypeNotification(n.type),
                                    color: n.isRead ? AppColor.kGrayscale40 : AppColor.kPrimary, size: 19),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                        child: Text(n.titre,
                                            style: GoogleFonts.plusJakartaSans(
                                                fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w700,
                                                fontSize: 14,
                                                color: AppColor.kGrayscaleDark100)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(_fmt.format(n.createdAt),
                                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kGrayscale40)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(n.message,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13, height: 1.4, color: AppColor.kGrayscale40)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

/// Pictogramme d'une notification selon son type (colis, paiement, douane…).
IconData iconeTypeNotification(String type) {
  switch (type) {
    case 'colis':    return Icons.inventory_2_outlined;
    case 'paiement': return Icons.payments_outlined;
    case 'douane':   return Icons.gavel_rounded;
    case 'reclamation': return Icons.support_agent_outlined;
    case 'enlevement':  return Icons.local_shipping_outlined;
    default:         return Icons.notifications_outlined;
  }
}
