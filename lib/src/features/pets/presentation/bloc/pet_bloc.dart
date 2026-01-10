import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/logger_service.dart';
import '../../../auth/domain/usecases/check_auth_status_usecase.dart';
import '../../domain/entities/pet_entity.dart';
import '../../domain/entities/medical_record_entity.dart';
import '../../domain/usecases/create_pet_usecase.dart';
import '../../domain/usecases/delete_pet_usecase.dart';
import '../../domain/usecases/get_pets_usecase.dart';
import '../../domain/usecases/get_all_available_pets_usecase.dart';
import '../../domain/usecases/update_pet_usecase.dart';
import '../../domain/usecases/get_catalogs_usecase.dart';
import 'pet_event.dart';
import 'pet_state.dart';

class PetBloc extends Bloc<PetEvent, PetState> {
  final GetPetsUseCase getPetsUseCase;
  final GetAllAvailablePetsUseCase getAllAvailablePetsUseCase;
  final CreatePetUseCase createPetUseCase;
  final DeletePetUseCase deletePetUseCase;
  final UpdatePetUseCase updatePetUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final GetCatalogsUseCase getCatalogsUseCase;

  // Variables temporales del Wizard (se mantienen igual)
  PetCreateStep1Changed? _step1Data;
  PetCreateStep2Changed? _step2Data;
  List<String> _step3Images = [];

