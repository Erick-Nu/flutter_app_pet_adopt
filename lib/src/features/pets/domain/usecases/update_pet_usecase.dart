import '../entities/pet_entity.dart';
import '../repositories/pet_repository.dart';

class UpdatePetUseCase {
  final PetRepository repository;

  UpdatePetUseCase(this.repository);

  Future<void> call(PetEntity pet) async {
    return await repository.updatePet(pet);
  }
}