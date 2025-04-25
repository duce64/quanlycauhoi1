import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String username;
  final String password;

  const LoginSubmitted(this.username, this.password);

  @override
  List<Object?> get props => [username, password];
}

class RegisterSubmitted extends AuthEvent {
  final String username;
  final String password;
  final String detail;
  final String department;
  final String fullname;

  const RegisterSubmitted({
    required this.username,
    required this.password,
    required this.detail,
    required this.department,
    required this.fullname,
  });

  @override
  List<Object?> get props => [username, password, detail, department, fullname];
}

class AuthUsernameChanged extends AuthEvent {
  final String username;
  const AuthUsernameChanged(this.username);

  @override
  List<Object?> get props => [username];
}

class AuthPasswordChanged extends AuthEvent {
  final String password;
  const AuthPasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}
