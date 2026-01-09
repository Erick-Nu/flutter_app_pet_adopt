import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../domain/entities/adopter_entity.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../bloc/adopter_profile.dart';
import '../perfil/edit_perfil_adopter_screen.dart';

class TabPerfilAdopter extends StatefulWidget {
  const TabPerfilAdopter({super.key});

  @override
  State<TabPerfilAdopter> createState() => _TabPerfilAdopterState();
}

class _TabPerfilAdopterState extends State<TabPerfilAdopter> {
  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser!.id;
    context.read<AdopterProfileBloc>().add(LoadAdopterProfile(userId));
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro de que deseas cerrar sesión?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: BlocListener<AdopterProfileBloc, AdopterProfileState>(
          listener: (context, state) {
            if (state is AdopterProfileLoaded) {
              showAppSnackBar(
                context,
                message: "Perfil actualizado correctamente",
                type: AppSnackBarType.success,
              );
              // Recargar el perfil
              final userId = Supabase.instance.client.auth.currentUser!.id;
              context.read<AdopterProfileBloc>().add(LoadAdopterProfile(userId));
            } else if (state is AdopterProfileError) {
              showAppSnackBar(
                context,
                message: "Error: ${state.message}",
                type: AppSnackBarType.error,
              );
            }
          },
          child: BlocBuilder<AdopterProfileBloc, AdopterProfileState>(
            builder: (context, state) {
              if (state is AdopterProfileLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cargando perfil...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              if (state is AdopterProfileError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        "Error al cargar perfil",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          final userId = Supabase.instance.client.auth.currentUser!.id;
                          context.read<AdopterProfileBloc>().add(LoadAdopterProfile(userId));
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              if (state is AdopterProfileLoaded) {
                final adopter = state.adopter;

                return RefreshIndicator(
                  onRefresh: () async {
                    final userId = Supabase.instance.client.auth.currentUser!.id;
                    context.read<AdopterProfileBloc>().add(LoadAdopterProfile(userId));
                  },
                  color: AppTheme.primaryOrange,
                  child: CustomScrollView(
                    slivers: [
                      // HEADER CON AVATAR
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryOrange,
                                AppTheme.primaryOrange.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage: (adopter.avatarUrl != null &&
                                        adopter.avatarUrl!.isNotEmpty
                                    ? NetworkImage(adopter.avatarUrl!)
                                        as ImageProvider
                                    : null),
                                child: (adopter.avatarUrl == null ||
                                        adopter.avatarUrl!.isEmpty)
                                    ? const Icon(Icons.person,
                                        size: 60, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                adopter.nombre,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Adoptante Verificado',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // CONTENIDO PRINCIPAL
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // INFORMACIÓN PERSONAL
                              const Text(
                                'Información Personal',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildModernInfoCard(
                                icon: Icons.credit_card_rounded,
                                title: 'Cédula',
                                value: adopter.cedula,
                                color: AppTheme.primaryOrange,
                              ),
                              const SizedBox(height: 12),
                              _buildModernInfoCard(
                                icon: Icons.phone_rounded,
                                title: 'Teléfono',
                                value: adopter.telefono ?? 'No registrado',
                                color: Colors.green,
                              ),
                              const SizedBox(height: 12),
                              _buildModernInfoCard(
                                icon: Icons.cake_rounded,
                                title: 'Edad',
                                value: adopter.edad?.toString() ?? 'No registrada',
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 12),
                              _buildModernInfoCard(
                                icon: Icons.wc_rounded,
                                title: 'Género',
                                value: adopter.sexo ?? 'No registrado',
                                color: Colors.purple,
                              ),
                              const SizedBox(height: 32),
                              _buildActionsSection(adopter),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const Center(child: Text("No hay datos"));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(AdopterEntity adopter) {
    return Column(
      children: [
        // BOTÓN EDITAR
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryOrange,
                AppTheme.primaryOrange.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOrange.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<AdopterProfileBloc>(),
                      child: EditPerfilAdopterScreen(adopter: adopter),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Editar Perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // BOTÓN CERRAR SESIÓN
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade300, width: 1.5),
            color: Colors.red.shade50,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded,
                      color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
