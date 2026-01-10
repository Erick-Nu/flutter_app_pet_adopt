import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/map_location_picker.dart'; // Asegúrate de tener este widget
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../domain/entities/foundation_entity.dart';
import '../../bloc/profile/foundation_profile_bloc.dart';
import '../../bloc/profile/foundation_profile_event.dart';
import '../../bloc/profile/foundation_profile_state.dart';

class TabProfile extends StatefulWidget {
  const TabProfile({super.key});

  @override
  State<TabProfile> createState() => _TabProfileState();
}

class _TabProfileState extends State<TabProfile> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Controladores
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  
  File? _newLogoFile;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _addressCtrl = TextEditingController();

    // Cargar perfil al iniciar
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      context.read<FoundationProfileBloc>().add(LoadProfile(userId));
    }
  }

  void _enableEditing(FoundationEntity foundation) {
    setState(() {
      _isEditing = true;
      _nameCtrl.text = foundation.nombre;
      _descCtrl.text = foundation.descripcion ?? '';
      _phoneCtrl.text = foundation.telefono ?? '';
      _addressCtrl.text = foundation.direccion ?? '';
      
      if (foundation.latitud != null && foundation.longitud != null) {
        _selectedLocation = LatLng(foundation.latitud!, foundation.longitud!);
      } else {
        _selectedLocation = const LatLng(-0.1807, -78.4678); // Default Quito
      }
    });
  }

  void _saveChanges(FoundationEntity original) {
    if (!_formKey.currentState!.validate()) return;

    final updated = original.copyWith(
      nombre: _nameCtrl.text,
      descripcion: _descCtrl.text,
      telefono: _phoneCtrl.text,
      direccion: _addressCtrl.text,
      latitud: _selectedLocation?.latitude,
      longitud: _selectedLocation?.longitude,
      newLogoFile: _newLogoFile,
    );

    context.read<FoundationProfileBloc>().add(UpdateProfileEvent(updated));
    setState(() => _isEditing = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newLogoFile = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Fondo gris profesional
      body: BlocConsumer<FoundationProfileBloc, FoundationProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
             // Opcional: Feedback visual si es necesario tras recargar
          }
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
          }
          
          if (state is ProfileLoaded) {
            final foundation = state.foundation;
            return CustomScrollView(
              slivers: [
                // 1. CABECERA EXPANDIBLE (SLIVER APP BAR)
                _buildSliverAppBar(foundation),

                // 2. CONTENIDO SCROLLABLE
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isEditing) ...[
                          _buildStatsRow(),
                          const SizedBox(height: 24),
                          _buildSectionTitle("Información"),
                          _buildInfoCard(foundation),
                          const SizedBox(height: 24),
                          _buildSectionTitle("Ubicación"),
                          _buildMapPreview(foundation),
                          const SizedBox(height: 30),
                          _buildLogoutButton(context),
                        ] else ...[
                          _buildEditForm(foundation),
                        ],
                        const SizedBox(height: 40), // Espacio final
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text("No se pudo cargar el perfil"));
        },
      ),
    );
  }

  // --- WIDGETS UI ---

  Widget _buildSliverAppBar(FoundationEntity foundation) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppTheme.primaryOrange,
      elevation: 0,
      actions: [
        if (!_isEditing)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
            onPressed: () => _enableEditing(foundation),
          )
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Fondo con gradiente
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFF8F00), AppTheme.primaryOrange],
                ),
              ),
            ),
            // Decoración curva blanca abajo
            Positioned(
              bottom: -1,
              child: Container(
                height: 30,
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
              ),
            ),
            // Contenido Central
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _newLogoFile != null
                              ? FileImage(_newLogoFile!) as ImageProvider
                              : (foundation.logoUrl != null ? NetworkImage(foundation.logoUrl!) : null),
                          child: (foundation.logoUrl == null && _newLogoFile == null)
                              ? const Icon(Icons.business, size: 50, color: Colors.grey)
                              : null,
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          right: 0, bottom: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blue,
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  foundation.nombre,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (!_isEditing)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: const Text("Fundación Verificada", style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                const SizedBox(height: 20), // Espacio para la curva
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard("Mascotas", "12", Icons.pets, Colors.blue)), // TODO: Conectar con conteo real
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("Adopciones", "85", Icons.favorite, Colors.pink)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(FoundationEntity f) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.description_outlined, f.descripcion ?? "Sin descripción"),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          _buildInfoRow(Icons.phone_outlined, f.telefono ?? "Sin teléfono"),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          _buildInfoRow(Icons.location_on_outlined, f.direccion ?? "Sin dirección"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryOrange, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreview(FoundationEntity f) {
    final location = (f.latitud != null && f.longitud != null) 
        ? LatLng(f.latitud!, f.longitud!) 
        : const LatLng(-0.1807, -78.4678);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MapLocationPicker(
          initialCenter: location,
          isReadOnly: true, // Modo solo lectura
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {
          // Mostrar diálogo de confirmación
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Cerrar Sesión"),
              content: const Text("¿Estás seguro de que quieres salir?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                  },
                  child: const Text("Salir", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.red.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  // --- MODO EDICIÓN ---

  Widget _buildEditForm(FoundationEntity original) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Datos Generales"),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: "Nombre Fundación", prefixIcon: Icon(Icons.business)),
            validator: (v) => v!.isEmpty ? "Requerido" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: "Descripción", prefixIcon: Icon(Icons.info_outline)),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: "Teléfono", prefixIcon: Icon(Icons.phone)),
            keyboardType: TextInputType.phone,
          ),
          
          const SizedBox(height: 32),
          _buildSectionTitle("Ubicación"),
          const Text("Mueve el marcador rojo para actualizar tu ubicación exacta.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          
          TextFormField(
            controller: _addressCtrl,
            decoration: const InputDecoration(labelText: "Dirección (Texto)", prefixIcon: Icon(Icons.map)),
          ),
          const SizedBox(height: 12),
          
          // MAPA INTERACTIVO PARA SELECCIONAR
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.5), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: MapLocationPicker(
                initialCenter: _selectedLocation!,
                isReadOnly: false,
                onPositionChanged: (pos) {
                  setState(() => _selectedLocation = pos);
                  // Opcional: Reverse Geocoding aquí si quieres actualizar el texto de dirección automáticamente
                },
              ),
            ),
          ),

          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text("Cancelar"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () => _saveChanges(original),
                  child: const Text("Guardar Cambios"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}