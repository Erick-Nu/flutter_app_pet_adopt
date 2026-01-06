import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/injection_container.dart';
import '../../../pets/presentation/bloc/pet_bloc.dart';
import '../../../pets/presentation/bloc/pet_event.dart';
import '../../../pets/presentation/screens/create_pet/pet_creation_wizard.dart';
import '../../data/repositories/foundation_repository_impl.dart';
import '../bloc/profile/foundation_profile_bloc.dart';
import 'tabs/tab_inicio.dart';
import 'tabs/tab_mascotas.dart';
import 'tabs/tab_profile.dart';



class TabSolicitudes extends StatelessWidget {
  const TabSolicitudes({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('📄 Solicitudes (Próximamente)', style: TextStyle(fontSize: 18, color: Colors.grey)),
    );
  }
}



// -----------------------------------------------------------------------------
// PANTALLA PRINCIPAL (SCAFFOLD)
// -----------------------------------------------------------------------------

class HomeFoundationScreen extends StatefulWidget {
  const HomeFoundationScreen({super.key});

  @override
  State<HomeFoundationScreen> createState() => _HomeFoundationScreenState();
}

class _HomeFoundationScreenState extends State<HomeFoundationScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const TabInicio(),
    const TabMascotas(),
    const TabSolicitudes(),
    const TabProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.deepOrange;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<PetBloc>()..add(LoadPets(userId))),
        BlocProvider(
          create: (_) => FoundationProfileBloc(
            FoundationRepositoryImpl(Supabase.instance.client),
          ),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: _tabs,
          ),
        ),

        floatingActionButton: _currentIndex == 1
            ? Builder(
                builder: (ctx) {
                  return FloatingActionButton.extended(
                    onPressed: () {
                      final petBloc = ctx.read<PetBloc>();
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: petBloc,
                            child: const PetCreationWizard(),
                          ),
                        ),
                      );
                    },
                    backgroundColor: primaryColor,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Nueva Mascota', style: TextStyle(color: Colors.white)),
                  );
                },
              )
            : null,

        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: MaterialStateProperty.all(
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          child: NavigationBar(
            elevation: 0,
            backgroundColor: Colors.white,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            indicatorColor: primaryColor.withOpacity(0.1),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard, color: primaryColor),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.pets_outlined),
                selectedIcon: Icon(Icons.pets, color: primaryColor),
                label: 'Mascotas',
              ),
              NavigationDestination(
                icon: Icon(Icons.mark_email_unread_outlined),
                selectedIcon: Icon(Icons.mark_email_unread, color: primaryColor),
                label: 'Solicitudes',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: primaryColor),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}