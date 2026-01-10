import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/logger_service.dart';
import '../models/catalog_model.dart';

abstract class CatalogRemoteDataSource {
  Future<List<CatalogModel>> getSpecies();
  Future<List<CatalogModel>> getBreeds(int speciesId);
  Future<List<CatalogModel>> getQualities();
  Future<CatalogModel?> getSpeciesById(int id);
  Future<CatalogModel?> getBreedById(int id);
}

class CatalogRemoteDataSourceImpl implements CatalogRemoteDataSource {
  final SupabaseClient supabaseClient;

  CatalogRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<CatalogModel>> getSpecies() async {
    try {
      final response = await supabaseClient
          .from('especies')
          .select()
          .order('nombre', ascending: true); // Orden alfabético

      return (response as List).map((e) => CatalogModel.fromJson(e)).toList();
    } catch (e) {
      LoggerService.error('Error obteniendo especies', context: 'CatalogDataSource', error: e);
      throw Exception('Error al cargar especies: $e');
    }
  }

  @override
  Future<List<CatalogModel>> getBreeds(int speciesId) async {
    try {
      final response = await supabaseClient
          .from('razas')
          .select()
          .eq('especie_id', speciesId) // Filtramos por especie
          .order('nombre', ascending: true);

      return (response as List).map((e) => CatalogModel.fromJson(e)).toList();
    } catch (e) {
      LoggerService.error('Error obteniendo razas', context: 'CatalogDataSource', error: e);
      throw Exception('Error al cargar razas: $e');
    }
  }

  @override
  Future<List<CatalogModel>> getQualities() async {
    try {
      final response = await supabaseClient
          .from('cualidades')
          .select()
          .order('nombre', ascending: true);

      return (response as List).map((e) => CatalogModel.fromJson(e)).toList();
    } catch (e) {
      LoggerService.error('Error obteniendo cualidades', context: 'CatalogDataSource', error: e);
      throw Exception('Error al cargar cualidades: $e');
    }
  }

  @override
  Future<CatalogModel?> getSpeciesById(int id) async {
    try {
      final response = await supabaseClient
          .from('especies')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return CatalogModel.fromJson(response);
    } catch (e) {
      LoggerService.error('Error obteniendo especie por id', context: 'CatalogDataSource', error: e);
      throw Exception('Error al cargar especie: $e');
    }
  }

  @override
  Future<CatalogModel?> getBreedById(int id) async {
    try {
      final response = await supabaseClient
          .from('razas')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return CatalogModel.fromJson(response);
    } catch (e) {
      LoggerService.error('Error obteniendo raza por id', context: 'CatalogDataSource', error: e);
      throw Exception('Error al cargar raza: $e');
    }
  }
}