  PetBloc({
    required this.getPetsUseCase,
    required this.getAllAvailablePetsUseCase,
    required this.createPetUseCase,
    required this.deletePetUseCase,
    required this.updatePetUseCase,
    required this.checkAuthStatusUseCase,
    required this.getCatalogsUseCase,
  }) : super(const PetState()) {
    
    // 1. CARGAR LISTA DE MASCOTAS
    on<LoadPets>((event, emit) async {
      emit(state.copyWith(status: PetStatus.loading));
      try {
        final pets = await getPetsUseCase(event.fundacionId);
        // Emitimos primero las mascotas para que la UI responda rápido
        emit(state.copyWith(status: PetStatus.success, pets: pets));

        // Luego, precargamos catálogos necesarios para resolver nombres
        try {
          final species = await getCatalogsUseCase.getSpecies();
          // Identificar especies presentes y cargar sus razas
          final speciesIds = pets
              .map((p) => p.especieId)
              .whereType<int>()
              .toSet()
              .toList();

          final breedsLists = await Future.wait(
            speciesIds.map((id) => getCatalogsUseCase.getBreeds(id)),
          );
          final allBreeds = breedsLists.expand((list) => list).toList();

          emit(state.copyWith(species: species, breeds: allBreeds));
        } catch (e) {
          LoggerService.error('Error precargando catálogos tras LoadPets', context: 'PetBloc', error: e);
        }
      } catch (e) {
        emit(state.copyWith(
          status: PetStatus.error, 
          errorMessage: e.toString()
        ));
      }
    });

    // 2. CARGAR FEED (ADOPTANTES)
    on<LoadAllAvailablePets>((event, emit) async {
      emit(state.copyWith(status: PetStatus.loading));
      try {
        final pets = await getAllAvailablePetsUseCase();
        // Emitimos primero las mascotas
        emit(state.copyWith(status: PetStatus.success, pets: pets));

        // Precargar catálogos para mapping de especie/raza
        try {
          final species = await getCatalogsUseCase.getSpecies();
          final speciesIds = pets
              .map((p) => p.especieId)
              .whereType<int>()
              .toSet()
              .toList();

          final breedsLists = await Future.wait(
            speciesIds.map((id) => getCatalogsUseCase.getBreeds(id)),
          );
          final allBreeds = breedsLists.expand((list) => list).toList();

          emit(state.copyWith(species: species, breeds: allBreeds));
        } catch (e) {
          LoggerService.error('Error precargando catálogos tras LoadAllAvailablePets', context: 'PetBloc', error: e);
        }
      } catch (e) {
        emit(state.copyWith(status: PetStatus.error, errorMessage: e.toString()));
      }
    });

    // 3. CARGAR CATÁLOGOS (Sin borrar mascotas)
    on<LoadCatalogs>((event, emit) async {
      // No cambiamos el status global a loading para no bloquear la lista
      try {
        final results = await Future.wait([
          getCatalogsUseCase.getSpecies(),
          getCatalogsUseCase.getQualities(),
        ]);
        emit(state.copyWith(
          species: results[0],
          qualities: results[1],
        ));
      } catch (e) {
        LoggerService.error('Error cargando catálogos', context: 'PetBloc', error: e);
        // Opcional: mostrar error silencioso o en snackbar
      }
    });

    // 4. CARGAR RAZAS
    on<LoadBreeds>((event, emit) async {
      try {
        final breeds = await getCatalogsUseCase.getBreeds(event.speciesId);
        emit(state.copyWith(breeds: breeds));
      } catch (e) {
        LoggerService.error('Error cargando razas', context: 'PetBloc', error: e);
      }
    });

    // 5. SUBMIT CREACIÓN (Usamos actionStatus)
    on<PetSubmitCreation>((event, emit) async {
      emit(state.copyWith(actionStatus: PetActionStatus.loading));
      
      try {
        // ... Lógica de validación previa ...
        if (_step1Data == null) throw Exception("Faltan datos del paso 1");

        final currentUser = await checkAuthStatusUseCase();
        if (currentUser == null) throw Exception('Usuario no autenticado');

        // ... Construcción de la entidad (Igual que antes) ...
        final MedicalRecordEntity? medicalRecord = _step2Data != null
            ? MedicalRecordEntity(
                esEsterilizado: _step2Data!.esEsterilizado,
                esDesparasitado: _step2Data!.esDesparasitado,
                tieneVacunas: _step2Data!.vacunasAlDia,
                tieneMicrochip: _step2Data!.tieneMicrochip,
                pesoKg: _step2Data!.peso ?? 0.0,
                observaciones: _step2Data!.observaciones,
              )
            : null;

        final List<File> galleryFiles = _step3Images.map((p) => File(p)).toList();
        final File? avatarFile = galleryFiles.isNotEmpty ? galleryFiles.first : null;

        final newPet = PetEntity(
          id: '',
          nombre: _step1Data!.nombre,
          descripcion: _step1Data!.descripcion,
          edad: _step1Data!.edad,
          sexo: _step1Data!.sexo,
          tamano: _step1Data!.tamano,
          status: 'disponible',
          fundacionId: currentUser.id,
          newAvatarFile: avatarFile,
          newGalleryFiles: galleryFiles,
          fichaMedica: medicalRecord,
          razaId: _step1Data!.razaId,
          especieId: _step1Data!.especieId,
        );

        await createPetUseCase(newPet);
        
        _clearWizardData();
        
        // Éxito en la acción + Recarga de lista
        // Primero emitimos éxito de acción
        emit(state.copyWith(
          actionStatus: PetActionStatus.success, 
          actionMessage: "Mascota creada correctamente"
        ));
        
        // Luego recargamos la lista (pondrá status global en loading si queremos, o silencioso)
        add(LoadPets(currentUser.id));
        
        // Reseteamos el estado de acción después de un momento
        await Future.delayed(Duration.zero);
        emit(state.copyWith(actionStatus: PetActionStatus.idle));

      } catch (e) {
        emit(state.copyWith(
          actionStatus: PetActionStatus.error, 
          actionMessage: e.toString()
        ));
      }
    });

    // 5b. SUBMIT ACTUALIZACIÓN
    on<PetSubmitUpdate>((event, emit) async {
      emit(state.copyWith(actionStatus: PetActionStatus.loading));
      try {
        if (_step1Data == null) throw Exception('Faltan datos del paso 1');

        final currentUser = await checkAuthStatusUseCase();
        if (currentUser == null) throw Exception('Usuario no autenticado');

        final MedicalRecordEntity? medicalRecord = _step2Data != null
            ? MedicalRecordEntity(
                esEsterilizado: _step2Data!.esEsterilizado,
                esDesparasitado: _step2Data!.esDesparasitado,
                tieneVacunas: _step2Data!.vacunasAlDia,
                tieneMicrochip: _step2Data!.tieneMicrochip,
                pesoKg: _step2Data!.peso ?? 0.0,
                observaciones: _step2Data!.observaciones,
              )
            : null;

        final List<File> galleryFiles = _step3Images.map((p) => File(p)).toList();
        final File? avatarFile = galleryFiles.isNotEmpty ? galleryFiles.first : null;

        final updatedPet = PetEntity(
          id: event.petId,
          nombre: _step1Data!.nombre,
          descripcion: _step1Data!.descripcion,
          edad: _step1Data!.edad,
          sexo: _step1Data!.sexo,
          tamano: _step1Data!.tamano,
          status: 'disponible',
          fundacionId: currentUser.id,
          newAvatarFile: avatarFile,
          newGalleryFiles: galleryFiles,
          fichaMedica: medicalRecord,
          razaId: _step1Data!.razaId,
          especieId: _step1Data!.especieId,
        );

        await updatePetUseCase(updatedPet);

        _clearWizardData();

        emit(state.copyWith(
          actionStatus: PetActionStatus.success,
          actionMessage: 'Mascota actualizada correctamente',
        ));

        // Recargar lista tras actualizar
        add(LoadPets(currentUser.id));

        await Future.delayed(Duration.zero);
        emit(state.copyWith(actionStatus: PetActionStatus.idle));
      } catch (e) {
        emit(state.copyWith(
          actionStatus: PetActionStatus.error,
          actionMessage: e.toString(),
        ));
      }
    });

    // 6. DELETE (Acción puntual)
    on<DeletePetEvent>((event, emit) async {
      // Podríamos usar actionStatus aquí también
      try {
        await deletePetUseCase(event.petId);
        add(LoadPets(event.fundacionId));
      } catch (e) {
        emit(state.copyWith(errorMessage: "No se pudo eliminar: $e"));
      }
    });

    // ... Handlers de Steps del Wizard (Igual que antes) ...
    on<PetCreateStep1Changed>((event, emit) => _step1Data = event);
    on<PetCreateStep2Changed>((event, emit) => _step2Data = event);
    on<PetCreateImagesChanged>((event, emit) => _step3Images = event.imagePaths);
  }

  void _clearWizardData() {
    _step1Data = null;
    _step2Data = null;
    _step3Images = [];
  }
}