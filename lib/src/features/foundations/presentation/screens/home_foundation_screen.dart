import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../pets/presentation/bloc/pet_bloc.dart';
import '../../../pets/presentation/bloc/pet_event.dart';
import '../../../pets/presentation/screens/pet_form_screen.dart';
import 'tabs/tab_inicio.dart';
import 'tabs/tab_mascotas.dart';



class TabSolicitudes extends StatelessWidget {
  const TabSolicitudes({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('📄 Solicitudes (Próximamente)', style: TextStyle(fontSize: 18, color: Colors.grey)),
    );
  }
}

class TabPerfil extends StatelessWidget {
  const TabPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.deepOrange,
            child: Icon(Icons.business, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 15),
          const Text(
            'Nombre de la Fundación',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text('fundacion@email.com', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          
          // Opciones de menú
          _buildProfileOption(Icons.edit, 'Editar Perfil', () {}),
          _buildProfileOption(Icons.settings, 'Configuración', () {}),
          _buildProfileOption(Icons.help_outline, 'Ayuda y Soporte', () {}),
          
          const Divider(height: 40),
          
          // Botón de Cerrar Sesión (Ahora vive aquí)
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              // Confirmación de UX antes de salir
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('¿Cerrar sesión?'),
                  content: const Text('Tendrás que ingresar tus datos nuevamente.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                      },
                      child: const Text('Salir', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
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
    const TabPerfil(),
  ];

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.deepOrange;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return BlocProvider(
      create: (_) => sl<PetBloc>()..add(LoadPets(userId)),
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
                            child: const PetFormScreen(),
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