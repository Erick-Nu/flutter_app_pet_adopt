import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/map_location_picker.dart';
import '../../../domain/entities/foundation_entity.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../bloc/profile/foundation_profile_event.dart';
import '../../bloc/profile/foundation_profile_state.dart';
import '../../bloc/profile/foundation_profile_bloc.dart';

class TabProfile extends StatefulWidget {
  const TabProfile({super.key});

  @override
  State<TabProfile> createState() => _TabProfileState();
}

class _TabProfileState extends State<TabProfile> with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  
  // Controllers
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  File? _newLogoFile;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    
    final userId = Supabase.instance.client.auth.currentUser!.id;
    context.read<FoundationProfileBloc>().add(LoadProfile(userId));
  }

  @override
  void dispose() {
    _animController.dispose();
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _enableEditing(FoundationEntity foundation) {
    setState(() {
      _isEditing = true;
      _nombreCtrl.text = foundation.nombre;
      _descCtrl.text = foundation.descripcion ?? '';
      _phoneCtrl.text = foundation.telefono ?? '';
      _addressCtrl.text = foundation.direccion ?? '';
      _selectedLocation = LatLng(
        foundation.latitud ?? -0.1807,
        foundation.longitud ?? -78.4678
      );
    });
    _animController.forward();
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _newLogoFile = null;
    });
    _animController.reverse();
  }

  void _saveChanges(FoundationEntity original) {
    final updated = original.copyWith(
      nombre: _nombreCtrl.text,
      descripcion: _descCtrl.text,
      telefono: _phoneCtrl.text,
      direccion: _addressCtrl.text,
      latitud: _selectedLocation?.latitude,
      longitud: _selectedLocation?.longitude,
      newLogoFile: _newLogoFile,
    );
    
    context.read<FoundationProfileBloc>().add(UpdateProfileEvent(updated));
    _animController.reverse();
    setState(() => _isEditing = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _newLogoFile = File(picked.path));
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('¿Cerrar sesión?'),
          ],
        ),
        content: const Text('Tendrás que ingresar tus datos nuevamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoundationProfileBloc, FoundationProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
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
        
        if (state is ProfileError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  "Error al cargar perfil",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    final userId = Supabase.instance.client.auth.currentUser!.id;
                    context.read<FoundationProfileBloc>().add(LoadProfile(userId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        
        if (state is ProfileLoaded) {
          final foundation = state.foundation;
          final displayLocation = LatLng(
            foundation.latitud ?? -0.1807, 
            foundation.longitud ?? -78.4678
          );

          return RefreshIndicator(
            onRefresh: () async {
              final userId = Supabase.instance.client.auth.currentUser!.id;
              context.read<FoundationProfileBloc>().add(LoadProfile(userId));
            },
            child: CustomScrollView(
              slivers: [
                // HEADER MODERNO CON LOGO
                SliverToBoxAdapter(
                  child: _buildModernHeader(foundation),
                ),

                // CONTENIDO PRINCIPAL
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (!_isEditing) ...[
                        _buildInfoSection(foundation, displayLocation),
                        const SizedBox(height: 24),
                        _buildActionsSection(foundation),
                      ] else ...[
                        _buildEditSection(foundation),
                      ],
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
          );
        }
        
        return Container();
      },
    );
  }

  Widget _buildModernHeader(FoundationEntity foundation) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryOrange,
            AppTheme.primaryOrange.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 20),
            // LOGO CON ANIMACIÓN
            GestureDetector(
              onTap: _isEditing ? _pickImage : null,
              child: Hero(
                tag: 'foundation_logo',
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage: _newLogoFile != null
                            ? FileImage(_newLogoFile!) as ImageProvider
                            : (foundation.logoUrl != null 
                                ? NetworkImage(foundation.logoUrl!) 
                                : null),
                        child: foundation.logoUrl == null && _newLogoFile == null
                            ? Icon(Icons.business, size: 60, color: Colors.grey.shade400) 
                            : null,
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        right: 5,
                        bottom: 5,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // NOMBRE Y DIRECCIÓN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    foundation.nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                    ),
                  ),
                  if (foundation.direccion != null && foundation.direccion!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            foundation.direccion!,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(FoundationEntity foundation, LatLng displayLocation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // INFORMACIÓN BÁSICA
        const Text(
          'Información de Contacto',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildModernInfoCard(
          icon: Icons.phone_rounded,
          title: 'Teléfono',
          value: foundation.telefono ?? 'No registrado',
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildModernInfoCard(
          icon: Icons.info_outline,
          title: 'Sobre nosotros',
          value: foundation.descripcion ?? 'Sin descripción',
          color: Colors.blue,
          maxLines: 4,
        ),
        
        // UBICACIÓN
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.map_outlined, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Nuestra Ubicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: MapLocationPicker(
            initialCenter: displayLocation,
            isReadOnly: true,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(FoundationEntity foundation) {
    return Column(
      children: [
        // BOTÓN EDITAR PERFIL
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryOrange, AppTheme.primaryOrange.withOpacity(0.8)],
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
              onTap: () => _enableEditing(foundation),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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
        
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        
        // OPCIONES ADICIONALES
        _buildMenuOption(
          icon: Icons.settings_outlined,
          title: 'Configuración',
          subtitle: 'Preferencias y ajustes',
          onTap: () {},
        ),
        _buildMenuOption(
          icon: Icons.help_outline,
          title: 'Ayuda y Soporte',
          subtitle: 'Preguntas frecuentes',
          onTap: () {},
        ),
        _buildMenuOption(
          icon: Icons.logout,
          title: 'Cerrar Sesión',
          subtitle: 'Salir de tu cuenta',
          color: Colors.red,
          onTap: _showLogoutDialog,
        ),
      ],
    );
  }

  Widget _buildEditSection(FoundationEntity foundation) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER MODO EDICIÓN
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modo Edición',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Actualiza la información de tu fundación',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancelEditing,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // FORMULARIO
          TextFormField(
            controller: _nombreCtrl,
            decoration: InputDecoration(
              labelText: "Nombre de la Fundación",
              prefixIcon: const Icon(Icons.business),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: "Descripción",
              hintText: "Cuéntanos sobre tu fundación...",
              prefixIcon: const Icon(Icons.description),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Teléfono de Contacto",
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 24),
          
          // SECCIÓN DE UBICACIÓN
          const Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                "Ubicación",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressCtrl,
            decoration: InputDecoration(
              labelText: "Dirección",
              hintText: "Ej: Av. Amazonas y Naciones Unidas",
              prefixIcon: const Icon(Icons.location_city),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: MapLocationPicker(
              initialCenter: _selectedLocation!,
              isReadOnly: false,
              onPositionChanged: (pos) {
                setState(() => _selectedLocation = pos);
                context.read<FoundationProfileBloc>().add(
                  PickAddressFromMap(pos.latitude, pos.longitude),
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),
          
          // BOTONES DE ACCIÓN
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _cancelEditing,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _saveChanges(foundation),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text('Guardar Cambios', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    int maxLines = 2,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? Colors.grey.shade700;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: itemColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: itemColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
