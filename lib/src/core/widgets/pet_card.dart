import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PetCard extends StatelessWidget {
  final String name;
  final String breed;
  final String age;
  final String sex; // 'Macho' o 'Hembra'
  final String? imageUrl; // Opcional por si no tiene foto aún
  final String status;    // 'En Adopción', 'Adoptado', etc.
  final Color statusColor;
  final VoidCallback? onTap;
  final String? heroTag;

  const PetCard({
    super.key,
    required this.name,
    required this.breed,
    required this.age,
    required this.sex,
    this.imageUrl,
    required this.status,
    this.statusColor = AppTheme.primaryOrange,
    this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130, // Altura fija para consistencia
        margin: const EdgeInsets.only(bottom: 16),
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
            // 1. Imagen de la Mascota
            Hero(
              tag: heroTag ?? 'pet_$name', // Animación bonita al navegar
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  color: Colors.grey.shade200,
                  image: imageUrl != null && imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(imageUrl!), // Usar CachedNetworkImage en producción
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null || imageUrl!.isEmpty
                    ? Icon(Icons.pets, size: 40, color: Colors.grey.shade400)
                    : null,
              ),
            ),

            // 2. Información
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge de Estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // Nombre y Raza
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      breed,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),

                    // Datos Rápidos (Edad y Sexo)
                    Row(
                      children: [
                        _buildInfoIcon(Icons.cake, age),
                        const SizedBox(width: 12),
                        _buildInfoIcon(
                          sex == 'Macho' ? Icons.male : Icons.female, 
                          sex,
                          color: sex == 'Macho' ? Colors.blue : Colors.pink,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3. Flecha de acción
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, String text, {Color color = Colors.grey}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}