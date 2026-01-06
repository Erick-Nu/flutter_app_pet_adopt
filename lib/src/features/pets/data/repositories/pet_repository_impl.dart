import '../../domain/entities/pet_entity.dart';
import '../../domain/repositories/pet_repository.dart';
import '../datasources/pet_remote_data_source.dart';

class PetRepositoryImpl implements PetRepository {
  final PetRemoteDataSource dataSource;

  PetRepositoryImpl(this.dataSource);

  @override
  Future<List<PetEntity>> getPetsByFoundation(String fundacionId) async {
    return await dataSource.getPets(fundacionId);
  }

  @override
  Future<void> createPet(PetEntity pet) async {
    await dataSource.createPetFull(pet);
  }


  @override
  Future<void> deletePet(String petId) async {
    await 
    dataSource.deletePet(petId);
  }

  @override
  Future<void> updatePet(PetEntity pet) async {
    await dataSource.updatePetFull(pet);
  }
}