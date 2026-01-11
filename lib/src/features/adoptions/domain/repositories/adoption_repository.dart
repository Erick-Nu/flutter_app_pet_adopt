import '../entities/adoption_request_entity.dart';

abstract class AdoptionRepository {
  Future<void> createRequest({required String petId, required String foundationId, required String adopterId});
  Future<List<AdoptionRequestEntity>> getRequestsForFoundation(String foundationId);
  Future<List<AdoptionRequestEntity>> getRequestsForAdopter(String adopterId);
  Future<void> respondToRequest({required String requestId, required String status, required String petId, required String adopterId, required String foundationId});
}
