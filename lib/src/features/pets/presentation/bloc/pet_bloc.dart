import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_pet_usecase.dart';
import '../../domain/usecases/delete_pet_usecase.dart';
import '../../domain/usecases/get_pets_usecase.dart';
import '../../domain/usecases/update_pet_usecase.dart';
import 'pet_event.dart';
import 'pet_state.dart';

class PetBloc extends Bloc<PetEvent, PetState> {
  // Inyectamos los casos de uso en lugar del repositorio directo
  final GetPetsUseCase getPetsUseCase;
  final CreatePetUseCase createPetUseCase;
  final DeletePetUseCase deletePetUseCase;
  final UpdatePetUseCase updatePetUseCase;

  PetBloc({
    required this.getPetsUseCase,
    required this.createPetUseCase,
    required this.deletePetUseCase,
    required this.updatePetUseCase,
  }) : super(PetsInitial()) {
    
    on<LoadPets>((event, emit) async {
      emit(PetsLoading());
      try {
        // Usamos el caso de uso
        final pets = await getPetsUseCase(event.fundacionId);
        emit(PetsLoaded(pets));
      } catch (e) {
        emit(PetsError(e.toString()));
      }
    });

    on<AddPet>((event, emit) async {
      try {
        log('[PetBloc] Creando mascota ${event.pet.nombre}');
        emit(PetsLoading());
        await createPetUseCase(event.pet);
        log('[PetBloc] Mascota creada, recargando lista');
        add(LoadPets(event.pet.fundacionId));
      } catch (e) {
        log('[PetBloc] Error al crear: $e');
        emit(PetsError(e.toString()));
      }
    });

    on<DeletePetEvent>((event, emit) async {
      try {
        log('[PetBloc] Eliminando mascota ${event.petId}');
        await deletePetUseCase(event.petId);
        log('[PetBloc] Mascota eliminada, recargando lista');
        add(LoadPets(event.fundacionId));
      } catch (e) {
        log('[PetBloc] Error al eliminar: $e', error: e, stackTrace: StackTrace.current);
        emit(PetsError("No se pudo eliminar: ${e.toString()}"));
      }
    });

    on<UpdatePetEvent>((event, emit) async {
      try {
        log('[PetBloc] Actualizando mascota ${event.pet.id}');
        emit(PetsLoading());
        await updatePetUseCase(event.pet);
        // Recargar la lista para ver los cambios
        log('[PetBloc] Mascota actualizada, recargando lista');
        add(LoadPets(event.pet.fundacionId));
      } catch (e) {
        log('[PetBloc] Error al actualizar: $e');
        emit(PetsError(e.toString()));
      }
    });
    
  }
}