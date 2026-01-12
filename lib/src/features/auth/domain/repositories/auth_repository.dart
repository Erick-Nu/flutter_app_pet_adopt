import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Iniciar sesión con email y contraseña
  Future<UserEntity> login(String email, String password);

  /// Iniciar sesión con Google OAuth
  Future<bool> signInWithGoogle();

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
    String? telefono,
  });

  /// Crear perfil adoptante desde Google (usuario ya existe en Auth)
  Future<void> createAdoptanteProfile(String userId, Map<String, dynamic> data);

  /// Crear perfil fundación desde Google (usuario ya existe en Auth)
  Future<void> createFundacionProfile(String userId, Map<String, dynamic> data);

  /// Enviar correo de recuperación
  Future<void> recoverPassword(String email);

  /// Cerrar sesión
  Future<void> logout();

  /// Obtener el usuario actual si ya inició sesión (Persistencia)
  Future<UserEntity?> getCurrentUser();
  
  /// Stream para escuchar cambios en tiempo real (Logueado <-> Deslogueado)
  Stream<UserEntity?> get authStateChanges;
}