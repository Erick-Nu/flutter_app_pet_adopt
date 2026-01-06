import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/pet_entity.dart';
import '../bloc/pet_bloc.dart';
import '../bloc/pet_event.dart';
import '../bloc/pet_state.dart';
import 'pet_form_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final PetEntity pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<PetBloc, PetState>(
      listener: (context, state) {
        // Cuando se carga la lista después de eliminar, cerramos la pantalla
        if (state is PetsLoaded) {
          // Navegar atrás solo si estamos en la pantalla de detalles
          if (mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // 1. App Bar con Imagen Grande
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppTheme.primaryOrange,
              flexibleSpace: FlexibleSpaceBar(
                background: widget.pet.avatarUrl != null && widget.pet.avatarUrl!.isNotEmpty
                    ? Image.network(widget.pet.avatarUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.pets, size: 100, color: Colors.grey.shade400),
                      ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    final petBloc = context.read<PetBloc>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: petBloc,
                          child: PetFormScreen(petToEdit: widget.pet),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),

            // 2. Información
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.pet.nombre,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 32),
                        ),
                        _buildStatusBadge(widget.pet.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildChip(Icons.cake, '${widget.pet.edad} años'),
                        const SizedBox(width: 10),
                        _buildChip(
                          widget.pet.sexo == 'macho' ? Icons.male : Icons.female, 
                          widget.pet.sexo.toUpperCase(),
                          color: widget.pet.sexo == 'macho' ? Colors.blue : Colors.pink,
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Sobre mí',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.pet.descripcion ?? 'Sin descripción disponible.',
                      style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar mascota?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Cerrar alerta
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              log('[PetDetail] Confirmando eliminación de mascota ${widget.pet.id}');
              Navigator.pop(ctx); // Cerrar diálogo
              // Disparar evento de borrado - El BlocListener se encargará de cerrar la pantalla
              context.read<PetBloc>().add(DeletePetEvent(widget.pet.id, widget.pet.fundacionId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mascota eliminada')),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, {Color color = Colors.black54}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'disponible' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}