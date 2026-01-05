import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Iniciar sesión con email y contraseña
  Future<UserEntity> login(String email, String password);

  /// Registrar un Adoptante (Crea Auth + Insert en tabla public.adoptantes)
  Future<UserEntity> registerAdoptante({
    required String email,
    required String password,
    required String nombre,
    required String cedula,
    String? telefono,
  });

  /// Registrar una Fundación (Crea Auth + Insert en tabla public.fundaciones)
  Future<UserEntity> registerFundacion({
    required String email,
    required String password,
    required String nombre,
    required String direccion,
    String? telefono,
  });

  /// Enviar correo de recuperación
  Future<void> recoverPassword(String email);

  /// Cerrar sesión
  Future<void> logout();

  /// Obtener el usuario actual si ya inició sesión (Persistencia)
  Future<UserEntity?> getCurrentUser();
  
  /// Stream para escuchar cambios en tiempo real (Logueado <-> Deslogueado)
  Stream<UserEntity?> get authStateChanges;
}