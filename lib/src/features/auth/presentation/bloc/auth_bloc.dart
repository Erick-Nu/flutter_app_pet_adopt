import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_adoptante_usecase.dart';
import '../../domain/usecases/register_fundacion_usecase.dart';
import '../../domain/usecases/recover_password_usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/get_user_role_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/services/logger_service.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterAdoptanteUseCase registerAdoptanteUseCase;
  final RegisterFundacionUseCase registerFundacionUseCase;
  final RecoverPasswordUseCase recoverPasswordUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final GetUserRoleUseCase getUserRoleUseCase;
  final AuthRepository authRepository;
  
  StreamSubscription? _authSubscription;

  AuthBloc({
    required this.loginUseCase,
    required this.registerAdoptanteUseCase,
    required this.registerFundacionUseCase,
    required this.recoverPasswordUseCase,
    required this.checkAuthStatusUseCase,
    required this.getUserRoleUseCase,
    required this.authRepository,
  }) : super(AuthInitial()) {
    _startAuthListener();
    
    // 1. Login
    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        LoggerService.auth('Ejecutando LoginUseCase', data: {'email': event.email});
        await loginUseCase(event.email, event.password);
        final userWithRole = await checkAuthStatusUseCase();
        
        if (userWithRole != null) {
          var resolvedType = userWithRole.type;
          if (resolvedType == null || resolvedType == 'unknown') {
            resolvedType = await getUserRoleUseCase(userWithRole.id);
          }
          final hydratedUser = UserEntity(
            id: userWithRole.id,
            email: userWithRole.email,
            type: resolvedType,
          );

          if (hydratedUser.type == null) {
            LoggerService.info('Usuario autenticado sin perfil. Redirigiendo a selector.', context: 'AuthBloc');
            emit(AuthenticatedNoProfile(hydratedUser));
          } else {
            LoggerService.success('Login exitoso con rol: ${hydratedUser.type}', context: 'AuthBloc');
            emit(AuthAuthenticated(hydratedUser));
          }
        } else {
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

    // 4. Google Sign In
    on<LoginWithGoogleRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        LoggerService.auth('Ejecutando LoginWithGoogleRequested', data: {});
        await authRepository.signInWithGoogle();
        LoggerService.success('Google Sign In iniciado', context: 'AuthBloc');
      } catch (e) {
        LoggerService.error('Error en Google Sign In', context: 'AuthBloc', error: e);
        emit(AuthError(e.toString()));
      }
    });

    // 5. Crear Perfil Google Adoptante
    on<CreateGoogleProfileAdoptante>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          emit(const AuthError('Sesión no encontrada'));
          return;
        }
        
        await authRepository.createAdoptanteProfile(user.id, event.data);
        final userEntity = UserEntity(
          id: user.id,
          email: user.email ?? '',
          type: 'adoptante',
        );
        emit(AuthAuthenticated(userEntity));
      } catch (e) {
        LoggerService.error('Error creando perfil adoptante', context: 'AuthBloc', error: e);
        emit(AuthError(e.toString()));
      }
    });

    // 6. Crear Perfil Google Fundación
    on<CreateGoogleProfileFundacion>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          emit(const AuthError('Sesión no encontrada'));
          return;
        }
        
        await authRepository.createFundacionProfile(user.id, event.data);
        final userEntity = UserEntity(
          id: user.id,
          email: user.email ?? '',
          type: 'fundacion',
        );
        emit(AuthAuthenticated(userEntity));
      } catch (e) {
        LoggerService.error('Error creando perfil fundación', context: 'AuthBloc', error: e);
        emit(AuthError(e.toString()));
      }
    });

    // 7. Recuperar Contraseña
    on<AuthRecoverPasswordRequested>(_onRecoverPassword);

    // 8. Verificar Sesión al inicio
    on<AuthCheckStatus>((event, emit) async {
      emit(AuthLoading());
      try {
        LoggerService.auth('Verificando estado de autenticación', data: {});
        final user = await checkAuthStatusUseCase();

        if (user != null) {
          var resolvedType = user.type;
          if (resolvedType == null || resolvedType == 'unknown') {
            resolvedType = await getUserRoleUseCase(user.id);
          }

          final hydratedUser = UserEntity(
            id: user.id,
            email: user.email,
            type: resolvedType,
          );

          if (hydratedUser.type == null) {
            LoggerService.info('Usuario autenticado sin perfil. Redirigiendo a selector.', context: 'AuthCheckStatus');
            emit(AuthenticatedNoProfile(hydratedUser));
          } else {
            LoggerService.success('Usuario autenticado: ${hydratedUser.type}', context: 'AuthCheckStatus');
            emit(AuthAuthenticated(hydratedUser));
          }
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

    // 9. Logout
    on<AuthLogoutRequested>((event, emit) async {
      try {
        await Supabase.instance.client.auth.signOut();
        LoggerService.info('Sesión cerrada exitosamente', context: 'AuthLogoutRequested');
        emit(AuthUnauthenticated());
      } catch (e) {
        LoggerService.error('Error al cerrar sesión', context: 'AuthLogoutRequested', error: e);
        emit(AuthError('Error al cerrar sesión: $e'));
        emit(AuthUnauthenticated());
      }
    });
  }

  void _startAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        LoggerService.auth('Auth cambió a SignedIn - disparando CheckAuthStatus', data: {});
        add(AuthCheckStatus());
      } else if (event.event == AuthChangeEvent.signedOut) {
        LoggerService.auth('Auth cambió a SignedOut', data: {});
        // No se puede usar emit() fuera de un handler, así que manejamos esto
        // directamente en el handler de AuthLogoutRequested
      }
    });
  }

  // ==================== MÉTODOS DE MANEJO DE EVENTOS ====================

  /// 7. Recuperar Contraseña
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

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
