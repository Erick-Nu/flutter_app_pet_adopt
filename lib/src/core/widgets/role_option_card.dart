import 'package:flutter/material.dart';

class RoleOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? color;
  final VoidCallback onTap;
  final bool isPrimary; // Nueva propiedad para destacar la tarjeta

  const RoleOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.color,
    this.isPrimary = false, // Por defecto es blanca
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainColor = color ?? theme.colorScheme.primary;

    // Definimos los colores según el estado isPrimary
    final backgroundColor = isPrimary ? mainColor : Colors.white;
    final titleColor = isPrimary ? Colors.white : Colors.black87;
    final descriptionColor = isPrimary ? Colors.white.withOpacity(0.9) : Colors.grey.shade600;
    final iconBgColor = isPrimary ? Colors.white : mainColor.withOpacity(0.1);
    
    // Icono dentro del círculo: si es primary, el icono es naranja y el fondo blanco
    final iconInnerColor = isPrimary ? mainColor : mainColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: isPrimary 
            ? null // Sin borde si es sólido
            : Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(isPrimary ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: isPrimary ? Colors.white.withOpacity(0.2) : mainColor.withOpacity(0.1),
          highlightColor: isPrimary ? Colors.white.withOpacity(0.1) : mainColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                // Ícono
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: iconInnerColor,
                  ),
                ),
                const SizedBox(width: 20),
                
                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: descriptionColor,
                          height: 1.4,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Flecha indicadora
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: isPrimary ? Colors.white.withOpacity(0.5) : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}