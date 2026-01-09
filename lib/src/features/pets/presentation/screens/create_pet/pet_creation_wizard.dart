import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/pet_bloc.dart';
import '../../bloc/pet_event.dart';
import '../../bloc/pet_state.dart';
import '../../../domain/entities/pet_entity.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/widgets/app_loader.dart';
import 'step_1_general_info.dart';
import 'step_2_medical_info.dart';
import 'step_3_gallery.dart';

class PetCreationWizard extends StatefulWidget {
  final PetEntity? petToEdit;

  const PetCreationWizard({super.key, this.petToEdit});

  @override
  State<PetCreationWizard> createState() => _PetCreationWizardState();
}

class _PetCreationWizardState extends State<PetCreationWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    // SI ESTAMOS EDITANDO: Pre-llenar los datos en el BLoC
    if (widget.petToEdit != null) {
      final p = widget.petToEdit!;

      // Cargar Paso 1 en memoria del BLoC
      context.read<PetBloc>().add(PetCreateStep1Changed(
        nombre: p.nombre,
        descripcion: p.descripcion,
        edad: p.edad,
        sexo: p.sexo,
        tamano: p.tamano ?? 'mediano',
      ));

      // Cargar Paso 2 en memoria del BLoC
      if (p.fichaMedica != null) {
        context.read<PetBloc>().add(PetCreateStep2Changed(
          esEsterilizado: p.fichaMedica!.esEsterilizado,
          esDesparasitado: p.fichaMedica!.esDesparasitado,
          vacunasAlDia: p.fichaMedica!.tieneVacunas,
          tieneMicrochip: p.fichaMedica!.tieneMicrochip,
          peso: p.fichaMedica!.pesoKg,
          tieneDiscapacidad: false,
          observaciones: p.fichaMedica!.observaciones,
        ));
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      // ÚLTIMO PASO: DECIDIR SI CREAR O ACTUALIZAR
      if (widget.petToEdit == null) {
        context.read<PetBloc>().add(PetSubmitCreation());
      } else {
        // Enviamos evento de actualización con el ID
        context.read<PetBloc>().add(PetSubmitUpdate(widget.petToEdit!.id));
      }
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.petToEdit != null;
    // 1. AÑADIMOS EL BLOC LISTENER AQUÍ
    return BlocListener<PetBloc, PetState>(
      listener: (context, state) {
        if (state is PetsLoading) {
          // Opcional: Mostrar un diálogo de carga si prefieres bloquear la pantalla
          // showDialog(...) 
        } else if (state is PetsLoaded) {
          // 2. ÉXITO: Si la lista se recargó, significa que se creó/actualizó la mascota
          final message = isEditing ? '¡Mascota actualizada! 🎉' : '¡Mascota registrada exitosamente! 🐾';
          showAppSnackBar(
            context,
            message: message,
            type: AppSnackBarType.success,
          );
          // 3. Regresar a la pantalla anterior
          Navigator.pop(context);
        } else if (state is PetsError) {
          // 4. ERROR
          showAppSnackBar(
            context,
            message: 'Error: ${state.message}',
            type: AppSnackBarType.error,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? "Editar Mascota" : "Publicar Mascota"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _prevPage,
          ),
        ),
        body: Column(
          children: [
            // Indicador de Progreso
            _buildProgressIndicator(),
            
            Expanded(
              child: BlocBuilder<PetBloc, PetState>(
                builder: (context, state) {
                  // Si está cargando, mostramos spinner en lugar del formulario
                  if (state is PetsLoading) {
                    return const Center(
                      child: AppLoader(label: "Guardando mascota..."),
                    );
                  }

                  return PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      Step1GeneralInfo(onNext: _nextPage, petToEdit: widget.petToEdit),
                      Step2MedicalInfo(onNext: _nextPage, petToEdit: widget.petToEdit),
                      Step3Gallery(onSubmit: _nextPage, petToEdit: widget.petToEdit),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: Colors.white,
      child: Row(
        children: [
          _buildStepCircle(0, "General"),
          _buildLine(0),
          _buildStepCircle(1, "Médico"),
          _buildLine(1),
          _buildStepCircle(2, "Fotos"),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int index, String label) {
    final isActive = _currentStep >= index;
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isActive ? Colors.orange : Colors.grey[300],
          child: Text(
            (index + 1).toString(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? Colors.black87 : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        )
      ],
    );
  }

  Widget _buildLine(int index) {
    return Expanded(
      child: Container(
        height: 2,
        color: _currentStep > index ? Colors.orange : Colors.grey[300],
        margin: const EdgeInsets.only(bottom: 14),
      ),
    );
  }
}