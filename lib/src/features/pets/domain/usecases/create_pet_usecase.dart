import '../entities/pet_entity.dart';
import '../repositories/pet_repository.dart';

class CreatePetUseCase {
  final PetRepository repository;

  CreatePetUseCase(this.repository);

  Future<void> call(PetEntity pet) async {
    return await repository.createPet(pet);
  }
}