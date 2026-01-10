import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/pet_card.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../bloc/adopter_profile.dart';
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
  // Filtros
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Carrusel
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  // Datos dummy para banners
  final List<Map<String, String>> _banners = [
    {
      'title': 'Adopta amor',
      'subtitle': 'Un amigo fiel te espera.',
      'image': 'https://images.unsplash.com/photo-1450778869180-41d0601e046e?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Tips de Cuidado',
      'subtitle': 'Guía para nuevos dueños.',
      'image': 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    context.read<PetBloc>().add(LoadAllAvailablePets());
    
    // Cargar perfil del adoptante para mostrar nombre y avatar
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      context.read<AdopterProfileBloc>().add(LoadAdopterProfile(userId));
    }
    
    // Auto-scroll banners
    _bannerTimer = Timer.periodic(const Duration(seconds: 6), (Timer timer) {
      if (_currentBannerIndex < _banners.length - 1) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onPetTap(dynamic pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PetDetailScreen(pet: pet, isAdopterView: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fondo gris muy claro profesional
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // 1. HEADER + BUSCADOR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 28),
                  _buildProfessionalSearchBar(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // 2. CONTENIDO SCROLLABLE
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<PetBloc>().add(LoadAllAvailablePets());
                },
                color: AppTheme.primaryOrange,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Categorías
                    SliverToBoxAdapter(child: _buildCategories()),

                    // Carrusel
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: _buildBannerCarousel(),
                      ),
                    ),

                    // Título Lista
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Explorar Mascotas",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1D1E)),
                            ),
                            if (_searchQuery.isNotEmpty || _selectedCategory != 'Todos')
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedCategory = 'Todos';
                                    _searchController.clear();
                                  });
                                  FocusScope.of(context).unfocus(); // Cerrar teclado
                                },
                                child: Text("Limpiar filtros", style: TextStyle(color: AppTheme.primaryOrange, fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Lista Filtrada
                    BlocBuilder<PetBloc, PetState>(
                      builder: (context, state) {
                        if (state.status == PetStatus.loading) {
                          return const SliverToBoxAdapter(
                            child: Padding(padding: EdgeInsets.only(top: 50), child: AppLoader(color: AppTheme.primaryOrange)),
                          );
                        }

                        // --- FILTRADO LOCAL ---
                        final filteredPets = state.pets.where((pet) {
                          // Filtro Categoría (Simulado, ajusta según tu modelo)
                          bool matchesCategory = true;
                          if (_selectedCategory != 'Todos') {
                            // TODO: Implementar filtrado real por tipo cuando esté disponible en PetEntity
                            // Ejemplo: matchesCategory = pet.tipo == _selectedCategory;
                          }

                          // Filtro Búsqueda (Nombre)
                          bool matchesSearch = true;
                          if (_searchQuery.isNotEmpty) {
                            final query = _searchQuery.toLowerCase();
                            matchesSearch = pet.nombre.toLowerCase().contains(query);
                          }

                          return matchesCategory && matchesSearch;
                        }).toList();

                        if (filteredPets.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
                                  const SizedBox(height: 10),
                                  Text(
                                    "No encontramos resultados",
                                    style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return PetCard(pet: filteredPets[index], onTap: () => _onPetTap(filteredPets[index]));
                              },
                              childCount: filteredPets.length,
                            ),
                          ),
                        );
                      },
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  /// Header Naranja Profesional (Con datos reales del AdopterProfileBloc)
  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<AdopterProfileBloc, AdopterProfileState>(
      builder: (context, state) {
        String displayName = "Adoptante";
        String? avatarUrl;

        if (state is AdopterProfileLoaded) {
          displayName = state.adopter.nombre;
          avatarUrl = state.adopter.avatarUrl;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryOrange, AppTheme.primaryOrange.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOrange.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            children: [
              // Avatar con borde
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImage(avatarUrl)
                      : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                ),
              ),
              const SizedBox(width: 16),
              
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bienvenido de nuevo,",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Botón Ubicación (Decorativo o funcional)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Buscador Rediseñado (Más limpio y moderno)
  Widget _buildProfessionalSearchBar() {
    return Row(
      children: [
        // Campo de Texto
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE0E0E0).withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Color(0xFF1A1D1E), fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9E9E9E), size: 22),
                hintText: "Buscar por nombre...",
                hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Botón Filtro (Separado y destacado)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: Abrir modal de filtros avanzados
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF212121), // Negro suave para contraste elegante
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  /// Filtro de Categorías
  Widget _buildCategories() {
    final categories = ["Todos", "Perros", "Gatos", "Aves"];
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryOrange : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? Colors.transparent : const Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF757575),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Carrusel de Banners Mejorado
  Widget _buildBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _banners.length,
            onPageChanged: (index) => setState(() => _currentBannerIndex = index),
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(banner['image']!),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "NUEVO",
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        banner['title']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        banner['subtitle']!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicadores (Dots)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _banners.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentBannerIndex == entry.key ? 24 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: _currentBannerIndex == entry.key 
                    ? AppTheme.primaryOrange 
                    : const Color(0xFFE0E0E0),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}