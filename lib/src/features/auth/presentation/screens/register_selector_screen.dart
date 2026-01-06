import 'package:flutter/material.dart';
// CORRECCIÓN 1: Usamos la ruta relativa correcta (subimos 4 niveles hasta llegar a src)
// O mejor aún, usamos la ruta del paquete que es más segura:
import 'package:flutter_app_pet_adopt/src/core/widgets/role_option_card.dart';

import 'register_adoptante_screen.dart';
import 'register_fundacion_screen.dart'; // CORRECCIÓN 2: Ya podemos usar esta pantalla

class RegisterSelectorScreen extends StatelessWidget {
  const RegisterSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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

                // OPCIÓN 1: ADOPTANTE
                RoleOptionCard(
                  icon: Icons.person_outline_rounded,
                  title: "Soy Adoptante",
                  description: "Busco adoptar una mascota y darle un hogar lleno de amor.",
                  color: colorScheme.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterAdoptanteScreen(),
                      ),
                    );
                  },
                ),

                // OPCIÓN 2: FUNDACIÓN
                RoleOptionCard(
                  icon: Icons.pets_rounded,
                  title: "Soy Fundación",
                  description: "Gestiono refugios, rescato animales y promuevo la adopción.",
                  color: Colors.blueAccent,
                  onTap: () {
                    // CORRECCIÓN 3: Navegación conectada correctamente
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterFundacionScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // FOOTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿Ya tienes una cuenta? ",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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