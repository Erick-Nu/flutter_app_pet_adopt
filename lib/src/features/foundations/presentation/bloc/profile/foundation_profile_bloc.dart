import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import '../../../data/repositories/foundation_repository_impl.dart';
import 'foundation_profile_event.dart';
import 'foundation_profile_state.dart';

class FoundationProfileBloc extends Bloc<FoundationProfileEvent, FoundationProfileState> {
  final FoundationRepositoryImpl repository;

  FoundationProfileBloc(this.repository) : super(ProfileInitial()) {
    
    on<LoadProfile>((event, emit) async {
      emit(ProfileLoading());
      try {
        final profile = await repository.getProfile(event.userId);
        emit(ProfileLoaded(profile));
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    });

    on<UpdateProfileEvent>((event, emit) async {
      emit(ProfileLoading());
      try {
        await repository.updateProfile(event.foundation);
        // Recargamos los datos frescos
        add(LoadProfile(event.foundation.id));
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    });

    on<PickAddressFromMap>((event, emit) async {
      if (state is ProfileLoaded) {
        final currentProfile = (state as ProfileLoaded).foundation;
        
        // Geocodificación Inversa: De Coordenadas -> Dirección texto
        String newAddress = currentProfile.direccion ?? '';
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(event.lat, event.lng);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            newAddress = "${p.street}, ${p.subLocality}, ${p.locality}";
          }
        } catch (_) {}

        // Emitimos el perfil actualizado localmente (sin guardar en BD aún)
        emit(ProfileLoaded(currentProfile.copyWith(
          latitud: event.lat,
          longitud: event.lng,
          direccion: newAddress, // Actualizamos el campo de texto automáticamente
        )));
      }
    });
  }
}
