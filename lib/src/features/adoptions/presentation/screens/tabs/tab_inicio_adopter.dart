import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/pet_card.dart';
import '../../../../../core/widgets/custom_search_bar.dart';
import '../../../../pets/presentation/bloc/pet_bloc.dart';
import '../../../../pets/presentation/bloc/pet_event.dart';
import '../../../../pets/presentation/bloc/pet_state.dart';
import '../../../../pets/presentation/screens/pet_detail_screen.dart';

class TabInicioAdopter extends StatefulWidget {
  const TabInicioAdopter({super.key});

  @override
  State<TabInicioAdopter> createState() => _TabInicioAdopterState();
}

class _TabInicioAdopterState extends State<TabInicioAdopter> {
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['Todos', 'Perros', 'Gatos', 'Pequeños', 'Cachorros'];

  @override
  void initState() {
    super.initState();
    context.read<PetBloc>().add(LoadAllAvailablePets());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => context.read<PetBloc>().add(LoadAllAvailablePets()),
        color: AppTheme.primaryOrange,
        child: CustomScrollView(
          slivers: [
            // 1. App Bar Flotante con Saludo
            SliverAppBar(
              floating: true,
              pinned: false,
              snap: true,
              backgroundColor: AppTheme.background,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hola, Humano 👋",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    "Adopta un amigo",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textPrimary),
                    onPressed: () {},
                  ),
                )
              ],
            ),

            // 2. Buscador Pegajoso (Persistent Header)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverSearchDelegate(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: CustomSearchBar(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    onFilterTap: () {
                      // TODO: Abrir modal de filtros avanzados
                    },
                  ),
                ),
              ),
            ),

            // 3. Lista de Categorías (Scroll Horizontal)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 60,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedCategoryIndex == index;
                    return Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategoryIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryOrange : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryOrange : Colors.grey.shade200,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryOrange.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Text(
                            _categories[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 4. Lista de Mascotas
            BlocBuilder<PetBloc, PetState>(
              builder: (context, state) {
                if (state is PetsLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (state is PetsError) {
                  return SliverFillRemaining(
                    child: Center(child: Text(state.message)),
                  );
                } else if (state is PetsLoaded) {
                  // Filtrar por texto de búsqueda
                  final filteredPets = state.pets.where((pet) {
                    final matchesSearch = pet.nombre
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                    // TODO: Agregar lógica de filtrado por categoría
                    return matchesSearch;
                  }).toList();

                  if (filteredPets.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pets, size: 60, color: Colors.grey),
                            SizedBox(height: 10),
                            Text(
                              "No encontramos coincidencias",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final pet = filteredPets[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: PetCard(
                              pet: pet,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<PetBloc>(),
                                      child: PetDetailScreen(
                                        pet: pet,
                                        isAdopterView: true,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: filteredPets.length,
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Delegado para mantener la barra de búsqueda fija al hacer scroll
class _SliverSearchDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverSearchDelegate({required this.child});

  @override
  double get minExtent => 80;

  @override
  double get maxExtent => 80;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppTheme.background,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
