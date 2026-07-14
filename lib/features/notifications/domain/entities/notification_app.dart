import 'package:equatable/equatable.dart';

class NotificationApp extends Equatable {
  final String id;
  final String titre;
  final String message;
  final String type;
  final bool isRead;
  final String? lienCible;
  final DateTime createdAt;

  const NotificationApp({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.isRead,
    this.lienCible,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, isRead];
}
