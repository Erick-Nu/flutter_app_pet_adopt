import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../chat/data/models/message.dart';
import '../../../../chat/data/services/gemini_service.dart';
import '../../../../chat/data/services/tts_service.dart';
import '../../../../chat/presentation/bloc/chat_cubit.dart';
import '../../../../chat/presentation/bloc/chat_state.dart';

class TabChatAdopter extends StatelessWidget {
  const TabChatAdopter({super.key});

  @override
  Widget build(BuildContext context) {
    // Inyectamos el Cubit aquí localmente para este Tab
    return BlocProvider(
      create: (context) => ChatCubit(GeminiService()),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TtsService _ttsService = TtsService();
  String? _speakingMessageId;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      context.read<ChatCubit>().sendMessage(text);
      _controller.clear();
    }
  }

  void _toggleSpeak(String messageId, String text) async {
    if (_speakingMessageId == messageId && _ttsService.isSpeaking) {
      await _ttsService.stop();
      setState(() => _speakingMessageId = null);
    } else {
      await _ttsService.speak(text);
      setState(() => _speakingMessageId = messageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Asistente IA 🐾', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.primaryOrange),
            onPressed: () => context.read<ChatCubit>().clearChat(),
            tooltip: 'Limpiar chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // LISTA DE MENSAJES
          Expanded(
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                final messages = switch (state) {
                  ChatInitial() => <Message>[],
                  ChatLoading(messages: var m) => m,
                  ChatLoaded(messages: var m) => m,
                  ChatError(messages: var m) => m,
                };

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (state is ChatLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (state is ChatLoading && index == messages.length) {
                      return const _TypingIndicator();
                    }
                    final message = messages[index];
                    final messageId = '${message.timestamp.millisecondsSinceEpoch}';
                    
                    return _MessageBubble(
                      message: message,
                      isSpeaking: _speakingMessageId == messageId,
                      onSpeak: () => _toggleSpeak(messageId, message.text),
                    );
                  },
                );
              },
            ),
          ),

          // INPUT
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Pregunta sobre cuidados, razas...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  BlocBuilder<ChatCubit, ChatState>(
                    builder: (context, state) {
                      final isLoading = state is ChatLoading;
                      return FloatingActionButton(
                        onPressed: isLoading ? null : _sendMessage,
                        backgroundColor: AppTheme.primaryOrange,
                        mini: true,
                        elevation: 2,
                        child: isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSpeaking;
  final VoidCallback onSpeak;

  const _MessageBubble({required this.message, required this.isSpeaking, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryOrange.withOpacity(0.1),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.smart_toy, size: 20, color: AppTheme.primaryOrange),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryOrange : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  if (!isUser) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isUser
                      ? Text(message.text, style: const TextStyle(color: Colors.white))
                      : MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(color: AppTheme.textPrimary),
                            strong: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                  if (!isUser) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onSpeak,
                      child: Icon(
                        isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                        size: 18,
                        color: isSpeaking ? AppTheme.primaryOrange : Colors.grey,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
      child: Row(
        children: [
          const Text("Escribiendo...", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(width: 8),
          SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1, color: Colors.grey)),
        ],
      ),
    );
  }
}
