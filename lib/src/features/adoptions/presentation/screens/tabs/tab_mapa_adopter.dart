import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TabMapaAdopter extends StatefulWidget {
  const TabMapaAdopter({super.key});

  @override
  State<TabMapaAdopter> createState() => _TabMapaAdopterState();
}

class _TabMapaAdopterState extends State<TabMapaAdopter> {
  List<Map<String, dynamic>> _foundations = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadFoundations();
  }

  Future<void> _loadFoundations() async {
    // Traer fundaciones que tengan ubicación
    final response = await Supabase.instance.client
        .from('fundaciones')
        .select('id, nombre, latitud, longitud, logo_url, direccion')
        .not('latitud', 'is', null);
    
    setState(() {
      _foundations = List<Map<String, dynamic>>.from(response);
    });
  }

  void _showFoundationInfo(Map<String, dynamic> foundation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: foundation['logo_url'] != null ? NetworkImage(foundation['logo_url']) : null,
                    radius: 30,
                    child: foundation['logo_url'] == null ? const Icon(Icons.business) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(foundation['nombre'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(foundation['direccion'] ?? 'Ubicación registrada', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              const Text("Esta fundación tiene mascotas disponibles para adopción. Visita su perfil o contáctalos para más información."),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx), // Aquí podrías ir al perfil público de la fundación
                  child: const Text("Ver Mascotas"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(-0.1807, -78.4678), // Centrar en tu ciudad default
        initialZoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.petadopt.app',
        ),
        MarkerLayer(
          markers: _foundations.map((f) {
            return Marker(
              point: LatLng(f['latitud'], f['longitud']),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => _showFoundationInfo(f),
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
