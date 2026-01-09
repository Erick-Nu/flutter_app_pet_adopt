import '../../domain/entities/adopter_entity.dart';

abstract class AdopterProfileState {}

class AdopterProfileInitial extends AdopterProfileState {}

class AdopterProfileLoading extends AdopterProfileState {}

class AdopterProfileLoaded extends AdopterProfileState {
  final AdopterEntity adopter;
  AdopterProfileLoaded(this.adopter);
}

class AdopterProfileError extends AdopterProfileState {
  final String message;
  AdopterProfileError(this.message);
}