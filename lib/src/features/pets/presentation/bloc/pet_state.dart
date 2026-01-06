import '../../domain/entities/pet_entity.dart';

abstract class PetState {}

class PetsInitial extends PetState {}
class PetsLoading extends PetState {}

class PetsLoaded extends PetState {
  final List<PetEntity> pets;
  PetsLoaded(this.pets);
}

class PetsError extends PetState {
  final String message;
  PetsError(this.message);
}