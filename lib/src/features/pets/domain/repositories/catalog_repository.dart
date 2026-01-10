import '../entities/catalog_entity.dart';

abstract class CatalogRepository {
  /// Obtiene la lista de especies (Perro, Gato, etc.)
  Future<List<CatalogEntity>> getSpecies();

  /// Obtiene las razas filtradas por el ID de la especie
  Future<List<CatalogEntity>> getBreeds(int speciesId);

  /// Obtiene las cualidades disponibles (Juguetón, Esterilizado, etc.)
  Future<List<CatalogEntity>> getQualities();

  /// Obtiene una especie por su ID
  Future<CatalogEntity?> getSpeciesById(int id);

  /// Obtiene una raza por su ID
  Future<CatalogEntity?> getBreedById(int id);
}