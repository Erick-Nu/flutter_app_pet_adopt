import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Asegúrate de que las rutas sean correctas según tu proyecto
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/pdf_generator_service.dart';
import '../../domain/entities/pet_entity.dart';
import '../bloc/pet_bloc.dart';
import '../bloc/pet_event.dart';
import '../bloc/pet_state.dart';
 

class PetDetailScreen extends StatefulWidget {
  final PetEntity pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  int _currentImageIndex = 0;
  bool _isGeneratingPdf = false;

  void _generatePdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      await PdfGeneratorService.generateAndPrintPetSheet(widget.pet);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generando PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colores auxiliares para el tema médico
    final medicalColor = Colors.teal.shade700;
    final medicalBg = Colors.teal.shade50;
    final pet = widget.pet;

    // Imágenes para carrusel: usar gallery si existe, sino avatar
    final images = pet.galleryUrls.isNotEmpty
        ? pet.galleryUrls
        : (pet.avatarUrl != null && pet.avatarUrl!.isNotEmpty
            ? [pet.avatarUrl!]
            : <String>[]);

    return BlocListener<PetBloc, PetState>(
      listener: (context, state) {
        if (state is PetsLoaded) {
          if (mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: CustomScrollView(
          slivers: [
            // 1. APP BAR CON CARRUSEL
            SliverAppBar(
              expandedHeight: 350,
              pinned: true,
              backgroundColor: AppTheme.primaryOrange,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                pet.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 5)],
                ),
              ),
              actions: [
                // Botón Editar
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      // Navegación a edición (puedes conectar tu Wizard aquí)
                      // Ojo: Para editar con el Wizard, necesitarías adaptarlo para recibir una 'pet' existente
                    },
                  ),
                ),
                // Botón Eliminar
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () => _confirmDelete(context),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    images.isEmpty
                        ? Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.pets, size: 80, color: Colors.white),
                          )
                        : PageView.builder(
                            itemCount: images.length,
                            onPageChanged: (i) => setState(() => _currentImageIndex = i),
                            itemBuilder: (_, idx) => Image.network(images[idx], fit: BoxFit.cover),
                          ),

                    // Degradado superior
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                    ),

                    // Indicador de páginas
                    if (images.length > 1)
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: images.asMap().entries.map((entry) {
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == entry.key
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 2. CONTENIDO PRINCIPAL
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -20), // Efecto de solapamiento
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER: Nombre y Estado ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.pet.nombre,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 32,
                                    color: Colors.black87,
                                  ),
                            ),
                          ),
                          _buildStatusBadge(widget.pet.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Raza (si existiera en el modelo actual) o ID
                      Text(
                        "ID: ${widget.pet.id.substring(0, 8)}...",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      
                      const SizedBox(height: 24),

                      // --- ATRIBUTOS RÁPIDOS (Grid) ---
                      Row(
                        children: [
                          _buildAttributeCard(
                            "Edad", 
                            "${widget.pet.edad ?? '?'} años", 
                            Icons.cake_rounded, 
                            Colors.orange.shade100, 
                            Colors.orange.shade800
                          ),
                          const SizedBox(width: 12),
                          _buildAttributeCard(
                            "Sexo", 
                            widget.pet.sexo.toUpperCase(), 
                            widget.pet.sexo == 'macho' ? Icons.male : Icons.female, 
                            widget.pet.sexo == 'macho' ? Colors.blue.shade50 : Colors.pink.shade50,
                            widget.pet.sexo == 'macho' ? Colors.blue.shade700 : Colors.pink.shade700,
                          ),
                          const SizedBox(width: 12),
                          _buildAttributeCard(
                            "Tamaño", 
                            widget.pet.tamano ?? 'N/A', 
                            Icons.height, 
                            Colors.purple.shade50, 
                            Colors.purple.shade700
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // --- SECCIÓN: FICHA MÉDICA ---
                      if (widget.pet.fichaMedica != null) ...[
                        Row(
                          children: [
                            Icon(Icons.medical_services_rounded, color: medicalColor),
                            const SizedBox(width: 10),
                            Text(
                              "Ficha Médica",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: medicalBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: medicalColor.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Peso
                              Row(
                                children: [
                                  Icon(Icons.monitor_weight_outlined, size: 20, color: medicalColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Peso: ${widget.pet.fichaMedica!.pesoKg} Kg",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600, 
                                      color: medicalColor,
                                      fontSize: 16
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              
                              // Badges Médicos (Wrap)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildMedicalBadge("Esterilizado", widget.pet.fichaMedica!.esEsterilizado),
                                  _buildMedicalBadge("Desparasitado", widget.pet.fichaMedica!.esDesparasitado),
                                  _buildMedicalBadge("Vacunas al día", widget.pet.fichaMedica!.tieneVacunas),
                                ],
                              ),

                              // Observaciones Veterinarias
                              if (widget.pet.fichaMedica!.observaciones != null && 
                                  widget.pet.fichaMedica!.observaciones!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  "Observaciones:",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: medicalColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.pet.fichaMedica!.observaciones!,
                                  style: TextStyle(color: Colors.teal.shade900, fontStyle: FontStyle.italic),
                                ),
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // --- SECCIÓN: HISTORIA ---
                      Text(
                        "Conoce su historia",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.pet.descripcion ?? 'Sin descripción disponible para esta mascota.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- SECCIÓN: GALERÍA (CUERPO) ---
                      if (images.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.photo_library_outlined, color: Colors.black87),
                            const SizedBox(width: 10),
                            Text('Galería', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 110,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: images.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (ctx, idx) {
                              final url = images[idx];
                              return GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      backgroundColor: Colors.black,
                                      insetPadding: const EdgeInsets.all(0),
                                      child: Stack(
                                        children: [
                                          PageView.builder(
                                            itemCount: images.length,
                                            controller: PageController(initialPage: idx),
                                            itemBuilder: (_, i) => InteractiveViewer(
                                              child: Image.network(images[i], fit: BoxFit.contain),
                                            ),
                                          ),
                                          Positioned(
                                            top: 30,
                                            right: 20,
                                            child: IconButton(
                                              icon: const Icon(Icons.close, color: Colors.white),
                                              onPressed: () => Navigator.of(context).pop(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(url, width: 140, height: 110, fit: BoxFit.cover),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 100), // Espacio para scroll final
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // FAB PDF
        floatingActionButton: _isGeneratingPdf
            ? const FloatingActionButton(
                onPressed: null,
                child: CircularProgressIndicator(color: Colors.white),
              )
            : FloatingActionButton.extended(
                onPressed: _generatePdf,
                backgroundColor: Colors.black87,
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                label: const Text(
                  'FICHA TÉCNICA',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildAttributeCard(String label, String value, IconData icon, Color bgColor, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: iconColor.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalBadge(String label, bool value) {
    if (!value) return const SizedBox.shrink(); // Si es falso no mostramos nada (o podrías mostrarlo gris)
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.teal),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.teal.shade800, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text = status.toUpperCase();

    switch (status) {
      case 'disponible':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'adoptado':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case 'en_espera':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar mascota?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              log('[PetDetail] Eliminando ${widget.pet.id}');
              Navigator.pop(ctx);
              context.read<PetBloc>().add(DeletePetEvent(widget.pet.id, widget.pet.fundacionId));
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}