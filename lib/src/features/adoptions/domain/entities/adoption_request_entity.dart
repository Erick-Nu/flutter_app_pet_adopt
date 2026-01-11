class AdoptionRequestEntity {
  final String id;
  final String petId;
  final String adopterId;
  final String foundationId;
  final String status; // 'pendiente', 'aprobada', 'rechazada'
  final DateTime date;
  
  // Datos expandidos para la UI
  final String? petName;
  final String? petImage;
  final String? petSize;
  final String? petAge;
  final String? petSex;
  final String? adopterName;
  final String? adopterAvatar;
  final String? foundationName;
  final String? foundationAvatar;

  AdoptionRequestEntity({
    required this.id,
    required this.petId,
    required this.adopterId,
    required this.foundationId,
    required this.status,
    required this.date,
    this.petName,
    this.petImage,
    this.petSize,
    this.petAge,
    this.petSex,
    this.adopterName,
    this.adopterAvatar,
    this.foundationName,
    this.foundationAvatar,
  });
}
