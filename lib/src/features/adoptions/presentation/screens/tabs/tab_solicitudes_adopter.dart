import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../presentation/bloc/adoption_bloc.dart';
import '../../../../../core/widgets/request_card.dart';

class TabSolicitudesAdopter extends StatefulWidget {
  const TabSolicitudesAdopter({super.key});

  @override
  State<TabSolicitudesAdopter> createState() => _TabSolicitudesAdopterState();
}

class _TabSolicitudesAdopterState extends State<TabSolicitudesAdopter> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      print('🔎 UI: Loading adopter requests for user: $_currentUserId');
      context.read<AdoptionBloc>().add(LoadAdopterRequests(_currentUserId!));
    } else {
      print('🔴 UI: No authenticated user found');
    }
  }

  Future<void> _onRefresh() async {
    if (_currentUserId != null) {
      print('🔄 UI: Refreshing adopter requests');
      context.read<AdoptionBloc>().add(LoadAdopterRequests(_currentUserId!));
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
            _buildCustomHeader(),
            const SizedBox(height: 10),
            Expanded(
              child: BlocBuilder<AdoptionBloc, AdoptionState>(
                builder: (context, state) {
                  print('✅ UI: State changed - ${state.runtimeType}');
                  if (state is AdoptionLoading) {
                    print('✅ UI: Showing loader');
                    return const Center(
                      child: AppLoader(color: AppTheme.primaryOrange, size: 60),
                    );
                  }
                  if (state is AdoptionLoaded) {
                    print('✅ UI: Loaded ${state.requests.length} requests');
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
                                print('✅ UI: Building card for request ${req.id}');
                                return RequestCard(
                                  request: req,
                                  isAdopterView: true,
                                  onAccept: () {},
                                  onReject: () {},
                                );
                              },
                            ),
                    );
                  }
                  if (state is AdoptionError) {
                    print('🔴 UI: Error - ${state.message}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Error: ${state.message}"),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _loadRequests,
                            icon: const Icon(Icons.refresh, color: AppTheme.primaryOrange),
                            label: const Text("Reintentar", style: TextStyle(color: AppTheme.primaryOrange)),
                          )
                        ],
                      ),
                    );
                  }
                  return const Center(child: Text("Estado desconocido"));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return BlocBuilder<AdoptionBloc, AdoptionState>(
      builder: (context, state) {
        int approved = 0;
        int pending = 0;
        if (state is AdoptionLoaded) {
          approved = state.requests.where((r) => r.status == 'aprobada').length;
          pending = state.requests.where((r) => r.status == 'pendiente').length;
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Mis Solicitudes",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pending > 0 ? "$pending pendientes" : "Sin pendientes",
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (approved > 0)
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Text(
                    approved > 99 ? "99+" : approved.toString(),
                    style: const TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

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
          ),
        );
      },
    );
  }
}
