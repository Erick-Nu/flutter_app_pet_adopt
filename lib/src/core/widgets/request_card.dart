import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/adoptions/domain/entities/adoption_request_entity.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';

class RequestCard extends StatelessWidget {
  final AdoptionRequestEntity request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isAdopterView; // <--- NUEVA PROPIEDAD

  const RequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
    this.isAdopterView = false, // Por defecto es false (vista de fundación)
  });

  @override
  Widget build(BuildContext context) {
    final bool isPending = request.status == 'pendiente';
    final bool isApproved = request.status == 'aprobada';

    // LÓGICA DE VISUALIZACIÓN:
    // Si es vista de adoptante -> Muestra datos de la Fundación
    // Si es vista de fundación -> Muestra datos del Adoptante
    final String displayName = isAdopterView 
        ? (request.foundationName ?? "Fundación") 
        : (request.adopterName ?? "Usuario");
        
    final String? displayAvatar = isAdopterView 
        ? request.foundationAvatar 
        : request.adopterAvatar;

    // Etiqueta secundaria (ej: "Fundación" o "Interesado en")
    final String subtitlePrefix = isAdopterView ? "Mascota: " : "Interesado en ";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // 1. FILA PRINCIPAL (Horizontal)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // A. Avatar (Fundación o Adoptante según el modo)
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  image: DecorationImage(
                    image: (displayAvatar != null && displayAvatar.isNotEmpty)
                        ? NetworkImage(displayAvatar)
                        : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // B. Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName, // Nombre dinámico
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        children: [
                          TextSpan(text: subtitlePrefix),
                          TextSpan(
                            text: request.petName ?? "una mascota",
                            style: const TextStyle(
                              color: AppTheme.primaryOrange, 
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // C. ESTADO Y ACCIONES (Lado Derecho)
              if (isApproved) ...[
                // Estado Aprobado
                _buildSquareButton(
                  icon: Icons.check_rounded,
                  color: Colors.green,
                  isAction: false,
                ),
                const SizedBox(width: 8),
                // Botón Chat (Visible para ambos)
                _buildSquareButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: const Color(0xFF2D3436),
                  isAction: true,
                  isFilled: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          petId: request.petId,
                          adopterId: request.adopterId,
                          foundationId: request.foundationId,
                          petName: request.petName ?? 'Mascota',
                          petImage: request.petImage,
                          petSize: request.petSize,
                          petAge: request.petAge,
                          petSex: request.petSex,
                          // Datos dinámicos (Quién es el "otro" en el chat)
                          otherUserName: isAdopterView 
                              ? (request.foundationName ?? 'Fundación')
                              : (request.adopterName ?? 'Usuario'),
                          otherUserAvatar: isAdopterView 
                              ? request.foundationAvatar 
                              : request.adopterAvatar,
                        ),
                      ),
                    );
                  },
                ),
              ] else ...[
                _buildStatusIcon(request.status),
              ]
            ],
          ),

          // 2. ACCIONES INFERIORES (Solo si está pendiente)
          // Si es Adoptante y está pendiente, mostramos un mensaje de espera
          if (isPending) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 8),
            
            if (!isAdopterView) 
              _buildIconActions() // Botones Aceptar/Rechazar (Solo Fundación)
            else 
              _buildWaitingMessage(), // Mensaje "Esperando respuesta" (Solo Adoptante)
          ]
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildWaitingMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        "Esperando respuesta de la fundación...",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Construye un botón o icono cuadrado de 44x44
  Widget _buildSquareButton({
    required IconData icon,
    required Color color,
    bool isAction = false,
    bool isFilled = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44, 
          height: 44,
          decoration: BoxDecoration(
            color: isFilled ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon, 
            size: 22, 
            color: isFilled ? Colors.white : color
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    // Si es rechazado -> Rojo
    if (status == 'rechazada') {
      return _buildSquareButton(
        icon: Icons.close_rounded, // Icono X
        color: Colors.redAccent,
      );
    }
    // Si es pendiente -> Naranja
    return _buildSquareButton(
      icon: Icons.access_time_rounded, // Icono Reloj
      color: Colors.orange,
    );
  }

  Widget _buildIconActions() {
    return Row(
      children: [
        // Botón Rechazar
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextButton.icon(
              onPressed: onReject,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                backgroundColor: Colors.red.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.close_rounded, size: 20),
              label: const Text("Rechazar"),
            ),
          ),
        ),
        const SizedBox(width: 10),
        
        // Botón Aceptar
        Expanded(
          child: SizedBox(
            height: 40,
            child: FilledButton.icon(
              onPressed: onAccept,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text("Aceptar"),
            ),
          ),
        ),
      ],
    );
  }
}