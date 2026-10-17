import 'package:flutter_test/flutter_test.dart';
import 'package:yobante_colis/features/notifications/domain/entities/notification_app.dart';

/// Ouvrir une notification la marque comme lue avec les autres notifications
/// non lues du même objet (même colis, même facture…).
void main() {
  NotificationApp notif(String id, {String? entite, String? entiteId, bool lue = false}) => NotificationApp(
    id: id,
    titre: 'Suivi',
    message: 'Votre colis avance',
    type: 'colis',
    isRead: lue,
    createdAt: DateTime(2026, 10, 17),
    entite: entite,
    entiteId: entiteId,
  );

  test('les notifications du même colis passent en lues, pas les autres', () {
    final liste = [
      notif('n1', entite: 'Colis', entiteId: 'c1'),
      notif('n2', entite: 'Colis', entiteId: 'c1'),
      notif('n3', entite: 'Colis', entiteId: 'c2'),
      notif('n4', entite: 'Facture', entiteId: 'c1'),
      notif('n5'),
      notif('n6', entite: 'Colis', entiteId: 'c1', lue: true),
    ];
    final (maj, lues) = NotificationApp.ouvrir(liste, liste.first);
    expect(lues, 2);
    expect([for (final n in maj) n.isRead], [true, true, false, false, false, true]);
  });

  test('une notification sans objet ne marque qu’elle-même', () {
    final liste = [notif('n1'), notif('n2')];
    final (maj, lues) = NotificationApp.ouvrir(liste, liste.first);
    expect(lues, 1);
    expect([for (final n in maj) n.isRead], [true, false]);
  });
}
