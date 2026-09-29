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
                padding: const EdgeInsets.all(16),
                itemCount: state.notifications.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final n = state.notifications[i];
                  final bloc = context.read<NotificationsBloc>();
                  return Dismissible(
                    key: ValueKey(n.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: AppColor.kErreur,
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) => bloc.add(SupprimerNotification(n.id)),
                    child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: n.isRead ? AppColor.kLine : AppColor.kPrimary.withValues(alpha: 0.1),
                      child: Icon(_typeIcon(n.type),
                          color: n.isRead ? AppColor.kGrayscale40 : AppColor.kPrimary, size: 18),
                    ),
                    title: Text(n.titre,
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700, fontSize: 13)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.message, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                        Text(_fmt.format(n.createdAt),
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColor.kGrayscale40)),
                      ],
                    ),
                    tileColor: n.isRead ? null : AppColor.kPrimary.withValues(alpha: 0.03),
                    onTap: () {
                      if (!n.isRead) bloc.add(MarquerLue(n.id));
                      // Colis, facture, réclamation, enlèvement… : ouverture de l'écran concerné
                      ouvrirEntiteNotification(context, n.entite, n.entiteId);
                    },
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

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'colis':    return Icons.inventory_2_outlined;
      case 'paiement': return Icons.payments_outlined;
      default:         return Icons.notifications_outlined;
    }
  }
}
