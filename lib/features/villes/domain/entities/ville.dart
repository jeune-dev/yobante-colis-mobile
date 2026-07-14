import 'package:equatable/equatable.dart';

class Ville extends Equatable {
  final String id;
  final String nom;
  final String? region;
  final bool isActive;

  const Ville({required this.id, required this.nom, this.region, this.isActive = true});

  @override
  List<Object?> get props => [id];
}
