import 'package:flutter/material.dart';
import '/src/core/widgets/role_option_card.dart'; // Importa el widget que acabamos de crear
import 'register_adoptante_screen.dart';
import 'register_fundacion_screen.dart';


class RegisterSelectorScreen extends StatelessWidget {
  const RegisterSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      // Usamos SafeArea para evitar conflictos con el notch/barra de estado
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- ENCABEZADO ---
                const Icon(
                  Icons.app_registration_rounded,
                  size: 64,
                  color: Colors.black87,
                ),
                const SizedBox(height: 24),
                Text(
                  "Crear nueva cuenta",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Para brindarte la mejor experiencia,\nselecciona cómo deseas registrarte.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 48),

                // --- OPCIONES DE REGISTRO ---
                
                // 1. ADOPTANTE
                RoleOptionCard(
                  icon: Icons.person_outline_rounded,
                  title: "Soy Adoptante",
                  description: "Busco adoptar una mascota y darle un hogar lleno de amor.",
                  color: colorScheme.primary, // Usa el Naranja de tu tema
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterAdoptanteScreen(),
                      ),
                    );
                  },
                ),

                // 2. FUNDACIÓN
                RoleOptionCard(
                  icon: Icons.pets_rounded,
                  title: "Soy Fundación",
                  description: "Gestiono refugios, rescato animales y promuevo la adopción.",
                  color: Colors.blueAccent, // Color distintivo para fundaciones
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterFundacionScreen(),
                      ) 
                    );// <--- Conectado
                  },
                ),

                const SizedBox(height: 32),

                // --- FOOTER (SALIDA) ---
                // UX: Siempre es bueno dar una salida si el usuario entró por error
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿Ya tienes una cuenta? ",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context), // Vuelve al Login
                      child: Text(
                        "Inicia Sesión",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}