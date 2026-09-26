import '../../domain/entities/notification_app.dart';

class NotificationModel extends NotificationApp {
  const NotificationModel({
    required super.id, required super.titre, required super.message,
    required super.type, required super.isRead, super.lienCible, required super.createdAt,
    super.entite, super.entiteId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'] as String,
        titre: json['titre'] as String? ?? '',
        message: json['message'] as String? ?? '',
        type: json['type'] as String? ?? 'systeme',
        isRead: json['isRead'] as bool? ?? false,
        lienCible: json['lienCible'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        entite: json['entite'] as String?,
        entiteId: json['entiteId'] as String?,
      );
}
