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
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      edad: json['edad'],
      sexo: json['sexo'] ?? 'macho',
      status: json['status'] ?? 'disponible',
      avatarUrl: json['avatar_url'],
      fundacionId: json['fundacion_id'],
      tamano: json['tamano'] ?? 'Mediano',
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
    };
  }
}