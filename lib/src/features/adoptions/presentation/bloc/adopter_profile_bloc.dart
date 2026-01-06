import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/adopter_repository_impl.dart';
import 'adopter_profile_event.dart';
import 'adopter_profile_state.dart';

class AdopterProfileBloc extends Bloc<AdopterProfileEvent, AdopterProfileState> {
  final AdopterRepositoryImpl repository;

  AdopterProfileBloc(this.repository) : super(AdopterProfileInitial()) {
    on<LoadAdopterProfile>((event, emit) async {
      dev.log('[AdopterProfileBloc] Cargando perfil de adoptante: ${event.userId}');
      emit(AdopterProfileLoading());
      try {
        final adopter = await repository.getProfile(event.userId);
        dev.log('[AdopterProfileBloc] Perfil cargado exitosamente: ${adopter.nombre}');
        emit(AdopterProfileLoaded(adopter));
      } catch (e) {
        dev.log('[AdopterProfileBloc] Error al cargar perfil', error: e);
        emit(AdopterProfileError(e.toString()));
      }
    });

    on<UpdateAdopterProfile>((event, emit) async {
      dev.log('[AdopterProfileBloc] Actualizando perfil: ${event.adopter.nombre}');
      emit(AdopterProfileLoading());
      try {
        await repository.updateProfile(event.adopter);
        dev.log('[AdopterProfileBloc] Perfil actualizado exitosamente');
        emit(AdopterProfileLoaded(event.adopter));
      } catch (e) {
        dev.log('[AdopterProfileBloc] Error al actualizar perfil', error: e);
        emit(AdopterProfileError(e.toString()));
      }
    });
  }
}
