import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/adopter_entity.dart';
import 'package:path/path.dart' as path;

class AdopterRepositoryImpl {
  final SupabaseClient client;
  AdopterRepositoryImpl(this.client);

  Future<AdopterEntity> getProfile(String userId) async {
    final response = await client.from('adoptantes').select().eq('id', userId).single();
    return AdopterEntity(
      id: response['id'],
      nombre: response['nombre'],
      cedula: response['cedula'],
      telefono: response['telefono'],
      avatarUrl: response['avatar_url'],
      edad: response['edad'],
      sexo: response['sexo'],
    );
  }

  Future<void> updateProfile(AdopterEntity adopter) async {
    String? avatarUrl = adopter.avatarUrl;

    // Subir imagen si existe nueva
    if (adopter.newAvatarFile != null) {
      final fileExt = path.extension(adopter.newAvatarFile!.path);
      final fileName = 'adopters/${adopter.id}/avatar_${DateTime.now().millisecondsSinceEpoch}$fileExt';
      await client.storage.from('avatars').upload(fileName, adopter.newAvatarFile!);
      avatarUrl = client.storage.from('avatars').getPublicUrl(fileName);
    }

    final data = {
      'nombre': adopter.nombre,
      'telefono': adopter.telefono,
      'edad': adopter.edad,
      'sexo': adopter.sexo,
      'avatar_url': avatarUrl,
    };

    await client.from('adoptantes').update(data).eq('id', adopter.id);
  }
}
