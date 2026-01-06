import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Asegúrate de que las rutas sean correctas según tu proyecto
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/pdf_generator_service.dart';
import '../../domain/entities/pet_entity.dart';
import '../bloc/pet_bloc.dart';
import '../bloc/pet_state.dart';
import 'create_pet/pet_creation_wizard.dart';

class PetDetailScreen extends StatefulWidget {
  final PetEntity pet;
  final bool isAdopterView;

  const PetDetailScreen({
    super.key, 
    required this.pet,
    this.isAdopterView = false,
  });

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
              actions: widget.isAdopterView
                  ? [] // No mostrar acciones para adoptantes
                  : [
                      // Botón Editar (solo para fundaciones)
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            // Navegar al Wizard en modo edición
                            final petBloc = context.read<PetBloc>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: petBloc,
                                  child: PetCreationWizard(petToEdit: widget.pet),
                                ),
                              ),
                            );
                          },
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

                    // Degradado superior (no bloquear gestos del carrusel)
                    IgnorePointer(
                      ignoring: true,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [Colors.black54, Colors.transparent],
                          ),
                        ),
                      ),
                    ),

                    // Indicador de páginas
                    if (images.length > 1)
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          ignoring: true,
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
                      // ENCABEZADO CON PROTECCIÓN DE ESPACIO
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.pet.nombre,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
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

                      const SizedBox(height: 20),

                      // TARJETAS DE INFO RÁPIDA (Responsive)
                      Row(
                        children: [
                          _buildInfoCard(
                            "Edad",
                            "${widget.pet.edad ?? '?'} años",
                            Icons.cake_rounded,
                            Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoCard(
                            "Sexo",
                            widget.pet.sexo,
                            widget.pet.sexo == 'macho' ? Icons.male : Icons.female,
                            widget.pet.sexo == 'macho' ? Colors.blue : Colors.pink,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoCard(
                            "Tamaño",
                            widget.pet.tamano ?? 'Mediano',
                            Icons.height,
                            Colors.purple,
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
        
        // FAB - Diferente según vista
        floatingActionButton: widget.isAdopterView
            ? FloatingActionButton.extended(
                onPressed: () => _initiateAdoptionChat(context),
                backgroundColor: AppTheme.primaryOrange,
                icon: const Icon(Icons.volunteer_activism, color: Colors.white),
                label: const Text(
                  'SOLICITAR ADOPCIÓN',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            : _isGeneratingPdf
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

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 11,
              ),
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

  /// Inicia el proceso de solicitud de adopción
  void _initiateAdoptionChat(BuildContext context) async {
    // 1. Verificar si ya existe chat (llamada a backend)
    // 2. Si no, crear chat en tabla 'chats'
    // 3. Navegar a la pantalla de chat
    
    // Por ahora, simularemos la navegación al Tab de Solicitudes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Iniciando solicitud de adopción..."))
    );
    Navigator.pop(context); // Vuelve al home (donde podrá ir al tab solicitudes)
    // TODO: Implementar navegación directa al ChatScreen específico
  }

}