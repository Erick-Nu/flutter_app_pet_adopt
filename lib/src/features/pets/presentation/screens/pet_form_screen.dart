import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/medical_record_entity.dart';
import '../../domain/entities/pet_entity.dart';
import '../bloc/pet_bloc.dart';
import '../bloc/pet_event.dart';
import '../bloc/pet_state.dart';

class PetFormScreen extends StatefulWidget {
  final PetEntity? petToEdit; // Si viene lleno, es EDICIÓN

  const PetFormScreen({super.key, this.petToEdit});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  int _currentStep = 0;
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>(); // Para validaciones

  // --- CONTROLADORES ---
  late TextEditingController _nombreCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _edadCtrl;
  late TextEditingController _pesoCtrl;
  late TextEditingController _obsMedicasCtrl;
  
  String _sexo = 'macho';
  
  // Datos Médicos
  bool _esEsterilizado = false;
  bool _esDesparasitado = false;
  bool _tieneVacunas = false;

  // Imágenes
  File? _newAvatarFile; // Solo si el usuario cambia la foto
  final List<File> _newGalleryFiles = []; // Solo nuevas fotos

  bool get isEditing => widget.petToEdit != null;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores
    _nombreCtrl = TextEditingController(text: widget.petToEdit?.nombre ?? '');
    _descCtrl = TextEditingController(text: widget.petToEdit?.descripcion ?? '');
    _edadCtrl = TextEditingController(text: widget.petToEdit?.edad?.toString() ?? '');
    _pesoCtrl = TextEditingController(text: widget.petToEdit?.fichaMedica?.pesoKg.toString() ?? '');
    _obsMedicasCtrl = TextEditingController(text: widget.petToEdit?.fichaMedica?.observaciones ?? '');
    
