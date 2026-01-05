import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterAdoptanteUseCase {
  final AuthRepository repository;

  RegisterAdoptanteUseCase(this.repository);

  Future<UserEntity> call({
    required String email,
    required String password,
    required String nombre,
    required String cedula,
    String? telefono,
  }) {
    return repository.registerAdoptante(
      email: email,
      password: password,
      nombre: nombre,
      cedula: cedula,
      telefono: telefono,
    );
  }
}