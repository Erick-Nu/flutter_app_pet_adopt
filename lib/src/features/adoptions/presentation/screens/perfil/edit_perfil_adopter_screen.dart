import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../domain/entities/adopter_entity.dart';
import '../../bloc/adopter_profile.dart';

class EditPerfilAdopterScreen extends StatefulWidget {
  final AdopterEntity adopter;

  const EditPerfilAdopterScreen({
    Key? key,
    required this.adopter,
  }) : super(key: key);

  @override
  State<EditPerfilAdopterScreen> createState() =>
      _EditPerfilAdopterScreenState();
}

class _EditPerfilAdopterScreenState extends State<EditPerfilAdopterScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _edadCtrl;
  String? _selectedSexo;
  File? _newAvatarFile;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingImage = false;

  // Track which fields have been modified
  Set<String> _modifiedFields = {};

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.adopter.nombre);
    _telefonoCtrl =
        TextEditingController(text: widget.adopter.telefono ?? '');
    _edadCtrl = TextEditingController(text: widget.adopter.edad?.toString() ?? '');
    _selectedSexo = widget.adopter.sexo;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _edadCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isLoadingImage = true);
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _newAvatarFile = File(image.path);
          _modifiedFields.add('avatar');
        });
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: 'Error al seleccionar imagen: $e',
          type: AppSnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    }
  }

  void _trackFieldChange(String fieldName) {
    setState(() => _modifiedFields.add(fieldName));
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) {
      showAppSnackBar(
        context,
        message: 'Por favor completa todos los campos correctamente',
        type: AppSnackBarType.info,
      );
      return;
    }

    if (_modifiedFields.isEmpty && _newAvatarFile == null) {
      showAppSnackBar(
        context,
        message: 'No hay cambios para guardar',
        type: AppSnackBarType.info,
      );
      return;
    }

    final updatedAdopter = widget.adopter.copyWith(
      nombre: _nombreCtrl.text,
      telefono: _telefonoCtrl.text,
      edad: int.tryParse(_edadCtrl.text),
      sexo: _selectedSexo,
    );

    context.read<AdopterProfileBloc>().add(
          UpdateAdopterProfile(updatedAdopter),
        );
  }

  void _cancelEditing() {
    if (_modifiedFields.isNotEmpty || _newAvatarFile != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Descartar cambios?'),
          content: const Text(
              'Tienes cambios sin guardar. ¿Estás seguro de que deseas salir?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continuar editando'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                'Descartar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
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
          icon: const Icon(Icons.arrow_back_ios_rounded),
          color: AppTheme.textPrimary,
          onPressed: _cancelEditing,
        ),
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<AdopterProfileBloc, AdopterProfileState>(
        listener: (context, state) {
          if (state is AdopterProfileLoaded) {
            showAppSnackBar(
              context,
              message: 'Perfil actualizado exitosamente',
              type: AppSnackBarType.success,
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) Navigator.pop(context);
            });
          } else if (state is AdopterProfileError) {
            showAppSnackBar(
              context,
              message: state.message,
              type: AppSnackBarType.error,
            );
          }
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // SECCIÓN AVATAR
                _buildAvatarSection(),

                // FORMULARIO
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Información Personal'),
                        const SizedBox(height: 20),
                        _buildFormField(
                          controller: _nombreCtrl,
                          label: 'Nombre Completo',
                          icon: Icons.person_rounded,
                          hint: 'Ingresa tu nombre',
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'El nombre es requerido';
                            }
                            if (value!.length < 3) {
                              return 'El nombre debe tener al menos 3 caracteres';
                            }
                            return null;
                          },
                          onChanged: (value) =>
                              _trackFieldChange('nombre'),
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _telefonoCtrl,
                          label: 'Teléfono',
                          icon: Icons.phone_rounded,
                          hint: 'Ej: +573001234567',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'El teléfono es requerido';
                            }
                            if (value!.length < 10) {
                              return 'Ingresa un teléfono válido';
                            }
                            return null;
                          },
                          onChanged: (value) =>
                              _trackFieldChange('telefono'),
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _edadCtrl,
                          label: 'Edad',
                          icon: Icons.cake_rounded,
                          hint: 'Ej: 25',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'La edad es requerida';
                            }
                            final edad = int.tryParse(value!);
                            if (edad == null || edad < 18 || edad > 100) {
                              return 'Debes ser mayor de 18 años';
                            }
                            return null;
                          },
                          onChanged: (value) =>
                              _trackFieldChange('edad'),
                        ),
                        const SizedBox(height: 16),
                        _buildGenderDropdown(),
                        const SizedBox(height: 40),
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: _newAvatarFile != null
                      ? FileImage(_newAvatarFile!)
                      : (widget.adopter.avatarUrl != null &&
                              widget.adopter.avatarUrl!.isNotEmpty
                          ? NetworkImage(widget.adopter.avatarUrl!)
                              as ImageProvider
                          : null),
                  child: (_newAvatarFile == null &&
                          (widget.adopter.avatarUrl == null ||
                              widget.adopter.avatarUrl!.isEmpty))
                      ? const Icon(Icons.person,
                          size: 70, color: Colors.white)
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _isLoadingImage ? null : _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _isLoadingImage
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryOrange,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 24,
                            color: AppTheme.primaryOrange,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Toca la cámara para cambiar tu foto',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryOrange),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.grey, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppTheme.primaryOrange,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: const TextStyle(
        fontSize: 16,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSexo,
      decoration: InputDecoration(
        labelText: 'Género',
        prefixIcon: const Icon(Icons.wc_rounded, color: AppTheme.primaryOrange),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.grey, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppTheme.primaryOrange,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: 'hombre',
          child: Text('Hombre'),
        ),
        DropdownMenuItem(
          value: 'mujer',
          child: Text('Mujer'),
        ),
        DropdownMenuItem(
          value: 'otro',
          child: Text('Otro'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedSexo = value;
          _trackFieldChange('sexo');
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecciona tu género';
        }
        return null;
      },
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<AdopterProfileBloc, AdopterProfileState>(
      builder: (context, state) {
        final isLoading = state is AdopterProfileLoading;

        return Column(
          children: [
            // BOTÓN GUARDAR
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLoading
                      ? [Colors.grey.shade400, Colors.grey.shade400]
                      : [
                          AppTheme.primaryOrange,
                          AppTheme.primaryOrange.withOpacity(0.8),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isLoading
                            ? Colors.grey
                            : AppTheme.primaryOrange)
                        .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading ? null : _saveChanges,
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        const Icon(Icons.check_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        isLoading ? 'Guardando...' : 'Guardar Cambios',
                        style: const TextStyle(
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
            // BOTÓN CANCELAR
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ),
                color: Colors.white,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading ? null : _cancelEditing,
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.grey.shade600,
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
      },
    );
  }
}
