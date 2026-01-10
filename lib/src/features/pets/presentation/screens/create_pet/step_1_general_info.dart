import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/catalog_entity.dart';
import '../../../domain/entities/pet_entity.dart';
import '../../bloc/pet_bloc.dart';
import '../../bloc/pet_event.dart';
import '../../bloc/pet_state.dart';

class Step1GeneralInfo extends StatefulWidget {
  final VoidCallback onNext;
  final PetEntity? petToEdit;

  const Step1GeneralInfo({super.key, required this.onNext, this.petToEdit});

  @override
  State<Step1GeneralInfo> createState() => _Step1GeneralInfoState();
}

class _Step1GeneralInfoState extends State<Step1GeneralInfo> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();

  // State values
  String _sexo = 'macho';
  String _tamano = 'mediano';
  List<CatalogEntity> _speciesList = [];
  List<CatalogEntity> _breedsList = [];
  int? _selectedEspecie;
  int? _selectedRaza;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    context.read<PetBloc>().add(LoadCatalogs());

    if (widget.petToEdit != null) {
      final p = widget.petToEdit!;
      _nombreCtrl.text = p.nombre;
      _descCtrl.text = p.descripcion ?? '';
      if (p.edad != null) _edadCtrl.text = p.edad.toString();
      _sexo = p.sexo;
      _tamano = p.tamano ?? 'mediano';
      _selectedEspecie = p.especieId;
      _selectedRaza = p.razaId;

      if (_selectedEspecie != null) {
        context.read<PetBloc>().add(LoadBreeds(_selectedEspecie!));
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _edadCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<PetBloc>().add(PetCreateStep1Changed(
            nombre: _nombreCtrl.text.trim(),
            descripcion: _descCtrl.text.trim(),
            edad: int.tryParse(_edadCtrl.text),
            sexo: _sexo,
            tamano: _tamano,
            especieId: _selectedEspecie,
            razaId: _selectedRaza,
          ));
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    const double fieldSpacing = 24.0;
    const double sectionSpacing = 32.0;

    return BlocListener<PetBloc, PetState>(
      listener: (context, state) {
        if (state.species.isNotEmpty) {
          setState(() => _speciesList = state.species);
        }
        if (state.breeds.isNotEmpty) {
          setState(() {
            _breedsList = state.breeds;
            // Si la raza seleccionada no está en la nueva lista, resetearla
            if (_selectedRaza != null &&
                !_breedsList.any((b) => b.id == _selectedRaza)) {
              _selectedRaza = null;
            }
          });
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: sectionSpacing),
              _buildNameInput(),
              const SizedBox(height: fieldSpacing),
              _buildSpeciesInput(),
              const SizedBox(height: fieldSpacing),
              _buildBreedInput(),
              const SizedBox(height: fieldSpacing),
              _buildAgeInput(),
              const SizedBox(height: fieldSpacing),
              _buildSexInput(),
              const SizedBox(height: fieldSpacing),
              _buildSizeInput(),
              const SizedBox(height: fieldSpacing),
              _buildDescriptionInput(),
              const SizedBox(height: sectionSpacing + 8),
              _buildSubmitButton(),
              const SizedBox(height: fieldSpacing),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.pets, color: AppTheme.primaryOrange, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Información Básica",
                      style: AppTheme.lightTheme.textTheme.headlineSmall
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text("Paso 1 de 3",
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryOrange,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text("Completa los datos esenciales para registrar a la mascota.",
            style: AppTheme.lightTheme.textTheme.bodyMedium
                ?.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildNameInput() {
    return TextFormField(
      controller: _nombreCtrl,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(color: AppTheme.textPrimary),
      cursorColor: AppTheme.primaryOrange,
      decoration: _AppDecorations.input(
        label: "Nombre de la mascota *",
        icon: Icons.pets_rounded,
      ),
      validator: (v) =>
          (v == null || v.isEmpty) ? "El nombre es obligatorio" : null,
    );
  }

  Widget _buildSpeciesInput() {
    return DropdownButtonFormField<int>(
      value: _selectedEspecie,
      isExpanded: true,
      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
      iconEnabledColor: AppTheme.primaryOrange,
      dropdownColor: AppTheme.surface,
      decoration: _AppDecorations.input(
        label: "Especie *",
        icon: Icons.category_rounded,
      ),
      items: _speciesList.map((e) {
        return DropdownMenuItem(
            value: e.id, child: Text(e.name, overflow: TextOverflow.ellipsis));
      }).toList(),
      onChanged: (val) {
        if (val == null) return;
        setState(() {
          _selectedEspecie = val;
          _selectedRaza = null;
          _breedsList = [];
        });
        context.read<PetBloc>().add(LoadBreeds(val));
      },
      validator: (v) => v == null ? 'Selecciona una especie' : null,
    );
  }

  Widget _buildBreedInput() {
    final bool isEnabled = _selectedEspecie != null;
    return DropdownButtonFormField<int>(
      value: _selectedRaza,
      isExpanded: true,
      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
      iconEnabledColor: AppTheme.primaryOrange,
      dropdownColor: AppTheme.surface,
      decoration: _AppDecorations.input(
        label: "Raza *",
        icon: Icons.search_rounded,
        hint: !isEnabled ? "Selecciona primero una especie" : "Selecciona una raza",
      ),
      items: _breedsList.map((e) {
        return DropdownMenuItem(
            value: e.id,
            child: Text(e.name, overflow: TextOverflow.ellipsis, maxLines: 1));
      }).toList(),
      onChanged: isEnabled ? (val) => setState(() => _selectedRaza = val) : null,
      validator: (v) => v == null ? 'Selecciona una raza' : null,
      disabledHint: Text("Selecciona primero una especie",
          style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5))),
    );
  }

  // --- CORREGIDO: Edad con asterisco y validador ---
  Widget _buildAgeInput() {
    return TextFormField(
      controller: _edadCtrl,
      keyboardType: TextInputType.number,
      cursorColor: AppTheme.primaryOrange,
      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
      decoration: _AppDecorations.input(
        label: "Edad *", // Se agregó el asterisco
        icon: Icons.calendar_today_rounded,
      ).copyWith(
        suffixText: "meses",
        suffixStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "La edad es obligatoria";
        if (int.tryParse(v) == null) return "Ingresa un número válido";
        return null;
      },
    );
  }

  Widget _buildSexInput() {
    return _FormSection(
      label: "Sexo *",
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          segments: const [
            ButtonSegment(
                value: 'macho', label: Text('Macho'), icon: Icon(Icons.male)),
            ButtonSegment(
                value: 'hembra',
                label: Text('Hembra'),
                icon: Icon(Icons.female)),
          ],
          selected: {_sexo},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() => _sexo = newSelection.first);
          },
          showSelectedIcon: false,
          style: _AppDecorations.segmentedButton(),
        ),
      ),
    );
  }

  Widget _buildSizeInput() {
    return _FormSection(
      label: "Tamaño *",
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'pequeño', label: Text('Pequeño')),
            ButtonSegment(value: 'mediano', label: Text('Mediano')),
            ButtonSegment(value: 'grande', label: Text('Grande')),
          ],
          selected: {_tamano},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() => _tamano = newSelection.first);
          },
          showSelectedIcon: false,
          style: _AppDecorations.segmentedButton(),
        ),
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return _FormSection(
      label: "Descripción *",
      tooltip:
          "Describe su personalidad, comportamiento, necesidades y por qué sería una gran mascota.",
      child: _CustomTextArea(
        controller: _descCtrl,
        maxLength: 500,
        hintText: "Ej: Es muy cariñoso y juguetón. Le encanta correr...",
        validator: (v) {
          if (v == null || v.trim().isEmpty) return "La descripción es requerida";
          if (v.length < 30) return "La descripción debe tener al menos 30 caracteres";
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.arrow_forward_rounded, size: 22),
        label: const Text(
          "Continuar",
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryOrange,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
      ),
    );
  }
}

