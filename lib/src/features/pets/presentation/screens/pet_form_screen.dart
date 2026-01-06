import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart'; // NECESITAS ESTE PAQUETE
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/medical_record_entity.dart';
import '../../domain/entities/pet_entity.dart';
import '../bloc/pet_bloc.dart';
import '../bloc/pet_event.dart';
import '../bloc/pet_state.dart';

class PetFormScreen extends StatefulWidget {
  final PetEntity? petToEdit;

  const PetFormScreen({super.key, this.petToEdit});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  int _currentStep = 0;
  final _picker = ImagePicker();

  // --- DATOS BÁSICOS ---
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  String _sexo = 'macho';

  // --- DATOS MÉDICOS ---
  bool _esEsterilizado = false;
  bool _esDesparasitado = false;
  bool _tieneVacunas = false;
  final _pesoCtrl = TextEditingController();
  final _obsMedicasCtrl = TextEditingController();

  // --- IMÁGENES ---
  File? _avatarFile;
  final List<File> _galleryFiles = [];

  @override
  void initState() {
    super.initState();
    final editing = widget.petToEdit;
    if (editing != null) {
      _nombreCtrl.text = editing.nombre;
      _descCtrl.text = editing.descripcion ?? '';
      _edadCtrl.text = editing.edad?.toString() ?? '';
      _sexo = editing.sexo;
    }
  }

  // Selección de Avatar
  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  // Selección de Galería
  Future<void> _pickGallery() async {
    final pickedList = await _picker.pickMultiImage();
    if (pickedList.isNotEmpty) {
      setState(() {
        _galleryFiles.addAll(pickedList.map((e) => File(e.path)));
      });
    }
  }

  void _submit() {
    if (_nombreCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio')),
      );
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser!.id;

    // Crear Entidad Médica
    final medicalRecord = MedicalRecordEntity(
      esEsterilizado: _esEsterilizado,
      esDesparasitado: _esDesparasitado,
      tieneVacunas: _tieneVacunas,
      pesoKg: double.tryParse(_pesoCtrl.text) ?? 0.0,
      observaciones: _obsMedicasCtrl.text,
    );

    // Crear Entidad Mascota COMPLETA
    final pet = PetEntity(
      id: '',
      nombre: _nombreCtrl.text,
      descripcion: _descCtrl.text,
      edad: int.tryParse(_edadCtrl.text) ?? 0,
      sexo: _sexo,
      status: 'disponible',
      fundacionId: userId,
      // Archivos Físicos
      newAvatarFile: _avatarFile,
      newGalleryFiles: _galleryFiles,
      fichaMedica: medicalRecord,
    );

    context.read<PetBloc>().add(AddPet(pet));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Mascota'), backgroundColor: AppTheme.primaryOrange),
      body: BlocConsumer<PetBloc, PetState>(
        listener: (context, state) {
          if (state is PetsLoaded) Navigator.pop(context);
          if (state is PetsError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is PetsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stepper(
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
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
                        child: Text(
                          _currentStep == 2 ? 'GUARDAR TODO' : 'CONTINUAR',
                          style: const TextStyle(color: Colors.white),
                        ),
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
              // PASO 1: DATOS GENERALES
              Step(
                title: const Text('Datos Básicos'),
                content: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                        child: _avatarFile == null
                            ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Foto de Perfil', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _edadCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Edad (meses)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField(
                            value: _sexo,
                            items: const [
                              DropdownMenuItem(value: 'macho', child: Text('Macho')),
                              DropdownMenuItem(value: 'hembra', child: Text('Hembra')),
                            ],
                            onChanged: (v) => setState(() => _sexo = v.toString()),
                            decoration: const InputDecoration(labelText: 'Sexo', border: OutlineInputBorder()),
                          ),
                        ),
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

              // PASO 2: FICHA MÉDICA
              Step(
                title: const Text('Salud'),
                content: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('¿Esterilizado?'),
                      value: _esEsterilizado,
                      onChanged: (v) => setState(() => _esEsterilizado = v),
                    ),
                    SwitchListTile(
                      title: const Text('¿Desparasitado?'),
                      value: _esDesparasitado,
                      onChanged: (v) => setState(() => _esDesparasitado = v),
                    ),
                    SwitchListTile(
                      title: const Text('¿Vacunas al día?'),
                      value: _tieneVacunas,
                      onChanged: (v) => setState(() => _tieneVacunas = v),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _pesoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Peso (Kg)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _obsMedicasCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Observaciones Veterinarias', border: OutlineInputBorder()),
                    ),
                  ],
                ),
                isActive: _currentStep >= 1,
              ),

              // PASO 3: GALERÍA
              Step(
                title: const Text('Galería de Fotos'),
                content: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Seleccionar Fotos Extra'),
                    ),
                    const SizedBox(height: 10),
                    if (_galleryFiles.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _galleryFiles.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Stack(
                                children: [
                                  Image.file(_galleryFiles[index], width: 100, height: 100, fit: BoxFit.cover),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _galleryFiles.removeAt(index)),
                                      child: const CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.close, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                isActive: _currentStep >= 2,
              ),
            ],
          );
        },
      ),
    );
  }
}