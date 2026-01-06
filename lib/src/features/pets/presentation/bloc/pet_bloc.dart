import 'dart:developer';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/pet_entity.dart';
import '../../domain/entities/medical_record_entity.dart';
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

  // --- VARIABLES TEMPORALES DEL WIZARD ---
  PetCreateStep1Changed? _step1Data;
  PetCreateStep2Changed? _step2Data;
  List<String> _step3Images = [];

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
    
    // --- HANDLERS PARA EL WIZARD ---
    // Paso 1: Info general
    on<PetCreateStep1Changed>((event, emit) {
      _step1Data = event;
      log('[PetBloc] Paso 1 guardado: nombre=${event.nombre}, sexo=${event.sexo}, tamaño=${event.tamano}');
    });

    // Paso 2: Info médica
    on<PetCreateStep2Changed>((event, emit) {
      _step2Data = event;
      log('[PetBloc] Paso 2 guardado: esterilizado=${event.esEsterilizado}, desparasitado=${event.esDesparasitado}, vacunas=${event.vacunasAlDia}');
    });

    // Paso 3: Imágenes
    on<PetCreateImagesChanged>((event, emit) {
      _step3Images = event.imagePaths;
      log('[PetBloc] Paso 3 guardado: ${_step3Images.length} imágenes');
    });

    // Submit final: crear mascota completa
    on<PetSubmitCreation>((event, emit) async {
      log('[PetBloc] Iniciando creación completa de mascota...');

      if (_step1Data == null) {
        emit(PetsError('Faltan datos del paso 1'));
        return;
      }

      emit(PetsLoading());

      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) throw Exception('Usuario no autenticado');

        // Construir ficha médica si existe paso 2
        final MedicalRecordEntity? medicalRecord = _step2Data != null
            ? MedicalRecordEntity(
                esEsterilizado: _step2Data!.esEsterilizado,
                esDesparasitado: _step2Data!.esDesparasitado,
                tieneVacunas: _step2Data!.vacunasAlDia,
                pesoKg: _step2Data!.peso ?? 0.0,
                observaciones: _step2Data!.observaciones,
              )
            : null;

        // Convertir rutas a archivos
        final List<File> galleryFiles = _step3Images.map((p) => File(p)).toList();
        final File? avatarFile = galleryFiles.isNotEmpty ? galleryFiles.first : null;

        // Construir entidad de mascota para el caso de uso
        final newPet = PetEntity(
          id: '',
          nombre: _step1Data!.nombre,
          descripcion: _step1Data!.descripcion,
          edad: _step1Data!.edad,
          sexo: _step1Data!.sexo,
          tamano: _step1Data!.tamano,
          status: 'disponible',
          fundacionId: userId,
          newAvatarFile: avatarFile,
          newGalleryFiles: galleryFiles,
          fichaMedica: medicalRecord,
        );

        await createPetUseCase(newPet);
        log('[PetBloc] Mascota creada exitosamente. Recargando lista...');

        // Limpiar borradores del wizard
        _step1Data = null;
        _step2Data = null;
        _step3Images = [];

        add(LoadPets(userId));
      } catch (e, stack) {
        log('[PetBloc] Error creando mascota: $e', stackTrace: stack);
        emit(PetsError('Error creando mascota: $e'));
      }
    });
  }
}