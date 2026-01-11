import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adopter_request_card.dart';
import '../../presentation/bloc/adoption_bloc.dart';
import '../../../../core/widgets/app_loader.dart';

class AdopterRequestsScreen extends StatefulWidget {
  const AdopterRequestsScreen({super.key});

  @override
  State<AdopterRequestsScreen> createState() => _AdopterRequestsScreenState();
}

class _AdopterRequestsScreenState extends State<AdopterRequestsScreen> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _currentUserId = user?.id;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<AdoptionBloc>()..add(_currentUserId != null ? LoadAdopterRequests(_currentUserId!) : LoadAdopterRequests('')),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Solicitudes'),
          backgroundColor: Colors.white,
        ),
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: BlocBuilder<AdoptionBloc, AdoptionState>(
            builder: (context, state) {
              if (state is AdoptionLoading) {
                return const Center(child: AppLoader(color: AppTheme.primaryOrange, size: 60));
              }
              if (state is AdoptionLoaded) {
                if (state.requests.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: state.requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final req = state.requests[index];
                    return AdopterRequestCard(request: req, adopterId: _currentUserId!);
                  },
                );
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("No se pudieron cargar los datos."),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () {
                        final id = _currentUserId;
                        if (id != null) {
                          context.read<AdoptionBloc>().add(LoadAdopterRequests(id));
                        }
                      },
                      icon: const Icon(Icons.refresh, color: AppTheme.primaryOrange),
                      label: const Text("Reintentar", style: TextStyle(color: AppTheme.primaryOrange)),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.mark_email_read_outlined, size: 60, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text("Sin solicitudes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Aún no has enviado solicitudes. Busca una mascota y envía tu interés desde su detalle.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}
