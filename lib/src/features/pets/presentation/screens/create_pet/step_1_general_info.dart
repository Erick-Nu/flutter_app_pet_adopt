import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/pet_bloc.dart';
import '../../bloc/pet_event.dart';
import '../../../domain/entities/pet_entity.dart';

class Step1GeneralInfo extends StatefulWidget {
  final VoidCallback onNext;
  final PetEntity? petToEdit;
  
  const Step1GeneralInfo({super.key, required this.onNext, this.petToEdit});

  @override
  State<Step1GeneralInfo> createState() => _Step1GeneralInfoState();
}

class _Step1GeneralInfoState extends State<Step1GeneralInfo> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  
  String _sexo = 'macho';
  String _tamano = 'mediano';
  
  // TODO: Estos deberían venir de una llamada a la BD (GetRaces/GetSpecies)
  int? _selectedEspecie; 
  int? _selectedRaza;

  @override
  void initState() {
    super.initState();
    // Pre-llenar si estamos editando
    if (widget.petToEdit != null) {
      final p = widget.petToEdit!;
      _nombreCtrl.text = p.nombre;
      _descCtrl.text = p.descripcion ?? '';
      if (p.edad != null) _edadCtrl.text = p.edad.toString();
      _sexo = p.sexo;
      _tamano = p.tamano ?? 'mediano';
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
      // Guardamos en el BLoC
      context.read<PetBloc>().add(PetCreateStep1Changed(
        nombre: _nombreCtrl.text,
        descripcion: _descCtrl.text,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("¿Quién es la nueva mascota?", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),

            // NOMBRE
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre de la mascota",
                prefixIcon: Icon(Icons.pets),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? "El nombre es obligatorio" : null,
            ),
            const SizedBox(height: 16),

            // EDAD y SEXO (Row)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _edadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Edad (meses)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // UX: Toggle buttons para Sexo
                ToggleButtons(
                  isSelected: [_sexo == 'macho', _sexo == 'hembra'],
                  onPressed: (idx) {
                    setState(() => _sexo = idx == 0 ? 'macho' : 'hembra');
                  },
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("Macho")),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("Hembra")),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // TAMAÑO (Chips para selección rápida)
            const Text("Tamaño", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: ['pequeño', 'mediano', 'grande'].map((size) {
                return ChoiceChip(
                  label: Text(size.toUpperCase()),
                  selected: _tamano == size,
                  onSelected: (bool selected) {
                    if (selected) setState(() => _tamano = size);
                  },
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            // DESCRIPCIÓN
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Historia o Descripción",
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.length < 20 ? "Escribe al menos 20 caracteres" : null,
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _submit,
                child: const Text("Siguiente: Ficha Médica"),
              ),
            )
          ],
        ),
      ),
    );
  }
}