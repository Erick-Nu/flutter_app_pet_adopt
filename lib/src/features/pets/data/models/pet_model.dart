import '../../domain/entities/pet_entity.dart';

class PetModel extends PetEntity {
  PetModel({
    required super.id,
    required super.nombre,
    super.descripcion,
    super.edad,
    super.sexo = 'macho',
    super.status = 'disponible',
    super.avatarUrl,
    required super.fundacionId,
    super.tamano = 'Mediano',
    super.razaId,
    super.especieId,
    super.galleryUrls = const [],
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    // Extraer URLs de la relación 'mascota_imagenes'
    List<String> loadedGallery = [];
    final rel = json['mascota_imagenes'];
    if (rel != null && rel is List) {
      loadedGallery = rel
          .whereType<Map<String, dynamic>>()
          .map((item) => item['imagen_url'])
          .whereType<String>()
          .toList();
    }

    // Si no hay galería, usar el avatar como fallback
    final avatar = json['avatar_url'] as String?;
    if (loadedGallery.isEmpty && avatar != null && avatar.isNotEmpty) {
      loadedGallery.add(avatar);
    }

    return PetModel(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      edad: json['edad'],
      sexo: json['sexo'] ?? 'macho',
      status: json['status'] ?? 'disponible',
      avatarUrl: avatar,
      fundacionId: json['fundacion_id'],
      tamano: json['tamano'] ?? 'Mediano',
      razaId: json['raza_id'],
      especieId: json['especie_id'],
      galleryUrls: loadedGallery,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'edad': edad,
      'sexo': sexo,
      'status': status,
      'avatar_url': avatarUrl,
      'fundacion_id': fundacionId,
      'tamano': tamano,
      'raza_id': razaId,
      'especie_id': especieId,
    };
  }
}