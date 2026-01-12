import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/foundation_entity.dart';
import '../models/foundation_model.dart';
import 'package:path/path.dart' as path;

class FoundationRepositoryImpl {
  final SupabaseClient client;

  FoundationRepositoryImpl(this.client);

  Future<FoundationEntity> getProfile(String userId) async {
    try {
      final response = await client.from('fundaciones').select().eq('id', userId).single();
      return FoundationModel.fromJson(response);
    } catch (e) {
      throw Exception('Error cargando perfil: $e');
    }
  }

  Future<void> updateProfile(FoundationEntity foundation) async {
    try {
      String? logoUrl = foundation.logoUrl;

      // 1. Subir Logo nuevo si existe
      if (foundation.newLogoFile != null) {
        final fileExt = path.extension(foundation.newLogoFile!.path);
        final fileName = '${foundation.id}/logo_${DateTime.now().millisecondsSinceEpoch}$fileExt';

        await client.storage.from('avatars').upload(
              fileName,
              foundation.newLogoFile!,
              fileOptions: const FileOptions(upsert: true),
            );
        logoUrl = client.storage.from('avatars').getPublicUrl(fileName);
      }

      // 2. Actualizar Datos
      final data = {
        'nombre': foundation.nombre,
        'descripcion': foundation.descripcion,
        'direccion': foundation.direccion,
        'telefono': foundation.telefono,
        'logo_url': logoUrl,
        'latitud': foundation.latitud,
        'longitud': foundation.longitud,
      };

      await client.from('fundaciones').update(data).eq('id', foundation.id);
    } catch (e) {
      throw Exception('No se pudo actualizar el perfil: $e');
    }
  }
}