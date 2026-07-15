import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../bloc/notifications_bloc.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static final _fmt = DateFormat('dd MMM, HH:mm', 'fr_FR');

  @override
  void initState() {
    super.initState();
    if (context.read<NotificationsBloc>().state is! NotificationsLoaded) {
      context.read<NotificationsBloc>().add(const LoadNotifications());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => context.read<NotificationsBloc>().add(const MarquerToutesLues()),
            child: Text('Tout lire', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
          ),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) return const ShimmerList();
          if (state is NotificationsFailure) return Center(child: Text(state.message));
          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return const EmptyState(icon: Icons.notifications_none_outlined, title: 'Aucune notification', subtitle: 'Vous n\'avez pas encore de notifications.');
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<NotificationsBloc>().add(const LoadNotifications()),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.notifications.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final n = state.notifications[i];
                  return ListTile(
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
                    onTap: n.isRead
                        ? null
                        : () => context.read<NotificationsBloc>().add(MarquerLue(n.id)),
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

  IconData _typeIcon(String type) {
    switch (type) {
      case 'colis':    return Icons.inventory_2_outlined;
      case 'paiement': return Icons.payments_outlined;
      default:         return Icons.notifications_outlined;
    }
  }
}
