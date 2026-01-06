import '../../../domain/entities/foundation_entity.dart';

abstract class FoundationProfileEvent {}

class LoadProfile extends FoundationProfileEvent {
  final String userId;
  LoadProfile(this.userId);
}

class UpdateProfileEvent extends FoundationProfileEvent {
  final FoundationEntity foundation;
  UpdateProfileEvent(this.foundation);
}

class PickAddressFromMap extends FoundationProfileEvent {
  final double lat;
  final double lng;
  PickAddressFromMap(this.lat, this.lng);
}
