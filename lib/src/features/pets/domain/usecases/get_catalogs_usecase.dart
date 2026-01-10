import '../entities/catalog_entity.dart';
import '../repositories/catalog_repository.dart';

class GetCatalogsUseCase {
  final CatalogRepository repository;

  GetCatalogsUseCase(this.repository);

  // Métodos individuales para flexibilidad
  Future<List<CatalogEntity>> getSpecies() => repository.getSpecies();
  
  Future<List<CatalogEntity>> getBreeds(int speciesId) => repository.getBreeds(speciesId);
  
  Future<List<CatalogEntity>> getQualities() => repository.getQualities();

  // Nuevos helpers get-by-id
  Future<CatalogEntity?> getSpeciesById(int id) => repository.getSpeciesById(id);
  Future<CatalogEntity?> getBreedById(int id) => repository.getBreedById(id);
}