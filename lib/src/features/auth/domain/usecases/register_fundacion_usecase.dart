import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterFundacionUseCase {
  final AuthRepository repository;

  RegisterFundacionUseCase(this.repository);

  Future<UserEntity> call({
    required String email,
    required String password,
    required String nombre,
    required String direccion,
    String? telefono,
  }) {
    return repository.registerFundacion(
      email: email,
      password: password,
      nombre: nombre,
      direccion: direccion,
      telefono: telefono,
    );
  }
}