import '../entities/adopter_entity.dart';
abstract class AdopterRepository {
  /// Obtiene el perfil de un adoptante por su ID de usuario
  Future<AdopterEntity> getAdopterProfile(String userId);
  /// Actualiza la información del adoptante y retorna la entidad actualizada
  Future<AdopterEntity> updateAdopterProfile(AdopterEntity adopter);
}