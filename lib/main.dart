import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'src/core/di/injection_container.dart' as di;
import 'src/core/theme/app_theme.dart';
import 'src/core/utils/snackbar_utils.dart';
import 'src/core/widgets/app_loader.dart';
import 'src/core/services/notification_service.dart';
import 'src/features/auth/presentation/bloc/auth_bloc.dart';
import 'src/features/auth/presentation/bloc/auth_event.dart';
import 'src/features/auth/presentation/bloc/auth_state.dart';
import 'src/features/auth/presentation/screens/welcome_screen.dart';
import 'src/features/adoptions/presentation/screens/home_adopter_screen.dart';
import 'src/features/foundations/presentation/screens/home_foundation_screen.dart';
import 'src/features/pets/presentation/bloc/pet_bloc.dart';
import 'src/features/adoptions/presentation/bloc/adoption_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. ELIMINAMOS dotenv.load(...)

  // 2. LEEMOS LAS VARIABLES DEL COMANDO DE CONSTRUCCIÓN
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Validación de seguridad para que sepas si faltan las keys
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('⚠️ ERROR: No se encontraron las variables de entorno. Asegúrate de usar --dart-define en el comando build.');
  }

  // 3. INICIALIZAMOS SUPABASE CON LAS VARIABLES INYECTADAS
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  await di.initDependencies();

  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetIt.I<AuthBloc>()..add(AuthCheckStatus()),
        ),
        BlocProvider(
          create: (_) => di.sl<PetBloc>(),
        ),
        BlocProvider(
          create: (_) => di.sl<AdoptionBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Pet Adopt',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          showAppSnackBar(
            context,
            message: state.message,
            type: AppSnackBarType.error,
          );
        }
      },
      builder: (context, state) {
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
        
        if (state is AuthAuthenticated) {
          final userType = state.user.type;
          
          if (userType == 'adoptante') {
            return const HomeAdopterScreen();
          } else if (userType == 'fundacion') {
            return const HomeFoundationScreen();
          } else {
            return const WelcomeScreen();
          }
        }
        
        return const WelcomeScreen();
      },
    );
  }
}