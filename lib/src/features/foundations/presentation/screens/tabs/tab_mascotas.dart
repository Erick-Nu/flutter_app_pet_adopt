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
  final List<String> _filters = ['Todos', 'Disponible', 'Adoptado', 'En Espera'];
  final List<String> _statusValues = ['', 'disponible', 'adoptado', 'en_espera'];
  int _selectedFilterIndex = 0;
  
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      context.read<PetBloc>().add(LoadPets(userId));
    }
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
        // --- 1. BARRA SUPERIOR ---
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
              TextField(
                controller: _searchCtrl,
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
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
                ),
              ),
              const SizedBox(height: 15),
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

        // --- 2. LISTA ---
        Expanded(
          child: BlocConsumer<PetBloc, PetState>(
            listenWhen: (previous, current) => 
                current.actionStatus != PetActionStatus.idle,
            listener: (context, state) {
              if (state.actionStatus == PetActionStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.actionMessage ?? 'Error desconocido'), backgroundColor: Colors.red),
                );
              } else if (state.actionStatus == PetActionStatus.success) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.actionMessage ?? 'Éxito'), backgroundColor: Colors.green),
                );
              }
            },
            builder: (context, state) {
              // Si está cargando LA LISTA por primera vez o recargando explícitamente
              if (state.status == PetStatus.loading && state.pets.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
              }

              if (state.status == PetStatus.error && state.pets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text(state.errorMessage ?? 'Error al cargar'),
                      TextButton(onPressed: _loadData, child: const Text("Reintentar"))
                    ],
                  ),
                );
              }

              // FILTRADO LOCAL
              final filteredPets = state.pets.where((pet) {
                final matchesSearch = _searchQuery.isEmpty || pet.nombre.toLowerCase().contains(_searchQuery);
                final selectedStatus = _statusValues[_selectedFilterIndex];
                final matchesStatus = selectedStatus.isEmpty || pet.status == selectedStatus;
                return matchesSearch && matchesStatus;
              }).toList();

              if (filteredPets.isEmpty) {
                if (state.status == PetStatus.loading) {
                   // Si está recargando pero aún no hay datos que mostrar tras el filtro
                   return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
                }
                return Center(
                  child: Text(
                    _searchQuery.isNotEmpty ? 'No hay coincidencias' : 'No hay mascotas registradas',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _loadData(),
                color: AppTheme.primaryOrange,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: filteredPets.length,
                  itemBuilder: (context, index) {
                    final pet = filteredPets[index];
                    return PetCard(
                      pet: pet,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<PetBloc>(),
                              child: PetDetailScreen(pet: pet),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}