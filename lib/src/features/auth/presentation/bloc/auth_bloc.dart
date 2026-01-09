import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_adoptante_usecase.dart';
import '../../domain/usecases/register_fundacion_usecase.dart';
import '../../domain/usecases/recover_password_usecase.dart';
import '../../../../core/services/logger_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterAdoptanteUseCase registerAdoptanteUseCase;
  final RegisterFundacionUseCase registerFundacionUseCase;
  final RecoverPasswordUseCase recoverPasswordUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerAdoptanteUseCase,
    required this.registerFundacionUseCase,
    required this.recoverPasswordUseCase,
  }) : super(AuthInitial()) {
    
    // 1. Login
    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await loginUseCase(event.email, event.password);
        
        // Verificar el rol del usuario en la BD
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          // A) Buscar en Fundaciones
          final fundacionData = await Supabase.instance.client
              .from('fundaciones')
              .select()
              .eq('id', userId)
              .maybeSingle();

          if (fundacionData != null) {
            final userWithType = UserEntity(
              id: user.id,
              email: user.email,
              type: 'fundacion',
            );
            emit(AuthAuthenticated(userWithType));
            return;
          }

          // B) Buscar en Adoptantes
          final adoptanteData = await Supabase.instance.client
              .from('adoptantes')
              .select()
              .eq('id', userId)
              .maybeSingle();

          if (adoptanteData != null) {
            final userWithType = UserEntity(
              id: user.id,
              email: user.email,
              type: 'adoptante',
            );
            emit(AuthAuthenticated(userWithType));
            return;
          }

          // Si no aparece en ninguna tabla
          emit(AuthError('Usuario no tiene perfil asignado.'));
          emit(AuthUnauthenticated());
          return;
        }
        
        emit(AuthAuthenticated(user));
      } catch (e) {
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
        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          final userId = session.user.id;
          final email = session.user.email;

          LoggerService.auth('Verificando sesión', data: {'userId': userId});

          // 1. Intentar buscar en tabla fundaciones
          final foundationData = await Supabase.instance.client
              .from('fundaciones')
              .select()
              .eq('id', userId)
              .maybeSingle();

          if (foundationData != null) {
            LoggerService.success('Usuario identificado como Fundación', context: 'AuthCheckStatus');
            final user = UserEntity(id: userId, email: email ?? '', type: 'fundacion');
            emit(AuthAuthenticated(user));
            return;
          }

          // 2. Intentar buscar en tabla adoptantes
          final adopterData = await Supabase.instance.client
              .from('adoptantes')
              .select()
              .eq('id', userId)
              .maybeSingle();

          if (adopterData != null) {
            LoggerService.success('Usuario identificado como Adoptante', context: 'AuthCheckStatus');
            final user = UserEntity(id: userId, email: email ?? '', type: 'adoptante');
            emit(AuthAuthenticated(user));
            return;
          }

          // Si no está en ninguno (raro), logout
          LoggerService.warning('Usuario sin tipo definido', context: 'AuthCheckStatus');
          emit(AuthUnauthenticated());
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