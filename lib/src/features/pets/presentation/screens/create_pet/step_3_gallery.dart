import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/pet_bloc.dart';
import '../../bloc/pet_event.dart';

class Step3Gallery extends StatefulWidget {
  final VoidCallback onSubmit;
  const Step3Gallery({super.key, required this.onSubmit});

  @override
  State<Step3Gallery> createState() => _Step3GalleryState();
}

class _Step3GalleryState extends State<Step3Gallery> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _images = []; // Rutas locales

  Future<void> _pickImage() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((e) => e.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _finish() {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes subir al menos una foto de portada")),
      );
      return;
    }
    // Guardamos las imágenes y disparamos el evento final
    context.read<PetBloc>().add(PetCreateImagesChanged(_images));
    widget.onSubmit(); // Esto llama al submit final en el Wizard
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Text("Galería de Fotos", style: Theme.of(context).textTheme.headlineSmall),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Sube fotos de alta calidad. La primera foto será la portada.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
        
        // AREA DE BOTÓN DE CARGA
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange, width: 1, style: BorderStyle.solid),
              // Patrón de diseño "Dotted Border" simulado
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 40, color: Colors.orange),
                  SizedBox(height: 8),
                  Text("Toca para agregar fotos", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // GRILLA DE FOTOS
        Expanded(
          child: _images.isEmpty
              ? Center(child: Text("No has seleccionado fotos aún", style: TextStyle(color: Colors.grey[400])))
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(_images[index]), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        if (index == 0)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: const Text("Portada", 
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          )
                      ],
                    );
                  },
                ),
        ),

        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _finish,
              child: const Text("PUBLICAR MASCOTA"),
            ),
          ),
        )
      ],
    );
  }
}