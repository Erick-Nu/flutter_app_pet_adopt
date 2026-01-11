import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/chat_message_entity.dart';
import '../../../data/repositories/chat_repository_impl.dart';

// Eventos
abstract class RealtimeChatEvent {}
class InitChat extends RealtimeChatEvent {
  final String petId, adopterId, foundationId;
  InitChat(this.petId, this.adopterId, this.foundationId);
}
class SendMessage extends RealtimeChatEvent { final String content; SendMessage(this.content); }
class _OnNewMessages extends RealtimeChatEvent { final List<ChatMessageEntity> messages; _OnNewMessages(this.messages); }

// Estados
abstract class RealtimeChatState {}
class ChatInitial extends RealtimeChatState {}
class ChatLoading extends RealtimeChatState {}
class ChatActive extends RealtimeChatState { 
  final String chatId;
  final List<ChatMessageEntity> messages;
  ChatActive(this.chatId, this.messages);
}
class ChatError extends RealtimeChatState { final String error; ChatError(this.error); }

class RealtimeChatBloc extends Bloc<RealtimeChatEvent, RealtimeChatState> {
  final ChatRepositoryImpl repository;
  StreamSubscription? _subscription;
  String? _currentChatId;

  RealtimeChatBloc(this.repository) : super(ChatInitial()) {
    on<InitChat>(_onInitChat);
    on<SendMessage>(_onSendMessage);
    on<_OnNewMessages>((event, emit) {
      emit(ChatActive(_currentChatId!, event.messages));
    });
  }

  Future<void> _onInitChat(InitChat event, Emitter<RealtimeChatState> emit) async {
    emit(ChatLoading());
    try {
      final chatId = await repository.getOrCreateChatId(
        petId: event.petId, adopterId: event.adopterId, foundationId: event.foundationId
      );
      _currentChatId = chatId;
      
      // Cancelar suscripción previa si existe
      _subscription?.cancel();
      // Iniciar escucha real
      _subscription = repository.getMessagesStream(chatId).listen((messages) {
        add(_OnNewMessages(messages));
      });
    } catch (e) {
      emit(ChatError("Error al iniciar chat: $e"));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<RealtimeChatState> emit) async {
    if (_currentChatId != null && event.content.trim().isNotEmpty) {
      // Optimistic UI: mostrar el mensaje inmediatamente
      if (state is ChatActive) {
        final current = (state as ChatActive).messages;
        final myId = repository.supabase.auth.currentUser!.id;
        final optimistic = ChatMessageEntity(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          content: event.content,
          senderId: myId,
          createdAt: DateTime.now(),
          isMine: true,
        );
        emit(ChatActive(_currentChatId!, List<ChatMessageEntity>.from(current)..add(optimistic)));
      }

      // Persistir en backend
      await repository.sendMessage(_currentChatId!, event.content);
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}