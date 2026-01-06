import '../entities/pet_entity.dart';
import '../repositories/pet_repository.dart';

class GetPetsUseCase {
  final PetRepository repository;

  GetPetsUseCase(this.repository);

  Future<List<PetEntity>> call(String fundacionId) async {
    return await repository.getPetsByFoundation(fundacionId);
  }
}