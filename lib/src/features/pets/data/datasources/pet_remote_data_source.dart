import 'dart:io';
import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet_model.dart';
import '../models/medical_record_model.dart';
import 'package:path/path.dart' as path; // Necesario para sacar extensión del archivo
import '../../domain/entities/pet_entity.dart';
import '../../../../core/services/logger_service.dart';

class PetRemoteDataSource {
  final SupabaseClient supabaseClient;

  PetRemoteDataSource(this.supabaseClient);

  Future<List<PetModel>> getPets(String fundacionId) async {
    try {
      dev.log('[PetRemoteDataSource] Cargando mascotas para fundación: $fundacionId');
        final response = await supabaseClient
          .from('mascotas')
          .select('*, mascota_imagenes(imagen_url)')
          .eq('fundacion_id', fundacionId)
          .order('created_at', ascending: false); // Más recientes primero

      final pets = (response as List).map((e) => PetModel.fromJson(e)).toList();
      dev.log('[PetRemoteDataSource] ${pets.length} mascotas cargadas exitosamente');
      return pets;
    } catch (e) {
      dev.log('[PetRemoteDataSource] Error al cargar mascotas', error: e);
      throw Exception('Error al cargar mascotas: $e');
    }
  }

  /// Traer todas las mascotas disponibles (Para el Home del Adoptante)
  Future<List<PetModel>> getAllAvailablePets() async {
    try {
      dev.log('[PetRemoteDataSource] Cargando todas las mascotas disponibles');
      final response = await supabaseClient
          .from('mascotas')
          .select('*, mascota_imagenes(imagen_url)')
          .eq('status', 'disponible') // Solo disponibles
          .order('created_at', ascending: false);

      final pets = (response as List).map((e) => PetModel.fromJson(e)).toList();
      dev.log('[PetRemoteDataSource] ${pets.length} mascotas disponibles cargadas');
      return pets;
    } catch (e) {
      dev.log('[PetRemoteDataSource] Error cargando feed de mascotas', error: e);
      throw Exception('Error cargando feed de mascotas: $e');
    }
  }

  Future<void> createPet(PetModel pet) async {
    try {
      dev.log('[PetRemoteDataSource] Creando mascota: ${pet.nombre}');
      // Nota: No enviamos 'id' porque la BD lo genera (gen_random_uuid)
      await supabaseClient.from('mascotas').insert(pet.toJson());
      dev.log('[PetRemoteDataSource] Mascota creada exitosamente: ${pet.nombre}');
    } catch (e) {
      dev.log('[PetRemoteDataSource] Error al crear mascota', error: e);
      throw Exception('Error al crear mascota: $e');
    }
  }

