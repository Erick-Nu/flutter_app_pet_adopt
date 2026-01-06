import 'dart:developer';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/pet_entity.dart';
import '../../domain/entities/medical_record_entity.dart';
import '../../domain/usecases/create_pet_usecase.dart';
import '../../domain/usecases/delete_pet_usecase.dart';
import '../../domain/usecases/get_pets_usecase.dart';
import '../../domain/usecases/get_all_available_pets_usecase.dart';
import '../../domain/usecases/update_pet_usecase.dart';
import 'pet_event.dart';
import 'pet_state.dart';

class PetBloc extends Bloc<PetEvent, PetState> {
  // Inyectamos los casos de uso en lugar del repositorio directo
  final GetPetsUseCase getPetsUseCase;
  final GetAllAvailablePetsUseCase getAllAvailablePetsUseCase;
  final CreatePetUseCase createPetUseCase;
  final DeletePetUseCase deletePetUseCase;
  final UpdatePetUseCase updatePetUseCase;

  // --- VARIABLES TEMPORALES DEL WIZARD ---
  PetCreateStep1Changed? _step1Data;
  PetCreateStep2Changed? _step2Data;
  List<String> _step3Images = [];

  PetBloc({
    required this.getPetsUseCase,
    required this.getAllAvailablePetsUseCase,
    required this.createPetUseCase,
    required this.deletePetUseCase,
    required this.updatePetUseCase,
  }) : super(PetsInitial()) {
    
    on<LoadPets>((event, emit) async {
      print('[PetBloc] LoadPets event recibido con fundacionId: ${event.fundacionId}');
      emit(PetsLoading());
      try {
        // Usamos el caso de uso
        print('[PetBloc] Llamando a getPetsUseCase...');
        final pets = await getPetsUseCase(event.fundacionId);
        print('[PetBloc] getPetsUseCase completado. Mascotas obtenidas: ${pets.length}');
        emit(PetsLoaded(pets));
      } catch (e) {
        print('[PetBloc] ERROR en LoadPets: $e');
        emit(PetsError(e.toString()));
      }
    });

    on<LoadAllAvailablePets>((event, emit) async {
      print('[PetBloc] LoadAllAvailablePets event recibido');
      emit(PetsLoading());
      try {
        print('[PetBloc] Llamando a getAllAvailablePetsUseCase...');
        final pets = await getAllAvailablePetsUseCase();
        print('[PetBloc] getAllAvailablePetsUseCase completado. Mascotas disponibles: ${pets.length}');
        emit(PetsLoaded(pets));
      } catch (e) {
        print('[PetBloc] ERROR en LoadAllAvailablePets: $e');
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
                tieneMicrochip: _step2Data!.tieneMicrochip,
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

    // Handler para ACTUALIZAR
    on<PetSubmitUpdate>((event, emit) async {
      log('[PetBloc] Iniciando actualización de mascota ${event.petId}...');

      emit(PetsLoading());

      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) throw Exception("Usuario no autenticado");

        // 1. Construir Ficha Médica
        final medicalRecord = _step2Data != null
            ? MedicalRecordEntity(
                esEsterilizado: _step2Data!.esEsterilizado,
                esDesparasitado: _step2Data!.esDesparasitado,
                tieneVacunas: _step2Data!.vacunasAlDia,
                tieneMicrochip: _step2Data!.tieneMicrochip,
                pesoKg: _step2Data!.peso ?? 0.0,
                observaciones: _step2Data!.observaciones,
              )
            : null;

        // 2. Archivos Nuevos (Solo los que son rutas locales)
        final newGalleryFiles = _step3Images.map((path) => File(path)).toList();

        // 3. Entidad para Actualizar
        final updatedPet = PetEntity(
          id: event.petId, // ID IMPORTANTE
          nombre: _step1Data?.nombre ?? '',
          descripcion: _step1Data?.descripcion,
          edad: _step1Data?.edad,
          sexo: _step1Data?.sexo ?? 'macho',
          tamano: _step1Data?.tamano,
          status: 'disponible',
          fundacionId: userId,
          newAvatarFile: null,
          newGalleryFiles: newGalleryFiles,
          fichaMedica: medicalRecord,
        );

        // 4. Llamar al Caso de Uso UPDATE
        await updatePetUseCase(updatedPet);

        log('[PetBloc] Mascota actualizada. Recargando lista.');

        // Limpiar temporales
        _step1Data = null;
        _step2Data = null;
        _step3Images = [];

        add(LoadPets(userId));
      } catch (e, stack) {
        log('[PetBloc] Error actualizando: $e', stackTrace: stack);
        emit(PetsError("Error actualizando: $e"));
      }
    });
  }
}