import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/pdf_generator_service.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../domain/entities/pet_entity.dart';
import '../bloc/pet_bloc.dart';
import '../bloc/pet_state.dart';
import '../../../../core/widgets/app_loader.dart';
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
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _generatePdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      await PdfGeneratorService.generateAndPrintPetSheet(widget.pet);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Error generando PDF: $e',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _onEdit() {
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
  }

  void _openFullScreenGallery(List<String> images, int initialIndex) {
    if (images.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (ctx, idx) {
                return InteractiveViewer(
                  child: Image.network(
                    images[idx], 
                    fit: BoxFit.contain,
                    errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    
    // --- 1. LÓGICA PARA EVITAR DUPLICADOS ---
    final Set<String> uniqueImages = {};
    
    // Agregar portada
    if (pet.avatarUrl != null && pet.avatarUrl!.isNotEmpty) {
      uniqueImages.add(pet.avatarUrl!);
    }
    // Agregar galería (el Set filtrará automáticamente si la URL es idéntica)
    uniqueImages.addAll(pet.galleryUrls);
    
    final List<String> allImages = uniqueImages.toList();
    // ----------------------------------------

    // Galería Grid (excluyendo la primera imagen si hay más de una, para variedad)
    final List<String> galleryImages = allImages.length > 1 ? allImages.sublist(1) : [];

    return Scaffold(
        backgroundColor: AppTheme.background,
        body: CustomScrollView(
          slivers: [
            // --- HEADER CARRUSEL ---
            SliverAppBar(
              expandedHeight: 380,
              pinned: true,
              backgroundColor: AppTheme.primaryOrange,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: widget.isAdopterView
                  ? []
                  : [
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Colors.white),
                          onPressed: _onEdit,
                          tooltip: 'Editar',
                        ),
                      ),
                    ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // A. CARRUSEL (FONDO)
                    allImages.isEmpty
                        ? Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.pets, size: 80, color: Colors.white),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: allImages.length,
                            // physics: const BouncingScrollPhysics(), // Scroll suave
                            onPageChanged: (i) => setState(() => _currentImageIndex = i),
                            itemBuilder: (_, idx) {
                              return GestureDetector(
                                onTap: () => _openFullScreenGallery(allImages, idx),
                                child: Image.network(
                                  allImages[idx], 
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),

                    // B. DEGRADADO SUPERIOR (Solo arriba, no cubre el centro)
                    Positioned(
                      top: 0, left: 0, right: 0,
                      height: 100, // Altura limitada
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // C. DEGRADADO INFERIOR (Solo abajo)
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      height: 80, // Altura limitada
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [AppTheme.background, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // D. INDICADORES (Puntos)
                    if (allImages.length > 1)
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: allImages.asMap().entries.map((entry) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _currentImageIndex == entry.key ? 24 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: _currentImageIndex == entry.key
                                    ? AppTheme.primaryOrange
                                    : Colors.white.withOpacity(0.8),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // --- CONTENIDO DEL CUERPO ---
            SliverToBoxAdapter(
              child: Container(
                transform: Matrix4.translationValues(0, -20, 0),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CABECERA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pet.nombre,
                                style: AppTheme.lightTheme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                  fontSize: 34,
                                  height: 1.1
                                ),
                              ),
                                const SizedBox(height: 6),
                                BlocBuilder<PetBloc, PetState>(
                                  builder: (context, state) {
                                    String? speciesName;
                                    String? breedName;
                                    if (pet.especieId != null) {
                                      for (final c in state.species) {
                                        if (c.id == pet.especieId) {
                                          speciesName = c.name;
                                          break;
                                        }
                                      }
                                    }
                                    if (pet.razaId != null) {
                                      for (final c in state.breeds) {
                                        if (c.id == pet.razaId) {
                                          breedName = c.name;
                                          break;
                                        }
                                      }
                                    }

                                    final speciesLabel = speciesName ?? 'Especie desconocida';
                                    final breedLabel = pet.razaId != null
                                        ? (breedName ?? 'Raza desconocida')
                                        : 'Raza desconocida';

                                    return Text(
                                      "$speciesLabel • $breedLabel",
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(pet.status),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // CHIPS
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.cake_rounded,
                          label: "${pet.edad ?? '?'} meses",
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          icon: pet.sexo.toLowerCase() == 'macho' ? Icons.male : Icons.female,
                          label: pet.sexo,
                          color: pet.sexo.toLowerCase() == 'macho' ? Colors.blue : Colors.pink,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          icon: Icons.straighten_rounded,
                          label: pet.tamano ?? '?',
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // HISTORIA
                    _buildSectionTitle("Historia"),
                    const SizedBox(height: 12),
                    Text(
                      pet.descripcion ?? "Sin historia disponible.",
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // SALUD
                    if (pet.fichaMedica != null) ...[
                      _buildSectionTitle("Salud y Bienestar"),
                      const SizedBox(height: 16),
                      _buildHealthCard(pet.fichaMedica!),
                      const SizedBox(height: 32),
                    ],

                    // GRID GALERÍA
                    if (galleryImages.isNotEmpty) ...[ 
                      _buildSectionTitle("Galería Completa"),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                        itemCount: galleryImages.length,
                        itemBuilder: (ctx, index) {
                          // index + 1 porque la 0 es la portada
                          return GestureDetector(
                            onTap: () => _openFullScreenGallery(allImages, index + 1),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                galleryImages[index], 
                                fit: BoxFit.cover,
                                loadingBuilder: (ctx, child, progress) {
                                  if (progress == null) return child;
                                  return Container(color: Colors.grey.shade100);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),

        // FAB
        floatingActionButton: widget.isAdopterView
            ? FloatingActionButton.extended(
                onPressed: () => _initiateAdoptionChat(context),
                backgroundColor: AppTheme.primaryOrange,
                elevation: 4,
                icon: const Icon(Icons.favorite_rounded, color: Colors.white),
                label: const Text(
                  'ME INTERESA',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              )
            : _isGeneratingPdf
                ? const FloatingActionButton(
                    onPressed: null,
                    backgroundColor: Colors.white,
                    child: AppLoader(color: AppTheme.primaryOrange, size: 24),
                  )
                : FloatingActionButton.extended(
                    onPressed: _generatePdf,
                    backgroundColor: AppTheme.textPrimary,
                    icon: const Icon(Icons.description_outlined, color: Colors.white),
                    label: const Text(
                      'FICHA TÉCNICA',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
      );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
        fontSize: 20,
      ),
    );
  }

  Widget _buildHealthCard(dynamic medical) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.health_and_safety_rounded, color: Colors.teal.shade700, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Peso Actual",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    Text(
                      "${medical.pesoKg} Kg",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18, 
                        color: AppTheme.textPrimary
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (medical.tieneVacunas)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield_rounded, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          "Protegido", 
                          style: TextStyle(
                            color: Colors.green.shade800, 
                            fontWeight: FontWeight.bold,
                            fontSize: 12
                          )
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildMedicalItem("Vacunas al día", medical.tieneVacunas, Icons.vaccines),
                    _buildMedicalItem("Esterilizado", medical.esEsterilizado, Icons.content_cut),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMedicalItem("Desparasitado", medical.esDesparasitado, Icons.bug_report),
                    _buildMedicalItem("Microchip", medical.tieneMicrochip, Icons.qr_code),
                  ],
                ),
              ],
            ),
          ),
          if (medical.observaciones != null && medical.observaciones!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Text(
                        "Nota Veterinaria",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    medical.observaciones!,
                    style: TextStyle(
                      color: Colors.orange.shade900.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicalItem(String label, bool value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? Colors.green : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value ? "Sí" : "No",
                  style: TextStyle(
                    color: value ? Colors.green.shade700 : Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: color.withOpacity(0.9),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'disponible':
        bg = Colors.green.shade50;
        text = Colors.green.shade700;
        break;
      case 'adoptado':
        bg = Colors.blue.shade50;
        text = Colors.blue.shade700;
        break;
      case 'en_espera':
        bg = Colors.orange.shade50;
        text = Colors.orange.shade800;
        break;
      default:
        bg = Colors.grey.shade100;
        text = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: text.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }

  void _initiateAdoptionChat(BuildContext context) {
    showAppSnackBar(
      context,
      message: "Próximamente: Chat de adopción",
      type: AppSnackBarType.info,
    );
  }
}