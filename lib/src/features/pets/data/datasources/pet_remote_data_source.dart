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
      
      // 1. SUBIR AVATAR (Si existe)
      String? avatarPathUrl;
      if (pet.newAvatarFile != null) {
        dev.log('[PetRemoteDataSource] Subiendo avatar para: ${pet.nombre}');
        avatarPathUrl = await _uploadImage(pet.newAvatarFile!, 'avatars');
        dev.log('[PetRemoteDataSource] Avatar subido exitosamente: $avatarPathUrl');
      }

      // 2. LLAMAR A LA FUNCIÓN RPC (Transacción Atómica)
      // Esto guarda mascota + ficha al mismo tiempo.
      dev.log('[PetRemoteDataSource] Llamando RPC registrar_mascota_completa');
      final response = await supabaseClient.rpc('registrar_mascota_completa', params: {
        'p_nombre': pet.nombre,
        'p_descripcion': pet.descripcion,
        'p_edad': pet.edad,
        'p_sexo': pet.sexo, // Asegúrate de enviar 'macho' o 'hembra' exacto
        'p_fundacion_id': pet.fundacionId,
        'p_avatar_url': avatarPathUrl,
        
        // Datos Ficha Médica (Manejamos nulos con valores por defecto)
        'p_es_esterilizado': pet.fichaMedica?.esEsterilizado ?? false,
        'p_es_desparasitado': pet.fichaMedica?.esDesparasitado ?? false,
        'p_tiene_vacunas': pet.fichaMedica?.tieneVacunas ?? false,
        'p_peso': pet.fichaMedica?.pesoKg ?? 0.0,
        'p_observaciones': pet.fichaMedica?.observaciones ?? '',
      });
      
      final newPetId = response as String; // ID devuelto por la función SQL
      dev.log('[PetRemoteDataSource] Mascota creada con ID: $newPetId');

      // 3. SUBIR GALERÍA (Esto va aparte porque son múltiples archivos)
      // Si esto falla, la mascota ya existe, pero sin fotos extra. Es aceptable.
      if (pet.newGalleryFiles != null && pet.newGalleryFiles!.isNotEmpty) {
        dev.log('[PetRemoteDataSource] Subiendo ${pet.newGalleryFiles!.length} imágenes de galería');
        for (var file in pet.newGalleryFiles!) {
          final imageUrl = await _uploadImage(file, 'gallery/$newPetId');
          await supabaseClient.from('mascota_imagenes').insert({
            'mascota_id': newPetId,
            'imagen_url': imageUrl,
          });
        }
        dev.log('[PetRemoteDataSource] Galería subida exitosamente');
      }

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
      final userId = supabaseClient.auth.currentUser!.id;
      final fullPath = '$userId/$folder/$fileName';

      dev.log('[PetRemoteDataSource] Subiendo imagen a: $fullPath');
      await supabaseClient.storage.from('pets').upload(fullPath, file);
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
      throw Exception('Error actualizando mascota: $e');
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
