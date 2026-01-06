import '../../domain/entities/pet_entity.dart';

abstract class PetEvent {}

class LoadPets extends PetEvent {
  final String fundacionId;
  LoadPets(this.fundacionId);
}

class AddPet extends PetEvent {
  final PetEntity pet;
  AddPet(this.pet);
}

class UpdatePetEvent extends PetEvent {
  final PetEntity pet;
  UpdatePetEvent(this.pet);
}

class DeletePetEvent extends PetEvent {
  final String petId;
  final String fundacionId; // Para recargar la lista
  DeletePetEvent(this.petId, this.fundacionId);
}