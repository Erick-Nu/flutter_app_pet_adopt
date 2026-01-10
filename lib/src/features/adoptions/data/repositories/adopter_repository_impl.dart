import '../../domain/entities/adopter_entity.dart';
import '../../domain/repositories/adopter_repository.dart';
import '../datasources/adopter_remote_data_source.dart';
import '../models/adopter_model.dart';

class AdopterRepositoryImpl implements AdopterRepository {
  // Inyectamos el DataSource que acabamos de crear
  final AdopterRemoteDataSource remoteDataSource;

  AdopterRepositoryImpl(this.remoteDataSource);

  @override
  Future<AdopterEntity> getAdopterProfile(String userId) async {
    // Simplemente delegamos la llamada. 
    // El DataSource devuelve un AdopterModel, que es válido porque extiende de AdopterEntity.
    return await remoteDataSource.getAdopterProfile(userId);
  }

  @override
  Future<AdopterEntity> updateAdopterProfile(AdopterEntity adopter) async {
    String? currentAvatarUrl = adopter.avatarUrl;

    // 1. LÓGICA DE COORDINACIÓN: ¿Hay una foto nueva por subir?
    if (adopter.newAvatarFile != null) {
      // Si hay archivo local, lo subimos primero al Storage
      currentAvatarUrl = await remoteDataSource.uploadAvatar(
        adopter.id, 
        adopter.newAvatarFile!
      );
    }

    // 2. Preparamos el Modelo con la URL correcta (la nueva o la que ya tenía)
    // Convertimos la Entidad (Domain) a Modelo (Data)
    final adopterModel = AdopterModel(
      id: adopter.id,
      nombre: adopter.nombre,
      cedula: adopter.cedula,
      email: adopter.email,
      telefono: adopter.telefono,
      avatarUrl: currentAvatarUrl, // Aquí va la URL actualizada (si cambió)
      edad: adopter.edad,
      sexo: adopter.sexo,
    );

    // 3. Guardamos los datos en la Base de Datos
    return await remoteDataSource.updateAdopterProfile(adopterModel);
  }
}