import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../../auth/presentation/bloc/auth_state.dart';

class TabPerfilFundacion extends StatelessWidget {
  const TabPerfilFundacion({super.key});

  void _onLogout(BuildContext context) {
    // Mostrar diálogo de confirmación para ser más profesional
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro de que deseas salir?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Disparar evento de logout
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: Text("Salir", style: TextStyle(color: AppTheme.primaryOrange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Obtenemos el usuario autenticado (si existe)
        final user = (state is AuthAuthenticated) ? state.user : null;
        final userEmail = user?.email ?? "cargando...";
        final userName = user != null
          ? (user.email.contains('@') ? user.email.split('@').first : user.email)
          : "Fundación";
        // Fallback para avatar (no disponible en UserEntity por ahora)
        final String? avatarUrl = null; 

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // --- 1. HEADER (Perfil) ---
                _buildProfileHeader(userName, userEmail, avatarUrl),

                // --- 2. OPCIONES DE MENÚ ---
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección: Cuenta
                      _buildSectionTitle("Mi Organización"),
                      const SizedBox(height: 10),
                      _buildMenuContainer([
                        _buildMenuItem(
                          icon: Icons.edit_outlined,
                          title: "Editar Perfil",
                          subtitle: "Actualiza logo, dirección y contacto",
                          onTap: () {
                            // TODO: Navegar a editar perfil
                          },
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.verified_user_outlined,
                          title: "Verificación",
                          subtitle: "Estado de la cuenta: Verificada",
                          iconColor: Colors.green,
                          onTap: () {},
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Sección: Configuración
                      _buildSectionTitle("Aplicación"),
                      const SizedBox(height: 10),
                      _buildMenuContainer([
                        _buildMenuItem(
                          icon: Icons.notifications_outlined,
                          title: "Notificaciones",
                          onTap: () {},
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.lock_outline,
                          title: "Seguridad y Contraseña",
                          onTap: () {},
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.help_outline,
                          title: "Ayuda y Soporte",
                          onTap: () {},
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Botón Cerrar Sesión
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => _onLogout(context),
                          icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
                          label: const Text(
                            "Cerrar Sesión", 
                            style: TextStyle(
                              color: AppTheme.error, 
                              fontSize: 16, 
                              fontWeight: FontWeight.w600
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.error.withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          "Versión 1.0.0",
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGETS COMPONENTES ---

  Widget _buildProfileHeader(String name, String email, String? avatarUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: const BoxDecoration(
        color: AppTheme.primaryOrange,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Avatar con borde
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : const AssetImage('assets/images/default_profile.png') as ImageProvider,
            ),
          ),
          const SizedBox(height: 16),
          // Nombre
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Email
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              email,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color iconColor = AppTheme.textSecondary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200, indent: 60);
  }
}