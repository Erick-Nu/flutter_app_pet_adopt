import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/message.dart';
import '../../data/services/gemini_service.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final GeminiService _geminiService;
  final List<Message> _messages = [];

  ChatCubit(this._geminiService) : super(ChatInitial()) {
    // Mensaje de bienvenida claro sobre el alcance
    _messages.add(Message(
      text: "¡Hola! Soy PetBot 🐶🐱. \n\nEstoy aquí exclusivamente para ayudarte con dudas sobre adopción, cuidado de mascotas y salud animal. ¿En qué te puedo orientar hoy?",
      isUser: false,
      timestamp: DateTime.now()
    ));
    emit(ChatLoaded(List.from(_messages)));
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    // Guardar historial previo (excluyendo el mensaje actual que vamos a añadir)
    final previousMessages = List<Message>.from(_messages);
    
    // Agregar mensaje usuario a la UI
    _messages.add(Message(text: message, isUser: true, timestamp: DateTime.now()));
    emit(ChatLoading(List.from(_messages)));

    try {
      // Llamada al servicio
      final response = await _geminiService.sendMessage(message, previousMessages);
      
      // Agregar respuesta IA
      _messages.add(Message(text: response, isUser: false, timestamp: DateTime.now()));
      emit(ChatLoaded(List.from(_messages)));
    } catch (e) {
      // Manejo de error elegante en el chat
      _messages.add(Message(text: "Lo siento, tuve un problema de conexión. Inténtalo de nuevo.", isUser: false, timestamp: DateTime.now()));
      emit(ChatLoaded(List.from(_messages))); // Volvemos a loaded para mostrar el error como mensaje
    }
  }

  void clearChat() {
    _messages.clear();
    _messages.add(Message(
      text: "¡Chat limpiado! 🗑️\n\n¿Tienes alguna otra consulta sobre tus mascotas?",
      isUser: false,
      timestamp: DateTime.now()
    ));
    emit(ChatLoaded(List.from(_messages)));
  }
}
