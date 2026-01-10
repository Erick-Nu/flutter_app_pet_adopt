import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/pet_entity.dart';
import '../../bloc/pet_bloc.dart';
import '../../bloc/pet_event.dart';

class Step2MedicalInfo extends StatefulWidget {
  final VoidCallback onNext;
  final PetEntity? petToEdit;

  const Step2MedicalInfo({super.key, required this.onNext, this.petToEdit});

  @override
  State<Step2MedicalInfo> createState() => _Step2MedicalInfoState();
}

class _Step2MedicalInfoState extends State<Step2MedicalInfo> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _pesoCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  // Estados Booleanos
  bool _esEsterilizado = false;
  bool _esDesparasitado = false;
  bool _vacunasAlDia = false;
  bool _tieneMicrochip = false;
  // bool _tieneDiscapacidad = false; // Opcional, si lo requieres descoméntalo

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.petToEdit != null) {
      final p = widget.petToEdit!;
      if (p.fichaMedica != null) {
        final f = p.fichaMedica!;
        _esEsterilizado = f.esEsterilizado;
        _esDesparasitado = f.esDesparasitado;
        _vacunasAlDia = f.tieneVacunas;
        _tieneMicrochip = f.tieneMicrochip;
        _pesoCtrl.text = f.pesoKg > 0 ? f.pesoKg.toString() : '';
        _observacionesCtrl.text = f.observaciones ?? '';
      }
    }
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<PetBloc>().add(PetCreateStep2Changed(
            esEsterilizado: _esEsterilizado,
            esDesparasitado: _esDesparasitado,
            vacunasAlDia: _vacunasAlDia,
            tieneMicrochip: _tieneMicrochip,
            peso: double.tryParse(_pesoCtrl.text.replaceAll(',', '.')),
            tieneDiscapacidad: false, // O mapear variable si existe
            observaciones: _observacionesCtrl.text.trim(),
          ));
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    const double fieldSpacing = 20.0;
    const double sectionSpacing = 32.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: sectionSpacing),

            // --- SECCIÓN 1: ESTADO DE SALUD ---
            Text(
              "Estado de Salud",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildSwitchTile(
              label: "Esterilizado / Castrado",
              icon: Icons.medical_services_outlined,
              value: _esEsterilizado,
              onChanged: (v) => setState(() => _esEsterilizado = v),
            ),
            const SizedBox(height: 12),
            
            _buildSwitchTile(
              label: "Vacunas al Día",
              icon: Icons.vaccines_outlined,
              value: _vacunasAlDia,
              onChanged: (v) => setState(() => _vacunasAlDia = v),
            ),
            const SizedBox(height: 12),
            
            _buildSwitchTile(
              label: "Desparasitado",
              icon: Icons.bug_report_outlined,
              value: _esDesparasitado,
              onChanged: (v) => setState(() => _esDesparasitado = v),
            ),
            const SizedBox(height: 12),
            
            _buildSwitchTile(
              label: "Tiene Microchip",
              icon: Icons.qr_code,
              value: _tieneMicrochip,
              onChanged: (v) => setState(() => _tieneMicrochip = v),
            ),

            const SizedBox(height: sectionSpacing),

            // --- SECCIÓN 2: DATOS FÍSICOS ---
            Text(
              "Detalles Físicos",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            _buildWeightInput(),
            
            const SizedBox(height: fieldSpacing),

            _buildObservacionesInput(),

            const SizedBox(height: sectionSpacing + 8),

            _buildSubmitButton(),
            const SizedBox(height: fieldSpacing),
          ],
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
              child: Icon(Icons.health_and_safety_rounded, color: AppTheme.primaryOrange, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ficha Médica",
                      style: AppTheme.lightTheme.textTheme.headlineSmall
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text("Paso 2 de 3",
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryOrange,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text("Indica el estado de salud y cuidados veterinarios.",
            style: AppTheme.lightTheme.textTheme.bodyMedium
                ?.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }

  /// Tarjeta de Switch con estilo "Naranja Opaco" cuando está inactivo
  Widget _buildSwitchTile({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    // Definimos el color inactivo como un naranja con opacidad media (el "naranja opaco")
    final Color inactiveBorderColor = AppTheme.primaryOrange.withOpacity(0.5);
    final Color activeColor = AppTheme.primaryOrange;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          // Si está activo: Fondo Naranja. Si no: Fondo blanco.
          color: value ? activeColor : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // Si está activo: Borde Naranja. Si no: Borde Naranja Opaco.
            color: value ? activeColor : inactiveBorderColor,
            width: 1.5,
          ),
          boxShadow: value 
            ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
            : [],
        ),
        child: Row(
          children: [
            // Icono
            Icon(
              icon,
              // Si está activo: Blanco. Si no: Naranja.
              color: value ? Colors.white : AppTheme.primaryOrange,
              size: 24,
            ),
            const SizedBox(width: 12),
            // Texto
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  // Si está activo: Blanco y Bold. Si no: Gris Oscuro y Normal.
                  color: value ? Colors.white : AppTheme.textPrimary,
                  fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
            // Switch visual (opcional, o podemos dejar solo la tarjeta cliqueable)
            // Aquí usamos un icono de check o círculo para reforzar el estado
            Icon(
              value ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: value ? Colors.white : inactiveBorderColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightInput() {
    return TextFormField(
      controller: _pesoCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      cursorColor: AppTheme.primaryOrange,
      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
      decoration: _AppDecorations.input(
        label: "Peso Aproximado",
        icon: Icons.monitor_weight_rounded,
        hint: "0.0",
      ).copyWith(
        suffixText: "kg",
        suffixStyle: TextStyle(
          color: AppTheme.textSecondary, 
          fontWeight: FontWeight.bold
        ),
      ),
      validator: (v) {
        if (v != null && v.isNotEmpty) {
          final n = double.tryParse(v.replaceAll(',', '.'));
          if (n == null) return "Ingresa un peso válido";
          if (n <= 0) return "El peso debe ser mayor a 0";
        }
        return null;
      },
    );
  }

  Widget _buildObservacionesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Observaciones Médicas",
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _observacionesCtrl,
          maxLines: 4,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          cursorColor: AppTheme.primaryOrange,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.5),
          decoration: _AppDecorations.input(
            // SIN EMOJIS, texto limpio
            hint: "Alergias, tratamientos en curso, cirugías recientes...",
            useBorder: true
          ).copyWith(
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
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
          "Siguiente: Fotos",
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

// --- DECORACIONES ---

class _AppDecorations {
  static InputDecoration input({
    String? label,
    String? hint,
    IconData? icon,
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
      prefixIcon: icon != null ? Icon(icon, color: AppTheme.primaryOrange, size: 22) : null,
      border: useBorder ? enabledBorder : border,
      enabledBorder: useBorder ? enabledBorder : border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      filled: true,
      fillColor: AppTheme.surface,
    );
  }
}