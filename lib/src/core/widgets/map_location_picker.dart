import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapLocationPicker extends StatefulWidget {
  final LatLng initialCenter;
  final bool isReadOnly;
  final Function(LatLng)? onPositionChanged;

  const MapLocationPicker({
    super.key,
    required this.initialCenter,
    this.isReadOnly = false,
    this.onPositionChanged,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late final MapController _mapController;
  late LatLng _currentPosition;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentPosition = widget.initialCenter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initialCenter,
                initialZoom: 15,
                onTap: widget.isReadOnly ? null : (tapPosition, point) {
                  setState(() => _currentPosition = point);
                  if (widget.onPositionChanged != null) {
                    widget.onPositionChanged!(point);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.petadopt.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
            if (!widget.isReadOnly)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
                  ),
                  child: const Text("Toca para mover", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}