import 'package:flutter/material.dart';
import '../../data/model/pet_model.dart';
import '../../services/pet_service.dart';
import '../../widgets/translated_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';

class AdoptedPetsScreen extends StatefulWidget {
  const AdoptedPetsScreen({Key? key}) : super(key: key);

  @override
  State<AdoptedPetsScreen> createState() => _AdoptedPetsScreenState();
}

class _AdoptedPetsScreenState extends State<AdoptedPetsScreen> {
  late Future<List<PetModel>> _adoptedPetsFuture;

  @override
  void initState() {
    super.initState();
    _loadAdoptedPets();
  }

  void _loadAdoptedPets() {
    setState(() {
      _adoptedPetsFuture = PetService.fetchAdoptedPets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            TranslatedText(
              'Mis Adopciones',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          _loadAdoptedPets();
          await _adoptedPetsFuture;
        },
        child: FutureBuilder<List<PetModel>>(
          future: _adoptedPetsFuture,
          builder: (context, snapshot) {
            // CASO 1: Cargando
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    TranslatedText(
                      'Cargando tus adopciones...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // CASO 2: Error
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 60),
                    SizedBox(height: 16),
                    TranslatedText(
                      'Error al cargar adopciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        '${snapshot.error}',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadAdoptedPets,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: TranslatedText(
                        'Reintentar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }

            // CASO 3: Sin adopciones
            final adoptedPets = snapshot.data ?? [];
            if (adoptedPets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, size: 80, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    TranslatedText(
                      'Aún no has adoptado mascotas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    TranslatedText(
                      'Toca el botón de Adopción para apoyar',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // CASO 4: Grid de adopciones estilo TikTok
            return Column(
              children: [
                // Header con contador
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumBackgroundGradient,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: AppColors.likeActive,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      TranslatedText(
                        '${adoptedPets.length} ${adoptedPets.length == 1 ? "mascota adoptada" : "mascotas adoptadas"}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // Grid 3x3
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(2),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 1,
                    ),
                    itemCount: adoptedPets.length,
                    itemBuilder: (context, index) {
                      final pet = adoptedPets[index];
                      return _buildPetThumbnail(pet, index, adoptedPets);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPetThumbnail(PetModel pet, int index, List<PetModel> allPets) {
    return GestureDetector(
      onTap: () => _openPetDetail(pet, index, allPets),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen
          pet.imageUrls.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: pet.imageUrls[0],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[400],
                    child: Icon(Icons.error, color: Colors.white),
                  ),
                )
              : Container(
                  color: Colors.grey[400],
                  child: Icon(Icons.pets, color: Colors.white, size: 40),
                ),

          // Overlay con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
              ),
            ),
          ),

          // Badge de plan adoptado
          if (pet.adoptionInfo != null)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  _getPlanIcon(pet),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Nombre de la mascota
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Text(
              pet.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getPlanIcon(PetModel pet) {
    if (pet.adoptionInfo == null) return '🐾';

    final plan = pet.adoptionInfo!.plan;
    switch (plan) {
      case 'guardian':
        return '🛡️';
      case 'protector':
        return '⭐';
      case 'angel':
        return '👼';
      default:
        return '🐾';
    }
  }

  void _openPetDetail(PetModel pet, int startIndex, List<PetModel> allPets) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdoptedPetsViewer(
          pets: allPets,
          initialIndex: startIndex,
          onUpdate: _loadAdoptedPets,
        ),
      ),
    );
  }
}

// ============================================
// VISOR DE MASCOTAS ADOPTADAS (Estilo TikTok)
// ============================================
class AdoptedPetsViewer extends StatefulWidget {
  final List<PetModel> pets;
  final int initialIndex;
  final VoidCallback onUpdate;

  const AdoptedPetsViewer({
    Key? key,
    required this.pets,
    required this.initialIndex,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<AdoptedPetsViewer> createState() => _AdoptedPetsViewerState();
}

class _AdoptedPetsViewerState extends State<AdoptedPetsViewer> {
  late PageController _pageController;
  int _currentIndex = 0;
  late List<PetModel> _pets;

  @override
  void initState() {
    super.initState();
    _pets = List.from(widget.pets);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pets.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView de mascotas
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _pets.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final pet = _pets[index];
              return _buildPetPage(pet);
            },
          ),

          // Botón de cerrar
          SafeArea(
            child: Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: () {
                  widget.onUpdate();
                  Navigator.pop(context);
                },
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetPage(PetModel pet) {
    final adoptionInfo = pet.adoptionInfo;

    return Stack(
      children: [
        // Imagen de la mascota
        Center(
          child: pet.imageUrls.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: pet.imageUrls[0],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(Icons.error, color: Colors.white, size: 60),
                  ),
                )
              : Center(child: Icon(Icons.pets, color: Colors.white, size: 80)),
        ),

        // Gradiente inferior
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
              ),
            ),
          ),
        ),

        // Información de la adopción
        Positioned(
          bottom: 20,
          left: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre de la mascota
              Text(
                pet.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),

              // Card con info del plan
              if (adoptionInfo != null)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            _getPlanName(adoptionInfo.plan),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '\$${adoptionInfo.amount} USD/mes',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Divider(color: Colors.white.withOpacity(0.3)),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Desde',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDate(adoptionInfo.startDate),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: adoptionInfo.status == 'active'
                                  ? Colors.green
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              adoptionInfo.status == 'active'
                                  ? 'Activo'
                                  : 'Inactivo',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 12),

              // Descripción
              Text(
                pet.description,
                style: TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPlanName(String? plan) {
    switch (plan) {
      case 'guardian':
        return '🛡️ Plan Guardián';
      case 'protector':
        return '⭐ Plan Protector';
      case 'angel':
        return '👼 Plan Ángel';
      default:
        return '🐾 Plan Adoptado';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
