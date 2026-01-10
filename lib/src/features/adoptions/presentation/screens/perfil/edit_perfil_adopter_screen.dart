import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/adopter_entity.dart';
import '../../bloc/adopter_profile_bloc.dart';
import '../../bloc/adopter_profile_event.dart';
import '../../bloc/adopter_profile_state.dart';

class EditPerfilAdopterScreen extends StatefulWidget {
  final AdopterEntity adopter;

  const EditPerfilAdopterScreen({super.key, required this.adopter});

  @override
  State<EditPerfilAdopterScreen> createState() => _EditPerfilAdopterScreenState();
}

class _EditPerfilAdopterScreenState extends State<EditPerfilAdopterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controladores
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  
  File? _newProfileImage;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final a = widget.adopter;
    _nameCtrl = TextEditingController(text: a.nombre);
    _phoneCtrl = TextEditingController(text: a.telefono ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // --- IMAGEN ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() => _newProfileImage = File(pickedFile.path));
      }
    } catch (_) {}
  }

  void _submitChanges() {
    if (_formKey.currentState!.validate()) {
      // Creamos la entidad actualizada (sin coordenadas)
      final updatedAdopter = widget.adopter.copyWith(
        nombre: _nameCtrl.text.trim(),
        telefono: _phoneCtrl.text.trim(),
        newAvatarFile: _newProfileImage,
      );

      setState(() => _submitted = true);
      
      // Enviamos evento al BLoC
      context.read<AdopterProfileBloc>().add(
        UpdateAdopterProfile(updatedAdopter),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: const Text(
          "Editar mi Perfil", 
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 20)
        ),
      ),
      body: BlocListener<AdopterProfileBloc, AdopterProfileState>(
        listener: (context, state) {
          if (_submitted && state is AdopterProfileLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("¡Perfil actualizado con éxito!"), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          } else if (state is AdopterProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.error),
            );
            setState(() => _submitted = false);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // --- FOTO DE PERFIL ---
                _buildImageSelector(),
                const SizedBox(height: 30),

                Align(alignment: Alignment.centerLeft, child: _buildSectionTitle("Datos Personales")),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _nameCtrl,
                  label: "Nombre Completo",
                  icon: Icons.person_outline,
                  validator: (v) => v!.isEmpty ? "Requerido" : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneCtrl,
                  label: "Celular / Teléfono",
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 40),

                // Botón Guardar
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: BlocBuilder<AdopterProfileBloc, AdopterProfileState>(
                    builder: (context, state) {
                      final isLoading = state is AdopterProfileLoading || _submitted;
                      return FilledButton(
                        onPressed: isLoading ? null : _submitChanges,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Guardar Cambios", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildImageSelector() {
    ImageProvider imageProvider;
    if (_newProfileImage != null) {
      imageProvider = FileImage(_newProfileImage!);
    } else if (widget.adopter.avatarUrl != null && widget.adopter.avatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(widget.adopter.avatarUrl!);
    } else {
      imageProvider = const AssetImage('assets/images/default_profile.png');
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Center(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryOrange, width: 3),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: CircleAvatar(radius: 60, backgroundColor: Colors.white, backgroundImage: imageProvider),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary));
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, validator: validator,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: AppTheme.primaryOrange),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2)),
      ),
    );
  }
}