    if (isEditing) {
      _sexo = widget.petToEdit!.sexo;
      // Cargar datos médicos si existen
      if (widget.petToEdit!.fichaMedica != null) {
        _esEsterilizado = widget.petToEdit!.fichaMedica!.esEsterilizado;
        _esDesparasitado = widget.petToEdit!.fichaMedica!.esDesparasitado;
        _tieneVacunas = widget.petToEdit!.fichaMedica!.tieneVacunas;
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _edadCtrl.dispose();
    _pesoCtrl.dispose();
    _obsMedicasCtrl.dispose();
    super.dispose();
  }

  // --- MÉTODOS DE IMAGEN ---
  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _newAvatarFile = File(picked.path));
  }

  Future<void> _pickGallery() async {
    final pickedList = await _picker.pickMultiImage();
    if (pickedList.isNotEmpty) {
      setState(() => _newGalleryFiles.addAll(pickedList.map((e) => File(e.path))));
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final userId = Supabase.instance.client.auth.currentUser!.id;

    // Entidad Médica
    final medicalRecord = MedicalRecordEntity(
      esEsterilizado: _esEsterilizado,
      esDesparasitado: _esDesparasitado,
      tieneVacunas: _tieneVacunas,
      pesoKg: double.tryParse(_pesoCtrl.text) ?? 0.0,
      observaciones: _obsMedicasCtrl.text,
    );

    // Entidad Mascota
    final pet = PetEntity(
      id: isEditing ? widget.petToEdit!.id : '', // ID existente si editamos
      nombre: _nombreCtrl.text,
      descripcion: _descCtrl.text,
      edad: int.tryParse(_edadCtrl.text) ?? 0,
      sexo: _sexo,
      status: isEditing ? widget.petToEdit!.status : 'disponible',
      fundacionId: userId,
      avatarUrl: widget.petToEdit?.avatarUrl, // Mantener URL vieja
      newAvatarFile: _newAvatarFile, // Archivo nuevo (puede ser null)
      newGalleryFiles: _newGalleryFiles,
      fichaMedica: medicalRecord,
    );

    if (isEditing) {
      log('[PetForm] Enviando actualización de mascota ${pet.id}');
      context.read<PetBloc>().add(UpdatePetEvent(pet));
    } else {
      log('[PetForm] Enviando creación de mascota ${pet.nombre}');
      context.read<PetBloc>().add(AddPet(pet));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Mascota' : 'Nueva Mascota'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<PetBloc, PetState>(
        listener: (context, state) {
          if (state is PetsLoaded) {
            Navigator.pop(context); // Cerrar formulario al terminar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isEditing ? 'Actualizado correctamente' : 'Creado correctamente')),
            );
          }
          if (state is PetsError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is PetsLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
          }

          return Form(
            key: _formKey,
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                } else {
                  _submit();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) setState(() => _currentStep--);
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            foregroundColor: Colors.white
                          ),
                          child: Text(_currentStep == 2 ? 'GUARDAR' : 'CONTINUAR'),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 10),
                        TextButton(onPressed: details.onStepCancel, child: const Text('ATRÁS')),
                      ],
                    ],
                  ),
                );
              },
              steps: [
              // PASO 1: DATOS
              Step(
                title: const Text('Información General'),
                content: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        // Muestra: 1. Foto nueva (File), 2. Foto vieja (URL), 3. Icono
                        backgroundImage: _newAvatarFile != null 
                            ? FileImage(_newAvatarFile!) 
                            : (isEditing && widget.petToEdit?.avatarUrl != null 
                                ? NetworkImage(widget.petToEdit!.avatarUrl!) as ImageProvider 
                                : null),
                        child: (_newAvatarFile == null && widget.petToEdit?.avatarUrl == null)
                            ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isEditing ? 'Toca para cambiar foto' : 'Subir foto principal',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextFormField(
                          controller: _edadCtrl, 
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Edad (meses/años)', border: OutlineInputBorder()),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            final value = int.tryParse(v);
                            if (value == null || value < 0) return 'Edad inválida';
                            return null;
                          },
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: DropdownButtonFormField(
                          value: _sexo,
                          items: const [
                            DropdownMenuItem(value: 'macho', child: Text('Macho')),
                            DropdownMenuItem(value: 'hembra', child: Text('Hembra')),
                          ],
                          onChanged: (v) => setState(() => _sexo = v.toString()),
                          decoration: const InputDecoration(labelText: 'Sexo', border: OutlineInputBorder()),
                        )),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                    ),
                  ],
                ),
                isActive: _currentStep >= 0,
              ),

              // PASO 2: SALUD
              Step(
                title: const Text('Ficha Médica'),
                content: Column(
                  children: [
                    SwitchListTile(title: const Text('Esterilizado'), value: _esEsterilizado, onChanged: (v) => setState(() => _esEsterilizado = v)),
                    SwitchListTile(title: const Text('Desparasitado'), value: _esDesparasitado, onChanged: (v) => setState(() => _esDesparasitado = v)),
                    SwitchListTile(title: const Text('Vacunas al día'), value: _tieneVacunas, onChanged: (v) => setState(() => _tieneVacunas = v)),
                    TextFormField(
                      controller: _pesoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Peso (Kg)', border: OutlineInputBorder()),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        final value = double.tryParse(v);
                        if (value == null || value < 0) return 'Peso inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _obsMedicasCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Observaciones', border: OutlineInputBorder()),
                    ),
                  ],
                ),
                isActive: _currentStep >= 1,
              ),

              // PASO 3: GALERÍA
              Step(
                title: const Text('Galería'),
                content: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Agregar Fotos'),
                    ),
                    const SizedBox(height: 10),
                    // Mostrar fotos nuevas seleccionadas
                    if (_newGalleryFiles.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _newGalleryFiles.length,
                          itemBuilder: (ctx, i) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Image.file(_newGalleryFiles[i], width: 100, height: 100, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                  ],
                ),
                isActive: _currentStep >= 2,
              ),
            ],
          ),
        );
      },
    ),
  );
  }
}