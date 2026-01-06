import 'dart:io';

class FoundationEntity {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? direccion;
  final String? telefono;
  final String? logoUrl;
  final double? latitud;
  final double? longitud;
  
  // Archivo local para cuando se actualiza el logo
  final File? newLogoFile;

  FoundationEntity({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.direccion,
    this.telefono,
    this.logoUrl,
    this.latitud,
    this.longitud,
    this.newLogoFile,
  });

  // Copiar objeto con cambios (útil para BLoC)
  FoundationEntity copyWith({
    String? nombre,
    String? descripcion,
    String? direccion,
    String? telefono,
    double? latitud,
    double? longitud,
    File? newLogoFile,
    String? logoUrl,
  }) {
    return FoundationEntity(
      id: this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      newLogoFile: newLogoFile ?? this.newLogoFile,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}