// --- PRIVATE HELPER WIDGETS ---

class _FormSection extends StatelessWidget {
  final String label;
  final String? tooltip;
  final Widget child;

  const _FormSection({required this.label, this.tooltip, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontSize: 14),
            ),
            if (tooltip != null) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: tooltip!,
                child: Icon(Icons.info_outline,
                    size: 16, color: AppTheme.textSecondary),
                triggerMode: TooltipTriggerMode.tap,
              )
            ]
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _CustomTextArea extends StatelessWidget {
  final TextEditingController controller;
  final int? maxLength;
  final String hintText;
  final String? Function(String?)? validator;

  const _CustomTextArea({
    required this.controller,
    this.maxLength,
    required this.hintText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 6,
      maxLength: maxLength,
      cursorColor: AppTheme.primaryOrange,
      textCapitalization: TextCapitalization.sentences,
      style:
          const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.5),
      decoration: _AppDecorations.input(
        hint: hintText,
        useBorder: true,
        icon: Icons.description,
      )
          .copyWith(
        contentPadding: const EdgeInsets.all(20),
        counterStyle:
            const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      validator: validator,
    );
  }
}

// --- DECORATIONS & STYLES ---

class _AppDecorations {
  static InputDecoration input({
    String? label,
    String? hint,
    required IconData icon,
    bool useBorder = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
          color: useBorder
              ? AppTheme.textSecondary.withOpacity(0.2)
              : Colors.transparent),
    );

    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppTheme.textSecondary.withOpacity(0.2)),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
      hintStyle:
          TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 14),
      prefixIcon: label != null ? Icon(icon, color: AppTheme.primaryOrange, size: 22) : null,
      border: useBorder ? enabledBorder : border,
      enabledBorder: useBorder ? enabledBorder : border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      filled: true,
      fillColor: AppTheme.surface,
    );
  }

  static ButtonStyle segmentedButton() {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        return states.contains(MaterialState.selected)
            ? AppTheme.primaryOrange
            : AppTheme.surface;
      }),
      foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        return states.contains(MaterialState.selected)
            ? Colors.white
            : AppTheme.textSecondary;
      }),
      side: MaterialStateProperty.all(
          BorderSide(color: AppTheme.textSecondary.withOpacity(0.2))),
      padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
      textStyle:
          MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.w500)),
      shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}