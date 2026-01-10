import '../../domain/entities/catalog_entity.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_data_source.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogRemoteDataSource remoteDataSource;

  CatalogRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CatalogEntity>> getSpecies() async {
    return await remoteDataSource.getSpecies();
  }

  @override
  Future<List<CatalogEntity>> getBreeds(int speciesId) async {
    return await remoteDataSource.getBreeds(speciesId);
  }

  @override
  Future<List<CatalogEntity>> getQualities() async {
    return await remoteDataSource.getQualities();
  }

  @override
  Future<CatalogEntity?> getSpeciesById(int id) async {
    return await remoteDataSource.getSpeciesById(id);
  }

  @override
  Future<CatalogEntity?> getBreedById(int id) async {
    return await remoteDataSource.getBreedById(id);
  }
}