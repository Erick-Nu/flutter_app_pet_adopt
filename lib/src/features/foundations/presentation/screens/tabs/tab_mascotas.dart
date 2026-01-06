import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/pet_card.dart';
import 'package:flutter_app_pet_adopt/src/features/pets/presentation/screens/pet_detail_screen.dart';
import 'package:flutter_app_pet_adopt/src/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:flutter_app_pet_adopt/src/features/pets/presentation/bloc/pet_event.dart';
import 'package:flutter_app_pet_adopt/src/features/pets/presentation/bloc/pet_state.dart';

class TabMascotas extends StatefulWidget {
  const TabMascotas({super.key});

  @override
  State<TabMascotas> createState() => _TabMascotasState();
}

class _TabMascotasState extends State<TabMascotas> {
  // Filtros por estado
  final List<String> _filters = ['Todos', 'Disponible', 'Adoptado', 'En Espera'];
  final List<String> _statusValues = ['', 'disponible', 'adoptado', 'en_espera'];
  int _selectedFilterIndex = 0;
  
  // Búsqueda por nombre
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Cargar mascotas cuando se inicializa el tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      print('[TabMascotas] Inicializando tab con userId: $userId');
      if (userId.isNotEmpty) {
        print('[TabMascotas] Disparando LoadPets event');
        context.read<PetBloc>().add(LoadPets(userId));
      } else {
        print('[TabMascotas] ERROR: userId está vacío!');
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
                controller: _searchCtrl,
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre...',
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
          child: BlocConsumer<PetBloc, PetState>(
            listener: (context, state) {
              print('[TabMascotas] Estado del BLoC cambió a: ${state.runtimeType}');
              if (state is PetsLoaded) {
                print('[TabMascotas] PetsLoaded con ${state.pets.length} mascotas');
              } else if (state is PetsError) {
                print('[TabMascotas] PetsError: ${state.message}');
              }
            },
            builder: (context, state) {
              print('[TabMascotas] Construyendo UI con estado: ${state.runtimeType}');
              
              // Estado de carga
              if (state is PetsLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryOrange),
                      SizedBox(height: 16),
                      Text('Cargando mascotas...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              
              // Estado inicial - forzar carga
              if (state is PetsInitial) {
                final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
                if (userId.isNotEmpty) {
                  context.read<PetBloc>().add(LoadPets(userId));
                }
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryOrange),
                );
              }
              
              // Error
              if (state is PetsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text('Error al cargar mascotas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(state.message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
                          context.read<PetBloc>().add(LoadPets(userId));
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              
              // Datos cargados
              if (state is PetsLoaded) {
                // Filtrar por búsqueda y estado
                final filteredPets = state.pets.where((pet) {
                  // Filtrar por nombre
                  final matchesSearch = _searchQuery.isEmpty || pet.nombre.toLowerCase().contains(_searchQuery);
                  
                  // Filtrar por estado
                  final selectedStatus = _statusValues[_selectedFilterIndex];
                  final matchesStatus = selectedStatus.isEmpty || pet.status == selectedStatus;
                  
                  return matchesSearch && matchesStatus;
                }).toList();

                if (filteredPets.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
                      context.read<PetBloc>().add(LoadPets(userId));
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    color: AppTheme.primaryOrange,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 300,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isNotEmpty || _selectedFilterIndex > 0
                                    ? Icons.search_off
                                    : Icons.pets_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty || _selectedFilterIndex > 0
                                    ? 'No hay mascotas que coincidan'
                                    : 'No hay mascotas registradas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty || _selectedFilterIndex > 0
                                    ? 'Intenta con otra búsqueda o filtro'
                                    : 'Desliza hacia abajo para actualizar',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
                    context.read<PetBloc>().add(LoadPets(userId));
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: AppTheme.primaryOrange,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    itemCount: filteredPets.length,
                    itemBuilder: (context, index) {
                      final pet = filteredPets[index];

                      return PetCard(
                        pet: pet,
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
                  ),
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