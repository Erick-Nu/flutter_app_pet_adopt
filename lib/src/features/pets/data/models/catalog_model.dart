import '../../domain/entities/catalog_entity.dart';

class CatalogModel extends CatalogEntity {
  const CatalogModel({
    required super.id,
    required super.name,
  });

  factory CatalogModel.fromJson(Map<String, dynamic> json) {
    return CatalogModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['nombre'] ?? '', // Mapeamos 'nombre' de la BD a 'name' de la entidad
    );
  }
}