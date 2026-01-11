import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../features/pets/domain/entities/pet_entity.dart'; // Importamos la entidad del proyecto

class ChatPetContextCard extends StatelessWidget {
  final PetEntity pet; // <--- Usamos la Entidad Oficial
  final String status; // El estado sigue viniendo de la solicitud (no de la mascota)

  const ChatPetContextCard({
    super.key,
    required this.pet,
    this.status = 'Solicitud Aprobada',
  });

  @override
  Widget build(BuildContext context) {
    // Intentamos obtener la imagen: puede ser avatarUrl o la primera de la galería
    final String? imageToShow = (pet.avatarUrl != null && pet.avatarUrl!.isNotEmpty)
        ? pet.avatarUrl
        : (pet.galleryUrls.isNotEmpty)
            ? pet.galleryUrls.first
            : null;
    
    print('🖼️ ChatPetContextCard - pet.avatarUrl: ${pet.avatarUrl}');
    print('🖼️ ChatPetContextCard - pet.galleryUrls: ${pet.galleryUrls}');
    print('🖼️ ChatPetContextCard - imageToShow: $imageToShow');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. FOTO
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade100,
              image: (imageToShow != null)
                  ? DecorationImage(
                      image: NetworkImage(imageToShow),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (imageToShow == null)
                ? Icon(Icons.pets, size: 35, color: Colors.grey.shade400)
                : null,
          ),
          const SizedBox(width: 16),
          
          // 2. INFORMACIÓN (Extraída de la Entidad)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pet.nombre, // Usamos la entidad
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 8),
                
                // CHIPS DE DATOS (Usando los campos de la entidad)
                Row(
                  children: [
                    // Tamaño
                    _buildInfoChip(Icons.straighten_rounded, pet.tamano ?? 'N/A'), 
                    const SizedBox(width: 8),
                    // Edad
                    _buildInfoChip(Icons.cake_outlined, pet.edad?.toString() ?? 'N/A'),
                    const SizedBox(width: 8),
                    // Sexo
                    _buildInfoChip(
                      (pet.sexo.toLowerCase() == 'macho') ? Icons.male : Icons.female, 
                      pet.sexo
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
      ),
    );
  }
}