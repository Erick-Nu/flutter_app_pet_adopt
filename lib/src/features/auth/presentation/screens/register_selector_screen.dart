import 'package:flutter/material.dart';
import 'register_adoptante_screen.dart';
// import 'register_fundacion_screen.dart'; // Lo crearemos después

class RegisterSelectorScreen extends StatelessWidget {
  const RegisterSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Cuenta"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "¿Cómo deseas registrarte?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Elige el tipo de cuenta que mejor se adapte a ti.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // OPCIÓN 1: ADOPTANTE
            _RoleCard(
              icon: Icons.person_outline,
              title: "Soy Adoptante",
              description: "Busco una mascota para darle un hogar.",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterAdoptanteScreen()),
                );
              },
            ),
            
            const SizedBox(height: 20),

            // OPCIÓN 2: FUNDACIÓN
            _RoleCard(
              icon: Icons.pets,
              title: "Soy Fundación",
              description: "Gestiono adopciones y rescato animales.",
              color: Colors.blueAccent, // Diferente para distinguir
              onTap: () {
                 // TODO: Navegar a pantalla de fundación
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text("Próximamente: Registro Fundación")),
                 );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para las tarjetas (para no repetir código)
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}