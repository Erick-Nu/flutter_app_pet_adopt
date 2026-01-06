import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Imports de tu arquitectura
import 'src/core/di/injection_container.dart' as di;
import 'src/core/services/supabase_service.dart';
import 'src/core/theme/app_theme.dart'; // Importamos el tema
import 'src/features/auth/presentation/bloc/auth_bloc.dart';
import 'src/features/auth/presentation/screens/welcome_screen.dart'; // Importamos Welcome
import 'src/features/adoptions/presentation/screens/home_adopter_screen.dart';
import 'src/features/foundations/presentation/screens/home_foundation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // 2. Inicializar Supabase y Dependencias
  await SupabaseService.initialize();
  await di.initDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Inyectamos el AuthBloc globalmente
        BlocProvider(create: (_) => di.sl<AuthBloc>()..add(AuthCheckStatus())),
      ],
      child: MaterialApp(
        title: 'PetAdopt',
        debugShowCheckedModeBanner: false,
        
        // APLICAMOS EL TEMA NARANJA AQUÍ
        theme: AppTheme.lightTheme, 
        
        // Enrutamos según estado de autenticación
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (state is AuthAuthenticated) {
              final userType = state.user.type;
              if (userType == 'adoptante') {
                return const HomeAdopterScreen();
              }
              if (userType == 'fundacion') {
                return const HomeFoundationScreen();
              }
            }

            // Default: bienvenida para no autenticados o estados iniciales
            return const WelcomeScreen();
          },
        ),
      ),
    );
  }
}