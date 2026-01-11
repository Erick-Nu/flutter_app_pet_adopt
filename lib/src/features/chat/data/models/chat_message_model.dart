import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/chat_message_entity.dart';

class ChatMessageModel extends ChatMessageEntity {
  ChatMessageModel({
    required super.id,
    required super.content,
    required super.senderId,
    required super.createdAt,
    super.isMine,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    return ChatMessageModel(
      id: json['id'].toString(),
      content: json['contenido'] ?? '',
      senderId: json['sender_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isMine: json['sender_id'] == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contenido': content,
      'sender_id': senderId,
      // 'chat_id' se agrega en el repositorio
    };
  }
}