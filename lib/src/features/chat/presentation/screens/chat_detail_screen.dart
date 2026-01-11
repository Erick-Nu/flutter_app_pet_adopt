import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/chat_floating_header.dart';
import '../../../../core/widgets/chat_pet_context_card.dart';
import '../../../pets/domain/entities/pet_entity.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../bloc/realtime/realtime_chat_bloc.dart';

class ChatDetailScreen extends StatelessWidget {
  // Datos crudos necesarios para el chat
  final String petId;
  final String adopterId;
  final String foundationId;
  final String otherUserName;
  final String? otherUserAvatar;
  
  // La Entidad Mascota (Puede venir construida o la construimos aquí)
  final PetEntity pet;

  ChatDetailScreen({
    super.key,
    required this.petId,
    required this.adopterId,
    required this.foundationId,
    required this.otherUserName,
    this.otherUserAvatar,
    
    // Recibimos los datos sueltos y CONSTRUIMOS la entidad en el constructor
    required String petName,
    String? petImage,
    String? petSize,
    String? petAge,
    String? petSex,
  }) : pet = PetEntity(
          id: petId,
          nombre: petName,
          avatarUrl: petImage,
          tamano: petSize,
          edad: petAge != null ? int.tryParse(petAge) : null,
          sexo: petSex ?? 'Desconocido',
          status: 'Adoptado', 
          fundacionId: foundationId,
          galleryUrls: petImage != null ? [petImage] : [],
        ) {
    print('🖼️ ChatDetailScreen - petImage recibido: $petImage');
    print('🖼️ ChatDetailScreen - petName: $petName, petSize: $petSize, petAge: $petAge, petSex: $petSex');
  }

  Future<PetEntity> _resolvePetImage() async {
    // Si ya tenemos avatar, no hacemos nada
    if (pet.avatarUrl != null && pet.avatarUrl!.isNotEmpty) {
      return pet;
    }
    try {
      print('🔎 ChatDetailScreen: Resolviendo imagen para mascota ${pet.nombre}');
      final gallery = await Supabase.instance.client
          .from('mascota_imagenes')
          .select('imagen_url')
          .eq('mascota_id', petId)
          .limit(1);

      String? firstImage;
      if (gallery.isNotEmpty) {
        final first = gallery.first;
        firstImage = first['imagen_url'] as String?;
      }

      if (firstImage != null && firstImage.isNotEmpty) {
        print('🖼️ ChatDetailScreen: Usando imagen de galería: $firstImage');
        // Reconstruir PetEntity con la imagen encontrada
        return PetEntity(
          id: pet.id,
          nombre: pet.nombre,
          descripcion: pet.descripcion,
          edad: pet.edad,
          sexo: pet.sexo,
          status: pet.status,
          avatarUrl: firstImage,
          fundacionId: pet.fundacionId,
          tamano: pet.tamano,
          razaId: pet.razaId,
          especieId: pet.especieId,
          galleryUrls: [firstImage],
          newAvatarFile: pet.newAvatarFile,
          newGalleryFiles: pet.newGalleryFiles,
          fichaMedica: pet.fichaMedica,
        );
      }
    } catch (e) {
      print('⚠️ ChatDetailScreen: error resolviendo imagen de mascota: $e');
    }
    // Fallback: retornar pet como está
    return pet;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RealtimeChatBloc(
        ChatRepositoryImpl(Supabase.instance.client),
      )..add(InitChat(petId, adopterId, foundationId)),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              // ESPACIO SOLICITADO
              const SizedBox(height: 20),

              // 1. HEADER
              ChatFloatingHeader(
                title: otherUserName,
                avatarUrl: otherUserAvatar,
                onBack: () => Navigator.pop(context),
                onCall: () {},
                onVideoCall: () {},
              ),

              // 2. CONTEXTO MASCOTA (resolver imagen si falta)
              FutureBuilder<PetEntity>(
                future: _resolvePetImage(),
                builder: (context, snapshot) {
                  final showPet = snapshot.data ?? pet;
                  return ChatPetContextCard(pet: showPet);
                },
              ),

              const SizedBox(height: 10),
              
              // 3. CHAT
              Expanded(
                child: BlocBuilder<RealtimeChatBloc, RealtimeChatState>(
                  builder: (context, state) {
                    if (state is ChatLoading) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
                    }
                    if (state is ChatActive) {
                      final messages = state.messages;
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[messages.length - 1 - index];
                          return _MessageBubble(message: message);
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // 4. INPUT
              const _ChatInputArea(),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget Interno: Burbuja de Mensaje
class _MessageBubble extends StatelessWidget {
  final ChatMessageEntity message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isMine ? AppTheme.primaryOrange : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMine ? 16 : 4),
            bottomRight: Radius.circular(message.isMine ? 4 : 16),
          ),
          boxShadow: [
            if (!message.isMine)
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: message.isMine ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// Widget Interno: Área de Input
class _ChatInputArea extends StatefulWidget {
  const _ChatInputArea();

  @override
  State<_ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<_ChatInputArea> {
  final _controller = TextEditingController();

  void _send() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      context.read<RealtimeChatBloc>().add(SendMessage(text));
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "Escribe un mensaje...",
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            height: 44,
            child: ElevatedButton(
              onPressed: _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                elevation: 2,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}