import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/adopter_repository.dart';
import 'adopter_profile_event.dart';
import 'adopter_profile_state.dart';

class AdopterProfileBloc extends Bloc<AdopterProfileEvent, AdopterProfileState> {
  final AdopterRepository repository;

  AdopterProfileBloc({required this.repository}) : super(AdopterProfileInitial()) {
    
    on<LoadAdopterProfile>((event, emit) async {
      emit(AdopterProfileLoading());
      try {
        final adopter = await repository.getAdopterProfile(event.userId);
        emit(AdopterProfileLoaded(adopter));
      } catch (e) {
        emit(AdopterProfileError(e.toString()));
      }
    });

    on<UpdateAdopterProfile>((event, emit) async {
      emit(AdopterProfileLoading());
      try {
        final updatedAdopter = await repository.updateAdopterProfile(event.adopter);
        emit(AdopterProfileLoaded(updatedAdopter));
      } catch (e) {
        emit(AdopterProfileError(e.toString()));
      }
    });
  }
}