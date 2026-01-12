import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/notification_service.dart';
import '../bloc/adopter_profile_bloc.dart';
import '../bloc/adoption_bloc.dart';
import 'tabs/tab_inicio_adopter.dart';
import 'tabs/tab_mapa_adopter.dart';
import 'tabs/tab_solicitudes_adopter.dart';
import 'tabs/tab_perfil_adopter.dart';
import 'tabs/tab_chat_adopter.dart';

class HomeAdopterScreen extends StatefulWidget {
  const HomeAdopterScreen({super.key});

  @override
  State<HomeAdopterScreen> createState() => _HomeAdopterScreenState();
}

class _HomeAdopterScreenState extends State<HomeAdopterScreen> {
  int _selectedIndex = 0;
  RealtimeChannel? _adoptionChannel; // Variable para la suscripción

  // Lista de Tabs
  final List<Widget> _pages = [
    const TabInicioAdopter(),      // 0. Inicio
    const TabMapaAdopter(),        // 1. Mapa
    const TabChatAdopter(),        // 2. IA
    const TabSolicitudesAdopter(), // 3. Solicitudes
    const TabPerfilAdopter(),      // 4. Perfil
  ];

  @override
  void initState() {
    super.initState();
    _setupAdopterListener();
  }

  void _setupAdopterListener() {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) {
      print("❌ No hay usuario autenticado para escuchar solicitudes");
      return;
    }

    print("🟢 Iniciando escucha (Adoptante) para ID: $myId");

    try {
      _adoptionChannel = Supabase.instance.client
          .channel('adopter_alerts')
          .onPostgresChanges(
            event: PostgresChangeEvent.update, // Escuchamos ACTUALIZACIONES
            schema: 'public',
            table: 'adopciones',
            callback: (payload) {
              final newRecord = payload.newRecord;
              print("🔔 Evento recibido en adopciones: $newRecord");
              
              // 1. ¿Es una solicitud mía?
              if (newRecord['adoptante_id'] == myId) {
                final estado = newRecord['estado_tramite'];
                
                // 2. Notificar según el estado
                if (estado == 'aprobada') {
                  print("✅ Solicitud APROBADA");
                  NotificationService().showNotification(
                    '¡Felicidades! 🎉',
                    'Tu solicitud de adopción ha sido APROBADA.',
                  );
                } else if (estado == 'rechazada') {
                  print("❌ Solicitud RECHAZADA");
                  NotificationService().showNotification(
                    'Solicitud Actualizada',
                    'Tu solicitud de adopción ha sido rechazada.',
                  );
                }
                
                // Opcional: Recargar lista
                // context.read<AdoptionBloc>().add(LoadAdopterRequests(myId));
              }
            },
          )
          .subscribe();

      print("✅ Canal de escucha configurado exitosamente");
    } catch (e) {
      print("❌ Error configurando listener: $e");
    }
  }

  @override
  void dispose() {
    if (_adoptionChannel != null) {
      Supabase.instance.client.removeChannel(_adoptionChannel!);
      print("🛑 Canal de escucha cancelado");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AdopterProfileBloc>()),
        // Bloc dedicado para solicitudes del adoptante (carga lista y abre chat cuando se apruebe)
        BlocProvider(create: (_) => di.sl<AdoptionBloc>()),
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