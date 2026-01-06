import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_theme.dart';

class TabMapaAdopter extends StatefulWidget {
  const TabMapaAdopter({super.key});

  @override
  State<TabMapaAdopter> createState() => _TabMapaAdopterState();
}

class _TabMapaAdopterState extends State<TabMapaAdopter> {
  // Coordenadas por defecto (Quito)
  final LatLng _defaultLocation = const LatLng(-0.1807, -78.4678);
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _foundations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFoundations();
  }

  /// Carga las fundaciones que tienen coordenadas válidas
  Future<void> _loadFoundations() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('fundaciones')
          .select('id, nombre, latitud, longitud, logo_url, direccion, telefono')
          .not('latitud', 'is', null) // Solo las que tienen ubicación
          .not('longitud', 'is', null);

      setState(() {
        _foundations = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      // Si hay fundaciones, centrar el mapa en la primera encontrada
      if (_foundations.isNotEmpty) {
        final first = _foundations.first;
        // Pequeño delay para asegurar que el mapa esté listo
        Future.delayed(const Duration(milliseconds: 500), () {
          _mapController.move(
            LatLng(first['latitud'], first['longitud']),
            13.0,
          );
        });
      }
    } catch (e) {
      debugPrint('Error cargando fundaciones en mapa: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showFoundationInfo(Map<String, dynamic> f) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryOrange, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: f['logo_url'] != null
                          ? NetworkImage(f['logo_url'])
                          : null,
                      child: f['logo_url'] == null
                          ? const Icon(Icons.pets, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f['nombre'] ?? 'Fundación',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                f['direccion'] ?? 'Sin dirección registrada',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              Text(
                "¡Visítanos!",
                style: TextStyle(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Estamos ubicados en esta zona. Acércate para conocer a nuestros peluditos o contáctanos al: ${f['telefono'] ?? 'Sin teléfono'}",
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    // TODO: Navegar al perfil completo de la fundación
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text("Ver Mascotas Disponibles"),
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
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultLocation,
              initialZoom: 12.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Evitar rotación accidental
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.petadopt.app',
              ),
              // CAPA DE MARCADORES (PUNTOS ROJOS)
              MarkerLayer(
                markers: _foundations.map((f) {
                  return Marker(
                    point: LatLng(f['latitud'], f['longitud']),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _showFoundationInfo(f),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          // Triángulo inferior del pin (opcional, decorativo)
                          ClipPath(
                            clipper: _TriangleClipper(),
                            child: Container(
                              color: Colors.red,
                              width: 10,
                              height: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          
          // Barra superior flotante
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.map, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Explorar Fundaciones",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${_foundations.length}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Botón para recargar / centrar
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'refresh_map',
              backgroundColor: Colors.white,
              onPressed: _loadFoundations,
              child: const Icon(Icons.refresh, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// Clipper para el piquito del marcador
class _TriangleClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size size) {
    final path = ui.Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<ui.Path> oldClipper) => false;
}
