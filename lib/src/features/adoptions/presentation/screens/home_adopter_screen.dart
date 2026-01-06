import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_theme.dart';
import '../bloc/adopter_profile_bloc.dart';
import 'tabs/tab_inicio_adopter.dart';
import 'tabs/tab_mapa_adopter.dart';
import 'tabs/tab_solicitudes_adopter.dart';
import 'tabs/tab_perfil_adopter.dart';

class HomeAdopterScreen extends StatefulWidget {
  const HomeAdopterScreen({super.key});

  @override
  State<HomeAdopterScreen> createState() => _HomeAdopterScreenState();
}

class _HomeAdopterScreenState extends State<HomeAdopterScreen> {
  int _selectedIndex = 0;

  // Lista de Tabs
  final List<Widget> _pages = [
    const TabInicioAdopter(),      // 0. Inicio
    const TabMapaAdopter(),        // 1. Mapa
    const Center(child: Text("Chat IA (Próximamente)")), // 2. IA
    const TabSolicitudesAdopter(), // 3. Solicitudes
    const TabPerfilAdopter(),      // 4. Perfil
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AdopterProfileBloc>()),
      ],
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          elevation: 10,
          indicatorColor: AppTheme.primaryOrange.withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primaryOrange),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded, color: AppTheme.primaryOrange),
              label: 'Mapa',
            ),
            NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy, color: AppTheme.primaryOrange),
              label: 'IA',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble, color: AppTheme.primaryOrange),
              label: 'Solicitudes',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppTheme.primaryOrange),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}