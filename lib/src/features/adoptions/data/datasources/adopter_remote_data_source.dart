import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/logger_service.dart';
import '../models/adopter_model.dart';

abstract class AdopterRemoteDataSource {
  /// Obtiene el perfil del adoptante por su ID de usuario (Auth ID)
  Future<AdopterModel> getAdopterProfile(String userId);

  /// Actualiza los datos textuales del perfil
  Future<AdopterModel> updateAdopterProfile(AdopterModel adopter);

  /// Sube la foto de perfil al Storage y retorna la URL pública
  Future<String> uploadAvatar(String userId, File imageFile);
}

class AdopterRemoteDataSourceImpl implements AdopterRemoteDataSource {
  final SupabaseClient supabaseClient;

  AdopterRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<AdopterModel> getAdopterProfile(String userId) async {
    try {
      LoggerService.info('Obteniendo perfil de adoptante: $userId', context: 'AdopterRemoteDataSource');
      
      final response = await supabaseClient
          .from('adoptantes')
          .select()
          .eq('id', userId)
          .single();

      // Convertimos el JSON de Supabase a nuestro AdopterModel
      return AdopterModel.fromJson(response);
      
    } catch (e) {
      LoggerService.error('Error al obtener perfil', context: 'AdopterRemoteDataSource', error: e);
      throw Exception('Error al cargar el perfil: $e');
    }
  }

  @override
  Future<AdopterModel> updateAdopterProfile(AdopterModel adopter) async {
    try {
      LoggerService.info('Actualizando perfil: ${adopter.id}', context: 'AdopterRemoteDataSource');
      
      // Convertimos el Modelo a JSON y lo enviamos
      // Nota: supabase.from().update()...select() devuelve el registro actualizado
      final response = await supabaseClient
          .from('adoptantes')
          .update(adopter.toJson())
          .eq('id', adopter.id)
          .select()
          .single();

      LoggerService.success('Perfil actualizado correctamente', context: 'AdopterRemoteDataSource');
      return AdopterModel.fromJson(response);

    } catch (e) {
      LoggerService.error('Error al actualizar perfil', context: 'AdopterRemoteDataSource', error: e);
      throw Exception('No se pudo actualizar el perfil: $e');
    }
  }

  @override
  Future<String> uploadAvatar(String userId, File imageFile) async {
    try {
      LoggerService.info('Subiendo avatar...', context: 'AdopterRemoteDataSource');
      
      // 1. Definir la ruta en el bucket: avatars/user_id/profile.jpg
      final fileExt = imageFile.path.split('.').last;
      final filePath = '$userId/profile_$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // 2. Subir al bucket 'avatars' (Asegúrate de tener este bucket creado en Supabase)
      await supabaseClient.storage.from('avatars').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true), // Sobrescribe si existe
          );

      // 3. Obtener URL pública
      final imageUrl = supabaseClient.storage.from('avatars').getPublicUrl(filePath);
      
      LoggerService.success('Avatar subido. URL: $imageUrl', context: 'AdopterRemoteDataSource');
      return imageUrl;

    } catch (e) {
      LoggerService.error('Error al subir avatar', context: 'AdopterRemoteDataSource', error: e);
      throw Exception('Error al subir la imagen: $e');
    }
  }
}