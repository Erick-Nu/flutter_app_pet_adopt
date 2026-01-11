import '../../domain/entities/adoption_request_entity.dart';

class AdoptionRequestModel extends AdoptionRequestEntity {
  AdoptionRequestModel({
    required super.id,
    required super.petId,
    required super.adopterId,
    required super.foundationId,
    required super.status,
    required super.date,
    super.petName,
    super.petImage,
    super.adopterName,
    super.adopterAvatar,
  });

  factory AdoptionRequestModel.fromJson(Map<String, dynamic> json) {
    final petData = json['mascotas'] as Map<String, dynamic>?;
    final adopterData = json['adoptantes'] as Map<String, dynamic>?;

    // Debug: ver si adopterData viene nulo (indicaría problema de RLS)
    if (adopterData == null) {
      print('⚠️  Advertencia: No se pudieron cargar datos del adoptante (posiblemente problema de RLS)');
    }

    return AdoptionRequestModel(
      id: json['id'] as String? ?? '',
      petId: json['mascota_id'] as String? ?? '',
      adopterId: json['adoptante_id'] as String? ?? '',
      foundationId: json['fundacion_id'] as String? ?? '',
      status: (json['estado_tramite'] as String?) ?? 'pendiente',
      date: DateTime.tryParse(json['fecha_adopcion'] as String? ?? '') ?? DateTime.now(),
      petName: petData?['nombre'] as String?,
      petImage: petData?['avatar_url'] as String?,
      adopterName: adopterData?['nombre'] as String? ?? 'Usuario Desconocido',
      adopterAvatar: adopterData?['avatar_url'] as String?,
    );
  }
}
