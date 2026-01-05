part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});
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
}

class AuthRegisterFundacionRequested extends AuthEvent {
  final String email;
  final String password;
  final String nombre;
  final String direccion;
  final String? telefono;

  const AuthRegisterFundacionRequested({
    required this.email,
    required this.password,
    required this.nombre,
    required this.direccion,
    this.telefono,
  });
}

class AuthRecoverPasswordRequested extends AuthEvent {
  final String email;
  const AuthRecoverPasswordRequested({required this.email});
}

class AuthCheckStatus extends AuthEvent {}
class AuthLogoutRequested extends AuthEvent {}