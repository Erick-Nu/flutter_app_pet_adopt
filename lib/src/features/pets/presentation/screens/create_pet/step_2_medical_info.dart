import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/pet_bloc.dart';
import '../../bloc/pet_event.dart';
import '../../../domain/entities/pet_entity.dart';

class Step2MedicalInfo extends StatefulWidget {
  final VoidCallback onNext;
  final PetEntity? petToEdit;
  
  const Step2MedicalInfo({super.key, required this.onNext, this.petToEdit});

  @override
  State<Step2MedicalInfo> createState() => _Step2MedicalInfoState();
}

class _Step2MedicalInfoState extends State<Step2MedicalInfo> {
  // Badges
  bool _esterilizado = false;
  bool _desparasitado = false;
  bool _vacunasDia = false;
  bool _microchip = false;
  bool _discapacidad = false;

  final _pesoCtrl = TextEditingController();
  final _descDiscapacidadCtrl = TextEditingController();
  final _detalleVacunasCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-llenar si estamos editando
    if (widget.petToEdit != null && widget.petToEdit!.fichaMedica != null) {
      final f = widget.petToEdit!.fichaMedica!;
      _esterilizado = f.esEsterilizado;
      _desparasitado = f.esDesparasitado;
      _vacunasDia = f.tieneVacunas;
      _microchip = f.tieneMicrochip;
      _pesoCtrl.text = f.pesoKg.toString();
    }
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _descDiscapacidadCtrl.dispose();
    _detalleVacunasCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<PetBloc>().add(PetCreateStep2Changed(
      esEsterilizado: _esterilizado,
      esDesparasitado: _desparasitado,
      vacunasAlDia: _vacunasDia,
      tieneMicrochip: _microchip,
      tieneDiscapacidad: _discapacidad,
      peso: double.tryParse(_pesoCtrl.text),
      descDiscapacidad: _discapacidad ? _descDiscapacidadCtrl.text : null,
      detalleVacunas: _detalleVacunasCtrl.text,
    ));
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Salud y Cuidados", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          // PESO
          TextFormField(
            controller: _pesoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Peso aproximado (Kg)",
              suffixText: "Kg",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // BADGES (Switches con iconos)
          _buildSwitch("Esterilizado", Icons.local_hospital, _esterilizado, (v) => setState(() => _esterilizado = v)),
          _buildSwitch("Desparasitado", Icons.health_and_safety, _desparasitado, (v) => setState(() => _desparasitado = v)),
          _buildSwitch("Vacunas al día", Icons.medical_services, _vacunasDia, (v) => setState(() => _vacunasDia = v)),
          _buildSwitch("Tiene Microchip", Icons.memory, _microchip, (v) => setState(() => _microchip = v)),
          
          const Divider(height: 30),
          
          // DISCAPACIDAD (Lógica condicional)
          _buildSwitch("¿Tiene alguna discapacidad?", Icons.accessible, _discapacidad, (v) => setState(() => _discapacidad = v)),
          
          if (_discapacidad) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _descDiscapacidadCtrl,
              decoration: const InputDecoration(
                labelText: "Detalle de la discapacidad",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFFFF3E0), // Fondo suave para resaltar
              ),
            ),
          ],

          const SizedBox(height: 20),
          TextFormField(
            controller: _detalleVacunasCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: "Detalle de vacunas (Opcional)",
              hintText: "Ej: Triple felina, Rabia...",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _submit,
              child: const Text("Siguiente: Galería de Fotos"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSwitch(String title, IconData icon, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      secondary: Icon(icon, color: Colors.orange),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}