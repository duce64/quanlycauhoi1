import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/service/api/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(const AuthState()) {
    on<AuthUsernameChanged>((event, emit) {
      emit(state.copyWith(username: event.username));
    });

    on<AuthPasswordChanged>((event, emit) {
      emit(state.copyWith(password: event.password));
    });

    on<LoginSubmitted>((event, emit) async {
      emit(state.copyWith(status: AuthStatus.submitting));
      try {
        await _authService.login(event.username, event.password);
        emit(state.copyWith(status: AuthStatus.success));
      } catch (e) {
        emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    });

    on<RegisterSubmitted>((event, emit) async {
      emit(state.copyWith(status: AuthStatus.submitting));
      try {
        await _authService.register(
          event.username,
          event.password,
          event.detail,
          event.department,
          event.fullname,
        );
        emit(state.copyWith(status: AuthStatus.success));
      } catch (e) {
        emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    });
  }
}
