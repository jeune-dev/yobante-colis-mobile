import '../../domain/entities/ville.dart';

class VilleModel extends Ville {
  const VilleModel({required super.id, required super.nom, super.region, super.isActive});

  factory VilleModel.fromJson(Map<String, dynamic> json) => VilleModel(
        id: json['id'] as String,
        nom: json['nom'] as String,
        region: json['region'] as String?,
        isActive: json['isActive'] as bool? ?? true,
      );
}