  /// Crea una mascota completa: sube avatar/galería y ficha médica asociada
  Future<void> createPetFull(PetEntity pet) async {
    try {
      dev.log('[PetRemoteDataSource] Iniciando creación completa de mascota: ${pet.nombre}');

      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Sesión expirada. Inicia sesión nuevamente.');
      }

      // Convertir PetEntity -> PetModel para aprovechar toJson (incluye raza/especie/tamaño)
      final petModel = PetModel(
        id: pet.id,
        nombre: pet.nombre,
        descripcion: pet.descripcion,
        edad: pet.edad,
        sexo: pet.sexo,
        fundacionId: pet.fundacionId,
        tamano: pet.tamano,
        razaId: pet.razaId,
        especieId: pet.especieId,
        avatarUrl: pet.avatarUrl,
        galleryUrls: pet.galleryUrls,
      );

      // Convertir ficha médica si existe
      final medicalModel = pet.fichaMedica != null
          ? MedicalRecordModel(
              esEsterilizado: pet.fichaMedica!.esEsterilizado,
              esDesparasitado: pet.fichaMedica!.esDesparasitado,
              tieneVacunas: pet.fichaMedica!.tieneVacunas,
              pesoKg: pet.fichaMedica!.pesoKg,
              observaciones: pet.fichaMedica!.observaciones,
            )
          : MedicalRecordModel();

      // Preparar imágenes: usamos newGalleryFiles si existen; si no, usar newAvatarFile
      final List<File> imageFiles = [];
      if (pet.newGalleryFiles != null && pet.newGalleryFiles!.isNotEmpty) {
        imageFiles.addAll(pet.newGalleryFiles!);
      } else if (pet.newAvatarFile != null) {
        imageFiles.add(pet.newAvatarFile!);
      }

      // Usar flujo directo de inserts que incluye raza/especie/tamaño
      await createPetComplete(petModel, medicalModel, imageFiles);

      dev.log('[PetRemoteDataSource] Creación completa de mascota finalizada exitosamente');
    } catch (e) {
      dev.log('[PetRemoteDataSource] Error creando mascota completa', error: e);
      throw Exception('Error creando mascota: $e');
    }
  }

  Future<void> updatePet(PetModel pet) async {
    try {
      dev.log('[PetRemoteDataSource] Actualizando mascota: ${pet.id} - ${pet.nombre}');
      await supabaseClient
          .from('mascotas')
          .update(pet.toJson())
          .eq('id', pet.id);
      dev.log('[PetRemoteDataSource] Mascota actualizada exitosamente: ${pet.id}');
    } catch (e) {
      dev.log('[PetRemoteDataSource] Error al actualizar mascota', error: e);
      throw Exception('Error al actualizar mascota: $e');
    }
  }

  Future<void> deletePet(String petId) async {
    try {
      dev.log('[PetRemoteDataSource] Iniciando eliminación de mascota: $petId');
      await supabaseClient.from('mascotas').delete().eq('id', petId);
      dev.log('[PetRemoteDataSource] Mascota eliminada exitosamente: $petId');
    } catch (e) {
      dev.log('[PetRemoteDataSource] Error al eliminar mascota: $e', error: e);
      throw Exception('Error al eliminar mascota: $e');
    }
  }

  Future<String> _uploadImage(File file, String folder) async {
    try {
      final fileExt = path.extension(file.path);
      final fileName = '${DateTime.now().toIso8601String()}$fileExt';
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Sesión expirada. Inicia sesión nuevamente.');
      }

      final userId = currentUser.id;
      final fullPath = '$userId/$folder/$fileName';

      dev.log('[PetRemoteDataSource] Subiendo imagen a: $fullPath');
      await supabaseClient.storage.from('pets').upload(
            fullPath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      final publicUrl = supabaseClient.storage.from('pets').getPublicUrl(fullPath);
      dev.log('[PetRemoteDataSource] Imagen subida exitosamente: $publicUrl');
      return publicUrl;
    } catch (e) {
      dev.log('[PetRemoteDataSource] Error subiendo imagen', error: e);
      throw Exception('Error subiendo imagen: $e');
    }
  }
  

  Future<void> updatePetFull(PetEntity pet) async {
    try {
      dev.log('[PetRemoteDataSource] Iniciando actualización completa de mascota: ${pet.id} - ${pet.nombre}');
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Sesión expirada. Inicia sesión nuevamente.');
      }
      
      // 1. GESTIÓN DE AVATAR
      String? avatarPathUrl = pet.avatarUrl; // Por defecto mantenemos el anterior
      
      // Si el usuario eligió una NUEVA foto, la subimos
      if (pet.newAvatarFile != null) {
        dev.log('[PetRemoteDataSource] Actualizando avatar');
        avatarPathUrl = await _uploadImage(pet.newAvatarFile!, 'avatars');
      }

      // 2. ACTUALIZAR TABLA MASCOTAS
      dev.log('[PetRemoteDataSource] Actualizando datos básicos de mascota');
      final petData = {
        'nombre': pet.nombre,
        'descripcion': pet.descripcion,
        'edad': pet.edad,
        'sexo': pet.sexo,
        'tamano': pet.tamano,
        'especie_id': pet.especieId,
        'raza_id': pet.razaId,
        // 'fundacion_id': ... (No se actualiza, la mascota no cambia de dueño)
        'avatar_url': avatarPathUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabaseClient
          .from('mascotas')
          .update(petData)
          .eq('id', pet.id);
      dev.log('[PetRemoteDataSource] Datos básicos actualizados');

      // 3. ACTUALIZAR FICHA MÉDICA (Upsert: Actualiza o Inserta si no existe)
      if (pet.fichaMedica != null) {
        dev.log('[PetRemoteDataSource] Actualizando ficha médica');
        final fichaData = {
          'mascota_id': pet.id, // Llave foránea para vincular
          'es_esterilizado': pet.fichaMedica!.esEsterilizado,
          'es_desparasitado': pet.fichaMedica!.esDesparasitado,
          'tiene_vacunas_al_dia': pet.fichaMedica!.tieneVacunas,
          'peso_kg': pet.fichaMedica!.pesoKg,
          'observaciones_veterinarias': pet.fichaMedica!.observaciones,
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Usamos upsert para manejar casos donde la ficha no existía antes
        await supabaseClient.from('fichas_medicas').upsert(
          fichaData, 
          onConflict: 'mascota_id' // Clave única para detectar duplicados
        );
        dev.log('[PetRemoteDataSource] Ficha médica actualizada');
      }

      // 4. AGREGAR NUEVAS FOTOS A LA GALERÍA
      if (pet.newGalleryFiles != null && pet.newGalleryFiles!.isNotEmpty) {
        dev.log('[PetRemoteDataSource] Agregando ${pet.newGalleryFiles!.length} fotos a galería');
        for (var file in pet.newGalleryFiles!) {
          final imageUrl = await _uploadImage(file, 'gallery/${pet.id}');
          await supabaseClient.from('mascota_imagenes').insert({
            'mascota_id': pet.id,
            'imagen_url': imageUrl,
          });
        }
        dev.log('[PetRemoteDataSource] Fotos de galería agregadas');
      }

      dev.log('[PetRemoteDataSource] Actualización completa finalizada exitosamente');
    } catch (e) {
      dev.log('[PetRemoteDataSource] Error actualizando mascota completa', error: e);
      // Mensaje amigable para la UI
      throw Exception('No se pudo actualizar la mascota. Detalle: $e');
    }
  }

  /// Crea una mascota completa con toda su información: datos básicos, ficha médica e imágenes
  Future<PetModel> createPetComplete(
    PetModel petData,
    MedicalRecordModel medicalData,
    List<File> imageFiles,
  ) async {
    try {
      dev.log('[PetRemoteDataSource] Iniciando createPetComplete para: ${petData.nombre}');
      final userId = supabaseClient.auth.currentUser!.id;
      dev.log('[PetRemoteDataSource] Usuario actual: $userId');

      // 1. Subir imágenes y obtener URLs
      dev.log('[PetRemoteDataSource] Subiendo ${imageFiles.length} imágenes');
      List<String> uploadedUrls = [];
      for (var imageFile in imageFiles) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
        final imagePath = 'gallery/$userId/$fileName';

        await supabaseClient.storage.from('pets').upload(imagePath, imageFile);
        final publicUrl = supabaseClient.storage.from('pets').getPublicUrl(imagePath);
        uploadedUrls.add(publicUrl);
        dev.log('[PetRemoteDataSource] Imagen subida: $publicUrl');
      }
      dev.log('[PetRemoteDataSource] Total de imágenes subidas: ${uploadedUrls.length}');

      // 2. Insertar Mascota (Tabla 'mascotas')
      dev.log('[PetRemoteDataSource] Insertando mascota en tabla mascotas');
      final petMap = petData.toJson();
      petMap['fundacion_id'] = userId;
      petMap['avatar_url'] = uploadedUrls.isNotEmpty ? uploadedUrls.first : null;
      dev.log('[PetRemoteDataSource] Datos de mascota: $petMap');

      final petResponse = await supabaseClient
          .from('mascotas')
          .insert(petMap)
          .select()
          .single();

      final newPetId = petResponse['id'];
      dev.log('[PetRemoteDataSource] Mascota insertada con ID: $newPetId');

      // 3. Insertar Ficha Médica (Tabla 'fichas_medicas')
      dev.log('[PetRemoteDataSource] Insertando ficha médica');
      final medicalMap = medicalData.toJson();
      medicalMap['mascota_id'] = newPetId;
      dev.log('[PetRemoteDataSource] Datos de ficha médica: $medicalMap');

      await supabaseClient.from('fichas_medicas').insert(medicalMap);
      dev.log('[PetRemoteDataSource] Ficha médica insertada exitosamente');

      // 4. Insertar Imágenes en Galería (Tabla 'mascota_imagenes')
      final imagesToInsert = uploadedUrls.map((url) => {
        'mascota_id': newPetId,
        'imagen_url': url,
      }).toList();

      if (imagesToInsert.isNotEmpty) {
        dev.log('[PetRemoteDataSource] Insertando ${imagesToInsert.length} imágenes en galería');
        await supabaseClient.from('mascota_imagenes').insert(imagesToInsert);
        dev.log('[PetRemoteDataSource] Imágenes de galería insertadas');
      }

      dev.log('[PetRemoteDataSource] createPetComplete finalizado exitosamente');
      return PetModel.fromJson(petResponse);
    } catch (e) {
      dev.log('[PetRemoteDataSource] Error en createPetComplete', error: e);
      LoggerService.error('Error creando mascota completa', error: e);
      rethrow;
    }
  }
}
