import 'package:equatable/equatable.dart';

enum AuthStatus { initial, submitting, success, failure }

class AuthState extends Equatable {
  final String username;
  final String password;
  final AuthStatus status;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.username = '',
    this.password = '',
    this.status = AuthStatus.initial,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    String? username,
    String? password,
    AuthStatus? status,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      username: username ?? this.username,
      password: password ?? this.password,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [username, password, status, isLoading, errorMessage];
}
