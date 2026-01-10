import 'dart:io';

class AdopterEntity {
  final String id;
  final String nombre;
  final String cedula;
  final String email;
  final String? telefono;
  final String? avatarUrl;
  final int? edad;
  final String? sexo;
  
  // Archivo para subir avatar nuevo
  final File? newAvatarFile;

  AdopterEntity({
    required this.id,
    required this.nombre,
    required this.cedula,
    required this.email,
    this.telefono,
    this.avatarUrl,
    this.edad,
    this.sexo,
    this.newAvatarFile,
  });

  AdopterEntity copyWith({
    String? nombre,
    String? telefono,
    int? edad,
    String? sexo,
    File? newAvatarFile,
    String? avatarUrl,
  }) {
    return AdopterEntity(
      id: id,
      cedula: cedula, // La cédula no suele cambiar
      email: email,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      edad: edad ?? this.edad,
      sexo: sexo ?? this.sexo,
      newAvatarFile: newAvatarFile ?? this.newAvatarFile,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
