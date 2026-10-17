import 'package:equatable/equatable.dart';

class NotificationApp extends Equatable {
  final String id;
  final String titre;
  final String message;
  final String type;
  final bool isRead;
  final String? lienCible;
  final DateTime createdAt;

  /// Ressource concernée (`Colis`, `Facture`, `Reclamation`…) et son identifiant.
  final String? entite;
  final String? entiteId;

  const NotificationApp({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.isRead,
    this.lienCible,
    required this.createdAt,
    this.entite,
    this.entiteId,
  });

  /// Même notification, ou autre notification du même objet (même colis…) :
  /// les ouvrir mène au même écran, elles sont lues ensemble.
  bool vaAvec(NotificationApp autre) =>
      autre.id == id ||
      (entite != null && (entiteId ?? '').isNotEmpty && autre.entite == entite && autre.entiteId == entiteId);

  NotificationApp lue() => NotificationApp(
    id: id,
    titre: titre,
    message: message,
    type: type,
    isRead: true,
    lienCible: lienCible,
    createdAt: createdAt,
    entite: entite,
    entiteId: entiteId,
  );

  /// Marque comme lues [ouverte] et les notifications du même objet ;
  /// renvoie la liste à jour et le nombre de notifications passées en lues.
  static (List<NotificationApp>, int) ouvrir(List<NotificationApp> liste, NotificationApp ouverte) {
    bool aLire(NotificationApp n) => !n.isRead && ouverte.vaAvec(n);
    return ([for (final n in liste) aLire(n) ? n.lue() : n], liste.where(aLire).length);
  }

  @override
  List<Object?> get props => [id, isRead];
}
