import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/location_requirement_dialog.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../pets/presentation/bloc/pet_bloc.dart';
import '../../../../pets/presentation/screens/create_pet/pet_creation_wizard.dart';
import '../../bloc/profile/foundation_profile_bloc.dart';
import '../../bloc/profile/foundation_profile_state.dart';

class TabInicio extends StatelessWidget {
  const TabInicio({super.key});

  void _navigateToCreatePet(BuildContext context) {
    final profileState = context.read<FoundationProfileBloc>().state;

    if (profileState is ProfileLoaded) {
      final f = profileState.foundation;
      // Validar ubicación
      if (f.latitud == null || f.longitud == null || (f.direccion == null || f.direccion!.isEmpty)) {
        showDialog(
          context: context,
          builder: (_) => BlocProvider.value(
            value: context.read<FoundationProfileBloc>(),
            child: LocationRequirementDialog(foundation: f),
          ),
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PetBloc>(),
          child: const PetCreationWizard(),
        ),
      ),
    );
  }

  void _navigateToRequests(BuildContext context) {
    showAppSnackBar(context, message: "Próximamente: Gestión de Solicitudes", type: AppSnackBarType.info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. NUEVO APPBAR PERSONALIZADO ---
              _buildCustomAppBar(context),
              
              const SizedBox(height: 32), // Más espacio para separar

              // 2. TARJETA PRINCIPAL (Publicar Mascota)
              _buildMainActionCard(
                context,
                title: "Publicar Nueva Mascota",
                subtitle: "Ayuda a un peludito a encontrar su hogar ideal hoy mismo.",
                icon: Icons.pets_rounded,
                onTap: () => _navigateToCreatePet(context),
              ),
              const SizedBox(height: 30),

              // 3. ACCIONES RÁPIDAS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Acciones Rápidas",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  // Opcional: Ver todo
                  // TextButton(onPressed: (){}, child: Text("Ver todo"))
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionItem(
                      context,
                      label: "Ver Solicitudes",
                      icon: Icons.assignment_ind_rounded,
                      color: Colors.blue,
                      count: 5, 
                      onTap: () => _navigateToRequests(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionItem(
                      context,
                      label: "Publicar Mascota",
                      icon: Icons.add_a_photo_rounded,
                      color: AppTheme.primaryOrange,
                      onTap: () => _navigateToCreatePet(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 4. RESUMEN
              Text(
                "Resumen General",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  /// Nuevo Header sofisticado con Logo y Notificaciones
  Widget _buildCustomAppBar(BuildContext context) {
    return BlocBuilder<FoundationProfileBloc, FoundationProfileState>(
      builder: (context, state) {
        String name = "Fundación";
        String? logoUrl;
        
        if (state is ProfileLoaded) {
          name = state.foundation.nombre;
          logoUrl = state.foundation.logoUrl;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Textos de Bienvenida
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Bienvenido de nuevo",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22, // Fuente más grande
                      fontWeight: FontWeight.w900, // Extra Bold
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Acciones Derecha (Notificación + Avatar)
            Row(
              children: [
                // Botón Notificaciones
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary, size: 24),
                    onPressed: () {
                      showAppSnackBar(context, message: "Sin notificaciones nuevas", type: AppSnackBarType.info);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // Avatar / Logo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: (logoUrl != null && logoUrl.isNotEmpty)
                          ? NetworkImage(logoUrl)
                          : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainActionCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [AppTheme.primaryOrange, AppTheme.primaryOrange.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryOrange.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int? count,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 30),
                    ),
                    if (count != null && count > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _buildStatCard("Mascotas", "12", Icons.pets, Colors.purple),
        const SizedBox(width: 16),
        _buildStatCard("Adoptados", "45", Icons.home_rounded, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}