import '../repositories/auth_repository.dart';

class RecoverPasswordUseCase {
  final AuthRepository repository;

  RecoverPasswordUseCase(this.repository);

  Future<void> call(String email) {
    return repository.recoverPassword(email);
  }
}