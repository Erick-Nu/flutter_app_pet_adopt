import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // IMPORTANTE: Para el GPS
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../foundations/domain/entities/foundation_entity.dart';
import '../../bloc/profile/foundation_profile_bloc.dart';
import '../../bloc/profile/foundation_profile_event.dart';
import '../../bloc/profile/foundation_profile_state.dart';

class EditFoundationProfileScreen extends StatefulWidget {
  final FoundationEntity foundation;

  const EditFoundationProfileScreen({super.key, required this.foundation});

  @override
  State<EditFoundationProfileScreen> createState() => _EditFoundationProfileScreenState();
}

class _EditFoundationProfileScreenState extends State<EditFoundationProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final MapController _mapController = MapController();

  // Controladores
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _descriptionCtrl;

  // Estado Ubicación
  late String _address;
  late double _lat;
  late double _lng;
  bool _isLoadingLocation = false; // Para mostrar carga al buscar GPS
  
  File? _newProfileImage;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final f = widget.foundation;
    _nameCtrl = TextEditingController(text: f.nombre);
    _phoneCtrl = TextEditingController(text: f.telefono ?? '');
    _descriptionCtrl = TextEditingController(text: f.descripcion ?? '');

    _address = f.direccion ?? 'Sin dirección registrada';
    
    // Coordenadas iniciales (Si no tiene, usamos un default temporal)
    _lat = f.latitud ?? -0.180653;
    _lng = f.longitud ?? -78.467834;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _descriptionCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE IMAGEN ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() => _newProfileImage = File(pickedFile.path));
      }
    } catch (_) {}
  }

  // --- LÓGICA DE GPS SEGURA ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // 1. Verificar si el servicio GPS está encendido
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        throw 'El GPS está desactivado. Por favor enciéndelo.';
      }

      // 2. Verificar Permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permisos de ubicación denegados.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Permisos denegados permanentemente. Habilítalos en Configuración.';
      }

      // 3. Obtener Ubicación
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // 4. Actualizar Mapa
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _address = "Ubicación GPS: ${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}";
      });

      _mapController.move(LatLng(_lat, _lng), 17.0);

    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: "Error: $e",
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  // Actualiza la posición al tocar el mapa manualmente
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _lat = point.latitude;
      _lng = point.longitude;
      _address = "Ubicación manual: ${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}"; 
    });
  }

  void _submitChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedFoundation = widget.foundation.copyWith(
        nombre: _nameCtrl.text.trim(),
        direccion: _address,
        telefono: _phoneCtrl.text.trim(),
        descripcion: _descriptionCtrl.text.trim(),
        latitud: _lat,
        longitud: _lng,
        newLogoFile: _newProfileImage,
      );

      setState(() => _submitted = true);
      // Ajusta según tu BLoC (si soporta imagen o no)
      context.read<FoundationProfileBloc>().add(UpdateProfileEvent(updatedFoundation)); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0, 
        centerTitle: false, 
        title: const Text(
          "Editar Perfil", 
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 20)
        ),
      ),
      body: BlocListener<FoundationProfileBloc, FoundationProfileState>(
        listener: (context, state) {
          if (_submitted && state is ProfileLoaded) {
            showAppSnackBar(
              context,
              message: "Perfil actualizado correctamente",
              type: AppSnackBarType.success,
            );
            Navigator.pop(context);
          } else if (state is ProfileError) {
            showAppSnackBar(
              context,
              message: state.message,
              type: AppSnackBarType.error,
            );
            setState(() => _submitted = false);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildImageSelector(),
                const SizedBox(height: 30),

                Align(alignment: Alignment.centerLeft, child: _buildSectionTitle("Información General")),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _nameCtrl,
                  label: "Nombre de la Fundación",
                  icon: Icons.business,
                  validator: (v) => v!.isEmpty ? "Requerido" : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneCtrl,
                  label: "Teléfono",
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "El teléfono es requerido";
                    if (v.length != 10) return "El teléfono debe tener exactamente 10 dígitos";
                    if (!RegExp(r'^\d+$').hasMatch(v)) return "El teléfono solo debe contener números";
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // --- SECCIÓN DE MAPA CON GPS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle("Ubicación y Dirección"),
                    // Botón pequeño de GPS en el título (opcional, o usamos el del mapa)
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Usa el botón GPS o toca el mapa para fijar la ubicación.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Contenedor del Mapa
                Container(
                  height: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(_lat, _lng), 
                            initialZoom: 15.0,
                            onTap: _onMapTap,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.petadopt.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(_lat, _lng),
                                  width: 60,
                                  height: 80,
                                  alignment: Alignment.topCenter,
                                  child: _buildCustomMarker(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        // --- BOTÓN FLOTANTE GPS ---
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton(
                            mini: false,
                            backgroundColor: Colors.white,
                            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                            child: _isLoadingLocation
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryOrange))
                                : const Icon(Icons.my_location_rounded, color: AppTheme.primaryOrange, size: 28),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                _buildAddressRow(), // Dirección en texto

                const SizedBox(height: 32),

                Align(alignment: Alignment.centerLeft, child: _buildSectionTitle("Sobre Nosotros")),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: "Misión y visión...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: BlocBuilder<FoundationProfileBloc, FoundationProfileState>(
                    builder: (context, state) {
                      final isLoading = state is ProfileLoading || _submitted;
                      return FilledButton(
                        onPressed: isLoading ? null : _submitChanges,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Guardar Cambios", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  /// Marcador personalizado: Patita Naranja
  Widget _buildCustomMarker() {
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
              color: AppTheme.primaryOrange,
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
            child: const Icon(Icons.pets, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 2),
          const Icon(Icons.arrow_drop_down, color: AppTheme.primaryOrange, size: 30),
        ],
      ),
    );
  }

  Widget _buildImageSelector() {
    ImageProvider imageProvider;
    if (_newProfileImage != null) {
      imageProvider = FileImage(_newProfileImage!);
    } else if (widget.foundation.logoUrl != null && widget.foundation.logoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(widget.foundation.logoUrl!);
    } else {
      imageProvider = const AssetImage('assets/images/default_profile.png');
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryOrange, width: 3),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: CircleAvatar(radius: 60, backgroundColor: Colors.white, backgroundImage: imageProvider),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.location_on_rounded, color: AppTheme.primaryOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ubicación seleccionada",
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  _address,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary));
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, String? Function(String?)? validator, int? maxLength}) {
    return TextFormField(
      controller: controller, 
      keyboardType: keyboardType, 
      validator: validator,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label, 
        prefixIcon: Icon(icon, color: AppTheme.primaryOrange),
        filled: true, 
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2)),
        counterText: '', // Ocultar el contador de caracteres
      ),
    );
  }
}