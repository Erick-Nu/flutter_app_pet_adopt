class MedicalRecordEntity {
  final bool esEsterilizado;
  final bool esDesparasitado;
  final bool tieneVacunas;
  final bool tieneMicrochip;
  final double pesoKg;
  final String? observaciones;

  MedicalRecordEntity({
    this.esEsterilizado = false,
    this.esDesparasitado = false,
    this.tieneVacunas = false,
    this.tieneMicrochip = false,
    this.pesoKg = 0.0,
    this.observaciones,
  });
}