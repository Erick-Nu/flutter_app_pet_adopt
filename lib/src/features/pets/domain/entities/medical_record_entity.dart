class MedicalRecordEntity {
  final bool esEsterilizado;
  final bool esDesparasitado;
  final bool tieneVacunas;
  final double pesoKg;
  final String? observaciones;

  MedicalRecordEntity({
    this.esEsterilizado = false,
    this.esDesparasitado = false,
    this.tieneVacunas = false,
    this.pesoKg = 0.0,
    this.observaciones,
  });
}