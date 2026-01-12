import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/chat_message_entity.dart';
import '../../../data/repositories/chat_repository_impl.dart';
import '../../../../../core/services/logger_service.dart';

// ============================================================================
// EVENTOS
// ============================================================================
abstract class RealtimeChatEvent {}

class InitChat extends RealtimeChatEvent {
  final String petId, adopterId, foundationId;
  InitChat(this.petId, this.adopterId, this.foundationId);
}

class SendMessage extends RealtimeChatEvent { 
  final String content; 
  SendMessage(this.content); 
}

// Evento interno que se dispara cada vez que llega un mensaje nuevo del stream
class _OnMessagesUpdated extends RealtimeChatEvent { 
  final List<ChatMessageEntity> messages; 
  _OnMessagesUpdated(this.messages); 
}

// ============================================================================
// ESTADOS
// ============================================================================
abstract class RealtimeChatState {}

class ChatInitial extends RealtimeChatState {}

class ChatLoading extends RealtimeChatState {}

class ChatActive extends RealtimeChatState { 
  final String chatId;
  final List<ChatMessageEntity> messages;
  ChatActive(this.chatId, this.messages);
}

class ChatError extends RealtimeChatState { 
  final String error; 
  ChatError(this.error); 
}

// ============================================================================
// BLOC
// ============================================================================
class RealtimeChatBloc extends Bloc<RealtimeChatEvent, RealtimeChatState> {
  final ChatRepositoryImpl repository;
  StreamSubscription? _messagesSubscription; // Para controlar la escucha
  String? _currentChatId;

  RealtimeChatBloc(this.repository) : super(ChatInitial()) {
    // 1. Iniciar el chat (Suscribirse al Stream)
    on<InitChat>(_onInitChat);

    // 2. Manejar la actualización de mensajes (Evento Interno)
    on<_OnMessagesUpdated>(_onMessagesUpdated);

    // 3. Enviar Mensaje (SendMessage)
    on<SendMessage>(_onSendMessage);
  }

  /// Inicializa el chat y se suscribe al stream de mensajes
  Future<void> _onInitChat(InitChat event, Emitter<RealtimeChatState> emit) async {
    emit(ChatLoading());
    try {
      LoggerService.info('Inicializando chat', context: 'RealtimeChatBloc');

      // Obtenemos o creamos el ID del chat
      final chatId = await repository.getOrCreateChatId(
        petId: event.petId, 
        adopterId: event.adopterId, 
        foundationId: event.foundationId,
      );

      _currentChatId = chatId;
      LoggerService.info('Chat ID obtenido: $chatId', context: 'RealtimeChatBloc');

      // Cancelar suscripción anterior si existía
      await _messagesSubscription?.cancel();

      // --- AQUÍ ESTÁ LA MAGIA DEL REALTIME ---
      // Nos suscribimos al stream del repositorio
      _messagesSubscription = repository.getMessagesStream(chatId).listen(
        (messages) {
          LoggerService.info('Nuevos mensajes recibidos: ${messages.length}', context: 'RealtimeChatBloc');
          // Cuando llega data nueva, disparamos el evento interno
          add(_OnMessagesUpdated(messages));
        },
        onError: (error) {
          LoggerService.error('Error en stream de chat', context: 'RealtimeChatBloc', error: error);
          add(_OnMessagesUpdated([])); // Emitir lista vacía en caso de error
        },
      );

      LoggerService.success('Escucha de chat iniciada', context: 'RealtimeChatBloc');
    } catch (e) {
      LoggerService.error('Error inicializando chat', context: 'RealtimeChatBloc', error: e);
      emit(ChatError("Error al iniciar chat: $e"));
    }
  }

  /// Actualiza el estado cuando llegan nuevos mensajes
  Future<void> _onMessagesUpdated(_OnMessagesUpdated event, Emitter<RealtimeChatState> emit) async {
    if (_currentChatId != null) {
      emit(ChatActive(_currentChatId!, event.messages));
    }
  }

  /// Envía un mensaje y lo persiste en la BD
  Future<void> _onSendMessage(SendMessage event, Emitter<RealtimeChatState> emit) async {
    if (_currentChatId == null || event.content.trim().isEmpty) {
      LoggerService.warning('Intento de envío inválido', context: 'RealtimeChatBloc');
      return;
    }

    try {
      // Optimistic UI: mostrar el mensaje inmediatamente
      if (state is ChatActive) {
        final current = (state as ChatActive).messages;
        final myId = repository.supabase.auth.currentUser!.id;
        
        // Crear mensaje optimista local
        final optimistic = ChatMessageEntity(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          content: event.content,
          senderId: myId,
          createdAt: DateTime.now(),
          isMine: true,
        );

        emit(ChatActive(_currentChatId!, List<ChatMessageEntity>.from(current)..add(optimistic)));
        LoggerService.info('Mensaje optimista mostrado', context: 'RealtimeChatBloc');
      }

      // Persistir en backend
      // OJO: NO necesitamos hacer emit aquí, el stream lo hará automáticamente
      // cuando Supabase notifique el INSERT.
      await repository.sendMessage(_currentChatId!, event.content);
      LoggerService.success('Mensaje enviado', context: 'RealtimeChatBloc');
    } catch (e) {
      LoggerService.error('Error enviando mensaje', context: 'RealtimeChatBloc', error: e);
      emit(ChatError("Error al enviar mensaje: $e"));
    }
  }

  @override
  Future<void> close() {
    LoggerService.info('Cerrando RealtimeChatBloc', context: 'RealtimeChatBloc');
    _messagesSubscription?.cancel(); // IMPORTANTE: Cerrar la escucha al salir
    return super.close();
  }
}
