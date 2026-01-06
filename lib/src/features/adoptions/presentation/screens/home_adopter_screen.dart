import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pet_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../pets/presentation/bloc/pet_bloc.dart';
import '../../../pets/presentation/bloc/pet_event.dart';
import '../../../pets/presentation/bloc/pet_state.dart';
import '../../../pets/presentation/screens/pet_detail_screen.dart';

class HomeAdopterScreen extends StatefulWidget {
  const HomeAdopterScreen({super.key});

  @override
  State<HomeAdopterScreen> createState() => _HomeAdopterScreenState();
}

class _HomeAdopterScreenState extends State<HomeAdopterScreen> {
  int _selectedIndex = 0;

  // Filtros estáticos por ahora
  final List<String> _categories = ['Todos', 'Perros', 'Gatos', 'Pequeños', 'Grandes'];
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    // Cargar mascotas al iniciar. 
    // NOTA: Asegúrate de que tu BLoC soporte cargar mascotas "públicas".
    // Si LoadPets filtra por ID de fundación, necesitarás crear un evento LoadAllPets en el futuro.
    // Por ahora usamos LoadPets con un ID genérico o el del usuario (dependiendo de tu backend).
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    context.read<PetBloc>().add(LoadPets(userId)); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),       // Tab 0: Inicio / Feed
          _buildSearchTab(),     // Tab 1: Búsqueda avanzada
          _buildFavoritesTab(),  // Tab 2: Favoritos
          _buildProfileTab(),    // Tab 3: Perfil
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.black26,
        indicatorColor: AppTheme.primaryOrange.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primaryOrange),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: AppTheme.primaryOrange),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: AppTheme.primaryOrange),
            label: 'Favoritos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primaryOrange),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // --- TAB 1: INICIO (FEED) ---
  Widget _buildHomeTab() {
    return SafeArea(
      child: Column(
        children: [
          // CABECERA Y BUSCADOR
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hola, Adoptante 👋",
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        const Text(
                          "Encuentra tu amigo",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_none, color: AppTheme.primaryOrange),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // BARRA DE BÚSQUEDA
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar raza, nombre...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: Icon(Icons.tune, color: AppTheme.primaryOrange),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                ),
              ],
            ),
          ),
          
          // FILTROS (CATEGORÍAS)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryOrange : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryOrange : Colors.grey.shade300,
                      ),
                      boxShadow: isSelected 
                        ? [BoxShadow(color: AppTheme.primaryOrange.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] 
                        : [],
                    ),
                    child: Center(
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // LISTA DE MASCOTAS
          Expanded(
            child: BlocBuilder<PetBloc, PetState>(
              builder: (context, state) {
                if (state is PetsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is PetsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 40, color: Colors.red),
                        const SizedBox(height: 10),
                        Text(state.message),
                        TextButton(
                          onPressed: () {
                             final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
                             context.read<PetBloc>().add(LoadPets(userId));
                          },
                          child: const Text("Reintentar"),
                        )
                      ],
                    ),
                  );
                } else if (state is PetsLoaded) {
                  if (state.pets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets, size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text("No hay mascotas disponibles", style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    );
                  }
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
                      context.read<PetBloc>().add(LoadPets(userId));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: state.pets.length,
                      itemBuilder: (context, index) {
                        final pet = state.pets[index];
                        return PetCard(
                          pet: pet,
                          onTap: () {
                            // Navegar al detalle pasando el BLoC
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
      ),
    );
  }

  // --- TABS SECUNDARIOS (PLACEHOLDERS) ---
  Widget _buildSearchTab() => const Center(child: Text('Búsqueda Avanzada (Mapa, Raza, etc)'));
  Widget _buildFavoritesTab() => const Center(child: Text('Mis Favoritos'));
  
  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 20),
          const Text("Mi Perfil de Adoptante", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text("Cerrar Sesión"),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          )
        ],
      ),
    );
  }
}