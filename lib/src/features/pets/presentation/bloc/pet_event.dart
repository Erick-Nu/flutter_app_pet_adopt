import '../../domain/entities/pet_entity.dart';

abstract class PetEvent {}

// --- EVENTOS DE CARGA ---
class LoadPets extends PetEvent {
  final String fundacionId;
  LoadPets(this.fundacionId);
}

class LoadAllAvailablePets extends PetEvent {}

// NUEVO: Cargar catálogos iniciales (Especies + Cualidades)
class LoadCatalogs extends PetEvent {}

// NUEVO: Cargar razas dinámicamente según la especie seleccionada
class LoadBreeds extends PetEvent {
  final int speciesId;
  LoadBreeds(this.speciesId);
}

// --- EVENTOS CRUD ---
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
  final String fundacionId;
  DeletePetEvent(this.petId, this.fundacionId);
}

// --- EVENTOS WIZARD (MULTIPASOS) ---
class PetCreateStep1Changed extends PetEvent {
  final String nombre;
  final String? descripcion;
  final int? edad;
  final String sexo;
  final String tamano;
  final int? especieId; // ID seleccionado
  final int? razaId;    // ID seleccionado

  PetCreateStep1Changed({
    required this.nombre,
    this.descripcion,
    this.edad,
    required this.sexo,
    required this.tamano,
    this.especieId,
    this.razaId,
  });
}

class PetCreateStep2Changed extends PetEvent {
  final bool esEsterilizado;
  final bool esDesparasitado;
  final bool vacunasAlDia;
  final bool tieneMicrochip;
  final double? peso;
  final bool tieneDiscapacidad;
  final String? descDiscapacidad;
  final String? detalleVacunas;
  final String? observaciones;

  PetCreateStep2Changed({
    required this.esEsterilizado,
    required this.esDesparasitado,
    required this.vacunasAlDia,
    required this.tieneMicrochip,
    this.peso,
    required this.tieneDiscapacidad,
    this.descDiscapacidad,
    this.detalleVacunas,
    this.observaciones,
  });
}

class PetCreateImagesChanged extends PetEvent {
  final List<String> imagePaths;
  PetCreateImagesChanged(this.imagePaths);
}

class PetSubmitCreation extends PetEvent {}

class PetSubmitUpdate extends PetEvent {
  final String petId;
  PetSubmitUpdate(this.petId);
}