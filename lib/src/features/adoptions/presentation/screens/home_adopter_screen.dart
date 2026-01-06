import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class HomeAdopterScreen extends StatefulWidget {
  const HomeAdopterScreen({super.key});

  @override
  State<HomeAdopterScreen> createState() => _HomeAdopterScreenState();
}

class _HomeAdopterScreenState extends State<HomeAdopterScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    Center(child: Text('🏠 Inicio\nRecomendados')),
    Center(child: Text('🔎 Buscar\nEncuentra tu compañero')),
    Center(child: Text('⭐ Favoritos\nTus guardados')),
    Center(child: Text('⚙️ Perfil\nTu información')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio Adoptante'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        indicatorColor: Colors.teal.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.teal),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: Colors.teal),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: Colors.teal),
            label: 'Favoritos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.teal),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
