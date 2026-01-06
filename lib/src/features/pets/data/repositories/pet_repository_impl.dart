import '../../domain/entities/pet_entity.dart';
import '../../domain/repositories/pet_repository.dart';
import '../datasources/pet_remote_data_source.dart';
import '../models/pet_model.dart';

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
  Future<void> updatePet(PetEntity pet) async {
    // Aquí sí necesitamos el ID para el update
    final model = PetModel(
      id: pet.id,
      nombre: pet.nombre,
      descripcion: pet.descripcion,
      edad: pet.edad,
      sexo: pet.sexo,
      status: pet.status,
      avatarUrl: pet.avatarUrl,
      fundacionId: pet.fundacionId,
      tamano: pet.tamano ?? 'Mediano',
    );
    await dataSource.updatePet(model);
  }

  @override
  Future<void> deletePet(String petId) async {
    await dataSource.deletePet(petId);
  }
}