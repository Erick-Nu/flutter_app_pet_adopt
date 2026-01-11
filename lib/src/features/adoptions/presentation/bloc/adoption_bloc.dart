import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/adoption_request_entity.dart';
import '../../domain/repositories/adoption_repository.dart';

abstract class AdoptionEvent {}
class LoadFoundationRequests extends AdoptionEvent { final String foundationId; LoadFoundationRequests(this.foundationId); }
class CreateRequestEvent extends AdoptionEvent { 
  final String petId, foundationId, adopterId;
  CreateRequestEvent(this.petId, this.foundationId, this.adopterId);
}
class RespondRequestEvent extends AdoptionEvent {
  final AdoptionRequestEntity request;
  final bool accepted;
  RespondRequestEvent(this.request, this.accepted);
}

abstract class AdoptionState {}
class AdoptionInitial extends AdoptionState {}
class AdoptionLoading extends AdoptionState {}
class AdoptionLoaded extends AdoptionState { final List<AdoptionRequestEntity> requests; AdoptionLoaded(this.requests); }
class AdoptionActionSuccess extends AdoptionState { 
  final String message; 
  final bool openChat; 
  AdoptionActionSuccess(this.message, {this.openChat = false});
}
class AdoptionError extends AdoptionState { final String message; AdoptionError(this.message); }

class AdoptionBloc extends Bloc<AdoptionEvent, AdoptionState> {
  final AdoptionRepository repository;
  final NotificationService notificationService = NotificationService();

  AdoptionBloc(this.repository) : super(AdoptionInitial()) {
    on<LoadFoundationRequests>(_onLoadFoundationRequests);
    on<CreateRequestEvent>(_onCreateRequest);
    on<RespondRequestEvent>(_onRespondRequest);
  }

  Future<void> _onLoadFoundationRequests(LoadFoundationRequests event, Emitter<AdoptionState> emit) async {
    emit(AdoptionLoading());
    try {
      final reqs = await repository.getRequestsForFoundation(event.foundationId);
      emit(AdoptionLoaded(reqs));
    } catch (e) {
      emit(AdoptionError("Error cargando solicitudes: $e"));
    }
  }

  Future<void> _onCreateRequest(CreateRequestEvent event, Emitter<AdoptionState> emit) async {
    emit(AdoptionLoading());
    try {
      await repository.createRequest(petId: event.petId, foundationId: event.foundationId, adopterId: event.adopterId);
      emit(AdoptionActionSuccess("Solicitud enviada con éxito"));
      notificationService.showNotification("Solicitud Enviada", "La fundación ha recibido tu interés.");
    } catch (e) {
      emit(AdoptionError(e.toString()));
    }
  }

  Future<void> _onRespondRequest(RespondRequestEvent event, Emitter<AdoptionState> emit) async {
    emit(AdoptionLoading());
    try {
      final status = event.accepted ? 'aprobada' : 'rechazada';
      await repository.respondToRequest(
        requestId: event.request.id,
        status: status,
        petId: event.request.petId,
        adopterId: event.request.adopterId,
        foundationId: event.request.foundationId
      );

      if (event.accepted) {
         emit(AdoptionActionSuccess("Solicitud Aceptada. Chat habilitado.", openChat: true));
      } else {
         emit(AdoptionActionSuccess("Solicitud Rechazada."));
      }
      add(LoadFoundationRequests(event.request.foundationId));
    } catch (e) {
      emit(AdoptionError("Error al responder: $e"));
    }
  }
}
