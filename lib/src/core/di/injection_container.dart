import 'package:get_it/get_it.dart';

// Imports de tus capas
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_adoptante_usecase.dart';
import '../../features/auth/domain/usecases/register_fundacion_usecase.dart';
import '../../features/auth/domain/usecases/recover_password_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../services/supabase_service.dart';
import '../../features/pets/presentation/bloc/pet_bloc.dart';
import '../../features/pets/domain/repositories/pet_repository.dart';
import '../../features/pets/domain/usecases/create_pet_usecase.dart';
import '../../features/pets/domain/usecases/delete_pet_usecase.dart';
import '../../features/pets/domain/usecases/get_pets_usecase.dart';
import '../../features/pets/data/repositories/pet_repository_impl.dart';
import '../../features/pets/data/datasources/pet_remote_data_source.dart';


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
  ));

  sl.registerFactory(() => PetBloc(
        getPetsUseCase: sl(),
        createPetUseCase: sl(),
        deletePetUseCase: sl(),
  ));

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterAdoptanteUseCase(sl()));
  sl.registerLazySingleton(() => RegisterFundacionUseCase(sl()));
  sl.registerLazySingleton(() => RecoverPasswordUseCase(sl()));

  // Use Cases
  sl.registerLazySingleton(() => GetPetsUseCase(sl()));
  sl.registerLazySingleton(() => CreatePetUseCase(sl()));
  sl.registerLazySingleton(() => DeletePetUseCase(sl()));

  // Repository
  sl.registerLazySingleton<PetRepository>(() => PetRepositoryImpl(sl()));

  // Data Source
  sl.registerLazySingleton(() => PetRemoteDataSource(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // Data Source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
}