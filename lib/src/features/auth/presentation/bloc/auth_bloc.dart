import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_adoptante_usecase.dart';
import '../../domain/usecases/register_fundacion_usecase.dart';
import '../../domain/usecases/recover_password_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/logger_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterAdoptanteUseCase registerAdoptanteUseCase;
  final RegisterFundacionUseCase registerFundacionUseCase;
  final RecoverPasswordUseCase recoverPasswordUseCase;
  late final AuthRepository _authRepository;

  AuthBloc({
    required this.loginUseCase,
    required this.registerAdoptanteUseCase,
    required this.registerFundacionUseCase,
    required this.recoverPasswordUseCase,
    AuthRepository? authRepository,
  }) : super(AuthInitial()) {
    _authRepository = authRepository ?? GetIt.I<AuthRepository>();
    
    // 1. Login
    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await loginUseCase(event.email, event.password);
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
          direccion: event.direccion,
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
      try {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      } catch (_) {
        emit(AuthUnauthenticated());
      }
    });

    // 6. Logout
    on<AuthLogoutRequested>((event, emit) async {
      await _authRepository.logout();
      emit(AuthUnauthenticated());
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