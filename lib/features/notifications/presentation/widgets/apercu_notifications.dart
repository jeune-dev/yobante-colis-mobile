import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/i18n/langue.dart';
import '../../../../core/services/compteur_notifications.dart';
import '../../../../core/services/ouverture_notification.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/notification_app.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../pages/notifications_page.dart';

/// Dernières notifications, visibles dès l'accueil : les non lues sont mises en
/// avant, un toucher ouvre l'écran concerné. Rechargé quand le compteur de non
/// lues change (push reçu, notification lue ailleurs).
class ApercuNotifications extends StatefulWidget {
  final int nombre;
  const ApercuNotifications({super.key, this.nombre = 3});

  @override
  State<ApercuNotifications> createState() => _ApercuNotificationsState();
}

class _ApercuNotificationsState extends State<ApercuNotifications> {
  List<NotificationApp>? _liste;

  @override
  void initState() {
    super.initState();
    _charger();
    CompteurNotifications.instance.addListener(_charger);
  }

  @override
  void dispose() {
    CompteurNotifications.instance.removeListener(_charger);
    super.dispose();
  }

  Future<void> _charger() async {
    final res = await sl<NotificationsRepository>().getNotifications(page: 1, limit: widget.nombre);
    res.fold((_) {}, (liste) {
      if (mounted) setState(() => _liste = liste);
    });
  }

  void _ouvrir(NotificationApp n) {
    if (!n.isRead) {
      sl<NotificationsRepository>().marquerLue(n.id);
      CompteurNotifications.instance.notificationLue();
    }
    if (!ouvrirEntiteNotification(context, n.entite, n.entiteId)) _toutVoir();
  }

  void _toutVoir() =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsPage())).then((_) => _charger());

  @override
  Widget build(BuildContext context) {
    final liste = _liste;
    // Rien à montrer tant que le chargement n'a pas abouti (accueil non bloqué)
    if (liste == null) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(tr('Notifications'), style: titreSection()),
        ValueListenableBuilder<int>(
          valueListenable: CompteurNotifications.instance,
          builder: (_, nonLues, _) => nonLues == 0
              ? const SizedBox.shrink()
              : Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColor.kErreur, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    nonLues > 99 ? '99+' : '$nonLues',
                    style: GoogleFonts.plusJakartaSans(color: AppColor.kWhite, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
        ),
        const Spacer(),
        TextButton(onPressed: _toutVoir, child: Text(tr('Tout voir'))),
      ]),
      const SizedBox(height: 4),
      if (liste.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(16)),
          child: Text(tr('Aucune notification pour le moment.'), style: texteDiscret(13)),
        )
      else
        for (final n in liste)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: n.isRead ? AppColor.kWhite : AppColor.kPrimaryLight,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _ouvrir(n),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: n.isRead ? Colors.transparent : AppColor.kSecondary, width: 4),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(iconeTypeNotification(n.type),
                        size: 20, color: n.isRead ? AppColor.kGrayscale40 : AppColor.kPrimary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                            child: Text(
                              n.titre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w700,
                                color: AppColor.kGrayscaleDark100,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(formatJourHeure().format(n.createdAt.toLocal()), style: texteDiscret(11)),
                        ]),
                        const SizedBox(height: 2),
                        Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: texteDiscret(12)),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ),
    ]);
  }
}
