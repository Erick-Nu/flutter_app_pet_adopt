import 'package:flutter/material.dart';

class RoleOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? color;
  final VoidCallback onTap;

  const RoleOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      // Decoración con sombra suave y bordes redondeados (Card moderna)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.08), // Sombra tintada con el color del rol
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
          // Splash color sutil
          splashColor: cardColor.withOpacity(0.1),
          highlightColor: cardColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                // Ícono con fondo suave
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: cardColor,
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
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                          height: 1.4, // Mejor legibilidad
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Flecha indicadora (Affordance de click)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}