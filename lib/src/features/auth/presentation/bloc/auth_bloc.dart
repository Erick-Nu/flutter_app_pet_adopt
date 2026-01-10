import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_adoptante_usecase.dart';
import '../../domain/usecases/register_fundacion_usecase.dart';
import '../../domain/usecases/recover_password_usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../../../core/services/logger_service.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterAdoptanteUseCase registerAdoptanteUseCase;
  final RegisterFundacionUseCase registerFundacionUseCase;
  final RecoverPasswordUseCase recoverPasswordUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerAdoptanteUseCase,
    required this.registerFundacionUseCase,
    required this.recoverPasswordUseCase,
    required this.checkAuthStatusUseCase,
  }) : super(AuthInitial()) {
    
    // 1. Login
    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        LoggerService.auth('Ejecutando LoginUseCase', data: {'email': event.email});
        
        // Primero hacemos el login (auth.signInWithPassword)
        await loginUseCase(event.email, event.password);
        
        // DESPUÉS: Usamos el caso de uso para obtener el rol correcto
        // Esto asegura que AuthAuthenticated siempre tenga el 'type' correcto
        final userWithRole = await checkAuthStatusUseCase();
        
        if (userWithRole != null) {
          LoggerService.success('Login exitoso con rol: ${userWithRole.type}', context: 'AuthBloc');
          emit(AuthAuthenticated(userWithRole));
        } else {
          // Caso raro: login exitoso pero falla al obtener datos
          LoggerService.error('Error al obtener perfil de usuario', context: 'AuthBloc');
          emit(AuthError("Error al obtener perfil de usuario"));
        }
      } catch (e) {
        LoggerService.error('Error en login', context: 'AuthBloc', error: e);
        emit(AuthError(e.toString()));
      }
    });

    // 2. Registro Adoptante
    on<AuthRegisterAdoptanteRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await registerAdoptanteUseCase(
          email: event.email,
          password: event.password,
          nombre: event.nombre,
          cedula: event.cedula,
          telefono: event.telefono,
        );
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
    
    // 3. Registro Fundación
    on<AuthRegisterFundacionRequested>((event, emit) async {
        emit(AuthLoading());
      try {
        final user = await registerFundacionUseCase(
          email: event.email,
          password: event.password,
          nombre: event.nombre,
          telefono: event.telefono,
        );
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    // 4. Recuperar Contraseña
    on<AuthRecoverPasswordRequested>(_onRecoverPassword);

    // 5. Verificar Sesión al inicio
    on<AuthCheckStatus>((event, emit) async {
      emit(AuthLoading());
      try {
        LoggerService.auth('Verificando estado de autenticación', data: {});
        
        // Toda la lógica sucia de Supabase.instance... SE BORRA.
        // Ahora es una sola línea limpia:
        final user = await checkAuthStatusUseCase();

        if (user != null) {
          LoggerService.success('Usuario autenticado: ${user.type}', context: 'AuthCheckStatus');
          emit(AuthAuthenticated(user));
        } else {
          LoggerService.info('Sin sesión activa', context: 'AuthCheckStatus');
          emit(AuthUnauthenticated());
        }
      } catch (e, stackTrace) {
        LoggerService.error('Error verificando sesión', context: 'AuthCheckStatus', error: e, stackTrace: stackTrace);
        emit(AuthError('Error verificando sesión: $e'));
        emit(AuthUnauthenticated());
      }
    });

    // 6. Logout
    on<AuthLogoutRequested>((event, emit) async {
      try {
        emit(AuthLoading());
        // Cerrar sesión en Supabase
        await Supabase.instance.client.auth.signOut();
        LoggerService.info('Sesión cerrada exitosamente', context: 'AuthLogoutRequested');
        emit(AuthUnauthenticated()); // Esto dispara el AuthWrapper en main.dart
      } catch (e) {
        LoggerService.error('Error al cerrar sesión', context: 'AuthLogoutRequested', error: e);
        emit(AuthError('Error al cerrar sesión: $e'));
        // Aún así emitimos Unauthenticated para poder hacer logout
        emit(AuthUnauthenticated());
      }
    });
  }

  // ==================== MÉTODOS DE MANEJO DE EVENTOS ====================

  /// 4. Recuperar Contraseña
  Future<void> _onRecoverPassword(
    AuthRecoverPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    LoggerService.section('RECUPERAR CONTRASEÑA - BLoC');
    emit(AuthLoading());
    try {
      LoggerService.auth('Ejecutando RecoverPasswordUseCase', data: {'email': event.email});
      await recoverPasswordUseCase(event.email);
      LoggerService.success('Correo de recuperación enviado', context: 'AuthBloc');
      emit(const AuthRecoverySuccess("Correo de recuperación enviado. Revisa tu bandeja."));
    } catch (e, stackTrace) {
      LoggerService.error('Error en recuperación de contraseña BLoC', context: 'AuthBloc', error: e, stackTrace: stackTrace);
      emit(AuthError(e.toString()));
    }
  }
}