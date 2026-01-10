import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/pets/domain/entities/pet_entity.dart';
import '../theme/app_theme.dart';
import '../../features/pets/presentation/bloc/pet_bloc.dart';
import '../../features/pets/presentation/bloc/pet_state.dart';

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
    // Determinamos la imagen a mostrar (fallback a primera de galería)
    String? coverUrl = pet.avatarUrl;
    if ((coverUrl == null || coverUrl.isEmpty) && pet.galleryUrls.isNotEmpty) {
      coverUrl = pet.galleryUrls.first;
    }
    final ImageProvider imageProvider = (coverUrl != null && coverUrl.isNotEmpty)
        ? NetworkImage(coverUrl)
        : const AssetImage('assets/images/default_pet.png');

    return GestureDetector(
      onTap: onTap,
      child: BlocBuilder<PetBloc, PetState>(
        builder: (context, state) {
          // Resolver nombres de especie y raza desde los catálogos cargados
          String? speciesName;
          String? breedName;
          if (pet.especieId != null) {
            for (final c in state.species) {
              if (c.id == pet.especieId) {
                speciesName = c.name;
                break;
              }
            }
          }
          if (pet.razaId != null) {
            for (final c in state.breeds) {
              if (c.id == pet.razaId) {
                breedName = c.name;
                break;
              }
            }
          }

          final speciesLabel = speciesName ?? 'Especie desconocida';
          final breedLabel = pet.razaId != null
              ? (breedName ?? 'Raza desconocida')
              : 'Raza desconocida';

          return Container(
        margin: const EdgeInsets.only(bottom: 16), // Espacio entre tarjetas
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. IMAGEN Y ESTADO (Stack) ---
            Stack(
              children: [
                // Imagen
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Hero(
                    tag: pet.id, // Animación suave al entrar al detalle
                    child: AspectRatio(
                      aspectRatio: 16 / 9, // Formato panorámico profesional
                      child: Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, _, __) => Container(
                          color: Colors.grey.shade100,
                          child: Icon(Icons.pets, size: 50, color: Colors.grey.shade300),
                        ),
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                    : null,
                                color: AppTheme.primaryOrange.withOpacity(0.5),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Badge de Estado (Top Right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildStatusBadge(pet.status),
                ),
              ],
            ),

            // --- 2. INFORMACIÓN ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila Superior: Nombre y Sexo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pet.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3436), // Negro suave profesional
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildGenderIcon(pet.sexo),
                    ],
                  ),
                  
                  const SizedBox(height: 4),

                  // Especie y Raza
                  Text(
                    "$speciesLabel • $breedLabel",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 12),

                  // Fila Inferior: Edad y Tamaño (Metadatos)
                  Row(
                    children: [
                      _buildMetaItem(Icons.calendar_today_rounded, "${pet.edad ?? '?'} meses"),
                      const SizedBox(width: 16),
                      _buildMetaItem(Icons.straighten_rounded, pet.tamano ?? 'N/A'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
        },
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label = status.toUpperCase();

    // Lógica de colores según estado
    switch (status.toLowerCase()) {
      case 'disponible':
        bg = Colors.green.shade50; // Fondo muy suave
        text = Colors.green.shade700; // Texto fuerte
        break;
      case 'adoptado':
        bg = Colors.blue.shade50;
        text = Colors.blue.shade700;
        break;
      case 'en_espera':
        bg = Colors.orange.shade50;
        text = Colors.orange.shade800;
        break;
      default:
        bg = Colors.grey.shade100;
        text = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.95), // Fondo ligado al estado para coherencia visual
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: text, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderIcon(String gender) {
    final isMale = gender.toLowerCase() == 'macho';
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isMale ? Colors.blue.withOpacity(0.1) : Colors.pink.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isMale ? Icons.male : Icons.female,
        size: 18,
        color: isMale ? Colors.blue : Colors.pink,
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}