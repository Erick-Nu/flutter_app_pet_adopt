import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

// Imports de tu arquitectura
import 'src/core/di/injection_container.dart' as di;
import 'src/core/theme/app_theme.dart';
import 'src/core/utils/snackbar_utils.dart';
import 'src/core/widgets/app_loader.dart';
import 'src/features/auth/presentation/bloc/auth_bloc.dart';
import 'src/features/auth/presentation/screens/welcome_screen.dart';
import 'src/features/adoptions/presentation/screens/home_adopter_screen.dart';
import 'src/features/foundations/presentation/screens/home_foundation_screen.dart';
import 'src/features/pets/presentation/bloc/pet_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Intentar leer variables vía --dart-define (producción)
  var supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  var supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

  // 2. Si están vacías, fallback a .env (desarrollo local)
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    await dotenv.load(fileName: ".env");
    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  // 3. Validar que tengamos las credenciales
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Las variables SUPABASE_URL y SUPABASE_ANON_KEY no están configuradas. '
      'Opción 1: Pásalas con --dart-define al compilar (producción). '
      'Opción 2: Configura .env en desarrollo.',
    );
  }

  debugPrint('✅ Inicializando Supabase con URL: $supabaseUrl');

  // 4. Inicializar Supabase y Dependencias
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  await di.initDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // AuthBloc: Verifica sesión al iniciar
        BlocProvider(
          create: (_) => GetIt.I<AuthBloc>()..add(AuthCheckStatus()),
        ),
        // PetBloc: Disponible en ambas pantallas
        BlocProvider(
          create: (_) => di.sl<PetBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Pet Adopt',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Usar AuthWrapper para manejar la navegación
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Widget que gestiona la navegación basada en el estado de autenticación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Mostrar errores si los hay
        if (state is AuthError) {
          showAppSnackBar(
            context,
            message: state.message,
            type: AppSnackBarType.error,
          );
        }
      },
      builder: (context, state) {
        // 1. Verificando sesión (splash screen)
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppLoader(),
                  SizedBox(height: 20),
                  Text('Cargando...'),
                ],
              ),
            ),
          );
        }

        // 2. Usuario autenticado - redirigir según tipo de usuario
        if (state is AuthAuthenticated) {
          final userType = state.user.type;
          
          if (userType == 'adoptante') {
            return const HomeAdopterScreen();
          } else if (userType == 'fundacion') {
            return const HomeFoundationScreen();
          } else {
            // Tipo de usuario desconocido - mostrar welcome
            return const WelcomeScreen();
          }
        }

        // 3. Por defecto (no autenticado o estado inicial)
        return const WelcomeScreen();
      },
    );
  }
}