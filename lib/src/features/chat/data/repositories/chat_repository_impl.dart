import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl {
  final SupabaseClient supabase;

  ChatRepositoryImpl(this.supabase);

  // Obtener ID del chat o crearlo si no existe (Upsert lógico)
  Future<String> getOrCreateChatId({required String petId, required String adopterId, required String foundationId}) async {
    final response = await supabase.from('chats')
        .select('id')
        .eq('mascota_id', petId)
        .eq('adoptante_id', adopterId)
        .eq('fundacion_id', foundationId)
        .maybeSingle();

    if (response != null) return response['id'];

    // Si no existe, lo creamos (aunque la aprobación ya debería haberlo creado)
    final newChat = await supabase.from('chats').insert({
      'mascota_id': petId,
      'adoptante_id': adopterId,
      'fundacion_id': foundationId,
    }).select('id').single();
    
    return newChat['id'];
  }

  // Escuchar mensajes en tiempo real
  Stream<List<ChatMessageEntity>> getMessagesStream(String chatId) {
    final myId = supabase.auth.currentUser!.id;
    
    return supabase
        .from('mensajes')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true) // Orden cronológico
        .map((maps) => maps.map((map) => ChatMessageModel.fromJson(map, myId)).toList());
  }

  Future<void> sendMessage(String chatId, String content) async {
    final myId = supabase.auth.currentUser!.id;
    await supabase.from('mensajes').insert({
      'chat_id': chatId,
      'sender_id': myId,
      'contenido': content,
    });
  }
}