import 'dart:io';
import 'medical_record_entity.dart';

class PetEntity {
  final String id;
  final String nombre;
  final String? descripcion;
  final int? edad;
  final String sexo; 
  final String status;
  final String? avatarUrl;
  final String fundacionId;
  final String? tamano;
  // URLs públicas de la galería de imágenes asociadas
  final List<String> galleryUrls;
  
  // --- CAMPOS TRANSITORIOS (Para el formulario) ---
  final File? newAvatarFile; // Archivo físico para subir
  final List<File>? newGalleryFiles; // Galería
  final MedicalRecordEntity? fichaMedica; // Datos médicos

  PetEntity({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.edad,
    required this.sexo,
    required this.status,
    this.avatarUrl,
    required this.fundacionId,
    this.tamano,
    this.galleryUrls = const [],
    this.newAvatarFile,
    this.newGalleryFiles,
    this.fichaMedica,
  });
}