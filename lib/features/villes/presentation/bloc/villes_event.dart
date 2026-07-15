import 'package:equatable/equatable.dart';

abstract class VillesEvent extends Equatable {
  const VillesEvent();
  @override
  List<Object?> get props => [];
}

class LoadVilles extends VillesEvent {
  const LoadVilles();
}
