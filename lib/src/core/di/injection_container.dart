import 'package:get_it/get_it.dart';

// Imports de tus capas
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_adoptante_usecase.dart';
import '../../features/auth/domain/usecases/register_fundacion_usecase.dart';
import '../../features/auth/domain/usecases/recover_password_usecase.dart';
import '../../features/auth/domain/usecases/check_auth_status_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../services/supabase_service.dart';
import '../../features/pets/presentation/bloc/pet_bloc.dart';
import '../../features/pets/domain/repositories/pet_repository.dart';
import '../../features/pets/domain/usecases/create_pet_usecase.dart';
import '../../features/pets/domain/usecases/delete_pet_usecase.dart';
import '../../features/pets/domain/usecases/get_pets_usecase.dart';
import '../../features/pets/domain/usecases/get_all_available_pets_usecase.dart';
import '../../features/pets/domain/usecases/update_pet_usecase.dart';
import '../../features/pets/data/repositories/pet_repository_impl.dart';
import '../../features/pets/data/datasources/pet_remote_data_source.dart';
import '../../features/pets/data/datasources/catalog_remote_data_source.dart';
import '../../features/pets/data/repositories/catalog_repository_impl.dart';
import '../../features/pets/domain/repositories/catalog_repository.dart';
import '../../features/pets/domain/usecases/get_catalogs_usecase.dart';
import '../../features/adoptions/presentation/bloc/adopter_profile_bloc.dart';
import '../../features/adoptions/domain/repositories/adopter_repository.dart';
import '../../features/adoptions/data/repositories/adopter_repository_impl.dart';
import '../../features/adoptions/data/datasources/adopter_remote_data_source.dart';


final sl = GetIt.instance; // Service Locator

Future<void> initDependencies() async {
  
  // 1. External (Supabase Client)
  // Nota: Supabase se inicializa en el main, aquí solo recuperamos la instancia
  sl.registerLazySingleton(() => SupabaseService.client);

  // ================= FEATURE: AUTH =================

  // Bloc
  sl.registerFactory(() => AuthBloc(
    loginUseCase: sl(),
    registerAdoptanteUseCase: sl(),
    registerFundacionUseCase: sl(),
    recoverPasswordUseCase: sl(),
    checkAuthStatusUseCase: sl(),
  ));

  sl.registerFactory(() => PetBloc(
    getPetsUseCase: sl(),
    createPetUseCase: sl(),
    deletePetUseCase: sl(),
    updatePetUseCase: sl(),
    getAllAvailablePetsUseCase: sl(),
    checkAuthStatusUseCase: sl(),
    getCatalogsUseCase: sl(),
  ));

  sl.registerFactory(() => AdopterProfileBloc(repository: sl()));

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterAdoptanteUseCase(sl()));
  sl.registerLazySingleton(() => RegisterFundacionUseCase(sl()));
  sl.registerLazySingleton(() => RecoverPasswordUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));

  // Use Cases
  sl.registerLazySingleton(() => GetAllAvailablePetsUseCase(sl()));
  sl.registerLazySingleton(() => GetPetsUseCase(sl()));
  sl.registerLazySingleton(() => CreatePetUseCase(sl()));
  sl.registerLazySingleton(() => DeletePetUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePetUseCase(sl()));
  sl.registerLazySingleton(() => GetCatalogsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<PetRepository>(() => PetRepositoryImpl(sl()));

  // Data Source
  sl.registerLazySingleton(() => PetRemoteDataSource(sl()));

  // Repository de Catálogos
  sl.registerLazySingleton<CatalogRepository>(
    () => CatalogRepositoryImpl(sl()),
  );

  // Data Source de Catálogos
  sl.registerLazySingleton<CatalogRemoteDataSource>(
    () => CatalogRemoteDataSourceImpl(sl()),
  );

  // ================= FEATURE: ADOPTIONS =================
  
  // Repository
  sl.registerLazySingleton<AdopterRepository>(
    () => AdopterRepositoryImpl(sl()),
  );

  // Data Source
  sl.registerLazySingleton<AdopterRemoteDataSource>(
    () => AdopterRemoteDataSourceImpl(sl()),
  );

  // ================= FEATURE: AUTH =================
  
  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // Data Source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
}