import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../../auth/presentation/bloc/auth_state.dart';
import '../../bloc/adopter_profile_bloc.dart';
import '../../bloc/adopter_profile_state.dart';
import '../perfil/edit_perfil_adopter_screen.dart';

class TabPerfilAdopter extends StatelessWidget {
  const TabPerfilAdopter({super.key});

  void _onLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro de que deseas salir?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: const Text("Salir", style: TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Datos básicos desde Auth
        final userEmail = (authState is AuthAuthenticated) ? authState.user.email : "cargando...";

        // Datos extendidos desde el perfil del adoptante
        final profileState = context.watch<AdopterProfileBloc>().state;
        String displayName = "Adoptante";
        String? avatarUrl;

        if (profileState is AdopterProfileLoaded) {
          displayName = profileState.adopter.nombre;
          avatarUrl = profileState.adopter.avatarUrl;
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32), // Espacio superior

                  // --- 1. HEADER TIPO TARJETA FLOTANTE ---
                  _buildHorizontalHeader(context, displayName, userEmail, avatarUrl),

                  // --- 2. OPCIONES DE MENÚ ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sección: Mi Cuenta
                        _buildSectionTitle("Mi Cuenta"),
                        const SizedBox(height: 10),
                        _buildMenuContainer([
                          _buildMenuItem(
                            icon: Icons.person_rounded,
                            title: "Editar Perfil",
                            subtitle: "Foto, nombre y teléfono",
                            onTap: () {
                              final state = context.read<AdopterProfileBloc>().state;
                              if (state is AdopterProfileLoaded) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<AdopterProfileBloc>(),
                                      child: EditPerfilAdopterScreen(
                                        adopter: state.adopter,
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                showAppSnackBar(
                                  context,
                                  message: 'Perfil aún cargando...',
                                  type: AppSnackBarType.info,
                                );
                              }
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.folder_shared_rounded,
                            title: "Mis Solicitudes",
                            subtitle: "Estado de tus adopciones",
                            // iconColor removido -> usa el default (Naranja)
                            onTap: () {
                              // TODO: Navegar al Tab de Solicitudes
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.favorite_rounded,
                            title: "Favoritos",
                            subtitle: "Mascotas guardadas",
                            // iconColor removido -> usa el default (Naranja)
                            onTap: () {},
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // Sección: Configuración
                        _buildSectionTitle("Configuración & Ayuda"),
                        const SizedBox(height: 10),
                        _buildMenuContainer([
                          _buildMenuItem(
                            icon: Icons.notifications_none_rounded,
                            title: "Notificaciones",
                            onTap: () {},
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.privacy_tip_outlined,
                            title: "Privacidad y Seguridad",
                            onTap: () {},
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.help_outline_rounded,
                            title: "Ayuda y Soporte",
                            onTap: () {},
                          ),
                        ]),
                        
                        const SizedBox(height: 30),
                        
                        // Versión de la app
                        Center(
                          child: Text(
                            "PetAdopt v1.0.0",
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- WIDGETS COMPONENTES ---

  Widget _buildHorizontalHeader(BuildContext context, String name, String email, String? avatarUrl) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryOrange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. IMAGEN (Izquierda)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : const AssetImage('assets/images/default_profile.png') as ImageProvider,
            ),
          ),
          
          const SizedBox(width: 16),

          // 2. TEXTOS (Centro)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 3. BOTÓN SALIR
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onLogout(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
    Color iconColor = AppTheme.primaryOrange, // Por defecto es Naranja
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
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
              Icon(Icons.chevron_right_rounded, size: 24, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 0.5, color: Colors.grey.shade100, indent: 60);
  }
}