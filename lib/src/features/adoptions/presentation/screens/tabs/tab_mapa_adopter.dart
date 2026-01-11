import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // Para el GPS
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/widgets/app_loader.dart'; // Tu loader personalizado

class TabMapaAdopter extends StatefulWidget {
  const TabMapaAdopter({super.key});

  @override
  State<TabMapaAdopter> createState() => _TabMapaAdopterState();
}

class _TabMapaAdopterState extends State<TabMapaAdopter> {
  final MapController _mapController = MapController();
  
  // Estado
  LatLng? _userLocation;
  List<Map<String, dynamic>> _foundations = [];
  bool _isLoading = true;
  // String? _errorMessage; // Reservado para futuros errores visibles

  // Coordenada default (Quito) por si no hay GPS
  final LatLng _defaultLocation = const LatLng(-0.1807, -78.4678);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  /// Inicializa GPS y Carga de Datos
  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);
    
    // 1. Intentar obtener ubicación del usuario (sin bloquear si falla)
    await _getUserLocation();

    // 2. Cargar fundaciones desde Supabase
    await _loadFoundations();

    setState(() => _isLoading = false);
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Intentar abrir configuración para activar ubicación
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showAppSnackBar(
            context,
            message: 'Habilita los permisos de ubicación en Configuración',
            type: AppSnackBarType.error,
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      
      // Mover el mapa al usuario si se encontró
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_userLocation!, 14.0);
      });

    } catch (e) {
      debugPrint("Error obteniendo GPS: $e");
    }
  }

  Future<void> _loadFoundations() async {
    try {
      final response = await Supabase.instance.client
          .from('fundaciones')
          .select('id, nombre, latitud, longitud, logo_url, direccion, telefono')
          .not('latitud', 'is', null)
          .not('longitud', 'is', null);

      setState(() {
        _foundations = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error cargando fundaciones: $e');
    }
  }

  // --- UI BOTTOM SHEET (Detalle Fundación) ---
  void _showFoundationInfo(Map<String, dynamic> f) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryOrange, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: f['logo_url'] != null ? NetworkImage(f['logo_url']) : null,
                      child: f['logo_url'] == null ? const Icon(Icons.pets, color: Colors.grey) : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f['nombre'] ?? 'Fundación',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_rounded, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(f['telefono'] ?? 'Sin teléfono', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppTheme.primaryOrange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f['direccion'] ?? 'Ubicación registrada',
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    // TODO: Navegar a perfil completo
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.pets),
                  label: const Text("Ver Mascotas en Adopción", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: AppLoader(color: AppTheme.primaryOrange, size: 60),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? _defaultLocation,
              initialZoom: 13.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.petadopt.app',
              ),
              
              // --- CAPA DE MARCADORES ---
              MarkerLayer(
                markers: [
                  // 1. Marcador del Adoptante (AZUL)
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 60,
                      height: 80,
                      alignment: Alignment.topCenter,
                      child: _buildPawMarker(color: Colors.blueAccent, isUser: true),
                    ),

                  // 2. Marcadores de Fundaciones (NARANJA)
                  ..._foundations.map((f) {
                    return Marker(
                      point: LatLng(f['latitud'], f['longitud']),
                      width: 60,
                      height: 80,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => _showFoundationInfo(f),
                        child: _buildPawMarker(color: AppTheme.primaryOrange, isUser: false),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // --- HEADER FLOTANTE ---
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.map_rounded, color: AppTheme.textSecondary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Mapa de Adopción", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Encuentra fundaciones cerca de ti", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${_foundations.length}",
                      style: const TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BOTÓN FLOTANTE "MI UBICACIÓN" ---
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'gps_btn',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: () {
                if (_userLocation != null) {
                  _mapController.move(_userLocation!, 15.0);
                } else {
                  _getUserLocation(); // Reintentar si falló antes
                }
              },
              child: const Icon(Icons.my_location_rounded, color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET MARCADOR (PATITA) ---
  Widget _buildPawMarker({required Color color, required bool isUser}) {
    // Marcador contenido en un tamaño fijo para evitar overflow
    return SizedBox(
      width: 60,
      height: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(
              Icons.pets,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 2),
          Icon(Icons.arrow_drop_down, color: color, size: 28),
        ],
      ),
    );
  }
}