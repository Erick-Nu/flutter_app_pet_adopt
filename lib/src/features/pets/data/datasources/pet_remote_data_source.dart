import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet_model.dart';
import 'package:path/path.dart' as path; // Necesario para sacar extensión del archivo
import '../../domain/entities/pet_entity.dart';

class PetRemoteDataSource {
  final SupabaseClient supabaseClient;

  PetRemoteDataSource(this.supabaseClient);

  Future<List<PetModel>> getPets(String fundacionId) async {
    try {
      final response = await supabaseClient
          .from('mascotas')
          .select()
          .eq('fundacion_id', fundacionId)
          .order('created_at', ascending: false); // Más recientes primero

      return (response as List).map((e) => PetModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error al cargar mascotas: $e');
    }
  }

  Future<void> createPet(PetModel pet) async {
    try {
      // Nota: No enviamos 'id' porque la BD lo genera (gen_random_uuid)
      await supabaseClient.from('mascotas').insert(pet.toJson());
    } catch (e) {
      throw Exception('Error al crear mascota: $e');
    }
  }

  /// Crea una mascota completa: sube avatar/galería y ficha médica asociada
  Future<void> createPetFull(PetEntity pet) async {
    try {
      // 1. SUBIR AVATAR (Si existe)
      String? avatarPathUrl;
      if (pet.newAvatarFile != null) {
        avatarPathUrl = await _uploadImage(pet.newAvatarFile!, 'avatars');
      }

      // 2. LLAMAR A LA FUNCIÓN RPC (Transacción Atómica)
      // Esto guarda mascota + ficha al mismo tiempo.
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

      // 3. SUBIR GALERÍA (Esto va aparte porque son múltiples archivos)
      // Si esto falla, la mascota ya existe, pero sin fotos extra. Es aceptable.
      if (pet.newGalleryFiles != null && pet.newGalleryFiles!.isNotEmpty) {
        for (var file in pet.newGalleryFiles!) {
          final imageUrl = await _uploadImage(file, 'gallery/$newPetId');
          await supabaseClient.from('mascota_imagenes').insert({
            'mascota_id': newPetId,
            'imagen_url': imageUrl,
          });
        }
      }

    } catch (e) {
      throw Exception('Error creando mascota: $e');
    }
  }

  Future<void> updatePet(PetModel pet) async {
    try {
      await supabaseClient
          .from('mascotas')
          .update(pet.toJson())
          .eq('id', pet.id);
    } catch (e) {
      throw Exception('Error al actualizar mascota: $e');
    }
  }

  Future<void> deletePet(String petId) async {
    try {
      await supabaseClient.from('mascotas').delete().eq('id', petId);
    } catch (e) {
      throw Exception('Error al eliminar mascota: $e');
    }
  }

  Future<String> _uploadImage(File file, String folder) async {
    try {
      final fileExt = path.extension(file.path);
      final fileName = '${DateTime.now().toIso8601String()}$fileExt';
      final userId = supabaseClient.auth.currentUser!.id;
      final fullPath = '$userId/$folder/$fileName';

      await supabaseClient.storage.from('pets').upload(fullPath, file);
      final publicUrl = supabaseClient.storage.from('pets').getPublicUrl(fullPath);
      return publicUrl;
    } catch (e) {
      throw Exception('Error subiendo imagen: $e');
    }
  }
}
