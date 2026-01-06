import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/adopter_entity.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../bloc/adopter_profile_bloc.dart';
import '../../bloc/adopter_profile_event.dart';
import '../../bloc/adopter_profile_state.dart';

class TabPerfilAdopter extends StatefulWidget {
  const TabPerfilAdopter({super.key});

  @override
  State<TabPerfilAdopter> createState() => _TabPerfilAdopterState();
}

class _TabPerfilAdopterState extends State<TabPerfilAdopter> with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  
  // Controllers
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  String? _selectedSexo;
  File? _newAvatarFile;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    
    final userId = Supabase.instance.client.auth.currentUser!.id;
    context.read<AdopterProfileBloc>().add(LoadAdopterProfile(userId));
  }

  @override
  void dispose() {
    _animController.dispose();
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _edadCtrl.dispose();
    super.dispose();
  }

  void _enableEditing(AdopterEntity adopter) {
    setState(() {
      _isEditing = true;
      _nombreCtrl.text = adopter.nombre;
      _telefonoCtrl.text = adopter.telefono ?? '';
      _edadCtrl.text = adopter.edad?.toString() ?? '';
      _selectedSexo = adopter.sexo;
    });
    _animController.forward();
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _newAvatarFile = null;
    });
    _animController.reverse();
  }

  void _saveChanges(AdopterEntity original) {
    final int? edad = _edadCtrl.text.isEmpty ? null : int.tryParse(_edadCtrl.text);
    
    final updated = original.copyWith(
      nombre: _nombreCtrl.text,
      telefono: _telefonoCtrl.text.isEmpty ? null : _telefonoCtrl.text,
      edad: edad,
      sexo: _selectedSexo,
      newAvatarFile: _newAvatarFile,
    );
    
    context.read<AdopterProfileBloc>().add(UpdateAdopterProfile(updated));
    _animController.reverse();
    setState(() => _isEditing = false);
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newAvatarFile = File(picked.path));
    }
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
    return BlocListener<AdopterProfileBloc, AdopterProfileState>(
      listener: (context, state) {
        if (state is AdopterProfileLoaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Perfil actualizado correctamente")),
          );
        } else if (state is AdopterProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${state.message}"), backgroundColor: Colors.red),
          );
        }
      },
      child: BlocBuilder<AdopterProfileBloc, AdopterProfileState>(
        builder: (context, state) {
          if (state is AdopterProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is AdopterProfileError) {
            return Center(child: Text("Error: ${state.message}"));
          }
          
          if (state is AdopterProfileLoaded) {
            final adopter = state.adopter;
            
            return SingleChildScrollView(
              child: Column(
                children: [
                  // HEADER CON GRADIENTE
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryOrange, AppTheme.primaryOrange.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Avatar
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: _newAvatarFile != null
                                  ? FileImage(_newAvatarFile!)
                                  : (adopter.avatarUrl != null && adopter.avatarUrl!.isNotEmpty
                                      ? NetworkImage(adopter.avatarUrl!) as ImageProvider
                                      : null),
                              child: (_newAvatarFile == null && (adopter.avatarUrl == null || adopter.avatarUrl!.isEmpty))
                                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                                  : null,
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(Icons.camera_alt, color: AppTheme.primaryOrange, size: 20),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          adopter.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // CONTENIDO
                  if (!_isEditing)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard("Cédula", adopter.cedula, Icons.credit_card),
                          _buildInfoCard("Teléfono", adopter.telefono ?? "No registrado", Icons.phone),
                          _buildInfoCard("Edad", adopter.edad?.toString() ?? "No registrada", Icons.cake),
                          _buildInfoCard("Género", adopter.sexo ?? "No registrado", Icons.wc),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _enableEditing(adopter),
                              icon: const Icon(Icons.edit),
                              label: const Text("Editar Perfil"),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info, color: Colors.orange.shade700),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      "Actualiza tu información personal",
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // FORMULARIO
                            TextFormField(
                              controller: _nombreCtrl,
                              decoration: InputDecoration(
                                labelText: "Nombre Completo",
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _telefonoCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: "Teléfono",
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _edadCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Edad",
                                prefixIcon: const Icon(Icons.cake),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedSexo,
                              items: [
                                const DropdownMenuItem(value: 'hombre', child: Text('Hombre')),
                                const DropdownMenuItem(value: 'mujer', child: Text('Mujer')),
                                const DropdownMenuItem(value: 'otro', child: Text('Otro')),
                              ],
                              onChanged: (v) => setState(() => _selectedSexo = v),
                              decoration: InputDecoration(
                                labelText: "Género",
                                prefixIcon: const Icon(Icons.wc),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _cancelEditing,
                                    child: const Text("Cancelar"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => _saveChanges(adopter),
                                    child: const Text("Guardar"),
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryOrange, size: 24),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
