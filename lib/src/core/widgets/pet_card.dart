import 'package:flutter/material.dart';
import '../../features/pets/domain/entities/pet_entity.dart';
import '../theme/app_theme.dart';

class PetCard extends StatelessWidget {
  final PetEntity pet;
  final VoidCallback onTap;

  const PetCard({
    super.key,
    required this.pet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // LÓGICA DE IMAGEN INTELIGENTE:
    // 1. Intentamos usar el avatar.
    // 2. Si no hay avatar, usamos la primera foto de la galería.
    // 3. Si no hay nada, queda null (y abajo mostramos el icono por defecto).
    String? imageToShow = pet.avatarUrl;
    
    if ((imageToShow == null || imageToShow.isEmpty) && pet.galleryUrls.isNotEmpty) {
      imageToShow = pet.galleryUrls.first;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // IMAGEN A LA IZQUIERDA (Cuadrada)
            Container(
              width: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                child: imageToShow != null && imageToShow.isNotEmpty
                    ? Image.network(
                        imageToShow,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
              ),
            ),
            
            // DETALLES A LA DERECHA
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // NOMBRE Y GÉNERO
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pet.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildGenderBadge(pet.sexo),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // ATRIBUTOS CON ÍCONOS
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildInfoChip(
                          icon: Icons.cake_outlined,
                          label: '${pet.edad ?? '?'} años',
                          color: Colors.purple,
                        ),
                        _buildInfoChip(
                          icon: Icons.straighten,
                          label: pet.tamano ?? 'Mediano',
                          color: Colors.teal,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // ESTADO
                    Row(
                      children: [
                        Expanded(child: _buildStatusBadge(pet.status)),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(Icons.pets, size: 50, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildGenderBadge(String sexo) {
    bool isMale = sexo.toLowerCase() == 'macho';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isMale ? Colors.blue : Colors.pink).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isMale ? Colors.blue : Colors.pink).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        isMale ? Icons.male : Icons.female,
        color: isMale ? Colors.blue : Colors.pink,
        size: 18,
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;
    
    switch (status) {
      case 'adoptado':
        color = Colors.blue;
        label = 'Adoptado';
        icon = Icons.check_circle;
        break;
      case 'en_espera':
        color = Colors.orange;
        label = 'En Espera';
        icon = Icons.schedule;
        break;
      default: // disponible
        color = Colors.green;
        label = 'Disponible';
        icon = Icons.favorite;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}