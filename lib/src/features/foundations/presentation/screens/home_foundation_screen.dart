import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/location_requirement_dialog.dart';
import '../../../pets/presentation/bloc/pet_bloc.dart';
import '../../../pets/presentation/bloc/pet_event.dart';
import '../../data/repositories/foundation_repository_impl.dart';
import '../bloc/profile/foundation_profile_bloc.dart';
import '../bloc/profile/foundation_profile_event.dart';
import '../bloc/profile/foundation_profile_state.dart';
import 'tabs/tab_inicio.dart';
import 'tabs/tab_mascotas.dart';
import 'tabs/tab_profile.dart';
import 'tabs/tab_solicitudes_foundation.dart';

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
  bool _hasShownLocationWarning = false;
  RealtimeChannel? _adoptionChannel; // Canal de Supabase para escuchar cambios

  final List<Widget> _tabs = [
    const TabInicio(),
    const TabMascotas(),
    const TabSolicitudesFoundation(),
    const TabPerfilFundacion(),
  ];

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) {
      print("❌ No hay usuario autenticado para escuchar solicitudes");
      return;
    }

    print("🟢 Iniciando escucha de solicitudes para Fundación: $myId");

    try {
      // Configurar el canal de Supabase para escuchar cambios en tiempo real
      _adoptionChannel = Supabase.instance.client
          .channel('public:adopciones:foundation_$myId') // Nombre único del canal
          .onPostgresChanges(
            event: PostgresChangeEvent.insert, // Escuchar solo NUEVOS registros (INSERT)
            schema: 'public',
            table: 'adopciones',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'fundacion_id',
              value: myId, // ¡Clave! Solo notificar si es para MÍ
            ),
            callback: (payload) {
              print("🔔 ¡Nueva solicitud recibida en tiempo real!");
              print("Payload: ${payload.newRecord}");

              // Mostrar la notificación en el dispositivo
              NotificationService().showNotification(
                '¡Nueva Solicitud de Adopción!',
                'Alguien quiere adoptar una de tus mascotas. Revisa la app.',
              );

              // Opcional: Aquí podrías disparar un evento a tu BLoC para recargar la lista automáticamente
              // context.read<FoundationProfileBloc>().add(LoadProfile(myId));
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
    // IMPORTANTE: Cancelar la suscripción al salir para ahorrar recursos
    if (_adoptionChannel != null) {
      Supabase.instance.client.removeChannel(_adoptionChannel!);
      print("🛑 Canal de escucha cancelado");
    }
    super.dispose();
  }

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
          )..add(LoadProfile(userId)),
        ),
      ],
      child: BlocListener<FoundationProfileBloc, FoundationProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded && !_hasShownLocationWarning) {
            final f = state.foundation;
            final missingLocation = f.latitud == null || f.longitud == null || (f.direccion == null || f.direccion!.isEmpty);
            if (missingLocation) {
              _hasShownLocationWarning = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => BlocProvider.value(
                    value: context.read<FoundationProfileBloc>(),
                    child: LocationRequirementDialog(foundation: f),
                  ),
                );
              });
            }
          }
        },
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: _tabs,
            ),
          ),
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
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.pets_outlined),
                  label: 'Mascotas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.mark_email_unread_outlined),
                  label: 'Solicitudes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}