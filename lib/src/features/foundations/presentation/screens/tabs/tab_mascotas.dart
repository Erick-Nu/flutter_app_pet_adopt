import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/pet_card.dart';
import 'package:flutter_app_pet_adopt/src/features/pets/presentation/screens/pet_detail_screen.dart';
import 'package:flutter_app_pet_adopt/src/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:flutter_app_pet_adopt/src/features/pets/presentation/bloc/pet_state.dart';

class TabMascotas extends StatefulWidget {
  const TabMascotas({super.key});

  @override
  State<TabMascotas> createState() => _TabMascotasState();
}

class _TabMascotasState extends State<TabMascotas> {
  // Mock de categorías para filtrar
  final List<String> _filters = ['Todos', 'Perros', 'Gatos', 'Otros'];
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // -------------------------------
        // 1. ZONA SUPERIOR (Búsqueda y Filtros)
        // -------------------------------
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Barra de Búsqueda
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o raza...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              
              // Chips de Filtro
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedFilterIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilterIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryOrange : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // -------------------------------
        // 2. LISTA DE MASCOTAS
        // -------------------------------
        Expanded(
          child: BlocBuilder<PetBloc, PetState>(
            builder: (context, state) {
              if (state is PetsLoading || state is PetsInitial) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
              }
              if (state is PetsError) {
                return Center(child: Text('Error: ${state.message}'));
              }
              if (state is PetsLoaded) {
                if (state.pets.isEmpty) {
                  return const Center(child: Text('No hay mascotas registradas 🐶'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: state.pets.length,
                  itemBuilder: (context, index) {
                    final pet = state.pets[index];
                    final statusLabel = pet.status == 'disponible' ? 'En Adopción' : 'Reservado';
                    final statusColor = pet.status == 'disponible' ? Colors.green : Colors.orange;

                    return PetCard(
                      heroTag: pet.id,
                      name: pet.nombre,
                      breed: 'Raza desconocida',
                      age: '${pet.edad ?? '-'} años',
                      sex: pet.sexo == 'macho' ? 'Macho' : 'Hembra',
                      status: statusLabel,
                      statusColor: statusColor,
                      imageUrl: pet.avatarUrl,
                      onTap: () {
                        final petBloc = context.read<PetBloc>();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: petBloc,
                              child: PetDetailScreen(pet: pet),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}