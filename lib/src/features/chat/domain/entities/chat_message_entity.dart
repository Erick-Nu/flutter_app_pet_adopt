class ChatMessageEntity {
  final String id;
  final String content;
  final String senderId;
  final DateTime createdAt;
  final bool isMine; // Helper para la UI

  ChatMessageEntity({
    required this.id,
    required this.content,
    required this.senderId,
    required this.createdAt,
    this.isMine = false,
  });
}