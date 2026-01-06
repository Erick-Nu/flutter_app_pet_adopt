import '../entities/pet_entity.dart';

abstract class PetRepository {
  Future<List<PetEntity>> getPetsByFoundation(String fundacionId);
  Future<void> createPet(PetEntity pet);
  Future<void> updatePet(PetEntity pet);
  Future<void> deletePet(String petId);
}