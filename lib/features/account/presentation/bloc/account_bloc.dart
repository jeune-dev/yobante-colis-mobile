import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/usecases/get_me.dart';
import '../../domain/usecases/modifier_info_personnelles.dart';
import '../../domain/usecases/change_password.dart';
import 'account_event.dart';
import 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final GetMe getMe;
  final ModifierInfoPersonnelles modifierInfoPersonnelles;
  final ChangePassword changePassword;
  final AccountRepository accountRepository;

  AccountBloc({
    required this.getMe,
    required this.modifierInfoPersonnelles,
    required this.changePassword,
    required this.accountRepository,
  }) : super(AccountInitial()) {
    on<LoadMe>(_onLoadMe);
    on<ModifierInfoPersonnellesEvent>(_onModifierInfo);
    on<UploadAvatarEvent>(_onUploadAvatar);
    on<ChangePasswordEvent>(_onChangePassword);
    on<ResetAccountState>((_, emit) => emit(AccountInitial()));
  }

  Future<void> _onLoadMe(LoadMe event, Emitter<AccountState> emit) async {
    emit(AccountLoading());
    final result = await getMe();
    result.fold(
      (failure) => emit(AccountError(failure.errorMessage)),
      (user) => emit(AccountLoaded(user)),
    );
  }

  Future<void> _onModifierInfo(
    ModifierInfoPersonnellesEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());
    final result = await modifierInfoPersonnelles(
      nom: event.nom,
      prenom: event.prenom,
      telephone: event.telephone,
    );
    result.fold(
      (failure) => emit(AccountError(failure.errorMessage)),
      (r) => emit(AccountSuccess(user: r.valeur, message: r.message)),
    );
  }

  Future<void> _onUploadAvatar(
    UploadAvatarEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());
    final result = await accountRepository.uploadAvatar(event.filePath);
    result.fold(
      (failure) => emit(AccountError(failure.errorMessage)),
      (r) => emit(AccountSuccess(user: r.valeur, message: r.message)),
    );
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());
    final result = await changePassword(
      oldPassword: event.oldPassword,
      newPassword: event.newPassword,
    );
    result.fold(
      (failure) => emit(AccountError(failure.errorMessage)),
      (message) => emit(PasswordChanged(message: message)),
    );
  }
}
