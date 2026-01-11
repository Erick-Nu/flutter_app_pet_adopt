import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChatFloatingHeader extends StatelessWidget {
  final String title;
  final String? avatarUrl;
  final VoidCallback onBack;
  final VoidCallback onCall;
  final VoidCallback onVideoCall;

  const ChatFloatingHeader({
    super.key,
    required this.title,
    this.avatarUrl,
    required this.onBack,
    required this.onCall,
    required this.onVideoCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange, // 1. Fondo del Widget: Naranja
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryOrange.withOpacity(0.4), // Sombra naranja difusa
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // 2. Flecha Atrás (Icono Blanco)
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white, // Fondo blanco semitransparente
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.primaryOrange),
            ),
          ),
          const SizedBox(width: 12),

          // 3. Avatar (Con borde blanco para resaltar)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                  ? NetworkImage(avatarUrl!)
                  : const AssetImage('assets/images/default_profile.png') as ImageProvider,
            ),
          ),
          const SizedBox(width: 12),

          // 4. Nombre del Adoptante (Texto Blanco)
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white, // Blanco puro
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 5. Botones de Acción (Fondo Blanco, Icono Naranja)
          _buildActionButton(Icons.phone_rounded, onCall),
          const SizedBox(width: 8),
          _buildActionButton(Icons.videocam_rounded, onVideoCall),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white, // Fondo Blanco para contrastar
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: AppTheme.primaryOrange), // Icono Naranja
      ),
    );
  }
}