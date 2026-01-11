import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../adoptions/presentation/bloc/adoption_bloc.dart';
import '../../../../../core/widgets/request_card.dart';

class TabSolicitudesFoundation extends StatefulWidget {
  const TabSolicitudesFoundation({super.key});

  @override
  State<TabSolicitudesFoundation> createState() => _TabSolicitudesFoundationState();
}

class _TabSolicitudesFoundationState extends State<TabSolicitudesFoundation> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      context.read<AdoptionBloc>().add(LoadFoundationRequests(_currentUserId!));
    }
  }

  Future<void> _onRefresh() async {
    if (_currentUserId != null) {
      context.read<AdoptionBloc>().add(LoadFoundationRequests(_currentUserId!));
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // 1. HEADER PERSONALIZADO (Sin Icono)
            _buildCustomHeader(),

            const SizedBox(height: 10),

            // 2. CONTENIDO PRINCIPAL
            Expanded(
              child: BlocConsumer<AdoptionBloc, AdoptionState>(
                listener: (context, state) {
                  if (state is AdoptionActionSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: state.openChat ? Colors.green : Colors.black87,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    if (state.openChat) {
                      // TODO: Navegar a la pantalla de Chat P2P
                    }
                  } else if (state is AdoptionError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: AppTheme.error),
                    );
                  }
                },
                builder: (context, state) {
                  // A) ESTADO DE CARGA
                  if (state is AdoptionLoading) {
                    return const Center(
                      child: AppLoader(color: AppTheme.primaryOrange, size: 60),
                    );
                  }
                  
                  // B) ESTADO CARGADO (Con o sin datos)
                  if (state is AdoptionLoaded) {
                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: AppTheme.primaryOrange,
                      backgroundColor: Colors.white,
                      displacement: 20,
                      child: state.requests.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: state.requests.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              itemBuilder: (context, index) {
                                final req = state.requests[index];
                                return RequestCard(
                                  request: req,
                                  onAccept: () => context.read<AdoptionBloc>().add(RespondRequestEvent(req, true)),
                                  onReject: () => context.read<AdoptionBloc>().add(RespondRequestEvent(req, false)),
                                );
                              },
                            ),
                    );
                  }
                  
                  // C) ESTADO INICIAL O ERROR
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("No se pudieron cargar los datos."),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh, color: AppTheme.primaryOrange),
                          label: const Text("Reintentar", style: TextStyle(color: AppTheme.primaryOrange)),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  /// Header Flotante Limpio (Sin Icono)
  Widget _buildCustomHeader() {
    return BlocBuilder<AdoptionBloc, AdoptionState>(
      builder: (context, state) {
        int count = 0;
        if (state is AdoptionLoaded) {
          count = state.requests.where((r) => r.status == 'pendiente').length;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24), // Padding ajustado
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOrange.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            children: [
              // Texto Principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Bandeja de Solicitudes",
                      style: TextStyle(
                        fontSize: 20, // Texto ligeramente más grande para compensar
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      count > 0 ? "Tienes $count pendientes de revisión" : "Estás al día",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Badge circular (Solo si hay pendientes)
              if (count > 0)
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)
                    ]
                  ),
                  child: Text(
                    count > 99 ? "99+" : count.toString(),
                    style: const TextStyle(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Estado Vacío
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.mark_email_read_outlined, size: 60, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 20),
                Text(
                  "Sin solicitudes nuevas",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Cuando un adoptante se interese en una de tus mascotas, aparecerá aquí.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}