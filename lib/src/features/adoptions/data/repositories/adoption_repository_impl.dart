import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/adoption_request_entity.dart';
import '../../domain/repositories/adoption_repository.dart';
import '../models/adoption_request_model.dart';

class AdoptionRepositoryImpl implements AdoptionRepository {
  final SupabaseClient supabase;

  AdoptionRepositoryImpl(this.supabase);

  @override
  Future<void> createRequest({
    required String petId,
    required String foundationId,
    required String adopterId,
  }) async {
    try {
      // Intentamos insertar directamente.
      // Si la mascota ya tiene solicitud (de CUALQUIER persona), la base de datos lanzará un error.
      await supabase.from('adopciones').insert({
        'mascota_id': petId,
        'fundacion_id': foundationId,
        'adoptante_id': adopterId,
        'estado_tramite': 'pendiente',
      });
    } on PostgrestException catch (e) {
      // CÓDIGO 23505 = Unique Constraint Violation (Ya existe registro)
      if (e.code == '23505') {
        // Aquí mostramos el mensaje que pediste, sin importar quién tenga la solicitud
        throw Exception('Mascota en proceso de adopción');
      }
      
      // Si es otro error de base de datos, lo mostramos normal
      throw Exception('Error de base de datos: ${e.message}');
      
    } catch (e) {
      // Cualquier otro error no controlado
      throw Exception('Error al enviar solicitud: $e');
    }
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
    try {
      // 1. Consulta explícita (Igual que en Foundation, para evitar errores de mapeo)
      final response = await supabase.from('adopciones')
          .select('''
            id,
            mascota_id,
            adoptante_id,
            fundacion_id,
            estado_tramite,
            fecha_adopcion,
            mascotas ( nombre, avatar_url, tamano, edad, sexo ),
            fundaciones ( nombre, logo_url ),
            adoptantes ( nombre, avatar_url )
          ''')
          .eq('adoptante_id', adopterId)
          .order('fecha_adopcion', ascending: false);

      print('📬 (Adopter) Solicitudes crudas: ${(response as List).length}');

      final requests = <AdoptionRequestEntity>[];

      for (final raw in (response as List)) {
        try {
          // Intentamos convertir el JSON
          final model = AdoptionRequestModel.fromJson(raw as Map<String, dynamic>);

          // 2. Lógica de recuperación de imagen (Fallback)
          // Si la mascota no tiene avatar en la tabla principal, buscamos en la galería
          if ((model.petImage == null || (model.petImage?.isEmpty ?? true)) && model.petId.isNotEmpty) {
            try {
              final gallery = await supabase
                  .from('mascota_imagenes')
                  .select('imagen_url')
                  .eq('mascota_id', model.petId)
                  .limit(1)
                  .maybeSingle(); // Usamos maybeSingle para evitar excepciones si está vacío

              if (gallery != null) {
                final firstImage = gallery['imagen_url'] as String?;
                if (firstImage != null) {
                  // Creamos una copia del modelo con la nueva imagen
                  requests.add(AdoptionRequestEntity(
                    id: model.id,
                    petId: model.petId,
                    adopterId: model.adopterId,
                    foundationId: model.foundationId,
                    status: model.status,
                    date: model.date,
                    petName: model.petName,
                    petImage: firstImage, // <--- Imagen recuperada
                    petSize: model.petSize,
                    petAge: model.petAge,
                    petSex: model.petSex,
                    adopterName: model.adopterName,
                    adopterAvatar: model.adopterAvatar,
                    foundationName: model.foundationName,
                    foundationAvatar: model.foundationAvatar,
                  ));
                  continue; // Saltamos al siguiente ciclo ya que agregamos este
                }
              }
            } catch (imgError) {
              print('⚠️ Error imagen secundaria (adopter): $imgError');
            }
          }

          // Si tiene imagen o falló el fallback, agregamos el modelo original
          requests.add(model);

        } catch (parseError) {
          print('❌ Error parseando solicitud individual: $parseError');
          // No hacemos rethrow para que una solicitud dañada no rompa toda la lista
        }
      }
      return requests;

    } catch (e) {
      print('❌ Error General Supabase (Adopter): $e');
      // Aquí sí lanzamos el error para que el Bloc muestre el estado de error
      rethrow;
    }
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
