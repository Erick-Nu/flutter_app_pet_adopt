import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/adoption_request_entity.dart';
import '../../domain/repositories/adoption_repository.dart';
import '../models/adoption_request_model.dart';

class AdoptionRepositoryImpl implements AdoptionRepository {
  final SupabaseClient supabase;

  AdoptionRepositoryImpl(this.supabase);

  @override
  Future<void> createRequest({required String petId, required String foundationId, required String adopterId}) async {
    final existing = await supabase.from('adopciones')
        .select()
        .eq('mascota_id', petId)
        .eq('adoptante_id', adopterId)
        .maybeSingle();

    if (existing != null) throw Exception('Ya has enviado una solicitud para esta mascota.');

    await supabase.from('adopciones').insert({
      'mascota_id': petId,
      'fundacion_id': foundationId,
      'adoptante_id': adopterId,
      'estado_tramite': 'pendiente',
    });
  }

  @override
  Future<List<AdoptionRequestEntity>> getRequestsForFoundation(String foundationId) async {
    try {
      final response = await supabase.from('adopciones')
          .select('''
            id,
            mascota_id,
            adoptante_id,
            fundacion_id,
            estado_tramite,
            fecha_adopcion,
            mascotas(nombre, avatar_url, tamano, edad, sexo),
            adoptantes(nombre, avatar_url)
          ''')
          .eq('fundacion_id', foundationId)
          .order('fecha_adopcion', ascending: false);

      // Debug: Ver qué datos llegan desde Supabase
      print('📋 Adopciones cargadas: ${(response as List).length} registros');
      if ((response as List).isNotEmpty) {
        print('🔍 Primer registro: ${response.first}');
      }

      // Mapear y completar imágenes faltantes
      final requests = <AdoptionRequestEntity>[];
      for (final item in response as List) {
        final json = item as Map<String, dynamic>;
        final request = AdoptionRequestModel.fromJson(json);

        // Si avatar_url es null, intentar obtener una imagen de galería
        if (request.petImage == null && request.petId.isNotEmpty) {
          try {
            final gallery = await supabase
              .from('mascota_imagenes')
              .select('imagen_url')
                .eq('mascota_id', request.petId)
                .limit(1);

            String? firstImage;
            if (gallery.isNotEmpty) {
              final first = gallery.first;
              firstImage = first['imagen_url'] as String?;
            }

            if (firstImage != null) {
              print('🖼️ Usando imagen de galería para ${request.petName}: $firstImage');
              requests.add(AdoptionRequestModel(
                id: request.id,
                petId: request.petId,
                adopterId: request.adopterId,
                foundationId: request.foundationId,
                status: request.status,
                date: request.date,
                petName: request.petName,
                petImage: firstImage,
                petSize: request.petSize,
                petAge: request.petAge,
                petSex: request.petSex,
                adopterName: request.adopterName,
                adopterAvatar: request.adopterAvatar,
              ));
              continue;
            }
          } catch (e) {
            print('⚠️ Error consultando galería para ${request.petName}: $e');
          }
        }

        // Si no se encontró imagen, agregar tal cual
        requests.add(request);
      }

      return requests;
    } catch (e) {
      print('❌ Error Supabase al cargar solicitudes: $e');
      rethrow;
    }
  }

  @override
  Future<List<AdoptionRequestEntity>> getRequestsForAdopter(String adopterId) async {
    final response = await supabase.from('adopciones')
        .select('*, mascotas(nombre, avatar_url, tamano, edad, sexo), fundaciones(nombre, avatar_url)')
        .eq('adoptante_id', adopterId)
        .order('fecha_adopcion', ascending: false);

    // Debug: visor rápido de resultados
    final list = response as List;
    print('📬 (Adopter) Adopciones cargadas: ${list.length} registros para $adopterId');
    if (list.isNotEmpty) {
      print('🔎 (Adopter) Primer registro: ${list.first}');
    }

    final requests = <AdoptionRequestEntity>[];
    for (final raw in (response as List)) {
      final model = AdoptionRequestModel.fromJson(raw as Map<String, dynamic>);

      // Fallback para imagen si avatar_url está vacío
      if ((model.petImage == null || (model.petImage?.isEmpty ?? true)) && model.petId.isNotEmpty) {
        try {
          final gallery = await supabase
              .from('mascota_imagenes')
              .select('imagen_url')
              .eq('mascota_id', model.petId)
              .limit(1);
          String? firstImage;
          if (gallery.isNotEmpty) {
            final first = gallery.first;
            firstImage = first['imagen_url'] as String?;
          }
          requests.add(AdoptionRequestEntity(
            id: model.id,
            petId: model.petId,
            adopterId: model.adopterId,
            foundationId: model.foundationId,
            status: model.status,
            date: model.date,
            petName: model.petName,
            petImage: firstImage ?? model.petImage,
            petSize: model.petSize,
            petAge: model.petAge,
            petSex: model.petSex,
            adopterName: model.adopterName,
            adopterAvatar: model.adopterAvatar,
            foundationName: model.foundationName,
            foundationAvatar: model.foundationAvatar,
          ));
          continue;
        } catch (e) {
          print('⚠️ Error consultando galería (adopter) para ${model.petName}: $e');
        }
      }

      requests.add(model);
    }
    return requests;
  }

  @override
  Future<void> respondToRequest({
    required String requestId, 
    required String status, 
    required String petId, 
    required String adopterId, 
    required String foundationId
  }) async {
    await supabase.from('adopciones').update({
      'estado_tramite': status
    }).eq('id', requestId);

    if (status == 'aprobada') {
      await supabase.from('chats').upsert({
        'mascota_id': petId,
        'adoptante_id': adopterId,
        'fundacion_id': foundationId,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'mascota_id, adoptante_id, fundacion_id');
    }
  }
}
