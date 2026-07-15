import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_app.dart';
import '../../domain/repositories/notifications_repository.dart';

// Events
abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override List<Object?> get props => [];
}
class LoadNotifications extends NotificationsEvent { const LoadNotifications(); }
class LoadNonLuesCount extends NotificationsEvent { const LoadNonLuesCount(); }
class MarquerLue extends NotificationsEvent {
  final String id;
  const MarquerLue(this.id);
  @override List<Object?> get props => [id];
}
class MarquerToutesLues extends NotificationsEvent { const MarquerToutesLues(); }

// States
abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override List<Object?> get props => [];
}
class NotificationsInitial extends NotificationsState {}
class NotificationsLoading extends NotificationsState {}
class NotificationsLoaded extends NotificationsState {
  final List<NotificationApp> notifications;
  final int nonLues;
  const NotificationsLoaded({required this.notifications, this.nonLues = 0});
  @override List<Object?> get props => [notifications, nonLues];
}
class NotificationsFailure extends NotificationsState {
  final String message;
  const NotificationsFailure(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository repo;
  NotificationsBloc({required this.repo}) : super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoad);
    on<LoadNonLuesCount>(_onCount);
    on<MarquerLue>(_onMarquerLue);
    on<MarquerToutesLues>(_onMarquerToutesLues);
  }

  Future<void> _onLoad(LoadNotifications _, Emitter<NotificationsState> emit) async {
    emit(NotificationsLoading());
    final listFuture = repo.getNotifications();
    final countFuture = repo.getNonLuesCount();
    final result = await listFuture;
    final countResult = await countFuture;
    result.fold(
      (f) => emit(NotificationsFailure(f.errorMessage)),
      (list) => emit(NotificationsLoaded(
        notifications: list,
        nonLues: countResult.fold((_) => 0, (c) => c),
      )),
    );
  }

  Future<void> _onCount(LoadNonLuesCount _, Emitter<NotificationsState> emit) async {
    final result = await repo.getNonLuesCount();
    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      result.fold((_) {}, (c) => emit(NotificationsLoaded(notifications: current.notifications, nonLues: c)));
    }
  }

  Future<void> _onMarquerLue(MarquerLue event, Emitter<NotificationsState> emit) async {
    await repo.marquerLue(event.id);
    add(const LoadNotifications());
  }

  Future<void> _onMarquerToutesLues(MarquerToutesLues _, Emitter<NotificationsState> emit) async {
    await repo.marquerToutesLues();
    add(const LoadNotifications());
  }
}
