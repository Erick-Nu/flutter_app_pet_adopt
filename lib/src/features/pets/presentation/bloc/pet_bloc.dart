import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_pet_usecase.dart';
import '../../domain/usecases/delete_pet_usecase.dart';
import '../../domain/usecases/get_pets_usecase.dart';
// import '../../domain/usecases/update_pet_usecase.dart'; // Cuando lo implementes
import 'pet_event.dart';
import 'pet_state.dart';

class PetBloc extends Bloc<PetEvent, PetState> {
  // Inyectamos los casos de uso en lugar del repositorio directo
  final GetPetsUseCase getPetsUseCase;
  final CreatePetUseCase createPetUseCase;
  final DeletePetUseCase deletePetUseCase;

  PetBloc({
    required this.getPetsUseCase,
    required this.createPetUseCase,
    required this.deletePetUseCase,
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
        emit(PetsLoading());
        await createPetUseCase(event.pet);
        add(LoadPets(event.pet.fundacionId));
      } catch (e) {
        emit(PetsError(e.toString()));
      }
    });

    on<DeletePetEvent>((event, emit) async {
      try {
        await deletePetUseCase(event.petId);
        add(LoadPets(event.fundacionId));
      } catch (e) {
        emit(PetsError("No se pudo eliminar: ${e.toString()}"));
      }
    });
  }
}