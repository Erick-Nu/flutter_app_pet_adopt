import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../domain/entities/pet_entity.dart';
import '../../bloc/pet_bloc.dart';
import '../../bloc/pet_event.dart';
import '../../bloc/pet_state.dart';

class Step3Gallery extends StatefulWidget {
  final VoidCallback onBack; // Opcional, si quisieras botón atrás
  final PetEntity? petToEdit;

  const Step3Gallery({
    super.key, 
    required this.onBack, 
    this.petToEdit
  });

  @override
  State<Step3Gallery> createState() => _Step3GalleryState();
}

class _Step3GalleryState extends State<Step3Gallery> {
  final ImagePicker _picker = ImagePicker();
  
  // Fotos nuevas (Rutas locales)
  List<String> _selectedImages = [];
  
  // Fotos existentes (URLs - Solo para edición)
  // Nota: Si la API soporta borrar fotos viejas, necesitaríamos lógica extra.
  // Por ahora mostramos las existentes como "solo lectura" o referencia.
  List<String> _existingImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.petToEdit != null) {
      // Cargar imágenes existentes si estamos editando
      _existingImages = widget.petToEdit!.galleryUrls; 
      // Mostramos las existentes como referencia; nuevas se agregan aparte
    }
  }

  /// Función para seleccionar imágenes de la galería
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 70, // Optimización básica
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          // Agregamos las nuevas rutas a la lista
          _selectedImages.addAll(pickedFiles.map((e) => e.path));
        });
      }
    } catch (e) {
      showAppSnackBar(
        context,
        message: "Error al seleccionar imágenes",
        type: AppSnackBarType.error,
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submit() {
    if (_selectedImages.isEmpty && _existingImages.isEmpty) {
      showAppSnackBar(
        context,
        message: "Debes agregar al menos una foto",
        type: AppSnackBarType.error,
      );
      return;
    }

    // 1. Guardar las imágenes en el Bloc
    context.read<PetBloc>().add(PetCreateImagesChanged(_selectedImages));

    // 2. Disparar el evento de CREAR o ACTUALIZAR
    if (widget.petToEdit == null) {
      context.read<PetBloc>().add(PetSubmitCreation());
    } else {
      context.read<PetBloc>().add(PetSubmitUpdate(widget.petToEdit!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ENCABEZADO ---
            _buildHeader(),
            const SizedBox(height: 24),

            // --- GRID DE FOTOS ---
            Text(
              "Fotos de la Mascota",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Agrega fotos claras. La primera foto será la portada.",
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            _buildImageGrid(),

            const SizedBox(height: 40),

            // --- BOTÓN FINALIZAR ---
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.photo_library_rounded, color: AppTheme.primaryOrange, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Galería", 
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Paso 3 de 3",
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    // Calculamos items: Botón agregar + imágenes nuevas + imágenes existentes (solo lectura)
    final totalItems = 1 + _selectedImages.length + _existingImages.length; 

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 columnas
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1, // Cuadrados
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Primer item: botón Agregar
        if (index == 0) return _buildAddButton();

        // A continuación: imágenes existentes (URLs)
        if (index <= _existingImages.length) {
          final url = _existingImages[index - 1];
          return _buildExistingImageCard(url);
        }

        // Finalmente: imágenes nuevas (rutas locales)
        final localIndex = index - 1 - _existingImages.length;
        final imagePath = _selectedImages[localIndex];
        return _buildImageCard(imagePath, localIndex);
      },
    );
  }

  /// Botón cuadrado con borde punteado para agregar fotos
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryOrange.withOpacity(0.5),
            width: 1.5,
            style: BorderStyle.solid, // Flutter no tiene 'dashed' nativo simple en Border.all, usamos sólido suave
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryOrange, size: 28),
            const SizedBox(height: 4),
            Text(
              "Agregar",
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Tarjeta de foto individual con botón de borrar
  Widget _buildImageCard(String path, int index) {
    return Stack(
      children: [
        // Imagen
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(File(path)),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        // Botón Borrar (X)
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
        // Etiqueta "Portada" para la primera foto
        if (index == 0)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: const Text(
                "Portada",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  /// Tarjeta para imagen existente (solo lectura)
  Widget _buildExistingImageCard(String url) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<PetBloc, PetState>(
      builder: (context, state) {
        final isLoading = state.actionStatus == PetActionStatus.loading;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: isLoading ? null : _submit,
            icon: isLoading 
                ? const SizedBox(
                    width: 20, height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Icon(Icons.check_circle_rounded, size: 22),
            label: Text(
              isLoading ? "Publicando..." : (widget.petToEdit == null ? "Publicar Mascota" : "Guardar Cambios"),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              disabledBackgroundColor: AppTheme.primaryOrange.withOpacity(0.6),
            ),
          ),
        );
      },
    );
  }
}