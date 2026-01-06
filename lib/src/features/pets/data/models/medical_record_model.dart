import '../../domain/entities/medical_record_entity.dart';

class MedicalRecordModel extends MedicalRecordEntity {
  MedicalRecordModel({
    super.esEsterilizado = false,
    super.esDesparasitado = false,
    super.tieneVacunas = false,
    super.pesoKg = 0.0,
    super.observaciones,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      esEsterilizado: json['es_esterilizado'] ?? false,
      esDesparasitado: json['es_desparasitado'] ?? false,
      tieneVacunas: json['tiene_vacunas_al_dia'] ?? false,
      pesoKg: (json['peso_kg'] ?? 0.0).toDouble(),
      observaciones: json['observaciones_veterinarias'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'es_esterilizado': esEsterilizado,
      'es_desparasitado': esDesparasitado,
      'tiene_vacunas_al_dia': tieneVacunas,
      'peso_kg': pesoKg,
      'observaciones_veterinarias': observaciones,
    };
  }
}
