import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/role_option_card.dart';
import 'register_adoptante_screen.dart';
import 'register_fundacion_screen.dart';
import 'login_screen.dart';
import '../../domain/entities/user_entity.dart';

class RegisterSelectorScreen extends StatelessWidget {
    final bool isGoogleAuth;
    final UserEntity? googleUser;
    
    const RegisterSelectorScreen({
      super.key,
      this.isGoogleAuth = false,
      this.googleUser,
    });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Elige tu perfil",
                  textAlign: TextAlign.center,
                  style: AppTheme.lightTheme.textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Selecciona el tipo de cuenta que mejor se adapte a tus necesidades para comenzar.",
                  textAlign: TextAlign.center,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 48),

                // OPCIÓN 1: ADOPTANTE (DESTACADA)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: RoleOptionCard(
                    isPrimary: true, // <--- ESTO LA PONE NARANJA CON TEXTO BLANCO
                    icon: Icons.person_rounded,
                    title: "Quiero Adoptar",
                    description: "Busco un nuevo amigo y compañero de vida.",
                    color: AppTheme.primaryOrange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegisterAdoptanteScreen(
                            isGoogleAuth: isGoogleAuth,
                            googleUser: googleUser,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // OPCIÓN 2: FUNDACIÓN (ESTÁNDAR)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: RoleOptionCard(
                    isPrimary: false, // <--- ESTA SE QUEDA BLANCA
                    icon: Icons.volunteer_activism_rounded,
                    title: "Soy Fundación",
                    description: "Gestiono adopciones y rescate de animales.",
                    color: AppTheme.primaryOrange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegisterFundacionScreen(
                            isGoogleAuth: isGoogleAuth,
                            googleUser: googleUser,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 48),

                // FOOTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿Ya tienes una cuenta? ",
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                         color: AppTheme.textSecondary
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(builder: (_) => const LoginScreen())
                        );
                      },
                      child: Text(
                        "Inicia Sesión",
                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryOrange,
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