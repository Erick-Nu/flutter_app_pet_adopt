import '../../domain/entities/adopter_entity.dart';

abstract class AdopterProfileEvent {}

class LoadAdopterProfile extends AdopterProfileEvent {
  final String userId;
  LoadAdopterProfile(this.userId);
}

class UpdateAdopterProfile extends AdopterProfileEvent {
  final AdopterEntity adopter;
  UpdateAdopterProfile(this.adopter);
}
