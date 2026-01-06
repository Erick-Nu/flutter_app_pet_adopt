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

// Eventos para el formulario multipasos
class PetCreateStep1Changed extends PetEvent {
  final String nombre;
  final String? descripcion;
  final int? edad;
  final String sexo; // 'macho' o 'hembra'
  final String tamano; // 'pequeño', 'mediano', 'grande'
  final int? especieId;
  final int? razaId;

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
  final List<String> imagePaths; // Rutas locales de las fotos seleccionadas
  PetCreateImagesChanged(this.imagePaths);
}

class PetSubmitCreation extends PetEvent {}

class PetSubmitUpdate extends PetEvent {
  final String petId;
  PetSubmitUpdate(this.petId);
}
