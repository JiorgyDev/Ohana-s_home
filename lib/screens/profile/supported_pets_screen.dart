import 'package:flutter/material.dart';
import '../../data/model/pet_model.dart';
import '../../services/pet_service.dart';
import '../../widgets/translated_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';

class SupportedPetsScreen extends StatefulWidget {
  const SupportedPetsScreen({Key? key}) : super(key: key);

  @override
  State<SupportedPetsScreen> createState() => _SupportedPetsScreenState();
}

class _SupportedPetsScreenState extends State<SupportedPetsScreen> {
  late Future<List<PetModel>> _supportedPetsFuture;

  @override
  void initState() {
    super.initState();
    _loadSupportedPets();
  }

  void _loadSupportedPets() {
    setState(() {
      _supportedPetsFuture = PetService.fetchSupportedPets();
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
            Icon(Icons.volunteer_activism, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            TranslatedText(
              'Mascotas que Apoyas',
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
          _loadSupportedPets();
          await _supportedPetsFuture;
        },
        child: FutureBuilder<List<PetModel>>(
          future: _supportedPetsFuture,
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
                      'Cargando mascotas...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // CASO 2: Error
            if (snapshot.hasError) {
              String errorMessage = '${snapshot.error}';

              // ✅ DETECTAR si el error es por falta de donaciones
              bool noHayDonaciones =
                  errorMessage.contains('no ha hecho donaciones') ||
                  errorMessage.contains('Realiza una donación');

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      noHayDonaciones
                          ? Icons.volunteer_activism
                          : Icons.error_outline,
                      color: noHayDonaciones ? Colors.grey[400] : Colors.red,
                      size: 80,
                    ),
                    SizedBox(height: 16),
                    TranslatedText(
                      noHayDonaciones
                          ? 'Realiza una donación para ver mascotas'
                          : 'Error al cargar apoyos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: noHayDonaciones ? Colors.grey[700] : Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: TranslatedText(
                        noHayDonaciones
                            ? 'Haz clic en "Apoyar" para contribuir al refugio y ver las mascotas que ayudas'
                            : errorMessage,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 24),
                    if (!noHayDonaciones)
                      ElevatedButton(
                        onPressed: _loadSupportedPets,
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

            // CASO 3: Sin apoyos (lista vacía)
            final supportedPets = snapshot.data ?? [];
            if (supportedPets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.volunteer_activism,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    TranslatedText(
                      'Realiza una donación para ver mascotas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    TranslatedText(
                      'Haz una donación única para apoyar al refugio',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // CASO 4: Grid de mascotas apoyadas (ESTILO TIKTOK)
            return Column(
              children: [
                // Header con contador
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryWithOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: TranslatedText(
                              'Gracias a tu apoyo, ${supportedPets.length} ${supportedPets.length == 1 ? "mascota tiene" : "mascotas tienen"} un hogar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      TranslatedText(
                        '🌟 Estas son las últimas mascotas del refugio que ayudas a cuidar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
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
                    itemCount: supportedPets.length,
                    itemBuilder: (context, index) {
                      final pet = supportedPets[index];
                      return _buildPetThumbnail(pet, index, supportedPets);
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

  void _openPetDetail(PetModel pet, int startIndex, List<PetModel> allPets) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupportedPetsViewer(
          pets: allPets,
          initialIndex: startIndex,
          onUpdate: _loadSupportedPets,
        ),
      ),
    );
  }
}

// ============================================
// VISOR DE MASCOTAS APOYADAS (Estilo TikTok)
// ============================================
class SupportedPetsViewer extends StatefulWidget {
  final List<PetModel> pets;
  final int initialIndex;
  final VoidCallback onUpdate;

  const SupportedPetsViewer({
    Key? key,
    required this.pets,
    required this.initialIndex,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<SupportedPetsViewer> createState() => _SupportedPetsViewerState();
}

class _SupportedPetsViewerState extends State<SupportedPetsViewer> {
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
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
              ),
            ),
          ),
        ),

        // Información de la mascota
        Positioned(
          bottom: 20,
          left: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge de "Apoyo"
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryWithOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volunteer_activism,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Mascota Apoyada',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

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

              // Descripción
              Text(
                pet.description,
                style: TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 12),

              // Info adicional
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem(Icons.favorite, '${pet.likes}', 'Likes'),
                    _buildInfoItem(
                      Icons.comment,
                      '${pet.comments}',
                      'Comentarios',
                    ),
                    _buildInfoItem(Icons.share, '${pet.shares}', 'Compartidos'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
        ),
      ],
    );
  }
}
