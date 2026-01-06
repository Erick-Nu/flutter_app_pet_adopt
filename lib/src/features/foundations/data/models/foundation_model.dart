import '../../domain/entities/foundation_entity.dart';

class FoundationModel extends FoundationEntity {
  FoundationModel({
    required super.id,
    required super.nombre,
    super.descripcion,
    super.direccion,
    super.telefono,
    super.logoUrl,
    super.latitud,
    super.longitud,
  });

  factory FoundationModel.fromJson(Map<String, dynamic> json) {
    return FoundationModel(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      direccion: json['direccion'],
      telefono: json['telefono'],
      logoUrl: json['logo_url'],
      latitud: json['latitud'] != null ? (json['latitud'] as num).toDouble() : null,
      longitud: json['longitud'] != null ? (json['longitud'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'direccion': direccion,
      'telefono': telefono,
      'logo_url': logoUrl,
      'latitud': latitud,
      'longitud': longitud,
    };
  }
}