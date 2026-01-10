import '../../domain/entities/catalog_entity.dart';
import '../../domain/entities/pet_entity.dart';

enum PetStatus { initial, loading, success, error }
enum PetActionStatus { idle, loading, success, error } // Para acciones como Guardar/Borrar

class PetState {
  // Estado General
  final PetStatus status;
  final String? errorMessage;
  
  // Datos
  final List<PetEntity> pets;
  final List<CatalogEntity> species;
  final List<CatalogEntity> breeds; // Razas actuales (según especie seleccionada)
  final List<CatalogEntity> qualities;

  // Estado de Acciones Específicas (Crear/Editar)
  // Esto evita que el "Cargando..." de guardar bloquee la lista de mascotas
  final PetActionStatus actionStatus; 
  final String? actionMessage; // Ej: "Mascota guardada"

  const PetState({
    this.status = PetStatus.initial,
    this.errorMessage,
    this.pets = const [],
    this.species = const [],
    this.breeds = const [],
    this.qualities = const [],
    this.actionStatus = PetActionStatus.idle,
    this.actionMessage,
  });

  PetState copyWith({
    PetStatus? status,
    String? errorMessage,
    List<PetEntity>? pets,
    List<CatalogEntity>? species,
    List<CatalogEntity>? breeds,
    List<CatalogEntity>? qualities,
    PetActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return PetState(
      status: status ?? this.status,
      errorMessage: errorMessage, // Si no se pasa, se limpia (o se mantiene según lógica, aquí limpiamos para no persistir errores)
      pets: pets ?? this.pets,
      species: species ?? this.species,
      breeds: breeds ?? this.breeds,
      qualities: qualities ?? this.qualities,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage,
    );
  }
}