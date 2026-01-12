import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity> login(String email, String password) async {
    // Aquí podrías envolver en try-catch para manejar errores de red
    return await remoteDataSource.login(email, password);
  }

  @override
  Future<bool> signInWithGoogle() async {
    return await remoteDataSource.signInWithGoogle();
  }

  @override
  Future<UserEntity> registerAdoptante({
    required String email,
    required String password,
    required String nombre,
    required String cedula,
    String? telefono,
  }) async {
    return await remoteDataSource.registerAdoptante(
      email: email,
      password: password,
      nombre: nombre,
      cedula: cedula,
      telefono: telefono,
    );
  }

  @override
  Future<UserEntity> registerFundacion({
    required String email,
    required String password,
    required String nombre,
    String? telefono,
  }) async {
    return await remoteDataSource.registerFundacion(
      email: email,
      password: password,
      nombre: nombre,
      telefono: telefono,
    );
  }

  @override
  Future<void> createAdoptanteProfile(String userId, Map<String, dynamic> data) async {
    return await remoteDataSource.createAdoptanteProfile(userId, data);
  }

  @override
  Future<void> createFundacionProfile(String userId, Map<String, dynamic> data) async {
    return await remoteDataSource.createFundacionProfile(userId, data);
  }

  @override
  Future<void> logout() async {
    return await remoteDataSource.logout();
  }

  @override
  Future<void> recoverPassword(String email) async {
    return await remoteDataSource.recoverPassword(email);
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return await remoteDataSource.getCurrentUser();
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return remoteDataSource.authStateChanges;
  }
}