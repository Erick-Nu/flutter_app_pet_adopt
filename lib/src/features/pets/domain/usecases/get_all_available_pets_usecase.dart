import '../entities/pet_entity.dart';
import '../repositories/pet_repository.dart';

class GetAllAvailablePetsUseCase {
  final PetRepository repository;

  GetAllAvailablePetsUseCase(this.repository);

  Future<List<PetEntity>> call() async {
    return await repository.getAllAvailablePets();
  }
}
