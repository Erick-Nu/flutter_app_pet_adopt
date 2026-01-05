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
    authRepository: sl(),
  ));

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterAdoptanteUseCase(sl()));
  sl.registerLazySingleton(() => RegisterFundacionUseCase(sl()));
  sl.registerLazySingleton(() => RecoverPasswordUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // Data Source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
}