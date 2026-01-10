import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterAdoptanteRequested extends AuthEvent {
  final String email;
  final String password;
  final String nombre;
  final String cedula;
  final String? telefono;

  const AuthRegisterAdoptanteRequested({
    required this.email,
    required this.password,
    required this.nombre,
    required this.cedula,
    this.telefono,
  });

  @override
  List<Object?> get props => [email, password, nombre, cedula, telefono];
}

class AuthRegisterFundacionRequested extends AuthEvent {
  final String email;
  final String password;
  final String nombre;
  final String? telefono;

  const AuthRegisterFundacionRequested({
    required this.email,
    required this.password,
    required this.nombre,
    this.telefono,
  });

  @override
  List<Object?> get props => [email, password, nombre, telefono];
}

class AuthCheckStatus extends AuthEvent {
  const AuthCheckStatus();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthRecoverPasswordRequested extends AuthEvent {
  final String email;
  const AuthRecoverPasswordRequested(this.email);

  @override
  List<Object?> get props => [email];
}