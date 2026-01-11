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
            mascotas(nombre, avatar_url),
            adoptantes(nombre, avatar_url)
          ''')
          .eq('fundacion_id', foundationId)
          .order('fecha_adopcion', ascending: false);

      // Debug: Ver qué datos llegan desde Supabase
      print('📋 Adopciones cargadas: ${(response as List).length} registros');
      if ((response as List).isNotEmpty) {
        print('🔍 Primer registro: ${response.first}');
      }

      return (response as List).map((e) => AdoptionRequestModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('❌ Error Supabase al cargar solicitudes: $e');
      rethrow;
    }
  }

  @override
  Future<List<AdoptionRequestEntity>> getRequestsForAdopter(String adopterId) async {
    final response = await supabase.from('adopciones')
        .select('*, mascotas(nombre, avatar_url)')
        .eq('adoptante_id', adopterId)
        .order('fecha_adopcion', ascending: false);
    return (response as List).map((e) => AdoptionRequestModel.fromJson(e as Map<String, dynamic>)).toList();
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
