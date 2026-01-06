import '../../../domain/entities/foundation_entity.dart';

abstract class FoundationProfileState {}

class ProfileInitial extends FoundationProfileState {}

class ProfileLoading extends FoundationProfileState {}

class ProfileLoaded extends FoundationProfileState {
  final FoundationEntity foundation;
  ProfileLoaded(this.foundation);
}

class ProfileError extends FoundationProfileState {
  final String message;
  ProfileError(this.message);
}
