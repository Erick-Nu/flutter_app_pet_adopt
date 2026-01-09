import '../../domain/entities/adopter_entity.dart';

class AdopterModel extends AdopterEntity {
  AdopterModel({
    required super.id,
    required super.nombre,
    required super.cedula,
    super.telefono,
    super.avatarUrl,
    super.edad,
    super.sexo,
  });

  /// Factory para convertir el JSON de Supabase en un objeto Dart
  factory AdopterModel.fromJson(Map<String, dynamic> json) {
    return AdopterModel(
      id: json['id'], 
      nombre: json['nombre'] ?? '',
      cedula: json['cedula'] ?? '', 
      telefono: json['telefono'],
      avatarUrl: json['avatar_url'], 
      edad: json['edad'],
      sexo: json['sexo'],
    );
  }

  /// Solo incluimos los campos que permitimos actualizar.
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'edad': edad,
      'sexo': sexo,
    };
  }
}